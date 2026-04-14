/**
 * PayPal Orders v2 for plan checkout (capture; mirrors Stripe confirm for plans).
 * Env: PAYPAL_ENABLED=true, PAYPAL_CLIENT_ID, PAYPAL_CLIENT_SECRET, PAYPAL_MODE=sandbox|live,
 *      PAYPAL_CURRENCY=JOD, CLIENT_URL
 */
import axios from "axios";
import pool from "../../models/db.js";
import { getPayPalAccessToken, getPayPalApiBase } from "../../services/paypalAccessToken.js";

function parseCustomId(customId) {
  if (!customId || typeof customId !== "string") return null;
  const parts = customId.split("_");
  if (parts.length < 2) return null;
  const userId = Number(parts[0]);
  const planId = Number(parts[1]);
  if (!Number.isFinite(userId) || !Number.isFinite(planId)) return null;
  return { userId, planId };
}

function round2(n) {
  return Math.round(Number(n) * 100) / 100;
}

function extractCaptureDetails(orderPayload) {
  const unit = orderPayload?.purchase_units?.[0];
  const captures = unit?.payments?.captures;
  const c = Array.isArray(captures) && captures.length > 0 ? captures[0] : null;
  if (!c) return null;
  const val = c.amount?.value != null ? Number(c.amount.value) : NaN;
  return {
    captureId: c.id || null,
    amount: Number.isFinite(val) ? val : null,
    currency: (c.amount?.currency_code || "JOD").toUpperCase(),
    status: c.status || null,
  };
}

async function completeReferralIfFirstPlan(client, userId, sessionKey) {
  const existingSubscriptions = await client.query(
    "SELECT id FROM subscriptions WHERE freelancer_id = $1 AND stripe_session_id != $2",
    [userId, sessionKey]
  );
  if (existingSubscriptions.rowCount > 0) return;

  try {
    const referralResult = await client.query(
      `
      SELECT id, referrer_user_id, status
      FROM referrals
      WHERE referred_user_id = $1 AND status = 'pending'
      LIMIT 1
      `,
      [userId]
    );
    if (referralResult.rows.length === 0) return;

    const referral = referralResult.rows[0];
    const referralId = referral.id;
    const referrerUserId = referral.referrer_user_id;
    const referrerReward = 5.0;

    await client.query(
      `UPDATE referrals SET status = 'completed', completed_at = CURRENT_TIMESTAMP WHERE id = $1`,
      [referralId]
    );
    await client.query(
      `INSERT INTO referral_rewards (user_id, referral_id, amount, type) VALUES ($1, $2, $3, 'referral')`,
      [referrerUserId, referralId, referrerReward]
    );
  } catch (err) {
    console.error("[PayPal] Referral completion error:", err);
  }
}

/**
 * POST /paypal/plan/create-order  { planId }  (auth)
 */
