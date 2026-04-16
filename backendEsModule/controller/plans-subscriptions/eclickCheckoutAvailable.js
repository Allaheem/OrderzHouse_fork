/**
 * Shared handler: whether eClick plan checkout is enabled (env).
 */
export function getEClickCheckoutAvailable(req, res) {
  const enabledFlag =
    process.env.ECLICK_ENABLED === "true" ||
    process.env.ECLICK_ENABLED === "1" ||
    String(process.env.ECLICK_ENABLED || "").toLowerCase() === "yes";
  const hasCheckoutUrl =
    typeof process.env.ECLICK_CHECKOUT_URL === "string" &&
    process.env.ECLICK_CHECKOUT_URL.trim().length > 0;

  res.json({
    available: enabledFlag || hasCheckoutUrl,
  });
}
