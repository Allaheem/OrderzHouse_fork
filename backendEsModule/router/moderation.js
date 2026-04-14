import express from "express";
import { authentication } from "../middleware/authentication.js";
import adminOnly from "../middleware/adminOnly.js";
import {
  listMyBlocks,
  createBlock,
  deleteBlock,
  createReport,
  adminListReports,
  adminUpdateReport,
} from "../controller/moderation.js";

const router = express.Router();

router.get("/blocks", authentication, listMyBlocks);
router.post("/blocks", authentication, createBlock);
router.delete("/blocks/:blockedUserId", authentication, deleteBlock);

router.post("/reports", authentication, createReport);

router.get("/admin/reports", authentication, adminOnly, adminListReports);
router.patch("/admin/reports/:id", authentication, adminOnly, adminUpdateReport);

export default router;
