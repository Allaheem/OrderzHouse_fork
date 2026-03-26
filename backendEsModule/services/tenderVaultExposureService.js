import pool from "../models/db.js";

const MIN_ELIGIBLE_TO_ROTATE = 300;
const BATCH_MIN = 50;
const BATCH_MAX = 70;
const EXPOSURE_HOURS = 12;
const ROTATION_INTERVAL_HOURS = 12;

const randomInt = (min, max) =>
  Math.floor(Math.random() * (max - min + 1)) + min;

const isExposedPublicId = (value) => /^TVX-\d+$/.test(String(value || "").trim());
let schemaCheckDone = false;

const isDev = process.env.NODE_ENV !== "production";

const logStep = (name, details = {}) => {
  console.log(`[tender-vault][service] ${name}`, details);
};

export const parseExposedPublicId = (value) => {
  if (!isExposedPublicId(value)) return null;
  return Number(String(value).trim().slice(4));
};

async function ensureExposureSchema(dbClient = pool) {
  if (schemaCheckDone) return;
  logStep("schema-check:start");

  await dbClient.query(
    `ALTER TABLE IF EXISTS tender_vault_rotation_batches
     ADD COLUMN IF NOT EXISTS cycle_number INTEGER`
  );
  await dbClient.query(
    `UPDATE tender_vault_rotation_batches
     SET cycle_number = 1
     WHERE cycle_number IS NULL`
  );

  await dbClient.query(
    `ALTER TABLE IF EXISTS tender_vault_projects
     ADD COLUMN IF NOT EXISTS exposure_count INTEGER NOT NULL DEFAULT 0`
  );
  await dbClient.query(
    `ALTER TABLE IF EXISTS tender_vault_projects
     ADD COLUMN IF NOT EXISTS last_exposed_at TIMESTAMP`
  );
  await dbClient.query(
    `ALTER TABLE IF EXISTS tender_vault_projects
     ADD COLUMN IF NOT EXISTS last_exposure_ended_at TIMESTAMP`
  );
  await dbClient.query(
    `ALTER TABLE IF EXISTS tender_vault_projects
     ADD COLUMN IF NOT EXISTS last_shown_cycle_number INTEGER`
  );

  schemaCheckDone = true;
  logStep("schema-check:done");
}

export async function deactivateExpiredExposures(dbClient = pool) {
  const { rowCount } = await dbClient.query(
    `UPDATE tender_vault_exposures
     SET is_active = false
     WHERE is_active = true
       AND visible_until <= NOW()`
  );
  return rowCount || 0;
}

export async function countEligiblePublishedTenders(dbClient = pool) {
  const { rows } = await dbClient.query(
    `SELECT COUNT(*)::int AS cnt
     FROM tender_vault_projects tv
     WHERE tv.status = 'published'
       AND tv.is_deleted = false`
  );
  return Number(rows[0]?.cnt || 0);
}

export async function countCurrentlyVisibleExposures(dbClient = pool) {
  const { rows } = await dbClient.query(
    `WITH active_batch AS (
       SELECT id
       FROM tender_vault_rotation_batches
       WHERE visible_from <= NOW() AND visible_until > NOW()
       ORDER BY id DESC
       LIMIT 1
     )
     SELECT COUNT(*)::int AS cnt
     FROM tender_vault_exposures e
     JOIN tender_vault_projects tv ON tv.id = e.tender_vault_project_id
     JOIN active_batch ab ON ab.id = e.batch_id
     WHERE e.is_active = true
       AND e.visible_from <= NOW()
       AND e.visible_until > NOW()
       AND tv.status = 'published'
       AND tv.is_deleted = false`
  );
  return Number(rows[0]?.cnt || 0);
}