export const createPayPalPlanOrder = async (req, res) => {
  try {
    if (process.env.PAYPAL_ENABLED !== "true") {
      return res.status(400).json({
        success: false,
        message: "PayPal checkout is disabled (set PAYPAL_ENABLED=true).",
      });
    }

    const userId = req.token?.userId;
    const planId = Number(req.body?.planId ?? req.body?.plan_id);
    if (!userId || !Number.isFinite(planId)) {
      return res.status(400).json({ success: false, message: "Missing planId" });
    }

    const userRes = await pool.query(
      "SELECT id, role_id FROM users WHERE id = $1 AND is_deleted = false",
      [userId]
    );
    if (userRes.rowCount === 0) {
      return res.status(404).json({ success: false, message: "User not found" });
    }
    const user = userRes.rows[0];
    const roleId = Number(user.role_id);
    if (![2, 3].includes(roleId)) {
      return res.status(403).json({
        success: false,
        message: "Only clients and freelancers can subscribe to plans via PayPal.",
      });
    }

    const planRes = await pool.query(
      "SELECT id, name, description, price, duration, plan_type FROM plans WHERE id = $1",
      [planId]
    );
    if (planRes.rowCount === 0) {
      return res.status(404).json({ success: false, message: "Plan not found" });
    }
    const plan = planRes.rows[0];
    const planPrice = Number(plan.price) || 0;

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

    const currentYear = new Date().getFullYear();
    const feeCheckRes = await pool.query(
      `SELECT id FROM user_yearly_fees WHERE user_id = $1 AND fee_year = $2 LIMIT 1`,
      [userId, currentYear]
    );
    const needsYearlyFee = feeCheckRes.rowCount === 0;

    let total = planPrice;
    if (needsYearlyFee) total += 25;
    if (planPrice === 0 && !needsYearlyFee && total === 0) {
      return res.status(400).json({
        success: false,
        message: "Nothing to charge for this plan. Use another option.",
      });
    }
    if (total <= 0) {
      return res.status(400).json({ success: false, message: "Invalid amount" });
    }

    const currency = (process.env.PAYPAL_CURRENCY || "JOD").toUpperCase();
    const valueStr = round2(total).toFixed(2);

    const clientUrl = (process.env.CLIENT_URL || "").replace(/\/$/, "");
    if (!clientUrl) {
      return res.status(500).json({
        success: false,
        message: "CLIENT_URL is not configured",
      });
    }

    const customId = `${userId}_${planId}_${Date.now()}`;
    const token = await getPayPalAccessToken();
    const base = getPayPalApiBase();

    const payload = {
      intent: "CAPTURE",
      purchase_units: [
        {
          amount: {
            currency_code: currency,
            value: valueStr,
          },
          description: String(plan.name || "Plan subscription").slice(0, 127),
          custom_id: customId,
        },
      ],
      application_context: {
        brand_name: process.env.PAYPAL_BRAND_NAME || "OrderzHouse",
        landing_page: "NO_PREFERENCE",
        user_action: "PAY_NOW",
        return_url: `${clientUrl}/payment/paypal-return?done=1`,
        cancel_url: `${clientUrl}/payment/paypal-cancel`,
      },
    };

    const { data } = await axios.post(`${base}/v2/checkout/orders`, payload, {
      headers: {
        Authorization: `Bearer ${token}`,
        "Content-Type": "application/json",
        Prefer: "return=representation",
      },
      timeout: 60000,
    });

    const orderId = data?.id;
    const links = Array.isArray(data?.links) ? data.links : [];
    const approve = links.find((l) => l.rel === "approve" || l.rel === "payer-action");
    const approvalUrl = approve?.href;

    if (!orderId || !approvalUrl) {
      console.error("[PayPal] create order unexpected response:", data);
      return res.status(502).json({
        success: false,
        message: "PayPal did not return an approval URL.",
      });
    }

    return res.json({
      success: true,
      orderId,
      approvalUrl,
      customId,
    });
  } catch (err) {
    console.error("[PayPal] createPayPalPlanOrder:", err?.response?.data || err.message);
    const msg =
      err?.response?.data?.message ||
      err?.response?.data?.details?.[0]?.description ||
      err.message ||
      "PayPal error";
    return res.status(500).json({ success: false, message: String(msg) });
  }
};

/**
 * POST /paypal/plan/capture  { orderId }  (auth)
 */
