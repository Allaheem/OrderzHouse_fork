import pool from "../models/db.js";
import { getProjectParticipants, isAdmin } from "../services/chatParticipantAccess.js";
import {
  createBulkNotifications,
  NOTIFICATION_TYPES,
} from "../services/notificationService.js";

async function getAdminIds() {
  const { rows } = await pool.query(
    `SELECT id FROM users WHERE role_id = 1 AND is_deleted = false`
  );
  return rows.map((r) => r.id);
}

async function getUserDisplayName(userId) {
  const { rows } = await pool.query(
    `SELECT first_name, last_name FROM users WHERE id = $1 AND is_deleted = false`,
    [userId]
  );
  if (!rows.length) return `User #${userId}`;
  const fn = rows[0].first_name || "";
  const ln = rows[0].last_name || "";
  const name = `${fn} ${ln}`.trim();
  return name || `User #${userId}`;
}

async function assertSharedProject(projectId, userA, userB) {
  const participants = await getProjectParticipants(projectId);
  const a = Number(userA);
  const b = Number(userB);
  if (!participants.includes(a) || !participants.includes(b)) {
    return { ok: false, message: "Users must both participate in this project" };
  }
  return { ok: true };
}

/** GET /moderation/blocks */
export const listMyBlocks = async (req, res) => {
  const blockerId = req.token?.userId;
  if (!blockerId) {
    return res.status(401).json({ success: false, message: "Authentication required" });
  }
  try {
    const { rows } = await pool.query(
      `SELECT ub.blocked_user_id AS user_id,
              TRIM(CONCAT(COALESCE(u.first_name, ''), ' ', COALESCE(u.last_name, ''))) AS display_name,
              ub.created_at
       FROM user_blocks ub
       JOIN users u ON u.id = ub.blocked_user_id AND u.is_deleted = false
       WHERE ub.blocker_user_id = $1
       ORDER BY ub.created_at DESC`,
      [blockerId]
    );
    return res.status(200).json({ success: true, blocks: rows });
  } catch (err) {
    if (err.code === "42P01") {
      return res.status(200).json({ success: true, blocks: [] });
    }
    console.error("listMyBlocks:", err.message);
    return res.status(500).json({ success: false, message: "Server error" });
  }
};

/** POST /moderation/blocks { blockedUserId, projectId } */
export const createBlock = async (req, res) => {
  const blockerId = req.token?.userId;
  const blockedUserId = Number(req.body?.blockedUserId);
  const projectId = Number(req.body?.projectId);
  if (!blockerId) {
    return res.status(401).json({ success: false, message: "Authentication required" });
  }
  if (!Number.isFinite(blockedUserId) || !Number.isFinite(projectId)) {
    return res.status(400).json({ success: false, message: "blockedUserId and projectId are required" });
  }
  if (blockedUserId === blockerId) {
    return res.status(400).json({ success: false, message: "Cannot block yourself" });
  }
  try {
    const access = await assertSharedProject(projectId, blockerId, blockedUserId);
    if (!access.ok) {
      return res.status(403).json({ success: false, message: access.message });
    }
    await pool.query(
      `INSERT INTO user_blocks (blocker_user_id, blocked_user_id)
       VALUES ($1, $2)
       ON CONFLICT (blocker_user_id, blocked_user_id) DO NOTHING`,
      [blockerId, blockedUserId]
    );
    return res.status(201).json({ success: true, message: "User blocked" });
  } catch (err) {
    if (err.code === "42P01") {
      return res.status(503).json({
        success: false,
        message: "Moderation tables missing — run migration 024 on the database",
      });
    }
    console.error("createBlock:", err.message);
    return res.status(500).json({ success: false, message: "Server error" });
  }
};

/** DELETE /moderation/blocks/:blockedUserId */
export const deleteBlock = async (req, res) => {
  const blockerId = req.token?.userId;
  const blockedUserId = Number(req.params.blockedUserId);
  if (!blockerId) {
    return res.status(401).json({ success: false, message: "Authentication required" });
  }
  if (!Number.isFinite(blockedUserId)) {
    return res.status(400).json({ success: false, message: "Invalid user id" });
  }
  try {
    await pool.query(
      `DELETE FROM user_blocks WHERE blocker_user_id = $1 AND blocked_user_id = $2`,
      [blockerId, blockedUserId]
    );
    return res.status(200).json({ success: true, message: "Block removed" });
  } catch (err) {
    console.error("deleteBlock:", err.message);
    return res.status(500).json({ success: false, message: "Server error" });
  }
};

const MAX_EXCERPT = 4000;
const MAX_NOTE = 2000;

