import pool from "../../models/db.js";

function isEClickEnabled() {
  const v = String(process.env.ECLICK_ENABLED || "").trim().toLowerCase();
  return v === "true" || v === "1" || v === "yes";
}

function hasEClickCheckoutUrl() {
  return (
    typeof process.env.ECLICK_CHECKOUT_URL === "string" &&
    process.env.ECLICK_CHECKOUT_URL.trim().length > 0
  );
}

function parseSessionId(sessionId) {
  if (!sessionId || typeof sessionId !== "string") return null;
  const parts = sessionId.split("_");
  if (parts.length < 4 || parts[0] !== "eclick") return null;
  const userId = Number(parts[1]);
  const planId = Number(parts[2]);
  if (!Number.isFinite(userId) || !Number.isFinite(planId)) return null;
  return { userId, planId };
}

function buildCheckoutUrl({ baseUrl, sessionId, userId, planId, returnUrl, cancelUrl }) {
  const url = new URL(baseUrl);
  url.searchParams.set("sessionId", sessionId);
  url.searchParams.set("userId", String(userId));
  url.searchParams.set("planId", String(planId));
  if (returnUrl) url.searchParams.set("returnUrl", returnUrl);
  if (cancelUrl) url.searchParams.set("cancelUrl", cancelUrl);
  return url.toString();
}

export const createEClickPlanCheckoutSession = async (req, res) => {
  try {
    if (!isEClickEnabled() && !hasEClickCheckoutUrl()) {
      return res.status(400).json({
        success: false,
        message:
          "eClick checkout is not configured. Set ECLICK_ENABLED=true and ECLICK_CHECKOUT_URL (or at least ECLICK_CHECKOUT_URL).",
      });
    }

    const userId = req.token?.userId;
    const planId = Number(req.body?.planId ?? req.body?.plan_id);
    if (userId === undefined || userId === null || !Number.isFinite(planId)) {
      return res.status(400).json({ success: false, message: "Missing planId" });
    }

    const userRes = await pool.query(
      "SELECT id, role_id FROM users WHERE id = $1 AND is_deleted = false",
      [userId]
    );
    if (userRes.rowCount === 0) {
      return res.status(404).json({ success: false, message: "User not found" });
    }
    const roleId = Number(userRes.rows[0].role_id);
    if (![2, 3].includes(roleId)) {
      return res.status(403).json({
        success: false,
        message: "Only clients and freelancers can subscribe to plans via eClick.",
      });
    }

    const planRes = await pool.query(
      "SELECT id FROM plans WHERE id = $1",
      [planId]
    );
    if (planRes.rowCount === 0) {
      return res.status(404).json({ success: false, message: "Plan not found" });
    }

    const activeSubscriptionCheck = await pool.query(
      `SELECT id FROM subscriptions
       WHERE freelancer_id = $1
         AND status IN ('active', 'pending_start')
         AND (end_date > NOW() OR start_date > NOW())
       LIMIT 1`,
      [userId]
    );
    if (activeSubscriptionCheck.rowCount > 0) {
      return res.status(400).json({
        success: false,
        message: "You already have an active or upcoming subscription.",
      });
    }

    const sessionId = `eclick_${userId}_${planId}_${Date.now()}`;
    const checkoutBase = (process.env.ECLICK_CHECKOUT_URL || "").trim();
    if (!checkoutBase) {
      return res.status(500).json({
        success: false,
        message: "ECLICK_CHECKOUT_URL is not configured",
      });
    }

    const returnUrl = (process.env.ECLICK_RETURN_URL || "").trim();
    const cancelUrl = (process.env.ECLICK_CANCEL_URL || "").trim();
    const checkoutUrl = buildCheckoutUrl({
      baseUrl: checkoutBase,
      sessionId,
      userId,
      planId,
      returnUrl,
      cancelUrl,
    });

    return res.json({
      success: true,
      orderId: sessionId,
      approvalUrl: checkoutUrl,
      message: "eClick checkout session created",
    });
  } catch (err) {
    console.error("[eClick] create session error:", err);
    return res.status(500).json({ success: false, message: "Failed to create eClick checkout session" });
  }
};

