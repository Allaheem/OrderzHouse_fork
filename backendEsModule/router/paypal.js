import express from "express";
import { authentication } from "../middleware/authentication.js";
import {
  createPayPalPlanOrder,
  capturePayPalPlanOrder,
} from "../controller/paypal/paypalPlanCheckout.js";
import { getPayPalCheckoutAvailable } from "../controller/plans-subscriptions/paypalCheckoutAvailable.js";

const paypalRouter = express.Router();

/** Public: mobile app uses this to show/hide “Pay with PayPal” without shipping client secrets. */
paypalRouter.get("/checkout-available", getPayPalCheckoutAvailable);

paypalRouter.post("/plan/create-order", authentication, createPayPalPlanOrder);
paypalRouter.post("/plan/capture", authentication, capturePayPalPlanOrder);

export default paypalRouter;