/** POST /moderation/reports */
export const createReport = async (req, res) => {
  const reporterId = req.token?.userId;
  const reportedUserId = Number(req.body?.reportedUserId);
  const projectId = Number(req.body?.projectId);
  const messageId =
    req.body?.messageId != null && req.body?.messageId !== ""
      ? Number(req.body.messageId)
      : null;
  let excerpt = (req.body?.messageExcerpt ?? "").toString().slice(0, MAX_EXCERPT);
  const note = (req.body?.note ?? "").toString().slice(0, MAX_NOTE);

  if (!reporterId) {
    return res.status(401).json({ success: false, message: "Authentication required" });
  }
  if (!Number.isFinite(reportedUserId) || !Number.isFinite(projectId)) {
    return res.status(400).json({
      success: false,
      message: "reportedUserId and projectId are required",
    });
  }
  if (reportedUserId === reporterId) {
    return res.status(400).json({ success: false, message: "Cannot report yourself" });
  }

  try {
    const access = await assertSharedProject(projectId, reporterId, reportedUserId);
    if (!access.ok) {
      return res.status(403).json({ success: false, message: access.message });
    }

    if (Number.isFinite(messageId)) {
      const { rows: msgRows } = await pool.query(
        `SELECT * FROM messages WHERE id = $1 AND project_id = $2 LIMIT 1`,
        [messageId, projectId]
      );
      if (msgRows.length && !excerpt) {
        const r = msgRows[0];
        excerpt = String(r.content ?? r.text ?? "").slice(0, MAX_EXCERPT);
      }
    }

    const { rows } = await pool.query(
      `INSERT INTO content_reports (
         reporter_user_id, reported_user_id, project_id, message_id,
         message_excerpt, reporter_note, status
       ) VALUES ($1, $2, $3, $4, $5, $6, 'open')
       RETURNING id, created_at`,
      [
        reporterId,
        reportedUserId,
        projectId,
        Number.isFinite(messageId) ? messageId : null,
        excerpt || null,
        note || null,
      ]
    );
    const report = rows[0];

    const reporterName = await getUserDisplayName(reporterId);
    const reportedName = await getUserDisplayName(reportedUserId);
    const adminIds = await getAdminIds();
    const msg = `UGC report #${report.id}: ${reporterName} reported ${reportedName} in project #${projectId}.`;
    await createBulkNotifications(
      adminIds,
      NOTIFICATION_TYPES.CHATS_ADMIN,
      msg,
      report.id,
      "content_report"
    );

    return res.status(201).json({
      success: true,
      message: "Report submitted",
      reportId: report.id,
    });
  } catch (err) {
    if (err.code === "42P01") {
      return res.status(503).json({
        success: false,
        message: "Moderation tables missing — run migration 024 on the database",
      });
    }
    console.error("createReport:", err.message);
    return res.status(500).json({ success: false, message: "Server error" });
  }
};

/** GET /moderation/admin/reports?status=open&limit=50&offset=0 */
export const adminListReports = async (req, res) => {
  const requesterId = req.token?.userId;
  if (!(await isAdmin(requesterId))) {
    return res.status(403).json({ success: false, message: "Admin access required" });
  }
  const status = (req.query.status || "").toString().trim();
  const limit = Math.min(Number(req.query.limit) || 50, 100);
  const offset = Math.max(Number(req.query.offset) || 0, 0);
  const allowed = ["", "open", "reviewed", "dismissed"];
  const statusFilter = allowed.includes(status) && status ? status : null;

  try {
    const params = [];
    let whereClause = "1=1";
    if (statusFilter) {
      whereClause = "r.status = $1";
      params.push(statusFilter);
    }
    const limIdx = params.length + 1;
    const offIdx = params.length + 2;
    params.push(limit, offset);

    const { rows } = await pool.query(
      `SELECT r.*,
        json_build_object(
          'id', rep.id,
          'first_name', rep.first_name,
          'last_name', rep.last_name
        ) AS reporter,
        json_build_object(
          'id', res.id,
          'first_name', res.first_name,
          'last_name', res.last_name
        ) AS reported
       FROM content_reports r
       JOIN users rep ON rep.id = r.reporter_user_id
       JOIN users res ON res.id = r.reported_user_id
       WHERE ${whereClause}
       ORDER BY r.created_at DESC
       LIMIT $${limIdx} OFFSET $${offIdx}`,
      params
    );
    return res.status(200).json({ success: true, reports: rows, limit, offset });
  } catch (err) {
    if (err.code === "42P01") {
      return res.status(200).json({ success: true, reports: [], limit, offset });
    }
    console.error("adminListReports:", err.message);
    return res.status(500).json({ success: false, message: "Server error" });
  }
};

/** PATCH /moderation/admin/reports/:id { status: reviewed | dismissed } */
export const adminUpdateReport = async (req, res) => {
  const requesterId = req.token?.userId;
  if (!(await isAdmin(requesterId))) {
    return res.status(403).json({ success: false, message: "Admin access required" });
  }
  const id = Number(req.params.id);
  const status = (req.body?.status || "").toString().trim().toLowerCase();
  if (!Number.isFinite(id)) {
    return res.status(400).json({ success: false, message: "Invalid report id" });
  }
  if (!["reviewed", "dismissed"].includes(status)) {
    return res.status(400).json({
      success: false,
      message: "status must be reviewed or dismissed",
    });
  }
  try {
    const { rows } = await pool.query(
      `UPDATE content_reports
       SET status = $1, reviewed_at = NOW(), reviewed_by_user_id = $2
       WHERE id = $3
       RETURNING *`,
      [status, requesterId, id]
    );
    if (!rows.length) {
      return res.status(404).json({ success: false, message: "Report not found" });
    }
    return res.status(200).json({ success: true, report: rows[0] });
  } catch (err) {
    console.error("adminUpdateReport:", err.message);
    return res.status(500).json({ success: false, message: "Server error" });
  }
};
