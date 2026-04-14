/**
 * Apple IAP: map plans to App Store product IDs; track subscription payment source
 * and Apple original transaction id for idempotency and admin visibility.
 *
 * Run once against production DB (from backendEsModule, with DATABASE_URL set):
 *   node migrations/025_plans_apple_iap_and_subscription_source.js
 */
import { fileURLToPath } from "url";
import pool from "../models/db.js";

export async function up() {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    await client.query(`
      ALTER TABLE plans
      ADD COLUMN IF NOT EXISTS apple_product_id VARCHAR(255) NULL;
    `);

    await client.query(`
      ALTER TABLE subscriptions
      ADD COLUMN IF NOT EXISTS apple_original_transaction_id VARCHAR(255) NULL;
    `);

    await client.query(`
      ALTER TABLE subscriptions
      ADD COLUMN IF NOT EXISTS payment_source VARCHAR(32) NULL DEFAULT 'company';
    `);

    await client.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS idx_subscriptions_apple_original_tx
      ON subscriptions (apple_original_transaction_id)
      WHERE apple_original_transaction_id IS NOT NULL;
    `);

    await client.query("COMMIT");
    console.log("✅ 025_plans_apple_iap_and_subscription_source applied");
  } catch (err) {
    await client.query("ROLLBACK");
    console.error("❌ 025 migration failed:", err);
    throw err;
  } finally {
    client.release();
  }
}

export async function down() {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    await client.query(`DROP INDEX IF EXISTS idx_subscriptions_apple_original_tx;`);
    await client.query(`
      ALTER TABLE subscriptions DROP COLUMN IF EXISTS payment_source;
    `);
    await client.query(`
      ALTER TABLE subscriptions DROP COLUMN IF EXISTS apple_original_transaction_id;
    `);
    await client.query(`
      ALTER TABLE plans DROP COLUMN IF EXISTS apple_product_id;
    `);
    await client.query("COMMIT");
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
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