async function normalizeOverlappingActiveBatches(dbClient = pool) {
  const { rows: activeRows } = await dbClient.query(
    `SELECT id
     FROM tender_vault_rotation_batches
     WHERE visible_from <= NOW() AND visible_until > NOW()
     ORDER BY id DESC`
  );
  if (activeRows.length <= 1) {
    return { cleaned: false, activeBatchId: activeRows[0]?.id || null };
  }

  const keepBatchId = Number(activeRows[0].id);
  const staleBatchIds = activeRows.slice(1).map((r) => Number(r.id));
  logStep("active-window:cleanup", {
    keepBatchId,
    staleBatchIds,
  });

  await dbClient.query(
    `UPDATE tender_vault_exposures
     SET is_active = false, visible_until = NOW()
     WHERE is_active = true
       AND batch_id = ANY($1::bigint[])`,
    [staleBatchIds]
  );

  await dbClient.query(
    `UPDATE tender_vault_rotation_batches
     SET visible_until = NOW()
     WHERE id = ANY($1::bigint[])`,
    [staleBatchIds]
  );

  return { cleaned: true, activeBatchId: keepBatchId };
}

async function getCurrentActiveBatch(dbClient = pool) {
  const { rows } = await dbClient.query(
    `SELECT id, selected_count, cycle_number, visible_from, visible_until
     FROM tender_vault_rotation_batches
     WHERE visible_from <= NOW() AND visible_until > NOW()
     ORDER BY id DESC
     LIMIT 1`
  );
  return rows[0] || null;
}

