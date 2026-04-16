import express from "express";
import rateLimit from "express-rate-limit";
import cookieParser from "cookie-parser";
import helmet from "helmet";
import "./models/db.js";
import cors from "cors";
import http from "http";
import dotenv from "dotenv";
import cron from "node-cron";
import "./services/notificationListeners.js";

// Cron jobs
import "./cron/expireSubscriptions.js";
import "./cron/autoExpireOldOffers.js";
import { startDeadlineWatcher } from "./cron/realTimeDeadlineWatcher.js";
import { cleanupDeactivatedUsers } from "./cron/cleanupDeactivatedUsers.js";
import { registerTenderVaultExposureRotationCron } from "./cron/tenderVaultExposureRotationCron.js";
import liveScreenRoutes from "./router/LiveScreen.js";

dotenv.config();

if (process.env.NODE_ENV !== "test") {
  const secret = process.env.JWT_SECRET || "";
  const minLen = process.env.NODE_ENV === "production" ? 32 : 16;
  if (secret.length < minLen) {
    console.error(
      `FATAL: JWT_SECRET must be set and at least ${minLen} characters (current length: ${secret.length}).`
    );
    process.exit(1);
  }
  if (process.env.NODE_ENV === "production" && !process.env.OTP_SECRET) {
    console.error("FATAL: OTP_SECRET must be set in production.");
    process.exit(1);
  }
  if (process.env.NODE_ENV === "production" && !process.env.REFRESH_TOKEN_SECRET) {
    console.error(
      "FATAL: REFRESH_TOKEN_SECRET must be set in production (do not reuse JWT_SECRET)."
    );
    process.exit(1);
  }
}

// Check email configuration (Resend) so OTP works everywhere
const hasEmailConfig = !!(process.env.RESEND_API_KEY && process.env.EMAIL_FROM);
console.log(`📧 Email configured: ${hasEmailConfig ? "✅ YES (Resend API key and EMAIL_FROM set)" : "❌ NO (OTP emails will fail)"}`);
if (!hasEmailConfig) {
  console.warn("⚠️  Set RESEND_API_KEY and EMAIL_FROM for OTP emails to work.");
}

// Start real-time deadline watcher
startDeadlineWatcher();

// delete permanently after 30 days
cron.schedule("*/20 * * * *", async () => {
console.log("Running cleanupDeactivatedUsers cron job...");
  await cleanupDeactivatedUsers();
});

// Tender Vault exposure rotation (12h window, 12h cadence)
registerTenderVaultExposureRotationCron();



// Routers
import SubscriptionRouter from "./router/subscription.js";
import CoursesRouter from "./router/course.js";
import assignmentsRouter from "./router/assignments.js";
import VerificationRouter from "./router/verification.js";
import paymentsRoutes from "./router/payments.js";
import AdminUser from "./router/adminUser.js"
import tasksRouter from "./router/tasks.js";
import usersRouter from "./router/user.js";
import plansRouter from "./router/plans.js";
import logsRouter from "./router/logs.js";
import projectsRouter from "./router/projects.js";
import categoriesRouter from "./router/category.js";
import notificationsRouter from "./router/notifications.js";
import authRouter from "./router/auth.js";
import offersRouter from "./router/offers.js";
import ratingsRouter from "./router/rating.js";
import Blogsrouter from "./router/blogs.js"
import freelancerCategoriesRouter from "./router/freelancerCategories.js";
import subscriptionsRoutes from "./router/subscription.js";
import analyticsRoutes from "./router/analytics.js";
import emailVerificationRoutes from "./router/emailVerification.js";
import chatsRouter from "./router/chats.js";
import moderationRouter from "./router/moderation.js";
import StripeRouter from "./router/Stripe/stripe.js";
import webhookRouter from "./router/Stripe/stripeWebhook.js";
import paypalRouter from "./router/paypal.js";
import searchRouter from "./router/search.js";
import referralsRouter from "./router/referrals.js";
import tenderVaultRouter from "./router/tenderVault.js";
import adminTenderVaultRoutes from "./router/adminTenderVaultRoutes.js";