export const captureEClickPlanOrder = async (req, res) => {
  const orderId = String(req.body?.orderId || "").trim();
  const parsed = parseSessionId(orderId);
  if (!parsed) {
    return res.status(400).json({ success: false, message: "Invalid eClick orderId" });
  }

  const userId = req.token?.userId;
  if (userId !== parsed.userId) {
    return res.status(403).json({ success: false, message: "Order does not belong to current user" });
  }

  try {
    const planId = parsed.planId;
    const { rows: plans } = await pool.query(
      "SELECT id, price FROM plans WHERE id = $1 LIMIT 1",
      [planId]
    );
    if (plans.length === 0) {
      return res.status(404).json({ success: false, message: "Plan not found" });
    }
    const planPrice = Number(plans[0].price) || 0;

    const currentYear = new Date().getFullYear();
    const feeCheckRes = await pool.query(
      `SELECT id FROM user_yearly_fees WHERE user_id = $1 AND fee_year = $2 LIMIT 1`,
      [userId, currentYear]
    );
    const needsYearlyFee = feeCheckRes.rowCount === 0;
    const total = planPrice + (needsYearlyFee ? 25 : 0);

    const client = await pool.connect();
    try {
      await client.query("BEGIN");

      const payResult = await client.query(
        `
        INSERT INTO payments (
          user_id,
          amount,
          currency,
          purpose,
          reference_id,
          stripe_session_id,
          stripe_payment_intent,
          status
        )
        VALUES ($1, $2, 'JOD', 'plan', $3, $4, $4, 'paid')
        ON CONFLICT (stripe_session_id)
        DO UPDATE SET status = 'paid'
        RETURNING id;
        `,
        [userId, total, planId, orderId]
      );

      if (needsYearlyFee) {
        await client.query(
          `
          INSERT INTO user_yearly_fees (user_id, fee_year, stripe_session_id)
          VALUES ($1, $2, $3)
          ON CONFLICT (user_id, fee_year) DO NOTHING
          `,
          [userId, currentYear, orderId]
        );
      }

      const placeholderStart = new Date();
      placeholderStart.setHours(0, 0, 0, 0);
      const placeholderEnd = new Date(placeholderStart);

      let subInsert;
      try {
        subInsert = await client.query(
          `
          INSERT INTO subscriptions (
            freelancer_id,
            plan_id,
            start_date,
            end_date,
            status,
            activated_at,
            stripe_session_id,
            payment_source
          )
          VALUES ($1, $2, $3, $4, 'pending_start', NULL, $5, 'eclick')
          ON CONFLICT (stripe_session_id) DO NOTHING
          RETURNING id;
          `,
          [userId, planId, placeholderStart, placeholderEnd, orderId]
        );
      } catch (err) {
        if (err.message && err.message.includes("activated_at")) {
          subInsert = await client.query(
            `
            INSERT INTO subscriptions (
              freelancer_id,
              plan_id,
              start_date,
              end_date,
              status,
              stripe_session_id,
              payment_source
            )
            VALUES ($1, $2, $3, $4, 'pending_start', $5, 'eclick')
            ON CONFLICT (stripe_session_id) DO NOTHING
            RETURNING id;
            `,
            [userId, planId, placeholderStart, placeholderEnd, orderId]
          );
        } else {
          throw err;
        }
      }

      if (subInsert.rowCount === 0) {
        await client.query("COMMIT");
        return res.json({
          success: true,
          message: "Subscription already recorded.",
          idempotent: true,
        });
      }

      await client.query("COMMIT");
      return res.json({
        success: true,
        message: "Subscription recorded via eClick.",
        subscriptionId: subInsert.rows[0]?.id,
        paymentId: payResult.rows[0]?.id,
      });
    } catch (txErr) {
      await client.query("ROLLBACK").catch(() => {});
      throw txErr;
    } finally {
      client.release();
    }
  } catch (err) {
    console.error("[eClick] capture error:", err);
    if (err.code === "23505") {
      return res.json({
        success: true,
        message: "Already processed.",
        idempotent: true,
      });
    }
    return res.status(500).json({ success: false, message: String(err.message || err) });
  }
};
