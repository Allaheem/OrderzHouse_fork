import express from "express";
import pool from "../models/db.js";
import authentication from "../middleware/authentication.js";
import adminOnly from "../middleware/adminOnly.js";

const router = express.Router();

async function getAggregateStats() {
  const totalProjects = await pool.query("SELECT COUNT(*) FROM projects");
  const processing = await pool.query(
    "SELECT COUNT(*) FROM projects WHERE status = 'in_progress'"
  );
  const clients = await pool.query(
    "SELECT COUNT(*) FROM users WHERE role_id = 2"
  );
  const freelancers = await pool.query(
    "SELECT COUNT(*) FROM users WHERE role_id = 3"
  );
  return {
    totalProjects: Number(totalProjects.rows[0].count),
    processing: Number(processing.rows[0].count),
    clients: Number(clients.rows[0].count),
    freelancers: Number(freelancers.rows[0].count),
  };
}

// Public aggregate counts (landing / health check). No PII — still useful for scraping; rate-limit globally.
router.get("/public-stats", async (req, res) => {
  try {
    const data = await getAggregateStats();
    res.json(data);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Server error retrieving stats" });
  }
});

// Same payload, admin-only (use when you want stats hidden from anonymous callers)
router.get("/stats", authentication, adminOnly, async (req, res) => {
  try {
    const data = await getAggregateStats();
    res.json(data);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Server error retrieving stats" });
  }
});

export default router;
