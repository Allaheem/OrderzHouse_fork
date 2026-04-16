import { useEffect, useRef } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import API from "../../api/client.js";
import { useToast } from "../toast/ToastProvider.jsx";

const CONFIRM_TIMEOUT = 3000;

export default function PaymentSuccess() {
  const navigate = useNavigate();
  const [params] = useSearchParams();
  const toast = useToast();
  const hasProcessed = useRef(false);

  useEffect(() => {
    // Prevent multiple runs
    if (hasProcessed.current) return;
    hasProcessed.current = true;

    const run = async () => {
      const session_id = params.get("session_id");

      // 1️⃣ FRONTEND CHECK: Validate session_id before calling backend
      if (!session_id || session_id.trim() === "") {
        toast.error("Invalid payment session. Please contact support.");
        return navigate("/", { replace: true });
      }

      // Timeout guard
      const timeoutId = setTimeout(() => {
        toast.error("Payment verification timed out. Please contact support.");
        navigate("/", { replace: true });
      }, CONFIRM_TIMEOUT);

      try {
        const res = await API.get("/stripe/confirm", {
          params: { session_id },
          timeout: 8000, // 8 second request timeout
        });

        clearTimeout(timeoutId);

        if (!res.data?.ok) {
          const errorMsg = res.data?.error || "Payment verification failed. Please contact support.";
          toast.error(errorMsg);
          return navigate("/", { replace: true });
        }

        const purpose = res.data.purpose;

        // 🔹 PLAN SUBSCRIPTION
        if (purpose === "plan") {
          toast.success(
            "Subscription purchased successfully. It will start when you begin your first project."
          );
          navigate("/freelancer", { replace: true });
          return;
        }

        // 🔹 PROJECT PAYMENT
        if (purpose === "project") {
          const projectId = res.data?.project_id;
          if (projectId) {
            navigate(`/projects/success/${projectId}?lang=en`, { replace: true });
          } else {
            toast.success(
              "Payment completed successfully. Your project is waiting for admin approval."
            );
            navigate("/client", { replace: true });
          }
          return;
        }

        // 🔹 OFFER ACCEPT (BIDDING) — دفع العميل مبلغ العرض وقبول الفريلانسر
        if (purpose === "offer") {
          toast.success(
            "Payment completed. The freelancer has been assigned and can start working."
          );
          navigate("/client/projects", { replace: true });
          return;
        }

        // Fallback for unknown purpose
        toast.success("Payment completed successfully.");
        navigate("/", { replace: true });

      } catch (e) {
        clearTimeout(timeoutId);

        // Extract error message from response or use default
        let errorMessage = "Payment verification failed. Please contact support.";
        
        if (e.response?.status === 400) {
          errorMessage = e.response?.data?.error || "Invalid payment session. Please contact support.";
        } else if (e.response?.status === 500) {
          errorMessage = "Server error during payment verification. Please contact support.";
        }
        
        toast.error(errorMessage);
        navigate("/", { replace: true });
      }
    };

    run();
  }, [navigate, params, toast]);

  return (
    <div className="min-h-screen flex items-center justify-center text-slate-600">
      Completing your payment...
    </div>
  );
}