export const capturePayPalPlanOrder = async (req, res) => {
  if (process.env.PAYPAL_ENABLED !== "true") {
    return res.status(400).json({ success: false, message: "PayPal disabled" });
  }

  const userId = req.token?.userId;
  const orderId = String(req.body?.orderId || "").trim();
  if (!userId || !orderId) {
    return res.status(400).json({ success: false, message: "Missing orderId" });
  }

  const sessionKey = `paypal_${orderId}`;

  const existingSub = await pool.query(
    `SELECT id FROM subscriptions WHERE stripe_session_id = $1 LIMIT 1`,
    [sessionKey]
  );
  if (existingSub.rowCount > 0) {
    return res.json({
      success: true,
      message: "Subscription already recorded for this PayPal order.",
      idempotent: true,
    });
  }

  try {
    const token = await getPayPalAccessToken();
    const base = getPayPalApiBase();

    const { data: orderGet } = await axios.get(`${base}/v2/checkout/orders/${orderId}`, {
      headers: { Authorization: `Bearer ${token}` },
      timeout: 60000,
    });

    const status = orderGet?.status;
    if (status !== "APPROVED" && status !== "COMPLETED") {
      return res.status(400).json({
        success: false,
        message: `Order not ready to capture (status: ${status || "unknown"}). Approve payment in PayPal first.`,
      });
    }

    const unit0 = orderGet?.purchase_units?.[0];
    const customId = unit0?.custom_id;
    const parsed = parseCustomId(customId);
    if (!parsed || parsed.userId !== userId) {
      return res.status(403).json({
        success: false,
        message: "This PayPal order does not belong to your account.",
      });
    }
    const planId = parsed.planId;

    let orderPayload = orderGet;
    if (status === "APPROVED") {
      const cap = await axios.post(
        `${base}/v2/checkout/orders/${orderId}/capture`,
        {},
        {
          headers: {
            Authorization: `Bearer ${token}`,
            "Content-Type": "application/json",
            Prefer: "return=representation",
          },
          timeout: 60000,
        }
      );
      orderPayload = cap.data;
    }

    const capDetails = extractCaptureDetails(orderPayload);
    if (!capDetails || capDetails.status !== "COMPLETED") {
      return res.status(400).json({
        success: false,
        message: `Capture not completed (status: ${capDetails?.status || "unknown"})`,
      });
    }

    const amountPaid = capDetails.amount;
    if (amountPaid == null || amountPaid <= 0) {
      return res.status(400).json({ success: false, message: "Invalid captured amount" });
    }

    const planRow = await pool.query(
      "SELECT id, price, duration, plan_type FROM plans WHERE id = $1",
      [planId]
    );
    if (planRow.rowCount === 0) {
      return res.status(404).json({ success: false, message: "Plan not found" });
    }
    const plan = planRow.rows[0];
    const planPrice = Number(plan.price) || 0;

    const currentYear = new Date().getFullYear();
    const feeCheckRes = await pool.query(
      `SELECT id FROM user_yearly_fees WHERE user_id = $1 AND fee_year = $2 LIMIT 1`,
      [userId, currentYear]
    );
    const needsYearlyFee = feeCheckRes.rowCount === 0;
    let expected = planPrice;
    if (needsYearlyFee) expected += 25;
    const diff = Math.abs(round2(amountPaid) - round2(expected));
    if (diff > 0.05) {
      console.warn("[PayPal] Amount mismatch:", {
        amountPaid,
        expected,
        userId,
        planId,
        orderId,
      });
      return res.status(400).json({
        success: false,
        message: "Captured amount does not match the order. Contact support if money was taken.",
      });
    }

    const currency = (capDetails.currency || process.env.PAYPAL_CURRENCY || "JOD").toUpperCase();
    const captureId = capDetails.captureId;

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
      VALUES ($1, $2, $3, 'plan', $4, $5, $6, 'paid')
      ON CONFLICT (stripe_session_id)
      DO UPDATE SET status = 'paid'
      RETURNING id;
      `,
      [userId, amountPaid, currency, planId, sessionKey, captureId]
    );

    if (needsYearlyFee) {
      await client.query(
        `
        INSERT INTO user_yearly_fees (user_id, fee_year, stripe_session_id)
        VALUES ($1, $2, $3)
        ON CONFLICT (user_id, fee_year) DO NOTHING
        `,
        [userId, currentYear, sessionKey]
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
        VALUES ($1, $2, $3, $4, 'pending_start', NULL, $5, 'paypal')
        ON CONFLICT (stripe_session_id) DO NOTHING
        RETURNING id;
        `,
        [userId, planId, placeholderStart, placeholderEnd, sessionKey]
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
          VALUES ($1, $2, $3, $4, 'pending_start', $5, 'paypal')
          ON CONFLICT (stripe_session_id) DO NOTHING
          RETURNING id;
          `,
          [userId, planId, placeholderStart, placeholderEnd, sessionKey]
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

    await completeReferralIfFirstPlan(client, userId, sessionKey);

    await client.query("COMMIT");

    return res.json({
      success: true,
      message: "Subscription activated via PayPal.",
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
    console.error("[PayPal] capturePayPalPlanOrder:", err?.response?.data || err);
    if (err.code === "23505") {
      return res.json({
        success: true,
        message: "Already processed.",
        idempotent: true,
      });
    }
    const msg =
      err?.response?.data?.message ||
      err?.response?.data?.details?.[0]?.description ||
      err.message;
    return res.status(500).json({ success: false, message: String(msg) });
  }
};
