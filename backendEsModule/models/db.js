import { Pool } from "pg";
import dotenv from "dotenv";

dotenv.config();

const fromUrl = process.env.DB_URL || process.env.DATABASE_URL;
const shouldUseSsl = (process.env.DB_SSL || "true").toLowerCase() !== "false";

/**
 * SSL to Postgres: in production default to verifying the server certificate.
 * Set DB_SSL_REJECT_UNAUTHORIZED=false only for dev/legacy DBs with self-signed certs.
 */
function buildSslOption() {
  if (!shouldUseSsl) return false;
  const explicit = process.env.DB_SSL_REJECT_UNAUTHORIZED;
  if (explicit !== undefined && explicit !== "") {
    return { rejectUnauthorized: explicit.toLowerCase() === "true" };
  }
  if (process.env.NODE_ENV === "production") {
    return { rejectUnauthorized: true };
  }
  return { rejectUnauthorized: false };
}

const ssl = buildSslOption();

// 🔹 Config object
const config = fromUrl
  ? {
      connectionString: fromUrl,
      ssl,
    }
  : {
      host: process.env.DB_HOST || process.env.PGHOST || "localhost",
      port: Number(process.env.DB_PORT || process.env.PGPORT || 5432),
      database: process.env.DB_NAME || process.env.PGDATABASE,
      user: process.env.DB_USER || process.env.PGUSER,
      password: process.env.DB_PASSWORD || process.env.PGPASSWORD,
      ssl,
    };

// 🔹 Initialize pool
const pool = new Pool(config);

// ✅ Test connection once at startup + log DB identity (masked, for debugging env mismatch)
(async () => {
  try {
    const result = await pool.query("SELECT NOW()");
    console.log("✅ Connected to PostgreSQL! Current time:", result.rows[0].now);
    const connStr = typeof fromUrl === "string" ? fromUrl : "";
    if (connStr) {
      try {
        const u = new URL(connStr.replace(/^postgresql?:\/\//, "https://"));
        const host = u.hostname || "";
        const masked = host ? `${host.substring(0, 24)}${host.length > 24 ? "..." : ""}` : "(parsed)";
        console.log("📎 DB host (masked):", masked);
      } catch (_) {
        console.log("📎 DB: connection from env (URL not parsed)");
      }
    } else {
      console.log("📎 DB host:", config.host || "localhost");
    }
    if (shouldUseSsl && ssl && ssl.rejectUnauthorized) {
      console.log("🔒 DB SSL: rejectUnauthorized=true");
    } else if (shouldUseSsl) {
      console.warn(
        "⚠️  DB SSL: rejectUnauthorized=false — prefer a proper CA and DB_SSL_REJECT_UNAUTHORIZED=true in production"
      );
    }
  } catch (err) {
    console.error("❌ DB connection error:", err.message);
  }
})();

export default pool;
