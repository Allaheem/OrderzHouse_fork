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

SubscriptionRouter.get("/admin/all", authentication, adminOnly, getAllSubscriptions);
SubscriptionRouter.get("/admin/subscriptions", authentication, adminOnly, getAdminSubscriptions);
SubscriptionRouter.get("/admin/subscriptions/freelancers", authentication, adminOnly, getFreelancersWithSubscriptions);
SubscriptionRouter.post("/admin/subscriptions/assign", authentication, adminOnly, assignSubscriptionToFreelancer);
SubscriptionRouter.post("/admin/subscriptions/:id/activate", authentication, adminOnly, activateSubscription);
SubscriptionRouter.post("/admin/subscriptions/:id/cancel", authentication, adminOnly, cancelSubscription);
SubscriptionRouter.get("/status", authentication, getSubscriptionStatus);
SubscriptionRouter.post("/apple/verify-receipt", authentication, verifyAppleReceipt);

export default SubscriptionRouter;
