import pool from "../models/db.js";

/**
 * Emit a room event only to sockets whose users have NOT blocked the sender.
 * Always delivers to the sending user (senderId).
 */
export async function emitToRoomExceptBlockers(io, roomKey, eventName, payload, senderId) {
  if (!io || !roomKey || !eventName) return;
  try {
    const sockets = await io.in(roomKey).fetchSockets();
    const numericSender = Number(senderId);
    const uids = [
      ...new Set(
        sockets.map((s) => Number(s.user?.userId)).filter((id) => Number.isFinite(id))
      ),
    ];

    let blockerSet = new Set();
    if (uids.length && Number.isFinite(numericSender)) {
      const { rows } = await pool.query(
        `SELECT blocker_user_id FROM user_blocks
         WHERE blocked_user_id = $1 AND blocker_user_id = ANY($2::int[])`,
        [numericSender, uids]
      );
      blockerSet = new Set(rows.map((r) => Number(r.blocker_user_id)));
    }

    for (const s of sockets) {
      const uid = Number(s.user?.userId);
      if (!Number.isFinite(uid)) continue;
      if (uid === numericSender || !blockerSet.has(uid)) {
        s.emit(eventName, payload);
      }
    }
  } catch (err) {
    console.error("emitToRoomExceptBlockers:", err?.message || err);
    io.to(roomKey).emit(eventName, payload);
  }
}
