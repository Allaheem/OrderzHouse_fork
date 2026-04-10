import { Server } from "socket.io";
import messageHandler from "../controller/messages.js";
import { authSocket } from "../middleware/authentication.js";
import pool from "../models/db.js";
import { assertUserMayJoinChatRoom } from "../services/chatParticipantAccess.js";

const allowedSocketOrigins = [
  process.env.FRONTEND_URL,
  "https://orderzhouse.com",
  "https://www.orderzhouse.com",
  "http://localhost:5173",
  "http://localhost:5174",
].filter(Boolean);

function socketCorsOrigin(origin, callback) {
  // Mobile / native clients often omit Origin
  if (!origin) return callback(null, true);
  if (process.env.NODE_ENV === "development") return callback(null, true);
  if (allowedSocketOrigins.includes(origin)) return callback(null, true);
  callback(new Error("Not allowed by CORS"));
}

function initSocket(server) {
  const io = new Server(server, {
    cors: {
      origin: socketCorsOrigin,
      methods: ["GET", "POST"],
      credentials: true,
    },
  });

  global.io = io;

  io.use(authSocket);

  io.on("connection", async (socket) => {
    const userId = socket.user?.userId;
    if (!userId) {
      console.warn("Socket connection without valid token.");
      socket.disconnect(true);
      return;
    }

    try {
      await pool.query("UPDATE users SET is_online = TRUE WHERE id = $1", [userId]);
      if (process.env.NODE_ENV !== "production") {
        console.log(`User ${userId} connected`);
      }

      // Join personal room for notifications
      socket.join(`user:${userId}`);

    } catch (err) {
      console.error("Error updating user online status:", err);
    }

    messageHandler(socket, io);

    socket.on("join_room", async ({ project_id, task_id }) => {
      try {
        const access = await assertUserMayJoinChatRoom(
          userId,
          project_id ?? null,
          task_id ?? null
        );
        if (!access.ok) {
          return socket.emit("join_error", { error: access.error });
        }

        const roomId = access.roomKey;

        if (project_id) {
          const project = await pool.query(
            `SELECT id FROM projects WHERE id = $1 AND is_deleted = false`,
            [project_id]
          );
          if (!project.rows.length)
            return socket.emit("join_error", { error: "Project not found" });
        }

        if (task_id) {
          const task = await pool.query(
            `SELECT id FROM tasks WHERE id = $1 AND is_deleted = false`,
            [task_id]
          );
          if (!task.rows.length)
            return socket.emit("join_error", { error: "Task not found" });
        }

        if (socket.roomId) socket.leave(socket.roomId);

        socket.join(roomId);
        socket.roomId = roomId;

        socket.emit("room_joined", { roomId });
        socket.to(roomId).emit("user_joined", { userId });

        if (process.env.NODE_ENV !== "production") {
          console.log(`👥 User ${userId} joined ${roomId}`);
        }
      } catch (err) {
        console.error("Error joining room:", err);
        socket.emit("join_error", { error: "Failed to join room" });
      }
    });

    socket.on("leave_room", () => {
      if (socket.roomId) {
        socket.to(socket.roomId).emit("user_left", { userId });
        socket.leave(socket.roomId);
        if (process.env.NODE_ENV !== "production") {
          console.log(`👋 User ${userId} left ${socket.roomId}`);
        }
        socket.roomId = null;
      }
    });

    socket.on("disconnect", async () => {
      try {
        await pool.query("UPDATE users SET is_online = FALSE WHERE id = $1", [
          userId,
        ]);
        if (process.env.NODE_ENV !== "production") {
          console.log(`User ${userId} disconnected`);
        }
      } catch (err) {
        console.error("Error updating user offline status:", err);
      }
    });
  });

  return io;
}

export default initSocket;