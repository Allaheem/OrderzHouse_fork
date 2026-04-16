import React, { useState, useEffect } from "react";

const primaryBtn =
  "bg-gradient-to-b from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 text-white focus-visible:ring-2 focus-visible:ring-orange-200/70";

// Format currency as JD
const formatJD = (value, { noDecimals = false } = {}) => {
  if (value == null || value === undefined || value === "") return "—";
  const num = Number(value);
  if (isNaN(num)) return "—";
  
  if (noDecimals) {
    const rounded = Math.round(num);
    return `${rounded} JD`;
  }
  
  const formatted = num.toFixed(2);
  const cleaned = formatted.replace(/\.?0+$/, "");
  return `${cleaned} JD`;
};

export default function PaymentStep({
  onBack,
  projectData = {},
  isSubmitting,
  onSubmit,
  onOfflinePayment, // New callback for offline payment
}) {
  const [selectedMethod, setSelectedMethod] = useState(null); // 'stripe', 'cliq', 'cash'

  // Guard: If project type is bidding, skip payment and submit directly
  // This is a safety measure in case someone manually navigates to this step
  useEffect(() => {
    if (projectData.project_type === "bidding" && onSubmit && !isSubmitting) {
      // Bidding projects should not go through payment step
      // Automatically submit the project creation
      onSubmit();
    }
  }, [projectData.project_type]); // Only depend on project_type to avoid re-triggering

  // Early return: Don't render payment UI for bidding projects
  // (This component should not be rendered for bidding, but this is a safety guard)
  if (projectData.project_type === "bidding") {
    return (
      <div className="rounded-2xl border bg-white p-8 shadow-sm">
        <div className="text-center py-8">
          <p className="text-slate-600">Processing bidding project...</p>
        </div>
      </div>
    );
  }

  const calculateAmount = () => {
    if (projectData.project_type === "fixed") {
      return formatJD(projectData.budget, { noDecimals: true });
    }
    if (projectData.project_type === "hourly") {
      const total = projectData.hourly_rate * 3;
      return formatJD(total, { noDecimals: true });
    }
    if (projectData.project_type === "bidding") {
      const min = projectData.budget_min || 0;
      const max = projectData.budget_max || 0;
      if (min > 0 && max > 0) {
        return `${formatJD(min, { noDecimals: true })} - ${formatJD(max, { noDecimals: true })}`;
      }
      return "—";
    }
    return "—";
  };

  const handleStripePayment = () => {
    setSelectedMethod('stripe');
    onSubmit();
  };

  const handleOfflinePayment = (method) => {
    setSelectedMethod(method);
    if (onOfflinePayment) {
      onOfflinePayment(method);
    }
  };

  return (
    <div className="rounded-2xl border bg-white p-8 shadow-sm">
      <h2 className="text-2xl font-bold mb-2">Payment</h2>
      <p className="text-slate-600 mb-6">
        Choose your payment method to complete the project posting.
      </p>

      <div className="rounded-xl border p-4 mb-6">
        <p className="font-semibold">Project</p>
        <p>{projectData.title}</p>
        <p className="mt-2 font-bold text-orange-600">
          Amount: {calculateAmount()}
        </p>
      </div>

      {/* Payment Method Selection */}
      <div className="mb-6 space-y-4">
        {/* Stripe option - hidden by default, only show if VITE_PAYMENTS_MODE === "stripe" */}
        {import.meta.env.VITE_PAYMENTS_MODE === "stripe" && (
          <button
            onClick={handleStripePayment}
            disabled={isSubmitting || selectedMethod !== null}
            className={`w-full p-5 rounded-2xl border-2 transition-all ${
              selectedMethod === 'stripe'
                ? 'border-orange-500 bg-orange-50 ring-2 ring-orange-200 shadow-md'
                : 'border-slate-200 bg-white hover:border-orange-300 hover:shadow-md'
            } ${isSubmitting || selectedMethod !== null ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}`}
          >
            <div className="flex items-center justify-between">
              <div className="flex-1 text-left">
                <p className="text-lg font-semibold text-slate-900">Pay with Stripe</p>
                <p className="text-sm text-slate-600 mt-1">Secure online payment</p>
              </div>
              <div className="text-2xl ml-4 flex-shrink-0">💳</div>
            </div>
          </button>
        )}

        <button
          onClick={() => handleOfflinePayment('cliq')}
          disabled={isSubmitting || selectedMethod !== null}
          className={`w-full p-5 rounded-2xl border-2 transition-all ${
            selectedMethod === 'cliq'
              ? 'border-orange-500 bg-orange-50 ring-2 ring-orange-200 shadow-md'
              : 'border-slate-200 bg-white hover:border-orange-300 hover:shadow-md'
          } ${isSubmitting || selectedMethod !== null ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}`}
        >
          <div className="flex items-center justify-between gap-4">
            <p className="text-lg font-semibold text-slate-900">Pay via CliQ</p>
            <div className="text-2xl flex-shrink-0">📱</div>
          </div>
        </button>

        <button
          onClick={() => handleOfflinePayment('cash')}
          disabled={isSubmitting || selectedMethod !== null}
          className={`w-full p-5 rounded-2xl border-2 transition-all ${
            selectedMethod === 'cash'
              ? 'border-orange-500 bg-orange-50 ring-2 ring-orange-200 shadow-md'
              : 'border-slate-200 bg-white hover:border-orange-300 hover:shadow-md'
          } ${isSubmitting || selectedMethod !== null ? 'opacity-50 cursor-not-allowed' : 'cursor-pointer'}`}
        >
          <div className="flex items-center justify-between gap-4">
            <p className="text-lg font-semibold text-slate-900">Pay Cash</p>
            <div className="text-2xl flex-shrink-0">💵</div>
          </div>
        </button>
      </div>

      {selectedMethod === 'cliq' || selectedMethod === 'cash' ? (
        <div className="mb-6 p-4 bg-yellow-50 border border-yellow-200 rounded-xl">
          <p className="text-sm text-yellow-800">
            ⚠️ Your project will be created but will remain hidden until admin approves your payment.
          </p>
        </div>
      ) : null}

      <div className="flex gap-4">
        <button
          onClick={onBack}
          className="flex-1 h-12 rounded-xl bg-slate-100 font-semibold"
          disabled={isSubmitting}
        >
          Back
        </button>

        {/* Stripe button - only show if Stripe option is visible and selected */}
        {import.meta.env.VITE_PAYMENTS_MODE === "stripe" && selectedMethod === 'stripe' && (
          <button
            onClick={handleStripePayment}
            disabled={isSubmitting}
            className={`flex-1 h-12 rounded-xl font-semibold ${primaryBtn}`}
          >
            {isSubmitting ? "Redirecting..." : "Pay with Stripe"}
          </button>
        )}
      </div>
    </div>
  );
}