export async function runTenderVaultExposureRotation() {
  const client = await pool.connect();
  try {
    logStep("run-rotation:entry");
    await ensureExposureSchema(client);
    await client.query("BEGIN");
    logStep("run-rotation:transaction-begin");

    const normalized = await normalizeOverlappingActiveBatches(client);
    if (normalized.cleaned) {
      logStep("run-rotation:normalized-overlap", normalized);
    }

    const expiredCount = await deactivateExpiredExposures(client);
    const eligibleCount = await countEligiblePublishedTenders(client);
    logStep("run-rotation:counts", { expiredCount, eligibleCount });

    const activeBatch = await getCurrentActiveBatch(client);
    if (activeBatch) {
      await client.query("COMMIT");
      return {
        skipped: true,
        reason: "active_batch_running",
        message: "Active batch already running. Wait until it ends or expire it manually.",
        activeBatchId: activeBatch.id,
        activeBatchVisibleUntil: activeBatch.visible_until,
        activeBatchSelectedCount: Number(activeBatch.selected_count || 0),
        expiredCount,
        eligibleCount,
        activatedCount: 0,
      };
    }

    if (eligibleCount < MIN_ELIGIBLE_TO_ROTATE) {
      await writeRotationLog(client, {
        selectedCount: 0,
        status: "skipped",
        errorMessage: `Minimum threshold not reached (${eligibleCount}/${MIN_ELIGIBLE_TO_ROTATE})`,
      });
      await client.query("COMMIT");
      return {
        skipped: true,
        reason: "minimum_threshold_not_reached",
        message: `Minimum threshold not reached (${eligibleCount}/${MIN_ELIGIBLE_TO_ROTATE}).`,
        expiredCount,
        eligibleCount,
        activatedCount: 0,
      };
    }

    const cycleResult = await client.query(
      `SELECT COALESCE(MAX(cycle_number), 1)::int AS current_cycle
       FROM tender_vault_rotation_batches`
    );
    let cycleNumber = Number(cycleResult.rows[0]?.current_cycle || 1);
    logStep("run-rotation:cycle-read", { cycleNumber });

    const unseenCountInCurrentCycle = await countUnseenEligibleInCycle(
      client,
      cycleNumber
    );

    // Fairness rule: no repeat in same cycle until every currently eligible tender is shown once.
    if (unseenCountInCurrentCycle === 0) {
      cycleNumber += 1;
      logStep("run-rotation:cycle-advanced", { cycleNumber });
    }

    const unseenCount = await countUnseenEligibleInCycle(client, cycleNumber);
    if (unseenCount === 0) {
      await writeRotationLog(client, {
        selectedCount: 0,
        status: "skipped",
        errorMessage: `No unseen eligible tenders for cycle ${cycleNumber}`,
      });
      await client.query("COMMIT");
      return {
        skipped: true,
        reason: "no_unseen_eligible",
        message: `No unseen eligible tenders for cycle ${cycleNumber}.`,
        expiredCount,
        eligibleCount,
        activatedCount: 0,
        cycleNumber,
      };
    }

    const requestedCount = randomInt(BATCH_MIN, BATCH_MAX);
    const selectedCount = Math.min(requestedCount, unseenCount);
    logStep("run-rotation:selection-target", { requestedCount, selectedCount, unseenCount });

    // For the current expected pool size (hundreds/thousands), ORDER BY RANDOM() is
    // simple, reliable, and keeps the rotation logic easy to maintain.
    const { rows: selectedRows } = await client.query(
      `WITH eligible_unseen AS (
         SELECT tv.id
         FROM tender_vault_projects tv
         WHERE tv.status = 'published'
           AND tv.is_deleted = false
           AND NOT EXISTS (
             SELECT 1
             FROM tender_vault_exposures e
             WHERE e.tender_vault_project_id = tv.id
               AND e.is_active = true
               AND e.visible_from <= NOW()
               AND e.visible_until > NOW()
           )
           AND NOT EXISTS (
             SELECT 1
             FROM tender_vault_exposures e_cycle
             JOIN tender_vault_rotation_batches b_cycle ON b_cycle.id = e_cycle.batch_id
             WHERE b_cycle.cycle_number = $1
               AND e_cycle.tender_vault_project_id = tv.id
           )
       )
       SELECT id
       FROM eligible_unseen
       ORDER BY RANDOM()
       LIMIT $2`,
      [cycleNumber, selectedCount]
    );

    if (!selectedRows.length) {
      await writeRotationLog(client, {
        selectedCount: 0,
        status: "skipped",
        errorMessage: `Selection returned zero rows for cycle ${cycleNumber}`,
      });
      await client.query("COMMIT");
      return { skipped: true, expiredCount, eligibleCount, activatedCount: 0, cycleNumber };
    }

    const selectedTenderIds = selectedRows.map((r) => r.id);
    logStep("run-rotation:selected", { selectedCount: selectedTenderIds.length });

    const { rows: batchRows } = await client.query(
      `INSERT INTO tender_vault_rotation_batches (selected_count, visible_from, visible_until, cycle_number)
       VALUES ($1, NOW(), NOW() + ($2::text || ' hours')::interval, $3)
       RETURNING id, visible_from, visible_until, cycle_number`,
      [selectedTenderIds.length, String(EXPOSURE_HOURS), cycleNumber]
    );

    const batch = batchRows[0];
    logStep("run-rotation:batch-created", { batchId: batch?.id, cycleNumber: batch?.cycle_number });
    await client.query(
      `INSERT INTO tender_vault_exposures (
         tender_vault_project_id,
         batch_id,
         visible_from,
         visible_until,
         is_active
       )
       SELECT x.tender_id, $1, $2, $3, true
       FROM UNNEST($4::int[]) AS x(tender_id)
       ON CONFLICT DO NOTHING`,
      [batch.id, batch.visible_from, batch.visible_until, selectedTenderIds]
    );

    await client.query(
      `UPDATE tender_vault_projects
       SET exposure_count = COALESCE(exposure_count, 0) + 1,
           last_exposed_at = $1,
           last_exposure_ended_at = $2,
           last_shown_cycle_number = $3
       WHERE id = ANY($4::int[])`,
      [batch.visible_from, batch.visible_until, cycleNumber, selectedTenderIds]
    );

    await writeRotationLog(client, {
      selectedCount: selectedTenderIds.length,
      status: "success",
      errorMessage: null,
    });

    await client.query("COMMIT");
    logStep("run-rotation:commit", { activatedCount: selectedTenderIds.length });
    return {
      skipped: false,
      expiredCount,
      eligibleCount,
      activatedCount: selectedTenderIds.length,
      batchId: batch.id,
      cycleNumber,
      requestedCount,
      unseenCountBeforeSelection: unseenCount,
    };
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("[tender-vault][service] run-rotation failed:", error?.stack || error);
    throw error;
  } finally {
    client.release();
  }
}

