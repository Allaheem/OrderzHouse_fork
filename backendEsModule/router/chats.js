import express from "express";
import {
  getMessagesByProjectId,
  getMessagesByTaskId,
  createMessage,
  getAllChatsForAdmin,
  getUserChats,
  getUnreadCountByProjectId,
  markProjectChatAsRead,
} from "../controller/chats.js";
import { authentication } from "../middleware/authentication.js";
import adminOnly from "../middleware/adminOnly.js";

const chatsRouter = express.Router();

// userchat
chatsRouter.get("/user-chats", authentication, getUserChats);

// Project chat
chatsRouter.get("/project/:projectId/messages", authentication, getMessagesByProjectId);
chatsRouter.get("/project/:projectId/unread", authentication, getUnreadCountByProjectId);
chatsRouter.post("/project/:projectId/read", authentication, markProjectChatAsRead);

// Task chat
chatsRouter.get("/task/:taskId/messages", authentication, getMessagesByTaskId);

// Create message (project OR task)
chatsRouter.post("/messages", authentication, createMessage);

// Admin — all chats
chatsRouter.get("/admin/all-chats", authentication, adminOnly, getAllChatsForAdmin);

export default chatsRouter;
