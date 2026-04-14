// Migration: user_blocks (server-side hide) + content_reports (UGC reports for admin)
import { fileURLToPath } from "url";
import pool from "../models/db.js";
import dotenv from "dotenv";

dotenv.config();

export async function up() {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    await client.query(`
      CREATE TABLE IF NOT EXISTS user_blocks (
        id SERIAL PRIMARY KEY,
        blocker_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        blocked_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        CONSTRAINT user_blocks_unique_pair UNIQUE (blocker_user_id, blocked_user_id),
        CONSTRAINT user_blocks_no_self CHECK (blocker_user_id <> blocked_user_id)
      )
    `);

    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_user_blocks_blocker ON user_blocks(blocker_user_id)
    `);
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_user_blocks_blocked ON user_blocks(blocked_user_id)
    `);

    await client.query(`
      CREATE TABLE IF NOT EXISTS content_reports (
        id SERIAL PRIMARY KEY,
        reporter_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        reported_user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        project_id INTEGER REFERENCES projects(id) ON DELETE SET NULL,
        message_id INTEGER,
        message_excerpt TEXT,
        reporter_note TEXT,
        status VARCHAR(32) NOT NULL DEFAULT 'open',
        reviewed_at TIMESTAMPTZ,
        reviewed_by_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        CONSTRAINT content_reports_no_self CHECK (reporter_user_id <> reported_user_id)
      )
    `);

    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_content_reports_status ON content_reports(status)
    `);
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_content_reports_created ON content_reports(created_at DESC)
    `);

    await client.query("COMMIT");
    console.log("✅ Migration 024: user_blocks + content_reports");
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("❌ Migration 024 failed:", error);
    throw error;
  } finally {
    client.release();
  }
}

export async function down() {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    await client.query("DROP TABLE IF EXISTS content_reports CASCADE");
    await client.query("DROP TABLE IF EXISTS user_blocks CASCADE");
    await client.query("COMMIT");
    console.log("✅ Rolled back migration 024");
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("❌ Rollback 024 failed:", error);
    throw error;
  } finally {
    client.release();
  }
}

const __filename = fileURLToPath(import.meta.url);
if (process.argv[1] === __filename) {
  up()
    .then(() => process.exit(0))
    .catch(() => process.exit(1));
}
