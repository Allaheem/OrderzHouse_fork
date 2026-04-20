import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useSelector } from "react-redux";
import API from "../../api/client.js";
import { loadStripe } from "@stripe/stripe-js";
import GradientButton from "../buttons/GradientButton.jsx";
import PaymentMethodModal from "./PaymentMethodChooser.jsx";
import PageMeta from "../PageMeta.jsx";
import { useToast } from "../toast/ToastProvider";


const stripeKey = import.meta.env.VITE_STRIPE_PUBLIC_KEY;
const stripePromise = stripeKey ? loadStripe(stripeKey) : null;

function freelancerVerificationBookingUrl() {
  const a = import.meta.env.VITE_FREELANCER_VERIFY_BOOKING_URL;
  const b = import.meta.env.VITE_COMPANY_SUBSCRIBE_URL;
  if (typeof a === "string" && a.trim()) return a.trim();
  if (typeof b === "string" && b.trim()) return b.trim();
  return "https://appointments.battechno.com/survey";
}

// =============== Auth Hook ===============
const useAuth = () => {
  const { user } = useSelector((s) => ({
    user: s.auth?.userData,
  }));
  return { user };
};
// =========================================

function CheckIcon({ className = "" }) {
  return (
    <svg
      className={className}
      width="14"
      height="14"
      viewBox="0 0 24 24"
      fill="none"
      aria-hidden="true"
    >
      <path
        d="M20 6L9 17l-5-5"
        stroke="currentColor"
        strokeWidth="2.4"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function PlanCard({
  plan,
  onSubscribe,
  canSubscribe,
  hasActiveSubscription,
  freelancerMode,
  onVerifyAccount,
  onActivateFreePlan = async () => {},
  freelancerActivating = false,
}) {
  const highlight = plan.plan_type === "popular";

  const durationLabel =
    plan.plan_type === "monthly"
      ? `${plan.duration} Month`
      : plan.plan_type === "yearly"
      ? `${plan.duration} Year`
      : plan.name;

  return (
    <div
      className={[
        "h-full rounded-3xl flex flex-col",
        "bg-white/85 backdrop-blur-xl ",
        "border border-slate-200/70",
        "shadow-[0_25px_60px_-45px_rgba(2,6,23,0.25)]",
        "hover:shadow-[0_35px_80px_-55px_rgba(2,6,23,0.28)]",
        "transition-all duration-300 ease-out",
        highlight
          ? "ring-1 ring-orange-500/20 bg-gradient-to-b from-orange-50/70 to-indigo-50/40"
          : "ring-1 ring-black/5",
      ].join(" ")}
      style={{ minHeight: 360 }}
    >
      
      <div className="p-6 flex-1 flex flex-col">
        <div className="flex items-start justify-between gap-3">
          <div>
            <p className="text-sm font-semibold text-slate-900">{plan.name ?? "Plan"}</p>

            <p className="mt-2 text-3xl font-semibold text-slate-900">
              {plan.price} <span className="text-sm font-normal text-slate-500">JD</span>
            </p>

            <p className="mt-1 text-sm text-slate-600">{durationLabel}</p>
          </div>

          {highlight ? (
            <span className="inline-flex items-center rounded-full border border-orange-500/15 bg-orange-500/10 px-3 py-1 text-xs font-semibold text-orange-600">
              Most popular
            </span>
          ) : (
            <span className="inline-flex items-center rounded-full border border-slate-200 bg-white px-3 py-1 text-xs font-semibold text-slate-600">
              Plan
            </span>
          )}
        </div>

        <div className="mt-5 h-px bg-slate-200/70" />

        <ul className="mt-5 space-y-2">
          {plan.features?.map((b, i) => (
            <li key={i} className="flex items-start gap-2 text-sm text-slate-700">
              <span className="mt-0.5 grid h-5 w-5 place-items-center rounded-full border border-orange-500/15 bg-orange-500/10 text-orange-700">
                <CheckIcon className="h-3 w-3" />
              </span>
              <span>{b}</span>
            </li>
          ))}
        </ul>

        <div className="mt-auto">
    {freelancerMode ? (
      <>
        <button
          type="button"
          disabled={hasActiveSubscription || freelancerActivating}
          onClick={() => onActivateFreePlan(plan)}
          className={`w-full rounded-full px-4 py-2.5 text-sm font-semibold shadow-[0_14px_30px_rgba(15,23,42,0.18)] transition ${
            hasActiveSubscription || freelancerActivating
              ? "text-slate-500 bg-slate-100 cursor-not-allowed"
              : "text-white bg-slate-900 hover:opacity-95 active:scale-[0.99]"
          }`}
        >
          {freelancerActivating
            ? "Activating…"
            : hasActiveSubscription
            ? "Free plan active"
            : "Activate free month"}
        </button>
        <p className="mt-2 text-xs text-slate-500 text-center">
          Starts your free period so you can receive orders. Paid tiers are handled by admin.
        </p>
        <button
          type="button"
          onClick={onVerifyAccount}
          disabled={freelancerActivating}
          className="mt-3 w-full rounded-full px-4 py-2.5 text-sm font-semibold border border-slate-300 text-slate-800 bg-white hover:bg-slate-50 disabled:opacity-50"
        >
          Verify account
        </button>
        <p className="mt-2 text-xs text-slate-500 text-center">
          Book a short interview to verify your profile after using the free plan.
        </p>
      </>
    ) : canSubscribe ? (
      <>
        <button
          onClick={() => !hasActiveSubscription && onSubscribe(plan)}
          disabled={hasActiveSubscription}
          className={`w-full rounded-full px-4 py-2.5 text-sm font-semibold transition ${
            hasActiveSubscription
              ? "text-slate-400 bg-slate-100 cursor-not-allowed opacity-50"
              : "text-white bg-slate-900 shadow-[0_14px_30px_rgba(15,23,42,0.18)] hover:opacity-95 active:scale-[0.99]"
          }`}
        >
          {hasActiveSubscription ? "Subscription Active" : "Subscribe"}
        </button>
        {hasActiveSubscription ? (
          <p className="mt-2 text-xs text-slate-500 text-center">
            You already have an active subscription.
          </p>
        ) : (
          <p className="mt-2 text-xs text-slate-500">
            Secure checkout — choose online or offline payment.
          </p>
        )}
      </>
    ) : (
      <div className="w-full rounded-full px-4 py-2.5 text-sm font-semibold text-slate-400 bg-slate-100 text-center">
        Freelancers only
      </div>
    )}
  </div>
      </div>
    </div>
  );
}

export default function Plans() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const toast = useToast();
  const [plans, setPlans] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedPlan, setSelectedPlan] = useState(null);
  const [hasActiveSubscription, setHasActiveSubscription] = useState(false);
  const [subscriptionExpiry, setSubscriptionExpiry] = useState(null);
  const [freelancerActivating, setFreelancerActivating] = useState(false);

  const isFreelancer = user?.role_id === 3;

  function normalizePlansPayload(payload) {
    // Supports API shapes: { plans: [...] } (current), { data: [...] }, or direct array (legacy)
    const list = Array.isArray(payload?.plans)
      ? payload.plans
      : Array.isArray(payload?.data)
      ? payload.data
      : Array.isArray(payload)
      ? payload
      : [];
    // Only show Monthly(1) + Yearly(1). Ignore multi-year tiers like "Two years".
    return list.filter((p) => {
      const t = String(p?.plan_type || "").toLowerCase();
      const d = Number(p?.duration || 0);
      if (Number(p?.price) <= 0) return true; // keep Free plan
      if (t === "monthly" && d === 1) return true;
      if (t === "yearly" && d === 1) return true;
      return false;
    });
  }

  useEffect(() => {
    API.get("/plans")
      .then((res) => {
        setPlans(normalizePlansPayload(res?.data));
        setLoading(false);
      })
      .catch(() => setLoading(false));
  }, [user?.id]);

  // Fetch subscription status for freelancers
  useEffect(() => {
    if (user && user.role_id === 3) {
      API.get("/subscriptions/status")
        .then((res) => {
          const data = res.data;
          if (data?.success && data?.subscription) {
            const sub = data.subscription;
            const isActive = sub.status === "active" || sub.status === "pending_start";
            setHasActiveSubscription(isActive);
            if (isActive && sub.end_date) {
              setSubscriptionExpiry(new Date(sub.end_date));
            } else if (isActive && sub.start_date) {
              setSubscriptionExpiry(new Date(sub.start_date));
            }
          } else {
            setHasActiveSubscription(false);
            setSubscriptionExpiry(null);
          }
        })
        .catch(() => {
          setHasActiveSubscription(false);
          setSubscriptionExpiry(null);
        });
    }
  }, [user]);

  const subscribeOnline = async () => {
    if (!user) return navigate("/login");
    if (!selectedPlan) {
      return;
    }

    // Prevent subscription if user has active subscription
    if (hasActiveSubscription) {
      toast.error("You already have an active subscription. You cannot change plans until it expires.");
      return;
    }

    try {
      const res = await API.post("/stripe/create-checkout-session", {
        plan_id: selectedPlan.id,
        user_id: user.id,
      });

      const data = res.data;
      // Handle free plan (no Stripe needed)
      if (data?.free === true || data?.url === null) {
        toast.success("Free plan subscribed successfully!");
        return;
      }

      // Handle Stripe checkout
      if (data?.url) {
        window.location.href = data.url;
      } else {
        toast.error("Failed to start checkout. Please try again.");
      }
    } catch (err) {
      const msg = err.response?.data?.message ?? err.response?.data?.error ?? "Failed to start checkout. Please try again.";
      toast.error(msg);
    }
  };

  const subscribeOffline = () => {
    if (!user) return navigate("/login");
    window.location.href = "https://appointments.battechno.com/survey";
  };

  const openFreelancerVerification = () => {
    const url = freelancerVerificationBookingUrl();
    try {
      window.open(url, "_blank", "noopener,noreferrer");
    } catch {
      window.location.href = url;
    }
  };

  const activateFreelancerFreePlan = async (plan) => {
    if (!user) return navigate("/login");
    if (hasActiveSubscription) {
      toast.error("You already have an active subscription.");
      return;
    }
    if (Number(plan.price) > 0) {
      toast.error("Only the free plan can be activated here.");
      return;
    }
    setFreelancerActivating(true);
    try {
      await API.post("/plans/subscribe", { plan_id: plan.id });
      toast.success("Free plan activated. You can receive orders.");
      const res = await API.get("/subscriptions/status");
      const data = res.data;
      if (data?.success && data?.subscription) {
        const sub = data.subscription;
        const isActive = sub.status === "active" || sub.status === "pending_start";
        setHasActiveSubscription(isActive);
        if (isActive && sub.end_date) {
          setSubscriptionExpiry(new Date(sub.end_date));
        } else if (isActive && sub.start_date) {
          setSubscriptionExpiry(new Date(sub.start_date));
        }
      } else {
        setHasActiveSubscription(false);
        setSubscriptionExpiry(null);
      }
    } catch (err) {
      const msg =
        err.response?.data?.message ??
        err.response?.data?.error ??
        "Could not activate the free plan.";
      toast.error(msg);
    } finally {
      setFreelancerActivating(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center text-slate-600">
        Loading plans...
      </div>
    );
  }

  return (
    <div className="relative isolate overflow-hidden bg-white">
      <PageMeta
        title="Plans & Pricing – OrderzHouse"
        description="Freelancers use the free plan; verify your account with the team. Clients and guests see full plan options where applicable."
      />
      {/* ✅ نفس Glows الموجودة في Pricing */}
           <div className="pointer-events-none absolute -top-28 left-[-80px] h-[360px] w-[360px] rounded-full bg-yellow-300/25 blur-3xl" />
          <div className="pointer-events-none absolute -top-28 right-[-90px] h-[380px] w-[380px] rounded-full bg-orange-400/20 blur-3xl" />
 
      {/* subtle dotted texture */}
      <div className="pointer-events-none absolute inset-0 opacity-[0.05] [background-image:radial-gradient(circle_at_1px_1px,black_1px,transparent_0)] [background-size:18px_18px]" />

      <div className="mx-auto max-w-6xl px-4 py-16 sm:py-32 md:px-8">
        {/* Header نفس الستايل */}
        <div className="max-w-2xl">
          <p className="text-sm text-orange-700">Pricing</p>
          <h1 className="mt-2 text-3xl font-semibold tracking-tight text-slate-900 sm:text-4xl">
            {isFreelancer ? "Free plan & verification" : "Choose Your Plan"}
          </h1>
          <p className="mt-3 text-slate-600">
            {isFreelancer
              ? "You are on the free freelancer plan. Book verification to become a trusted account after we review your work. Paid upgrades are arranged through admin, not in the app."
              : "Pick a plan that fits your workflow — upgrade anytime."}
          </p>
        </div>

        {/* Active subscription notice */}
        {!isFreelancer && hasActiveSubscription && subscriptionExpiry && (
          <div className="mt-6 rounded-xl bg-orange-50 border border-orange-200 px-4 py-3">
            <p className="text-sm font-semibold text-orange-900">
              You already have an active subscription. You can change plans after it expires on {subscriptionExpiry.toLocaleDateString()}.
            </p>
          </div>
        )}
        {isFreelancer && hasActiveSubscription && subscriptionExpiry && (
          <div className="mt-6 rounded-xl bg-emerald-50 border border-emerald-200 px-4 py-3">
            <p className="text-sm font-semibold text-emerald-900">
              Your free plan is active. You can receive orders. Current period includes {subscriptionExpiry.toLocaleDateString()}.
            </p>
          </div>
        )}

        {/* Grid نفس Pricing */}
        {plans.length === 0 && !loading && (
          <p className="mt-10 text-center text-slate-600">
            No free plan is available from the server. Ask an admin to add a plan with price 0, or contact support.
          </p>
        )}
        <div className="mt-10 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          {plans.map((p) => (
            <PlanCard 
              key={p.id} 
              plan={p} 
              onSubscribe={setSelectedPlan}
              canSubscribe={user?.role_id === 3}
              hasActiveSubscription={hasActiveSubscription}
              freelancerMode={isFreelancer}
              onVerifyAccount={openFreelancerVerification}
              onActivateFreePlan={activateFreelancerFreePlan}
              freelancerActivating={freelancerActivating}
            />
          ))}
        </div>

        {!isFreelancer && (
          <PaymentMethodModal
            open={!!selectedPlan}
            onClose={() => setSelectedPlan(null)}
            onOnline={subscribeOnline}
            onOffline={subscribeOffline}
          />
        )}

        <p className="mt-10 text-center text-sm font-semibold text-slate-600">
          * A contract is signed after subscription.
        </p>

        <div className="mt-4 flex justify-center">
          <GradientButton
            href="/contracts/contract.pdf"
            className="text-sm px-4 py-2 rounded-lg"
            style={{ width: "fit-content" }}
          >
            View Contract
          </GradientButton>
        </div>
      </div>
    </div>
  );
}
