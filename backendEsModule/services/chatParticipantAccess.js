import pool from "../models/db.js";

/**
 * Shared access rules for project/task chat (REST + Socket.IO).
 * Keeps participant lists aligned with getMessagesByProjectId / getUserChats.
 */

export async function isAdmin(userId) {
  if (!userId) return false;
  const { rows } = await pool.query(
    `SELECT role_id FROM users WHERE id = $1 AND is_deleted = false`,
    [userId]
  );
  return rows[0]?.role_id === 1;
}

export async function getProjectParticipants(projectId) {
  const { rows } = await pool.query(
    `SELECT p.user_id, pa.freelancer_id
     FROM projects p
     LEFT JOIN project_assignments pa ON pa.project_id = p.id
     WHERE p.id = $1 AND p.is_deleted = false`,
    [projectId]
  );
  const ids = new Set(
    rows.flatMap((r) => [r.user_id, r.freelancer_id]).filter(Boolean)
  );
  const { rows: offerRows } = await pool.query(
    `SELECT DISTINCT freelancer_id FROM offers
     WHERE project_id = $1 AND offer_status IN ('pending', 'accepted')`,
    [projectId]
  );
  for (const r of offerRows) {
    if (r.freelancer_id) ids.add(r.freelancer_id);
  }
  return [...ids];
}

export async function getTaskParticipants(taskId) {
  const { rows } = await pool.query(
    `SELECT freelancer_id, assigned_client_id FROM tasks WHERE id = $1`,
    [taskId]
  );
  if (!rows.length) return [];
  return [rows[0].freelancer_id, rows[0].assigned_client_id].filter(Boolean);
}

const allowedProjectStatuses = [
  "active",
  "bidding",
  "in_progress",
  "pending_review",
  "reviewing",
  "pending_admin_approval",
];

const allowedTaskStatuses = [
  "active",
  "in_progress",
  "pending_approval",
  "pending_payment",
  "pending_review",
  "reviewing",
  "completed",
];

export async function isChatAllowed(projectId, taskId) {
  try {
    if (projectId) {
      const { rows } = await pool.query(
        `SELECT status, completion_status FROM projects WHERE id = $1 AND is_deleted = false`,
        [projectId]
      );
      return (
        rows.length > 0 &&
        (allowedProjectStatuses.includes(rows[0].status) ||
          allowedProjectStatuses.includes(rows[0].completion_status))
      );
    }

    if (taskId) {
      const { rows } = await pool.query(
        `SELECT status FROM tasks WHERE id = $1 AND is_deleted = false`,
        [taskId]
      );
      return (
        rows.length > 0 && allowedTaskStatuses.includes(rows[0].status)
      );
    }

    return false;
  } catch (err) {
    console.error("❌ Error in isChatAllowed:", err.message);
    return false;
  }
}

/**
 * Non-admin must be a participant; chat status must allow messaging.
 * Admins may join for support even when status would block normal users.
 */
function includesUser(participants, userId) {
  const uid = Number(userId);
  if (!Number.isFinite(uid)) return false;
  return participants.some((p) => Number(p) === uid);
}

export async function assertUserMayJoinChatRoom(userId, projectId, taskId) {
  const uid = Number(userId);
  if (!userId || !Number.isFinite(uid)) {
    return { ok: false, error: "Not authenticated" };
  }

  if (projectId != null && projectId !== "" && taskId != null && taskId !== "") {
    return { ok: false, error: "Provide either project_id or task_id" };
  }

  if (projectId != null && projectId !== "") {
    const pid = Number(projectId);
    if (!Number.isFinite(pid)) {
      return { ok: false, error: "Invalid project" };
    }
    const admin = await isAdmin(uid);
    if (!admin) {
      if (!(await isChatAllowed(pid, null))) {
        return { ok: false, error: "Chat is not available for this project" };
      }
      const participants = await getProjectParticipants(pid);
      if (!includesUser(participants, uid)) {
        return { ok: false, error: "Access denied" };
      }
    }
    return { ok: true, roomKey: `project:${pid}` };
  }

  if (taskId != null && taskId !== "") {
    const tid = Number(taskId);
    if (!Number.isFinite(tid)) {
      return { ok: false, error: "Invalid task" };
    }
    const admin = await isAdmin(uid);
    if (!admin) {
      if (!(await isChatAllowed(null, tid))) {
        return { ok: false, error: "Chat is not available for this task" };
      }
      const participants = await getTaskParticipants(tid);
      if (!includesUser(participants, uid)) {
        return { ok: false, error: "Access denied" };
      }
    }
    return { ok: true, roomKey: `task:${tid}` };
  }

  return { ok: false, error: "No valid room ID" };
}