const app = express();

/** Default 5050: on many Macs port 5000 is taken by Control Center (AirPlay). */
const DEFAULT_DEV_PORT = 5050;

if (process.env.NODE_ENV !== "test") {
  app.set("trust proxy", 1);
}

if (process.env.NODE_ENV === "production") {
  app.use(
    helmet({
      crossOriginResourcePolicy: { policy: "cross-origin" },
    })
  );
}

// ✅ Stripe webhook needs the raw body (mounted BEFORE express.json())
// This ensures the webhook route gets raw body for signature verification
app.use("/stripe", webhookRouter);

// Body and cookies: must be before all API routes (e.g. /referrals, /users) so req.body and req.cookies are set
app.use(express.json());
app.use(cookieParser());

// CORS configuration - supports both local and production
const allowedOrigins = [
  process.env.FRONTEND_URL,
  "https://orderzhouse.com",
  "https://www.orderzhouse.com",
  "http://localhost:5173",
  "http://localhost:5174",
  "http://localhost:5175"
].filter(Boolean); // Remove undefined values

/** Admin UI opened from phone/tablet on same Wi‑Fi (http://192.168.x.x:5173) */
function isPrivateLanOrigin(origin) {
  try {
    const u = new URL(origin);
    const h = u.hostname.toLowerCase();
    if (h === "localhost" || h === "127.0.0.1") return true;
    if (h.endsWith(".local")) return true;
    if (/^192\.168\.\d{1,3}\.\d{1,3}$/.test(h)) return true;
    if (/^10\.\d{1,3}\.\d{1,3}\.\d{1,3}$/.test(h)) return true;
    if (/^172\.(1[6-9]|2\d|3[0-1])\.\d{1,3}\.\d{1,3}$/.test(h)) return true;
  } catch (_) {
    return false;
  }
  return false;
}

app.use(cors({
  origin: (origin, callback) => {
    // Allow requests with no origin (like mobile apps or Postman)
    if (!origin) return callback(null, true);
    
    // Check if origin is in allowed list
    if (allowedOrigins.includes(origin)) {
      callback(null, true);
    } else if (isPrivateLanOrigin(origin)) {
      callback(null, true);
    } else {
      // In development, allow all origins for easier testing
      if (process.env.NODE_ENV === "development") {
        callback(null, true);
      } else {
        callback(new Error("Not allowed by CORS"));
      }
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  exposedHeaders: ['Content-Type', 'Authorization']
}));

// Global rate limiter for all API routes (does not apply to /stripe webhook mounted above)
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 600,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: "Too many requests, please try again later." },
});
app.use(globalLimiter);

// Stricter limiter for auth endpoints (environment-aware)
const isDevelopment = process.env.NODE_ENV === "development";
const authMaxRequests = isDevelopment ? 1000 : 20; // 20 per 15 min: protects from brute force, allows typos/retries

// Log rate limit configuration on startup
console.log(`🔒 Auth Rate Limiter: ${authMaxRequests} requests per 15 minutes (${isDevelopment ? "DEVELOPMENT" : "PRODUCTION"} mode)`);

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: authMaxRequests,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: "Too many login/register attempts, please try later." },
  // Skip rate limiting in development if needed (uncomment if still having issues)
  // skip: (req) => isDevelopment,
});
app.use("/users/login", authLimiter);
app.use("/users/register", authLimiter);
app.use("/auth/google", authLimiter);
app.use("/auth/2fa/verify-login", authLimiter);

// Stricter limiter for password reset (do not leak email existence)
const passwordResetLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: "Too many password reset attempts. Please try again later." },
});
app.use("/users/forgot-password", passwordResetLimiter);
app.use("/users/reset-password", passwordResetLimiter);
app.use("/auth/forgot-password", passwordResetLimiter);
app.use("/auth/verify-reset-otp", passwordResetLimiter);
app.use("/auth/reset-password", passwordResetLimiter);

const signupOtpLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: isDevelopment ? 200 : 30,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: "Too many signup attempts. Please try again later." },
});
app.use("/users/request-signup-otp", signupOtpLimiter);
app.use("/users/verify-and-register", signupOtpLimiter);

// Routers
//APPOINTMENTS
app.use("/assignments", assignmentsRouter);
app.use("/verification", VerificationRouter);
app.use("/freelancerCategories", freelancerCategoriesRouter);
app.use("/blogs", Blogsrouter)
app.use("/admUser" , AdminUser)
app.use("/category" , categoriesRouter);
app.use("/tasks", tasksRouter);
app.use("/offers", offersRouter);
app.use("/analytics", analyticsRoutes);
app.use("/projects", projectsRouter);
app.use("/users", usersRouter);
app.use("/plans", plansRouter);
app.use("/logs", logsRouter);
app.use("/courses", CoursesRouter);
app.use("/subscriptions", subscriptionsRoutes);
app.use("/chats", chatsRouter);
app.use("/notifications", notificationsRouter);
app.use("/auth", authRouter);
app.use("/ratings", ratingsRouter);
app.use("/email", emailVerificationRoutes);
app.use("/payments", paymentsRoutes);
app.use("/chat", chatsRouter);
app.use("/moderation", moderationRouter);
app.use("/api", liveScreenRoutes);
app.use("/stripe", StripeRouter);
app.use("/paypal", paypalRouter);
app.use("/search", searchRouter);
app.use("/referrals", referralsRouter);
app.use("/tender-vault", tenderVaultRouter);
app.use("/api/admin/tender-vault", adminTenderVaultRoutes);
console.log("[routes] mounted /api/admin/tender-vault");

let server, io;

if (process.env.NODE_ENV !== "test") {
  server = http.createServer(app);
  const { default: initSocket } = await import("./sockets/socket.js");
  io = initSocket(server);

  const isTest = process.env.NODE_ENV === "test";
  const envPortRaw = process.env.PORT;
  const parsedEnv =
    envPortRaw !== undefined && String(envPortRaw).trim() !== ""
      ? Number.parseInt(String(envPortRaw), 10)
      : NaN;
  const primaryPort = isTest
    ? 0
    : Number.isFinite(parsedEnv) && parsedEnv > 0
      ? parsedEnv
      : DEFAULT_DEV_PORT;
  const fallbackPorts = [5000, 5001, 3001].filter(
    (p) => Number.isFinite(p) && p > 0 && p !== primaryPort
  );
  const portsToTry = isTest ? [0] : [primaryPort, ...fallbackPorts];

  const tryListen = (index) => {
    if (index >= portsToTry.length) {
      console.error("❌ Could not bind. Tried ports:", portsToTry.join(", "));
      process.exit(1);
    }
    const port = portsToTry[index];
    server.removeAllListeners("error");
    server.once("error", (err) => {
      if (err && err.code === "EADDRINUSE") {
        const next = portsToTry[index + 1];
        console.warn(
          `⚠️ Port ${port} in use${next != null ? ` — trying ${next}…` : ""}`
        );
        tryListen(index + 1);
        return;
      }
      throw err;
    });
    // Bind all interfaces so phones/tablets on LAN can reach the API (e.g. http://192.168.x.x:5050).
    server.listen(port, "0.0.0.0", () => {
      const addressInfo = server.address();
      const boundPort =
        typeof addressInfo === "object" && addressInfo
          ? addressInfo.port
          : port;
      if (!isTest && boundPort !== primaryPort) {
        console.warn(
          `ℹ️ Bound on ${boundPort} (preferred was ${primaryPort}). Update backendEsModule/.env: PORT=${boundPort} and APP_API_URL=http://localhost:${boundPort}`
        );
      }
      console.log(`✅ Server listening at http://0.0.0.0:${boundPort} (LAN + localhost)`);
    });
  };

  tryListen(0);
} else {
  // For tests, create minimal server without socket.io
  server = http.createServer(app);
  io = null;
}

export { app, server, io };