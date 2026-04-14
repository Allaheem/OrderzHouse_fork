import express from "express";
import { getAllSubscriptions } from "../controller/plans-subscriptions/subscriptions.js"
import { getSubscriptionStatus } from "../controller/plans-subscriptions/getSubscriptionStatus.js";
import { verifyAppleReceipt } from "../controller/plans-subscriptions/appleIapVerifyReceipt.js";
import { 
  assignSubscriptionToFreelancer, 
  getAdminSubscriptions,
  getFreelancersWithSubscriptions,
  activateSubscription,
  cancelSubscription
} from "../controller/plans-subscriptions/adminSubscriptions.js";
import { authentication } from "../middleware/authentication.js";
import adminOnly from "../middleware/adminOnly.js";
import { getPayPalCheckoutAvailable } from "../controller/plans-subscriptions/paypalCheckoutAvailable.js";

const SubscriptionRouter = express.Router();

/** Same as GET /paypal/checkout-available — for clients on older API deploys that only added subscriptions routes. */
SubscriptionRouter.get("/paypal-checkout-available", getPayPalCheckoutAvailable);

SubscriptionRouter.get("/admin/all", adminOnly ,getAllSubscriptions);
SubscriptionRouter.get("/admin/subscriptions", authentication, getAdminSubscriptions);
SubscriptionRouter.get("/admin/subscriptions/freelancers", authentication, getFreelancersWithSubscriptions);
SubscriptionRouter.post("/admin/subscriptions/assign", authentication, assignSubscriptionToFreelancer);
SubscriptionRouter.post("/admin/subscriptions/:id/activate", authentication, activateSubscription);
SubscriptionRouter.post("/admin/subscriptions/:id/cancel", authentication, cancelSubscription);
SubscriptionRouter.get("/status", authentication, getSubscriptionStatus);
SubscriptionRouter.post("/apple/verify-receipt", authentication, verifyAppleReceipt);

export default SubscriptionRouter;
