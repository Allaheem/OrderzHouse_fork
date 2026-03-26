const pool = require("../../models/db.js");

async function up() {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    await client.query(`
      CREATE TABLE IF NOT EXISTS public.tender_vault_rotation_batches (
        id BIGSERIAL PRIMARY KEY,
        selected_count INTEGER NOT NULL,
        visible_from TIMESTAMP NOT NULL,
        visible_until TIMESTAMP NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    `);

    await client.query(`
      CREATE TABLE IF NOT EXISTS public.tender_vault_exposures (
        id BIGSERIAL PRIMARY KEY,
        tender_vault_project_id INTEGER NOT NULL REFERENCES public.tender_vault_projects(id) ON DELETE CASCADE,
        batch_id BIGINT NOT NULL REFERENCES public.tender_vault_rotation_batches(id) ON DELETE CASCADE,
        visible_from TIMESTAMP NOT NULL,
        visible_until TIMESTAMP NOT NULL,
        is_active BOOLEAN NOT NULL DEFAULT true,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      );
    `);

    await client.query(`
      CREATE OR REPLACE FUNCTION update_tender_vault_exposures_updated_at()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    `);

    await client.query(`
      DROP TRIGGER IF EXISTS trigger_update_tender_vault_exposures_updated_at ON public.tender_vault_exposures;
      CREATE TRIGGER trigger_update_tender_vault_exposures_updated_at
      BEFORE UPDATE ON public.tender_vault_exposures
      FOR EACH ROW
      EXECUTE FUNCTION update_tender_vault_exposures_updated_at();
    `);

    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_tve_visibility_window
      ON public.tender_vault_exposures(is_active, visible_from, visible_until);
    `);

    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_tve_tender_id
      ON public.tender_vault_exposures(tender_vault_project_id);
    `);

    await client.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS uq_tve_active_per_tender
      ON public.tender_vault_exposures(tender_vault_project_id)
      WHERE is_active = true;
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
    await client.query("DROP TABLE IF EXISTS public.tender_vault_exposures CASCADE");
    await client.query("DROP TABLE IF EXISTS public.tender_vault_rotation_batches CASCADE");
    await client.query("DROP FUNCTION IF EXISTS update_tender_vault_exposures_updated_at");
    await client.query("COMMIT");
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
}

module.exports = { up, down };
