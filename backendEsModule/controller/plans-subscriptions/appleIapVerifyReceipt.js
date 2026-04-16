import pool from "../../models/db.js";

const PRODUCTION_VERIFY = "https://buy.itunes.apple.com/verifyReceipt";
const SANDBOX_VERIFY = "https://sandbox.itunes.apple.com/verifyReceipt";

async function postVerifyReceipt(receiptData, password, url) {
  const res = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      "receipt-data": receiptData,
      password,
      "exclude-old-transactions": true,
    }),
  });
  return res.json();
}

function parseLatestReceiptInfo(body) {
  let info = body?.latest_receipt_info;
  if (!info) return [];
  if (typeof info === "string") {
    try {
      info = JSON.parse(info);
    } catch {
      return [];
    }
  }
  return Array.isArray(info) ? info : [info];
}

/**
 * POST /subscriptions/apple/verify-receipt
 * Body: { receiptData: string (base64), planId?: number }
 * If planId is omitted, the plan is inferred from receipt line items vs plans.apple_product_id (restore flows).
 * Authenticated clients (role 2) and freelancers (role 3).
 */
export const verifyAppleReceipt = async (req, res) => {
  const userId = req.token?.userId;
  const roleId = Number(req.token?.role ?? req.token?.roleId ?? 0);
  const { receiptData, planId } = req.body || {};

  if (!userId) {
    return res.status(401).json({ success: false, message: "Unauthorized" });
  }
  if (![2, 3].includes(roleId)) {
    return res.status(403).json({
      success: false,
      message: "Only clients and freelancers can activate subscriptions from the app",
    });
  }

  if (!receiptData || typeof receiptData !== "string") {
    return res.status(400).json({ success: false, message: "receiptData is required" });
  }
  let pid = Number(planId);
  const planIdProvided = Number.isInteger(pid) && pid > 0;

  const sharedSecret = process.env.APPLE_IAP_SHARED_SECRET;
  if (!sharedSecret || !String(sharedSecret).trim()) {
    console.error("APPLE_IAP_SHARED_SECRET is not configured");
    return res.status(503).json({
      success: false,
      message: "In-app purchases are not configured on the server. Please contact support.",
    });
  }

  const client = await pool.connect();
  try {
    let body = await postVerifyReceipt(receiptData, sharedSecret, PRODUCTION_VERIFY);
    if (body?.status === 21007) {
      body = await postVerifyReceipt(receiptData, sharedSecret, SANDBOX_VERIFY);
    }

    if (body?.status !== 0) {
      console.warn("[Apple IAP] verifyReceipt non-zero status:", body?.status);
      return res.status(400).json({
        success: false,
        message: `Apple receipt validation failed (status ${body?.status ?? "unknown"})`,
      });
    }

    const items = parseLatestReceiptInfo(body);
    const now = Date.now();
    const activeItems = items.filter((row) => Number(row.expires_date_ms || 0) > now);

    if (!activeItems.length) {
      return res.status(400).json({
        success: false,
        message:
          "No active subscription found in this receipt. If you just subscribed, wait a moment and try again.",
      });
    }

    let planRow;
    if (planIdProvided) {
      const planRes = await client.query(
        `SELECT id, name, duration, plan_type, apple_product_id FROM plans WHERE id = $1`,
        [pid]
      );
      if (!planRes.rows.length) {
        return res.status(404).json({ success: false, message: "Plan not found" });
      }
      planRow = planRes.rows[0];
      const expectedProductId = planRow.apple_product_id?.trim();
      if (!expectedProductId) {
        return res.status(400).json({
          success: false,
          message:
            "This plan is not linked to an App Store product yet. Use Subscribe from Company or pick another plan.",
        });
      }
      const matches = activeItems.filter((row) => String(row.product_id || "") === expectedProductId);
      if (!matches.length) {
        return res.status(400).json({
          success: false,
          message:
            "No active App Store line item matches this plan. Pick the plan you purchased or use Restore.",
        });
      }
      planRow._matches = matches;
    } else {
      const { rows: mappedPlans } = await client.query(
        `SELECT id, name, duration, plan_type, apple_product_id FROM plans
         WHERE apple_product_id IS NOT NULL AND trim(apple_product_id) <> ''`
      );
      const matches = [];
      for (const row of activeItems) {
        const prod = String(row.product_id || "");
        const p = mappedPlans.find((mp) => (mp.apple_product_id || "").trim() === prod);
        if (p) matches.push({ receipt: row, plan: p });
      }
      if (!matches.length) {
        return res.status(400).json({
          success: false,
          message:
            "Receipt has no product that matches a plan in the system. Ask admin to set App Store product ID on a plan.",
        });
      }
      matches.sort(
        (a, b) =>
          Number(b.receipt.expires_date_ms || 0) - Number(a.receipt.expires_date_ms || 0)
      );
      planRow = matches[0].plan;
      planRow._matches = matches.map((m) => m.receipt);
      pid = planRow.id;
    }

    const matches = planRow._matches;
    delete planRow._matches;

    const best = [...matches].sort(
      (a, b) => Number(b.expires_date_ms || 0) - Number(a.expires_date_ms || 0)
    )[0];
    const originalTx = String(best.original_transaction_id || "");
    if (!originalTx) {
      return res.status(400).json({ success: false, message: "Invalid receipt: missing transaction id" });
    }

    const expiresMs = Number(best.expires_date_ms || 0);
    const endDate = new Date(expiresMs);

    await client.query("BEGIN");

    const existing = await client.query(
      `SELECT id, freelancer_id
       FROM subscriptions
       WHERE apple_original_transaction_id = $1
       LIMIT 1`,
      [originalTx]
    );
    if (existing.rows.length > 0) {
      const ownerId = Number(existing.rows[0].freelancer_id);
      if (ownerId !== Number(userId)) {
        await client.query("ROLLBACK");
        return res.status(403).json({
          success: false,
          message: "This App Store purchase belongs to another account.",
        });
      }
      await client.query("COMMIT");
      return res.json({
        success: true,
        message: "Subscription already recorded for this Apple purchase.",
        subscription_id: existing.rows[0].id,
        idempotent: true,
      });
    }

    await client.query(
      `UPDATE users SET is_verified = true, updated_at = CURRENT_TIMESTAMP WHERE id = $1`,
      [userId]
    );

    const subInsert = await client.query(
      `INSERT INTO subscriptions (
        freelancer_id,
        plan_id,
        status,
        start_date,
        end_date,
        activated_at,
        stripe_session_id,
        apple_original_transaction_id,
        payment_source
      ) VALUES (
        $1, $2, 'active',
        CURRENT_DATE,
        $3::date,
        CURRENT_TIMESTAMP,
        NULL,
        $4,
        'apple'
      )
      RETURNING id, status, start_date, end_date`,
      [userId, pid, endDate.toISOString().slice(0, 10), originalTx]
    );

    await client.query("COMMIT");

    return res.json({
      success: true,
      message: "Subscription activated via App Store.",
      subscription: subInsert.rows[0],
    });
  } catch (err) {
    await client.query("ROLLBACK").catch(() => {});
    console.error("verifyAppleReceipt error:", err);
    if (err.code === "23505") {
      return res.json({
        success: true,
        message: "Subscription already recorded.",
        idempotent: true,
      });
    }
    return res.status(500).json({ success: false, message: "Server error" });
  } finally {
    client.release();
  }
};