async function countUnseenEligibleInCycle(dbClient, cycleNumber) {
  const { rows } = await dbClient.query(
    `SELECT COUNT(*)::int AS cnt
     FROM tender_vault_projects tv
     WHERE tv.status = 'published'
       AND tv.is_deleted = false
       AND NOT EXISTS (
         SELECT 1
         FROM tender_vault_exposures e
         JOIN tender_vault_rotation_batches b ON b.id = e.batch_id
         WHERE b.cycle_number = $1
           AND e.tender_vault_project_id = tv.id
       )`,
    [cycleNumber]
  );
  return Number(rows[0]?.cnt || 0);
}

async function writeRotationLog(dbClient, { selectedCount, status, errorMessage }) {
  try {
    await dbClient.query(
      `INSERT INTO tender_rotation_logs (
         triggered_by_user_id, selected_count, skipped_cooldown, skipped_max_usage, skipped_archived,
         execution_time_ms, status, error_message
       )
       VALUES (NULL, $1, 0, 0, 0, 0, $2, $3)`,
      [selectedCount || 0, status || "success", errorMessage || null]
    );
  } catch (_) {
    // Best-effort logging only; rotation must not fail due to logs table schema drift.
  }
}

export async function getTenderVaultRotationDashboardSummary() {
  await ensureExposureSchema(pool);
  logStep("summary:entry");
  const { rows } = await pool.query(
    `WITH status_counts AS (
       SELECT
         COUNT(*) FILTER (WHERE status = 'stored' AND is_deleted = false)::int AS stored_count,
         COUNT(*) FILTER (WHERE status = 'published' AND is_deleted = false)::int AS published_count,
         COUNT(*) FILTER (WHERE status = 'archived' AND is_deleted = false)::int AS archived_count
       FROM tender_vault_projects
     ),
     eligible AS (
       SELECT COUNT(*)::int AS eligible_count
       FROM tender_vault_projects
       WHERE status = 'published' AND is_deleted = false
     ),
     visible AS (
       SELECT COUNT(*)::int AS visible_now_count
       FROM tender_vault_exposures e
       JOIN tender_vault_projects tv ON tv.id = e.tender_vault_project_id
       WHERE e.is_active = true
         AND e.batch_id = (
           SELECT id
           FROM tender_vault_rotation_batches
           WHERE visible_from <= NOW() AND visible_until > NOW()
           ORDER BY id DESC
           LIMIT 1
         )
         AND e.visible_from <= NOW()
         AND e.visible_until > NOW()
         AND tv.status = 'published'
         AND tv.is_deleted = false
     ),
     latest_batch AS (
       SELECT id, selected_count, cycle_number, visible_from, visible_until
       FROM tender_vault_rotation_batches
       ORDER BY id DESC
       LIMIT 1
     ),
     active_batch AS (
       SELECT id, selected_count, cycle_number, visible_from, visible_until
       FROM tender_vault_rotation_batches
       WHERE visible_from <= NOW() AND visible_until > NOW()
       ORDER BY id DESC
       LIMIT 1
     ),
     cycle_ref AS (
       SELECT COALESCE((SELECT cycle_number FROM latest_batch), 1)::int AS current_cycle
     ),
     shown_cycle AS (
       SELECT COUNT(DISTINCT e.tender_vault_project_id)::int AS shown_in_cycle_count
       FROM tender_vault_exposures e
       JOIN tender_vault_rotation_batches b ON b.id = e.batch_id
       JOIN tender_vault_projects tv ON tv.id = e.tender_vault_project_id
       JOIN cycle_ref cr ON cr.current_cycle = b.cycle_number
       WHERE tv.status = 'published' AND tv.is_deleted = false
     )
     SELECT
       sc.stored_count,
       sc.published_count,
       sc.archived_count,
       el.eligible_count,
       vi.visible_now_count,
       300::int AS minimum_threshold,
       (el.eligible_count >= 300) AS rotation_active,
       cr.current_cycle,
       lb.id AS latest_batch_id,
       lb.selected_count AS latest_batch_selected_count,
       lb.visible_from AS latest_batch_visible_from,
       lb.visible_until AS latest_batch_visible_until,
       ab.id AS active_batch_id,
       ab.selected_count AS active_batch_selected_count,
       ab.visible_from AS active_batch_visible_from,
       ab.visible_until AS active_batch_visible_until,
       sh.shown_in_cycle_count,
       GREATEST(el.eligible_count - sh.shown_in_cycle_count, 0)::int AS unseen_in_cycle_count,
       CASE
         WHEN el.eligible_count = 0 THEN 0
         ELSE ROUND((sh.shown_in_cycle_count::numeric / el.eligible_count::numeric) * 100, 2)
       END AS cycle_completion_percent,
       CASE
         WHEN ab.id IS NOT NULL THEN EXTRACT(EPOCH FROM (ab.visible_until - NOW()))::bigint
         ELSE NULL
       END AS active_batch_remaining_seconds,
       CASE
         WHEN ab.id IS NOT NULL THEN ab.visible_until
         WHEN lb.id IS NOT NULL THEN lb.visible_until + INTERVAL '${ROTATION_INTERVAL_HOURS} hours'
         ELSE NULL
       END AS next_rotation_estimate
     FROM status_counts sc, eligible el, visible vi, cycle_ref cr, shown_cycle sh
     LEFT JOIN latest_batch lb ON true
     LEFT JOIN active_batch ab ON true`
  );

  const summary = rows[0] || {};
  logStep("summary:computed", {
    eligible_count: summary?.eligible_count ?? 0,
    visible_now_count: summary?.visible_now_count ?? 0,
    current_cycle: summary?.current_cycle ?? 1,
  });
  return {
    ...summary,
    fairness_rule:
      "No tender repeats in the same cycle until all currently eligible published tenders are shown once.",
    behavior_notes: [
      "Published tenders join the eligible pool immediately.",
      "Every 12 hours, 50-70 tenders are exposed publicly for 12 hours.",
      "If unseen tenders remaining are fewer than the random target, all remaining unseen are shown and cycle ends cleanly.",
      "Archived/unpublished/deleted tenders are excluded from eligibility and cycle progress math.",
    ],
  };
}

