import pool from "../models/db.js";
import crypto from "crypto";

/**
 * Generate a unique referral code for a user
 */
export function generateReferralCode(userId) {
  // Generate a 7-character code using user ID + random string
  const randomPart = crypto.randomBytes(4).toString('hex').toUpperCase().substring(0, 4);
  const userIdPart = userId.toString().padStart(3, '0').substring(0, 3);
  return `${randomPart}${userIdPart}`.substring(0, 7);
}

/**
 * Ensure user has a referral code (generate if missing)
 * @param {number} userId - The user ID
 * @param {object} client - Database client (optional, will create new if not provided)
 */
async function ensureReferralCode(userId, client = null) {
  const shouldRelease = !client;
  if (!client) {
    client = await pool.connect();
  }
  
  try {
    // Check if referral_code column exists
    const columnCheck = await client.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'users' AND column_name = 'referral_code'
      LIMIT 1
    `);
    
    if (columnCheck.rows.length === 0) {
      // Return a special value instead of throwing - let caller handle gracefully
      throw new Error('referral_code column does not exist');
    }
    
    const result = await client.query(
      'SELECT referral_code FROM users WHERE id = $1 AND is_deleted = false',
      [userId]
    );
    
    if (result.rows.length === 0) {
      throw new Error('User not found');
    }
    
    let referralCode = result.rows[0].referral_code;
    
    // Generate if missing
    if (!referralCode) {
      let attempts = 0;
      let isUnique = false;
      
      while (!isUnique && attempts < 10) {
        referralCode = generateReferralCode(userId);
        const checkResult = await client.query(
          'SELECT id FROM users WHERE referral_code = $1',
          [referralCode]
        );
        
        if (checkResult.rows.length === 0) {
          isUnique = true;
        } else {
          attempts++;
        }
      }
      
      if (!isUnique) {
        throw new Error('Failed to generate unique referral code after 10 attempts');
      }
      
      await client.query(
        'UPDATE users SET referral_code = $1 WHERE id = $2',
        [referralCode, userId]
      );
    }
    
    return referralCode;
  } catch (err) {
    // Re-throw as-is - let caller decide how to handle schema errors
    // The caller will check for schema-related error messages
    throw err;
  } finally {
    if (shouldRelease) {
      client.release();
    }
  }
}

/**
 * GET /referrals/me
 * Get current user's referral information
 * Returns: { code, invitedCount, successfulCount, earnedAmount, weeklyRemaining }
 */
export const getMyReferrals = async (req, res) => {
  // Safe extraction of userId from token
  const userId = req.token?.userId || req.token?.id || req.user?.id || req.user?.userId;
  
  if (!userId) {
    return res.status(401).json({ 
      success: false, 
      message: "Unauthorized: missing user in token" 
    });
  }
  
  // Check schema existence BEFORE starting transaction to avoid transaction abort issues
  const schemaCheckClient = await pool.connect();
  let schemaExists = false;
  let tablesExist = false;
  try {
    // Check for referral_code column
    const columnCheck = await schemaCheckClient.query(`
      SELECT column_name 
      FROM information_schema.columns 
      WHERE table_name = 'users' AND column_name = 'referral_code'
      LIMIT 1
    `);
    schemaExists = columnCheck.rows.length > 0;
    
    // Check for referrals table
    if (schemaExists) {
      const tableCheck = await schemaCheckClient.query(`
        SELECT table_name 
        FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'referrals'
        LIMIT 1
      `);
      tablesExist = tableCheck.rows.length > 0;
    }
  } catch (schemaErr) {
    console.warn('GET /referrals/me: Could not check schema, assuming missing', schemaErr.message);
    schemaExists = false;
    tablesExist = false;
  } finally {
    schemaCheckClient.release();
  }
  
  // If schema doesn't exist, return default values immediately
  if (!schemaExists || !tablesExist) {
    console.warn('GET /referrals/me WARNING: Database schema not migrated. Returning default values.', {
      userId,
      schemaExists,
      tablesExist
    });
    return res.json({
      success: true,
      code: null,
      referralCode: null, // Legacy field for frontend compatibility
      link: '',
      invitedCount: 0,
      successfulCount: 0,
      earnedAmount: 0,
      weeklyRemaining: 3,
      stats: {
        invited: 0,
        completed: 0,
        earned: 0,
      },
      rules: {
        referrerReward: 5.0,
        friendReward: 5.0,
        currency: "JOD",
      },
    });
  }
  
  // Schema exists, proceed with transaction
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    
    // First, verify user exists
    const userCheck = await client.query(
      'SELECT id FROM users WHERE id = $1 AND is_deleted = false',
      [userId]
    );
    
    if (userCheck.rows.length === 0) {
      await client.query('ROLLBACK');
      console.error('GET /referrals/me ERROR: User not found', { userId });
      return res.status(404).json({ 
        success: false, 
        message: "User not found" 
      });
    }
    
    // Ensure user has referral code (use transaction client)
    let referralCode;
    try {
      referralCode = await ensureReferralCode(userId, client);
    } catch (codeErr) {
      await client.query('ROLLBACK');
      console.error('GET /referrals/me ERROR: Failed to ensure referral code', {
        userId,
        error: codeErr.message,
        stack: codeErr.stack
      });
      return res.status(500).json({ 
        success: false, 
        message: "Failed to generate referral code"
      });
    }
    
    // Build referral link (adjust domain as needed)
    const domain = process.env.FRONTEND_URL || 'https://orderzhouse.com';
    const referralLink = `${domain}/app?ref=${referralCode}`;
    
    // Get stats - handle missing tables gracefully
    let stats = { invited: 0, completed: 0, earned: 0, weeklyRemaining: 3 };
    try {
      // Get total counts and earned amount
      const statsResult = await client.query(`
        SELECT 
          COALESCE(COUNT(*) FILTER (WHERE status = 'pending'), 0)::INTEGER as invited,
          COALESCE(COUNT(*) FILTER (WHERE status = 'completed'), 0)::INTEGER as completed,
          COALESCE(SUM(rr.amount), 0)::NUMERIC as earned
        FROM referrals r
        LEFT JOIN referral_rewards rr ON r.id = rr.referral_id AND rr.user_id = $1
        WHERE r.referrer_user_id = $1
      `, [userId]);
      
      // Get weekly referral count (last 7 days)
      const weeklyCountResult = await client.query(`
        SELECT COUNT(*)::INTEGER as weekly_count
        FROM referrals
        WHERE referrer_user_id = $1
          AND created_at >= NOW() - INTERVAL '7 days'
      `, [userId]);
      
      if (statsResult.rows && statsResult.rows.length > 0) {
        const row = statsResult.rows[0];
        const weeklyCount = weeklyCountResult.rows[0]?.weekly_count || 0;
        const weeklyRemaining = Math.max(0, 3 - weeklyCount);
        
        stats = {
          invited: parseInt(row.invited || 0, 10),
          completed: parseInt(row.completed || 0, 10),
          earned: parseFloat(row.earned || 0),
          weeklyRemaining,
        };
      } else if (weeklyCountResult.rows && weeklyCountResult.rows.length > 0) {
        const weeklyCount = weeklyCountResult.rows[0]?.weekly_count || 0;
        stats.weeklyRemaining = Math.max(0, 3 - weeklyCount);
      }
    } catch (statsErr) {
      // If tables don't exist, rollback and use default zero stats
      const errorMsg = statsErr.message || statsErr.toString() || '';
      if (errorMsg.includes('does not exist') || 
          errorMsg.includes('relation') ||
          errorMsg.includes('referrals') ||
          errorMsg.includes('aborted')) {
        try {
          await client.query('ROLLBACK');
        } catch (rollbackErr) {
          // Ignore rollback errors if transaction already aborted
        }
        console.warn('GET /referrals/me WARNING: Referrals tables may not exist, using zero stats', {
          error: errorMsg
        });
        // Return early with default values
        return res.json({
          success: true,
          code: referralCode,
          referralCode: referralCode, // Legacy field for frontend compatibility
          link: referralLink,
          invitedCount: 0,
          successfulCount: 0,
          earnedAmount: 0,
          weeklyRemaining: 3,
          stats: {
            invited: 0,
            completed: 0,
            earned: 0,
          },
          rules: {
            referrerReward: 5.0,
            friendReward: 5.0,
            currency: "JOD",
          },
        });
      } else {
        // Re-throw if it's a different error
        throw statsErr;
      }
    }
    
    // Get referral rules (configurable - can be moved to config table)
    const rules = {
      referrerReward: 5.0,
      friendReward: 5.0,
      currency: "JOD",
    };
    
    // Optional: Get list of referrals - handle missing tables gracefully
    let referralsList = [];
    try {
      const referralsListResult = await client.query(`
        SELECT 
          u.email as referred_user_email,
          r.status,
          r.created_at,
          r.completed_at
        FROM referrals r
        JOIN users u ON r.referred_user_id = u.id
        WHERE r.referrer_user_id = $1
        ORDER BY r.created_at DESC
        LIMIT 20
      `, [userId]);
      
      if (referralsListResult.rows) {
        referralsList = referralsListResult.rows;
      }
    } catch (listErr) {
      // If tables don't exist or transaction aborted, use empty list
      const errorMsg = listErr.message || listErr.toString() || '';
      if (errorMsg.includes('does not exist') || 
          errorMsg.includes('relation') ||
          errorMsg.includes('referrals') ||
          errorMsg.includes('aborted')) {
        console.warn('GET /referrals/me WARNING: Referrals tables may not exist, using empty list', {
          error: errorMsg
        });
        referralsList = [];
        // Transaction may be aborted, try to rollback
        try {
          await client.query('ROLLBACK');
        } catch (rollbackErr) {
          // Ignore rollback errors (transaction may already be rolled back)
        }
      } else {
        // Re-throw if it's a different error
        throw listErr;
      }
    }
    
    // Commit transaction (only if not already rolled back)
    try {
      // Check if transaction is still active by trying to commit
      await client.query('COMMIT');
    } catch (commitErr) {
      // If commit fails (transaction already aborted/rolled back), that's okay
      // We already have the data we need
      const commitErrorMsg = commitErr.message || commitErr.toString() || '';
      if (!commitErrorMsg.includes('aborted') && !commitErrorMsg.includes('ROLLBACK')) {
        // Only log if it's an unexpected error
        console.warn('GET /referrals/me: Commit failed, but continuing', commitErrorMsg);
      }
    }
    
    // Return format matching frontend requirements
    // Include both new format (for future use) and legacy format (for current frontend)
    return res.json({
      success: true,
      code: referralCode,
      referralCode: referralCode, // Legacy field for frontend compatibility
      link: referralLink,
      invitedCount: stats.invited || 0,
      successfulCount: stats.completed || 0,
      earnedAmount: stats.earned || 0,
      weeklyRemaining: stats.weeklyRemaining || 3,
      // Legacy format for current frontend
      stats: {
        invited: stats.invited || 0,
        completed: stats.completed || 0,
        earned: stats.earned || 0,
      },
      rules: {
        referrerReward: 5.0,
        friendReward: 5.0,
        currency: "JOD",
      },
    });
  } catch (err) {
    try {
      await client.query('ROLLBACK');
    } catch (rollbackErr) {
      console.error('GET /referrals/me ROLLBACK ERROR:', rollbackErr);
    }
    console.error('GET /referrals/me ERROR:', err);
    console.error('Error details:', {
      message: err.message,
      stack: err.stack,
      userId,
      name: err.name
    });
    return res.status(500).json({ 
      success: false, 
      message: "Server error"
    });
  } finally {
    client.release();
  }
};

/**
 * POST /referrals/code
 * Create or get referral code for current user
 * Always returns the same code for the same user
 */
export const createOrGetReferralCode = async (req, res) => {
  const userId = req.token?.userId || req.token?.id || req.user?.id || req.user?.userId;
  
  if (!userId) {
    return res.status(401).json({ 
      success: false, 
      message: "Unauthorized: missing user in token" 
    });
  }
  
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    
    // Ensure user exists
    const userCheck = await client.query(
      'SELECT id FROM users WHERE id = $1 AND is_deleted = false',
      [userId]
    );
    
    if (userCheck.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ 
        success: false, 
        message: "User not found" 
      });
    }
    
    // Ensure referral code exists (generate if missing)
    const referralCode = await ensureReferralCode(userId, client);
    
    await client.query('COMMIT');
    
    return res.json({
      success: true,
      code: referralCode,
    });
  } catch (err) {
    try {
      await client.query('ROLLBACK');
    } catch (rollbackErr) {
      console.error('createOrGetReferralCode ROLLBACK ERROR:', rollbackErr);
    }
    console.error('createOrGetReferralCode error:', err);
    return res.status(500).json({ 
      success: false, 
      message: "Server error"
    });
  } finally {
    client.release();
  }
};

/**
 * POST /referrals/apply
 * Apply referral code during signup
 * Business Rules:
 * - User cannot apply their own code
 * - User can apply a referral code only once
 * - Referrer must not exceed 3 referrals within the last 7 days (weekly limit)
 */
export const applyReferralCode = async (req, res) => {
  const { code } = req.body;
  const referredUserId = req.token?.userId; // User who just signed up
  
  if (!code || !referredUserId) {
    return res.status(400).json({ 
      success: false, 
      message: "Referral code and user ID are required" 
    });
  }
  
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    
    // Find referrer by code
    const referrerResult = await client.query(
      'SELECT id FROM users WHERE referral_code = $1 AND id != $2',
      [code.toUpperCase().trim(), referredUserId]
    );
    
    if (referrerResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ 
        success: false, 
        message: "Invalid referral code" 
      });
    }
    
    const referrerUserId = referrerResult.rows[0].id;
    
    // Check if user is trying to refer themselves (additional check)
    if (referrerUserId === referredUserId) {
      await client.query('ROLLBACK');
      return res.status(400).json({ 
        success: false, 
        message: "You cannot refer yourself." 
      });
    }
    
    // Check if referral already exists (user can only apply one referral code)
    const existingResult = await client.query(
      'SELECT id FROM referrals WHERE referred_user_id = $1',
      [referredUserId]
    );
    
    if (existingResult.rows.length > 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ 
        success: false, 
        message: "Referral code already used." 
      });
    }
    
    // MANDATORY: Check weekly limit - count referrals in last 7 days for referrer
    const weeklyCountResult = await client.query(`
      SELECT COUNT(*)::INTEGER as weekly_count
      FROM referrals
      WHERE referrer_user_id = $1
        AND created_at >= NOW() - INTERVAL '7 days'
    `, [referrerUserId]);
    
    const weeklyCount = weeklyCountResult.rows[0]?.weekly_count || 0;
    
    if (weeklyCount >= 3) {
      await client.query('ROLLBACK');
      return res.status(400).json({ 
        success: false, 
        message: "You have reached the weekly referral limit (3)." 
      });
    }
    
    // Create referral record with status 'pending' (becomes 'completed' when payment happens)
    await client.query(`
      INSERT INTO referrals (referrer_user_id, referred_user_id, status)
      VALUES ($1, $2, 'pending')
    `, [referrerUserId, referredUserId]);
    
    await client.query('COMMIT');
    
    return res.json({
      success: true,
      message: "Referral code applied successfully",
    });
  } catch (err) {
    try {
      await client.query('ROLLBACK');
    } catch (rollbackErr) {
      console.error('applyReferralCode ROLLBACK ERROR:', rollbackErr);
    }
    console.error('applyReferralCode error:', err);
    return res.status(500).json({ 
      success: false, 
      message: "Server error" 
    });
  } finally {
    client.release();
  }
};

/**
 * POST /referrals/complete
 * Mark referral as completed when referred user purchases first paid plan
 */
export const completeReferral = async (req, res) => {
  const { referredUserId } = req.body;
  const adminUserId = req.token?.userId; // Usually called by system/admin after payment
  
  if (!referredUserId) {
    return res.status(400).json({ 
      success: false, 
      message: "referredUserId is required" 
    });
  }
  
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    
    // Find pending referral
    const referralResult = await client.query(`
      SELECT id, referrer_user_id, status
      FROM referrals
      WHERE referred_user_id = $1 AND status = 'pending'
      LIMIT 1
    `, [referredUserId]);
    
    if (referralResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ 
        success: false, 
        message: "No pending referral found" 
      });
    }
    
    const referral = referralResult.rows[0];
    const referralId = referral.id;
    const referrerUserId = referral.referrer_user_id;
    
    // Get reward amounts from config (can be moved to config table)
    const referrerReward = 5.0; // JOD
    const friendReward = 5.0; // JOD (optional - for referred user)
    
    // Mark referral as completed
    await client.query(`
      UPDATE referrals
      SET status = 'completed', completed_at = CURRENT_TIMESTAMP
      WHERE id = $1
    `, [referralId]);
    
    // Create reward for referrer
    await client.query(`
      INSERT INTO referral_rewards (user_id, referral_id, amount, type)
      VALUES ($1, $2, $3, 'referral')
    `, [referrerUserId, referralId, referrerReward]);
    
    // Optional: Create reward for referred user (discount/credit)
    // Uncomment if you want to give reward to referred user too
    // await client.query(`
    //   INSERT INTO referral_rewards (user_id, referral_id, amount, type)
    //   VALUES ($1, $2, $3, 'referral_friend')
    // `, [referredUserId, referralId, friendReward]);
    
    await client.query('COMMIT');
    
    return res.json({
      success: true,
      message: "Referral completed and rewards issued",
    });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('completeReferral error:', err);
    return res.status(500).json({ success: false, message: "Server error" });
  } finally {
    client.release();
  }
};

