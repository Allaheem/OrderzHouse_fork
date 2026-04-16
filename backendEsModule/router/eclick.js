import express from "express";
import { authentication } from "../middleware/authentication.js";
import {
  createEClickPlanCheckoutSession,
  captureEClickPlanOrder,
} from "../controller/eclick/eclickPlanCheckout.js";
import { getEClickCheckoutAvailable } from "../controller/plans-subscriptions/eclickCheckoutAvailable.js";

const eClickRouter = express.Router();

/** Public: mobile app uses this to show/hide "Pay with eClick". */
eClickRouter.get("/checkout-available", getEClickCheckoutAvailable);

eClickRouter.post("/plan/create-session", authentication, createEClickPlanCheckoutSession);
eClickRouter.post("/plan/capture", authentication, captureEClickPlanOrder);

export default eClickRouter;
