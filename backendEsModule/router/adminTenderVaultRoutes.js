import express from "express";
import authentication from "../middleware/authentication.js";
import pool from "../models/db.js";
import {
  runTenderVaultExposureRotation,
  getTenderVaultRotationDashboardSummary,
  countCurrentlyVisibleExposures,
} from "../services/tenderVaultExposureService.js";

const router = express.Router();

const canUseTestControls = (req) => {
  const isDev = process.env.NODE_ENV !== "production";
  const role = Number(req.token?.role || req.token?.roleId || 0);
  const isAdmin = role === 1;
  const enabledByEnv =
    String(process.env.ENABLE_TENDER_VAULT_TEST_ENDPOINTS || "").toLowerCase() === "true";
  return isDev || isAdmin || enabledByEnv;
};

router.use(authentication);
router.use(async (req, res, next) => {
  try {
    const userId = req.token?.userId;
    const role = Number(req.token?.role || req.token?.roleId || 0);
    const isAdmin = role === 1;
    const isClient = role === 2;
    const isDev = process.env.NODE_ENV !== "production";

    console.log("[tender-vault] test-route auth context", {
      userId: userId || null,
      role,
      isAdmin,
      isClient,
      isDev,
      url: req.originalUrl,
    });

    if (!userId) {
      return res.status(401).json({ success: false, message: "Unauthorized" });
    }

    if (isAdmin && isDev) return next();

    if (isClient) {
      const { rows } = await pool.query(
        `SELECT can_manage_tender_vault
         FROM users
         WHERE id = $1 AND is_deleted = false`,
        [userId]
      );
      if (!rows.length) {
        return res.status(404).json({ success: false, message: "User not found" });
      }
      if (!rows[0].can_manage_tender_vault) {
        return res.status(403).json({
          success: false,
          message: "Access denied. You do not have permission to manage tender vault.",
        });
      }
      return next();
    }

    return res.status(403).json({
      success: false,
      message: "Access denied for Tender Vault test routes.",
    });
  } catch (error) {
    console.error("[tender-vault] test-route auth middleware error:", error?.stack || error);
    return res.status(500).json({
      success: false,
      message: "Failed to validate Tender Vault test route access.",
      ...(process.env.NODE_ENV !== "production" && error?.message
        ? { error: error.message }
        : {}),
    });
  }
});

router.post("/test-run-rotation", async (req, res) => {
  try {
    if (!canUseTestControls(req)) {
      return res.status(403).json({
        success: false,
        message: "Tender Vault test controls are disabled.",
      });
    }

    console.log("[tender-vault] test-run-rotation hit");
    console.log("[tender-vault] test-run-rotation req", {
      userId: req.token?.userId || null,
      role: req.token?.role || req.token?.roleId || null,
    });
    console.log(
      "[tender-vault] service function:",
      runTenderVaultExposureRotation?.name || "unknown"
    );
    const result = await runTenderVaultExposureRotation();
    const summary = await getTenderVaultRotationDashboardSummary();

    return res.status(200).json({
      success: true,
      result,
      skipped: !!result?.skipped,
      reason: result?.reason || null,
      message: result?.message || null,
      batch_id: result?.batchId ?? null,
      selected_count: result?.activatedCount ?? 0,
      visible_from: summary?.active_batch_visible_from ?? null,
      visible_until: summary?.active_batch_visible_until ?? null,
      active_visible_count_now: summary?.visible_now_count ?? 0,
    });
  } catch (error) {
    console.error("adminTenderVaultRoutes /test-run-rotation error:", error?.stack || error);
    return res.status(500).json({
      success: false,
      message: "Failed to run Tender Vault rotation test.",
      ...(process.env.NODE_ENV !== "production" && error?.message
        ? { error: error.message }
        : {}),
    });
  }
});

router.post("/test-expire-current-batch", async (req, res) => {
  const client = await pool.connect();
  try {
    if (!canUseTestControls(req)) {
      return res.status(403).json({
        success: false,
        message: "Tender Vault test controls are disabled.",
      });
    }

    console.log("TEST EXPIRE CURRENT BATCH TRIGGERED");
    await client.query("BEGIN");

    const { rows: activeBatchRows } = await client.query(
      `SELECT id, cycle_number
       FROM tender_vault_rotation_batches
       WHERE visible_from <= NOW() AND visible_until > NOW()
       ORDER BY id DESC
       LIMIT 1`
    );

    if (!activeBatchRows.length) {
      await client.query("COMMIT");
      const visibleNow = await countCurrentlyVisibleExposures();
      return res.status(200).json({
        success: true,
        expired: false,
        message: "No active batch to expire.",
        active_visible_count_now: visibleNow,
      });
    }

    const batch = activeBatchRows[0];
    const { rowCount } = await client.query(
      `UPDATE tender_vault_exposures
       SET is_active = false, visible_until = NOW()
       WHERE batch_id = $1 AND is_active = true`,
      [batch.id]
    );

    await client.query(
      `UPDATE tender_vault_rotation_batches
       SET visible_until = NOW()
       WHERE id = $1`,
      [batch.id]
    );

    await client.query("COMMIT");
    const visibleNow = await countCurrentlyVisibleExposures();

    return res.status(200).json({
      success: true,
      expired: true,
      batch_id: batch.id,
      cycle_number: batch.cycle_number,
      expired_exposure_count: rowCount || 0,
      active_visible_count_now: visibleNow,
    });
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("adminTenderVaultRoutes /test-expire-current-batch error:", error?.stack || error);
    return res.status(500).json({
      success: false,
      message: "Failed to expire current Tender Vault batch.",
      ...(process.env.NODE_ENV !== "production" && error?.message
        ? { error: error.message }
        : {}),
    });
  } finally {
    client.release();
  }
});

export default router;