export async function fetchActiveExposedTenderVaultProjects(filters = {}) {
  const { categoryId, subCategoryId, subSubCategoryId, search } = filters;
  const params = [];
  let p = 1;
  let where = `
    e.is_active = true
    AND e.visible_from <= NOW()
    AND e.visible_until > NOW()
    AND tv.status = 'published'
    AND tv.is_deleted = false
  `;

  if (categoryId) {
    where += ` AND tv.category_id = $${p++}`;
    params.push(Number(categoryId));
  }
  if (subCategoryId) {
    where += ` AND (tv.metadata->>'sub_category_id')::int = $${p++}`;
    params.push(Number(subCategoryId));
  }
  if (subSubCategoryId) {
    where += ` AND (tv.metadata->>'sub_sub_category_id')::int = $${p++}`;
    params.push(Number(subSubCategoryId));
  }
  if (search && String(search).trim()) {
    where += ` AND (tv.title ILIKE $${p} OR tv.description ILIKE $${p})`;
    params.push(`%${String(search).trim()}%`);
    p++;
  }

  const { rows } = await pool.query(
    `WITH active_batch AS (
       SELECT id
       FROM tender_vault_rotation_batches
       WHERE visible_from <= NOW() AND visible_until > NOW()
       ORDER BY id DESC
       LIMIT 1
     )
     SELECT
      CONCAT('TVX-', e.id::text) AS id,
      tv.id AS tender_vault_project_id,
      e.id AS exposure_id,
      e.batch_id AS rotation_id,
      tv.title,
      tv.description,
      tv.category_id,
      (tv.metadata->>'sub_category_id')::int AS sub_category_id,
      (tv.metadata->>'sub_sub_category_id')::int AS sub_sub_category_id,
      tv.budget_min,
      tv.budget_max,
      tv.currency,
      tv.duration,
      tv.attachments,
      tv.metadata,
      tv.created_at,
      tv.updated_at,
      tv.created_by AS user_id,
      'bidding' AS project_type,
      'bidding' AS status,
      'not_started' AS completion_status,
      false AS is_deleted,
      NULL AS budget,
      NULL AS hourly_rate,
      NULL AS preferred_skills,
      NULL AS cover_pic,
      tv.duration AS duration_days,
      NULL::int AS duration_hours,
      'days' AS duration_type,
      u.username AS client_username,
      u.first_name,
      u.last_name,
      u.profile_pic_url,
      c.name AS category_name,
      sc.name AS sub_category_name,
      ssc.name AS sub_sub_category_name,
      'tender_vault' AS source_type,
      false AS is_actionable,
      true AS is_rotated_demo
    FROM tender_vault_exposures e
    JOIN active_batch ab ON ab.id = e.batch_id
    JOIN tender_vault_projects tv ON tv.id = e.tender_vault_project_id
    LEFT JOIN users u ON u.id = tv.created_by
    LEFT JOIN categories c ON c.id = tv.category_id
    LEFT JOIN sub_categories sc ON sc.id = (tv.metadata->>'sub_category_id')::int
    LEFT JOIN sub_sub_categories ssc ON ssc.id = (tv.metadata->>'sub_sub_category_id')::int
    WHERE ${where}`,
    params
  );

  return rows;
}

