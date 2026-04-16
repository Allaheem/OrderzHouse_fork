/**
 * Shared handler: whether eClick plan checkout is enabled (env).
 */
export function getEClickCheckoutAvailable(req, res) {
  res.json({
    available: process.env.ECLICK_ENABLED === "true",
  });
}
