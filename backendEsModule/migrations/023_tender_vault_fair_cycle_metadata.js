const pool = require("../../models/db.js");

async function up() {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    await client.query(`
      ALTER TABLE public.tender_vault_rotation_batches
      ADD COLUMN IF NOT EXISTS cycle_number INTEGER;
    `);

    await client.query(`
      UPDATE public.tender_vault_rotation_batches
      SET cycle_number = 1
      WHERE cycle_number IS NULL;
    `);

    await client.query(`
      ALTER TABLE public.tender_vault_rotation_batches
      ALTER COLUMN cycle_number SET NOT NULL;
    `);

    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_tvrb_cycle_number
      ON public.tender_vault_rotation_batches(cycle_number, id DESC);
    `);

    await client.query(`
      ALTER TABLE public.tender_vault_projects
      ADD COLUMN IF NOT EXISTS exposure_count INTEGER NOT NULL DEFAULT 0;
    `);

    await client.query(`
      ALTER TABLE public.tender_vault_projects
      ADD COLUMN IF NOT EXISTS last_exposed_at TIMESTAMP;
    `);

    await client.query(`
      ALTER TABLE public.tender_vault_projects
      ADD COLUMN IF NOT EXISTS last_exposure_ended_at TIMESTAMP;
    `);

    await client.query(`
      ALTER TABLE public.tender_vault_projects
      ADD COLUMN IF NOT EXISTS last_shown_cycle_number INTEGER;
    `);

    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_tvp_last_shown_cycle
      ON public.tender_vault_projects(last_shown_cycle_number);
    `);

    await client.query("COMMIT");
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
}

async function down() {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    await client.query("DROP INDEX IF EXISTS public.idx_tvp_last_shown_cycle");
    await client.query("DROP INDEX IF EXISTS public.idx_tvrb_cycle_number");
    await client.query("ALTER TABLE public.tender_vault_projects DROP COLUMN IF EXISTS last_shown_cycle_number");
    await client.query("ALTER TABLE public.tender_vault_projects DROP COLUMN IF EXISTS last_exposure_ended_at");
    await client.query("ALTER TABLE public.tender_vault_projects DROP COLUMN IF EXISTS last_exposed_at");
    await client.query("ALTER TABLE public.tender_vault_projects DROP COLUMN IF EXISTS exposure_count");
    await client.query("ALTER TABLE public.tender_vault_rotation_batches DROP COLUMN IF EXISTS cycle_number");
    await client.query("COMMIT");
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
}

module.exports = { up, down };
