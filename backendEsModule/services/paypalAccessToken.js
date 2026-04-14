/**
 * PayPal REST API access token (OAuth2 client_credentials).
 * Sandbox: https://api-m.sandbox.paypal.com
 * Live:    https://api-m.paypal.com
 */
import axios from "axios";

let _cached = { token: null, expiresAt: 0 };

export function getPayPalApiBase() {
  const mode = (process.env.PAYPAL_MODE || "sandbox").toLowerCase();
  return mode === "live"
    ? "https://api-m.paypal.com"
    : "https://api-m.sandbox.paypal.com";
}

export async function getPayPalAccessToken() {
  const clientId = process.env.PAYPAL_CLIENT_ID?.trim();
  const secret = process.env.PAYPAL_CLIENT_SECRET?.trim();
  if (!clientId || !secret) {
    throw new Error("PAYPAL_CLIENT_ID and PAYPAL_CLIENT_SECRET must be set");
  }

  const now = Date.now() / 1000;
  if (_cached.token && _cached.expiresAt > now + 60) {
    return _cached.token;
  }

  const auth = Buffer.from(`${clientId}:${secret}`, "utf8").toString("base64");
  const base = getPayPalApiBase();

  const { data } = await axios.post(
    `${base}/v1/oauth2/token`,
    "grant_type=client_credentials",
    {
      headers: {
        Authorization: `Basic ${auth}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      timeout: 30000,
    }
  );

  const token = data?.access_token;
  const expiresIn = Number(data?.expires_in || 32400);
  if (!token) {
    throw new Error("PayPal OAuth: missing access_token");
  }

  _cached = {
    token,
    expiresAt: now + expiresIn,
  };
  return token;
}
