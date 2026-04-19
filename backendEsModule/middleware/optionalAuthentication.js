import jwt from "jsonwebtoken";
import pool from "../models/db.js";
import { normalizeTokenPayload } from "./authentication.js";

/**
 * Attaches `req.token` when a valid Bearer JWT is present; otherwise `req.token` is null.
 * Does not fail if the header is missing or invalid — used for public endpoints that behave
 * differently per role (e.g. GET /plans for freelancers vs clients).
 */
export const optionalAuthentication = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || typeof authHeader !== "string") {
    req.token = null;
    return next();
  }

  const parts = authHeader.split(" ");
  const token = parts.length >= 2 ? parts.pop() : null;
  if (!token) {
    req.token = null;
    return next();
  }

  jwt.verify(token, process.env.JWT_SECRET, async (err, result) => {
    if (err) {
      req.token = null;
      return next();
    }

    const decoded = normalizeTokenPayload(result);
    if (decoded?.is_deleted === true) {
      req.token = null;
      return next();
    }

    try {
      const userCheck = await pool.query(
        "SELECT id FROM users WHERE id = $1 AND is_deleted = FALSE",
        [decoded.userId]
      );
      if (userCheck.rows.length === 0) {
        req.token = null;
        return next();
      }
    } catch (e) {
      console.error("[optionalAuthentication] DB check:", e);
      req.token = null;
      return next();
    }

    req.token = decoded;
    next();
  });
};

export default optionalAuthentication;