// ============== Partner referral tracking (visits + signups) ==============

const COOKIE_OH_REF_SID = "oh_ref_sid";
const COOKIE_MAX_AGE_DAYS = 30;

/**
 * POST /referrals/visit — record partner referral hit (public).
 * Body: { source, medium?, campaign?, ref?, landing_path?, session_id? }
 * Session: 1) req.cookies.oh_ref_sid, 2) body.session_id, 3) generate new.
 * Writes two tables:
 * - referral_pageviews: every call (total page visits). No ON CONFLICT.
 * - referral_visits: one row per (source, session_id) — unique sessions. ON CONFLICT DO NOTHING.
 * Cookie: 30d, path=/, sameSite=lax, secure only in production.
 */
export const recordPartnerVisit = async (req, res) => {
  const { source, medium, campaign, ref, landing_path, session_id: bodySid } = req.body || {};
  if (!source || typeof source !== "string") {
    return res.status(400).json({ success: false, message: "source is required" });
  }
  const src = source.trim().toLowerCase();
  const med = medium != null && medium !== "" ? String(medium).trim() : null;
  const camp = campaign != null && campaign !== "" ? String(campaign).trim() : null;
  const refVal = ref != null && ref !== "" ? String(ref).trim() : null;
  const landing = landing_path != null && landing_path !== "" ? String(landing_path).trim() : null;

  let session_id;
  const cookieSid = req.cookies && req.cookies[COOKIE_OH_REF_SID];
  if (cookieSid && typeof cookieSid === "string" && cookieSid.trim()) {
    session_id = cookieSid.trim();
  } else if (bodySid && typeof bodySid === "string" && bodySid.trim()) {
    session_id = bodySid.trim();
  } else {
    session_id = crypto.randomBytes(16).toString("hex");
  }

  const cookieOptions = {
    maxAge: COOKIE_MAX_AGE_DAYS * 24 * 60 * 60 * 1000,
    httpOnly: false,
    sameSite: "lax",
    path: "/",
    secure: process.env.NODE_ENV === "production",
  };
  res.cookie(COOKIE_OH_REF_SID, session_id, cookieOptions);

  const userAgent = req.get("User-Agent") || req.headers?.["user-agent"] || null;
  let ip = null;
  try {
    const raw = req.ip || req.connection?.remoteAddress;
    if (raw && typeof raw === "string") ip = raw;
  } catch (e) {}

  try {
    // (1) Total visits: insert every hit into referral_pageviews
    await pool.query(
      `INSERT INTO referral_pageviews (source, medium, campaign, ref, session_id, landing_path, user_agent, ip)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [src, med, camp, refVal, session_id, landing, userAgent, ip]
    );

    // (2) Unique visits: one row per (source, session_id) in referral_visits
    const visitInsert = await pool.query(
      `INSERT INTO referral_visits (source, medium, campaign, ref, session_id, landing_path)
       VALUES ($1, $2, $3, $4, $5, $6)
       ON CONFLICT (source, session_id) DO NOTHING
       RETURNING id`,
      [src, med, camp, refVal, session_id, landing]
    );
    const sessionCreated = visitInsert.rowCount > 0;
    return res.status(200).json({
      success: true,
      session_id,
      logged: { pageview: true, sessionCreated },
    });
  } catch (err) {
    console.error("[referrals/visit] error", err);
    return res.status(500).json({
      success: false,
      message: "referrals visit insert failed",
    });
  }
};

/**
 * GET /referrals/partners — admin only. Returns list of partners for dropdown.
 * If table referral_partners does not exist, returns [] (run migration 016_referral_partners.sql).
 */
export const getReferralPartners = async (req, res) => {
  try {
    const { rows } = await pool.query(
      "SELECT code, name FROM referral_partners WHERE is_active = true ORDER BY name"
    );
    return res.status(200).json(rows);
  } catch (err) {
    const isMissingTable =
      err.code === "42P01" ||
      (err.message && err.message.includes("referral_partners") && err.message.includes("does not exist"));
    if (isMissingTable) {
      console.warn(
        "referral_partners table missing. Run migration: backendEsModule/migrations/016_referral_partners.sql"
      );
      return res.status(200).json([]);
    }
    console.error("getReferralPartners error:", err);
    return res.status(500).json({ success: false, message: "Server error" });
  }
};

/** Default date range when from/to not provided: last 30 days (inclusive). */
function getDefaultDateRange() {
  const to = new Date();
  const from = new Date(to);
  from.setDate(from.getDate() - 30);
  return {
    from: from.toISOString().slice(0, 10),
    to: to.toISOString().slice(0, 10),
  };
}

/** Compute from/to (YYYY-MM-DD) from range param. Timezone-safe using UTC. range: 24h | 7d | 30d | 90d | all. */
function getDateRangeFromRangeParam(range) {
  const r = typeof range === "string" ? range.trim().toLowerCase() : "";
  const now = new Date();
  const toDate = now.toISOString().slice(0, 10);
  if (r === "all") {
    return { from: "2000-01-01", to: toDate };
  }
  const ms = now.getTime();
  let fromDate;
  if (r === "24h") {
    fromDate = new Date(ms - 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
  } else if (r === "7d") {
    fromDate = new Date(ms - 7 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
  } else if (r === "90d") {
    fromDate = new Date(ms - 90 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
  } else {
    // 30d or default
    fromDate = new Date(ms - 30 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10);
  }
  return { from: fromDate, to: toDate };
}

/**
 * GET /referrals/stats?source=efe&range=24h|7d|30d|90d|all — admin only.
 * Also accepts from/to (YYYY-MM-DD). If range is provided it takes precedence; else from/to; else default 30d.
 * Date range: created_at::date between from and to (inclusive).
 */
export const getPartnerReferralStats = async (req, res) => {
  try {
    const { source, range, from, to } = req.query;
    if (!source || typeof source !== "string" || !source.trim()) {
      return res.status(400).json({ success: false, message: "source is required" });
    }
    const sourceVal = source.trim().toLowerCase();
    let fromDate, toDate;
    const rangeVal = typeof range === "string" ? range.trim() : "";
    if (rangeVal && /^(24h|7d|30d|90d|all)$/i.test(rangeVal)) {
      const computed = getDateRangeFromRangeParam(rangeVal);
      fromDate = computed.from;
      toDate = computed.to;
    } else {
      const fromStr = typeof from === "string" ? from.trim() : "";
      const toStr = typeof to === "string" ? to.trim() : "";
      fromDate = /^\d{4}-\d{2}-\d{2}$/.test(fromStr) ? fromStr : null;
      toDate = /^\d{4}-\d{2}-\d{2}$/.test(toStr) ? toStr : null;
      if (!fromDate || !toDate) {
        const def = getDefaultDateRange();
        if (!fromDate) fromDate = def.from;
        if (!toDate) toDate = def.to;
      }
    }

    const paramsSource = [sourceVal, fromDate, toDate];
    // visits = total page hits (referral_pageviews); uniqueVisits = distinct sessions (referral_visits)
    let visits = 0;
    let uniqueVisits = 0;
    try {
      const [pageviewsResult, sessionsResult] = await Promise.all([
        pool.query(
          `SELECT COUNT(*) AS total FROM referral_pageviews
           WHERE LOWER(TRIM(source)) = $1 AND created_at::date >= $2::date AND created_at::date <= $3::date`,
          paramsSource
        ),
        pool.query(
          `SELECT COUNT(*) AS total FROM referral_visits
           WHERE LOWER(TRIM(source)) = $1 AND created_at::date >= $2::date AND created_at::date <= $3::date`,
          paramsSource
        ),
      ]);
      visits = parseInt(pageviewsResult.rows[0]?.total ?? "0", 10);
      uniqueVisits = parseInt(sessionsResult.rows[0]?.total ?? "0", 10);
    } catch (tableErr) {
      if (tableErr.code === "42P01" && tableErr.message && tableErr.message.includes("referral_pageviews")) {
        const fallback = await pool.query(
          `SELECT COUNT(*) AS total FROM referral_visits
           WHERE LOWER(TRIM(source)) = $1 AND created_at::date >= $2::date AND created_at::date <= $3::date`,
          paramsSource
        );
        uniqueVisits = parseInt(fallback.rows[0]?.total ?? "0", 10);
        visits = uniqueVisits;
      } else {
        throw tableErr;
      }
    }

    const signupsResult = await pool.query(
      `SELECT COUNT(*) AS total FROM users
       WHERE LOWER(TRIM(COALESCE(signup_source, ''))) = $1 AND created_at::date >= $2::date AND created_at::date <= $3::date`,
      [sourceVal, fromDate, toDate]
    );
    const signups = parseInt(signupsResult.rows[0]?.total ?? "0", 10);
    const conversionRate = uniqueVisits > 0 ? Math.round((signups / uniqueVisits) * 10000) / 100 : 0;

    return res.status(200).json({
      source: sourceVal,
      visits,
      uniqueVisits,
      signups,
      conversionRate,
    });
  } catch (err) {
    console.error("getPartnerReferralStats error:", err);
    return res.status(500).json({ success: false, message: "Server error" });
  }
};

/**
 * GET /referrals/signups?source=efe&range=30d&page=1&limit=20 — admin only.
 * Also accepts from/to. If range provided it takes precedence; else from/to; else default 30d.
 */
export const getPartnerSignups = async (req, res) => {
  try {
    const { source, range, from, to, page = "1", limit = "20" } = req.query;
    if (!source || typeof source !== "string" || !source.trim()) {
      return res.status(400).json({ success: false, message: "source is required" });
    }
    const sourceVal = source.trim().toLowerCase();
    let fromDate, toDate;
    const rangeVal = typeof range === "string" ? range.trim() : "";
    if (rangeVal && /^(24h|7d|30d|90d|all)$/i.test(rangeVal)) {
      const computed = getDateRangeFromRangeParam(rangeVal);
      fromDate = computed.from;
      toDate = computed.to;
    } else {
      fromDate = from && /^\d{4}-\d{2}-\d{2}$/.test(from) ? from : null;
      toDate = to && /^\d{4}-\d{2}-\d{2}$/.test(to) ? to : null;
      if (!fromDate || !toDate) {
        const def = getDefaultDateRange();
        if (!fromDate) fromDate = def.from;
        if (!toDate) toDate = def.to;
      }
    }
    const pageNum = Math.max(1, parseInt(String(page), 10) || 1);
    const limitNum = Math.min(100, Math.max(1, parseInt(String(limit), 10) || 20));
    const offset = (pageNum - 1) * limitNum;

    const countResult = await pool.query(
      `SELECT COUNT(*) AS total FROM users
       WHERE LOWER(TRIM(COALESCE(signup_source, ''))) = $1 AND created_at::date >= $2::date AND created_at::date <= $3::date`,
      [sourceVal, fromDate, toDate]
    );
    const total = parseInt(countResult.rows[0]?.total ?? "0", 10);

    const listResult = await pool.query(
      `SELECT id, first_name, last_name, email, created_at,
              signup_source, signup_campaign, signup_medium, signup_landing_path
       FROM users
       WHERE LOWER(TRIM(COALESCE(signup_source, ''))) = $1 AND created_at::date >= $2::date AND created_at::date <= $3::date
       ORDER BY created_at DESC
       LIMIT $4 OFFSET $5`,
      [sourceVal, fromDate, toDate, limitNum, offset]
    );
    const items = listResult.rows.map((row) => ({
      id: row.id,
      name: [row.first_name, row.last_name].filter(Boolean).join(" ") || null,
      email: row.email,
      created_at: row.created_at,
      signup_source: row.signup_source,
      signup_campaign: row.signup_campaign ?? null,
      signup_medium: row.signup_medium ?? null,
      signup_landing_path: row.signup_landing_path ?? null,
    }));

    return res.status(200).json({
      items,
      page: pageNum,
      limit: limitNum,
      total,
    });
  } catch (err) {
    console.error("getPartnerSignups error:", err);
    return res.status(500).json({ success: false, message: "Server error" });
  }
};