export async function fetchExposedTenderByPublicId(publicId) {
  const exposureId = parseExposedPublicId(publicId);
  if (!exposureId) return null;

  const { rows } = await pool.query(
    `WITH active_batch AS (
       SELECT id
       FROM tender_vault_rotation_batches
       WHERE visible_from <= NOW() AND visible_until > NOW()
       ORDER BY id DESC
       LIMIT 1
     )
     SELECT
      CONCAT('TVX-', e.id::text) AS id,
      tv.id AS tender_vault_project_id,
      e.id AS exposure_id,
      e.batch_id AS rotation_id,
      tv.title,
      tv.description,
      tv.category_id,
      (tv.metadata->>'sub_category_id')::int AS sub_category_id,
      (tv.metadata->>'sub_sub_category_id')::int AS sub_sub_category_id,
      tv.budget_min,
      tv.budget_max,
      tv.currency,
      tv.duration,
      tv.attachments,
      tv.metadata,
      tv.created_at,
      tv.updated_at,
      tv.created_by AS user_id,
      'bidding' AS project_type,
      'bidding' AS status,
      'not_started' AS completion_status,
      false AS is_deleted,
      NULL AS budget,
      NULL AS hourly_rate,
      NULL AS preferred_skills,
      NULL AS cover_pic,
      tv.duration AS duration_days,
      NULL::int AS duration_hours,
      'days' AS duration_type,
      u.username AS client_username,
      u.email AS client_email,
      u.first_name,
      u.last_name,
      u.profile_pic_url,
      c.name AS category_name,
      sc.name AS sub_category_name,
      ssc.name AS sub_sub_category_name,
      'tender_vault' AS source_type,
      false AS is_actionable,
      true AS is_rotated_demo
    FROM tender_vault_exposures e
    JOIN active_batch ab ON ab.id = e.batch_id
    JOIN tender_vault_projects tv ON tv.id = e.tender_vault_project_id
    LEFT JOIN users u ON u.id = tv.created_by
    LEFT JOIN categories c ON c.id = tv.category_id
    LEFT JOIN sub_categories sc ON sc.id = (tv.metadata->>'sub_category_id')::int
    LEFT JOIN sub_sub_categories ssc ON ssc.id = (tv.metadata->>'sub_sub_category_id')::int
    WHERE e.id = $1
      AND e.is_active = true
      AND e.visible_from <= NOW()
      AND e.visible_until > NOW()
      AND tv.status = 'published'
      AND tv.is_deleted = false
    LIMIT 1`,
    [exposureId]
  );

  return rows[0] || null;
}
