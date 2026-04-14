/**
 * Shared handler: whether PayPal plan checkout is enabled (env). Mounted at multiple paths for compatibility.
 */
export function getPayPalCheckoutAvailable(req, res) {
  res.json({
    available: process.env.PAYPAL_ENABLED === "true",
  });
}
