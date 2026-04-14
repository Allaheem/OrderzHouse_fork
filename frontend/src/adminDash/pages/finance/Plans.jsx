import { useEffect, useState, useCallback } from "react";
import { useSelector, useDispatch } from "react-redux";
import {
  FiPlus,
  FiEdit2,
  FiTrash2,
  FiX,
  FiUsers,
  FiArrowLeft,
} from "react-icons/fi";
import PeopleTable from "../Tables";
import PlansAPI from "../../api/plans";
import {
  setPlans,
  addPlan,
  removePlan,
  updatePlan,
  setLoading,
  setError,
  clearError,
} from "../../../slice/planSlice.js";
import toast from "react-hot-toast";

const PRIMARY = "#028090";

export default function Plans() {
  const dispatch = useDispatch();
  const { plans: items, loading, error } = useSelector((state) => state.plan);
  const { token } = useSelector((state) => state.auth);

  const [open, setOpen] = useState(false);
  const [editId, setEditId] = useState(null);
  const [form, setForm] = useState({
    name: "",
    price: "",
    duration: 30,
    description: "",
    featuresText: "",
    plan_type: "monthly",
    apple_product_id: "",
  });

  const [subscriptionCounts, setSubscriptionCounts] = useState({});
  const [viewSubsPlanId, setViewSubsPlanId] = useState(null);
  const [selectedPlanName, setSelectedPlanName] = useState("");

  // ---------------------------
  // FETCH PLANS + COUNTS
  // ---------------------------
  const fetchPlans = useCallback(async () => {
    try {
      dispatch(setLoading(true));
      dispatch(clearError());

      const [plansRes, countsRes] = await Promise.all([
        PlansAPI.getPlans(),
        PlansAPI.getPlanSubscriptionCounts(),
      ]);

      const plansArray = Array.isArray(plansRes?.plans)
        ? plansRes.plans
        : Array.isArray(plansRes)
        ? plansRes
        : [];

      dispatch(setPlans(plansArray));

      const countMap = {};
      if (Array.isArray(countsRes?.counts)) {
        countsRes.counts.forEach((c) => {
          countMap[c.plan_id] = Number(c.subscription_count || 0);
        });
      }
      setSubscriptionCounts(countMap);
    } catch (err) {
      const detail =
        err?.response?.data?.message ||
        err?.response?.data?.error ||
        err?.message ||
        (typeof err?.code === "string" ? err.code : null);
      const text =
        detail && String(detail).trim()
          ? `Failed to load plans: ${String(detail).trim()}`
          : "Failed to load plans (is the API running on port 5050?)";
      dispatch(setError(text));
      console.error(err);
    } finally {
      dispatch(setLoading(false));
    }
  }, [dispatch]);

  useEffect(() => {
    fetchPlans();
  }, [fetchPlans]);

  // ---------------------------
  // HANDLERS
  // ---------------------------
  const openAdd = useCallback(() => {
    setEditId(null);
    setForm({
      name: "",
      price: "",
      duration: 30,
      description: "",
      featuresText: "",
      plan_type: "monthly",
      apple_product_id: "",
    });
    setOpen(true);
  }, []);

  const openEdit = useCallback(
    (id) => {
      const plan = items.find((p) => p.id === id);
      if (!plan) return;
      setEditId(id);
      setForm({
        name: plan.name,
        price: plan.price,
        duration: plan.duration,
        description: plan.description,
        featuresText: (plan.features ?? []).join("\n"),
        plan_type: plan.plan_type ?? "monthly",
        apple_product_id: plan.apple_product_id ?? "",
      });
      setOpen(true);
    },
    [items]
  );

  const onDelete = useCallback(
    async (id) => {
      if (!window.confirm("Are you sure you want to delete this plan?")) return;

      try {
        await PlansAPI.deletePlan(id);
        dispatch(removePlan(id));
        await fetchPlans();
      } catch (err) {
        console.error("Failed to delete plan:", err);
        dispatch(setError("Failed to delete plan"));
      }
    },
    [dispatch, fetchPlans]
  );

  const onSubmit = useCallback(
    async (e) => {
      e.preventDefault();

      const payload = {
        ...form,
        price: Number(form.price),
        duration: Number(form.duration),
        features: form.featuresText
          .split("\n")
          .map((s) => s.trim())
          .filter(Boolean),
        apple_product_id: form.apple_product_id?.trim() || null,
      };

      const isEditing = editId != null;

      toast.promise(
        isEditing
          ? PlansAPI.editPlan(editId, payload)
          : PlansAPI.createPlan(payload),
        {
          loading: isEditing ? "Updating plan..." : "Creating plan...",
          // Must not be `async`: react-hot-toast uses the return value as the toast message;
          // an async function returns a Promise → "Objects are not valid as a React child".
          success: (res) => {
            if (isEditing) {
              dispatch(updatePlan(res.plan || res));
            } else {
              dispatch(addPlan(res.plan || res));
            }
            void fetchPlans().then(() => {
              setOpen(false);
            });
            return isEditing
              ? "Plan updated successfully"
              : "Plan created successfully";
          },
          error: (err) => {
            try {
              const raw =
                err?.response?.data?.message ??
                err?.response?.data?.error ??
                err?.message;
              if (typeof raw === "string" && raw.trim()) return raw.trim();
              if (raw != null && typeof raw === "object") {
                try {
                  return JSON.stringify(raw);
                } catch {
                  return "Failed to save plan";
                }
              }
            } catch {
              /* ignore */
            }
            return "Failed to save plan";
          },
        },
        { style: { borderRadius: "8px" } }
      );
    },
    [editId, form, dispatch, fetchPlans]
  );

  const viewSubscribers = (id) => {
    const plan = items.find((p) => p.id === id);
    setSelectedPlanName(plan?.name || "");
    setViewSubsPlanId(id);
  };

  const closeSubs = () => {
    setViewSubsPlanId(null);
    setSelectedPlanName("");
  };

  const formatDuration = (duration, planType) => {
    const num = Number(duration);
    const unit =
      planType === "yearly" ? "year" : planType === "monthly" ? "month" : "day";
    return `${num} ${num === 1 ? unit : `${unit}s`}`;
  };

  /** API/DB may return features as array, stringified JSON, or rarely non-array — avoid render crash */
  const normalizeFeatures = (features) => {
    if (Array.isArray(features)) return features;
    if (typeof features === "string" && features.trim()) {
      try {
        const parsed = JSON.parse(features);
        return Array.isArray(parsed) ? parsed : [];
      } catch {
        return [];
      }
    }
    return [];
  };

  // ---------------------------
  // SUBSCRIBERS VIEW
  // ---------------------------
  if (viewSubsPlanId) {
    return (
      <div className="space-y-6 px-4 sm:px-6 lg:px-8 py-6">
        <div className="flex items-center gap-3 mb-2">
          {/* Back */}
          <button
            onClick={closeSubs}
            className="w-9 h-9 grid place-items-center rounded-full border border-slate-200 hover:bg-slate-50 text-slate-700"
            title="Back"
          >
            <FiArrowLeft />
          </button>
          <h1 className="text-2xl sm:text-3xl font-semibold text-slate-900">
            {selectedPlanName} – Subscribers
          </h1>
        </div>

        <PeopleTable
          title=""
          endpoint={`/plans/${viewSubsPlanId}/subscribers`}
          token={token}
          columns={[
            { label: "#", key: "row_number", render: (_, index) => index + 1 },
            { label: "User ID", key: "user_id" },
            { label: "Email", key: "email" },
            { label: "Status", key: "status" },
            { label: "Start Date", key: "start_date" },
            { label: "End Date", key: "end_date" },
          ]}
          filters={[]}
          formFields={[]}
          crudConfig={{
            showEdit: false,
            showDelete: true,
            showExpand: false,
            customActions: [
              {
                label: "Cancel",
                icon: <FiX />,
                onClick: async (row) => {
                  if (window.confirm("Cancel this subscription?")) {
                    await PlansAPI.adminCancelSubscription(row.id);
                  }
                },
                variant: "warning",
              },
            ],
          }}
        />
      </div>
    );
  }

  // ---------------------------
  // MAIN PAGE
  // ---------------------------
  return (
    <div className="space-y-6 px-4 sm:px-6 lg:px-8 py-6">
    

      {loading && (
        <div className="text-center py-8 text-slate-500 text-base">
          Loading…
        </div>
      )}

      {!loading && error && (
        <div className="bg-red-50 text-red-700 py-3 px-4 rounded-xl border border-red-200 text-sm text-center">
          {error}
        </div>
      )}

      {!loading && !error && (
        <div className="grid gap-6 grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
          {items.map((p) => (
            <div
              key={p.id}
              className="relative flex flex-col bg-white shadow-sm border border-slate-200 rounded-xl hover:shadow-md transition-shadow duration-300 w-full max-w-md mx-auto"
            >
              {/* Header strip */}
              <div className="mx-4 mb-0 border-b border-slate-200 pt-4 pb-3 px-1">
                <span className="text-xs font-medium text-slate-600 uppercase">
                  {p.plan_type}
                </span>
              </div>

              {/* Body */}
              <div className="p-5 flex-grow">
                <h5 className="mb-2 text-slate-800 text-xl font-semibold">
                  {p.name}
                </h5>
                <div className="text-2xl font-bold text-slate-800 mb-3">
                  ${p.price}
                  <span className="text-sm font-normal text-slate-500">
                    {" "}
                    / {formatDuration(p.duration, p.plan_type)}
                  </span>
                </div>
                <p className="text-slate-600 leading-relaxed font-light mb-4 text-sm">
                  {p.description}
                </p>
                <ul className="space-y-2 text-sm text-slate-700">
                  {normalizeFeatures(p.features).map((f, i) => (
                    <li key={i} className="flex items-start gap-2">
                      <span className="text-emerald-500 mt-0.5">✓</span>
                      <span>{f}</span>
                    </li>
                  ))}
                </ul>
              </div>

              {/* Actions — Blog Top Bar */}
              <div className="p-5 pt-0 flex items-center gap-1.5">
                {/* Edit: Primary outline */}
                <button
                  onClick={() => openEdit(p.id)}
                  className="h-9 px-3 rounded-full border inline-flex items-center gap-2 text-sm"
                  style={{ borderColor: PRIMARY, color: PRIMARY }}
                  title="Edit"
                >
                  <FiEdit2 />
                </button>

                {/* Delete: Outline */}
                <button
                  onClick={() => onDelete(p.id)}
                  className="h-9 px-3 rounded-full border border-slate-200 hover:bg-red-50 inline-flex items-center gap-2 text-sm text-red-600"
                  title="Delete"
                >
                  <FiTrash2 />
                </button>

                {/* View Subscribers: Outline  */}
                <button
                  onClick={() => viewSubscribers(p.id)}
                  className="h-9 px-3 rounded-full border border-slate-200 hover:bg-slate-50 inline-flex items-center gap-2 text-sm text-slate-700"
                  title="View Subscribers"
                >
                  <FiUsers />
                </button>
              </div>

              {/* Footer counts */}
              <div className="mx-4 border-t border-slate-200 pb-4 pt-3 px-1">
                <span className="text-sm text-slate-600 font-medium">
                  {subscriptionCounts[p.id] ?? 0}{" "}
                  {subscriptionCounts[p.id] === 1
                    ? "subscriber"
                    : "subscribers"}
                </span>
              </div>
            </div>
          ))}
        </div>
      )}

      {open && (
        <Modal
          title={editId == null ? "Add Plan" : "Edit Plan"}
          onClose={() => setOpen(false)}
        >
          <form onSubmit={onSubmit} className="space-y-4">
            <Field label="Name" required>
              <input
                type="text"
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
                className="w-full rounded-lg border border-slate-300 focus:ring-2 focus:ring-slate-300 px-3 py-2 text-sm"
                required
              />
            </Field>

            <Field label="Price" required>
              <input
                type="number"
                step="0.01"
                value={form.price}
                onChange={(e) => setForm({ ...form, price: e.target.value })}
                className="w-full rounded-lg border border-slate-300 focus:ring-2 focus:ring-slate-300 px-3 py-2 text-sm"
                required
              />
            </Field>

            <Field
              label={`Duration (${
                form.plan_type === "yearly" ? "years" : "months"
              })`}
              required
            >
              <input
                type="number"
                min="1"
                value={form.duration}
                onChange={(e) => setForm({ ...form, duration: e.target.value })}
                className="w-full rounded-lg border border-slate-300 focus:ring-2 focus:ring-slate-300 px-3 py-2 text-sm"
                required
              />
            </Field>

            <Field label="Description">
              <textarea
                value={form.description}
                onChange={(e) =>
                  setForm({ ...form, description: e.target.value })
                }
                className="w-full rounded-lg border border-slate-300 focus:ring-2 focus:ring-slate-300 px-3 py-2 text-sm"
                rows="3"
              />
            </Field>

            <Field label="Features (one per line)">
              <textarea
                value={form.featuresText}
                onChange={(e) =>
                  setForm({ ...form, featuresText: e.target.value })
                }
                className="w-full rounded-lg border border-slate-300 focus:ring-2 focus:ring-slate-300 px-3 py-2 text-sm"
                rows="4"
              />
            </Field>

            <Field label="Plan Type">
              <select
                value={form.plan_type}
                onChange={(e) =>
                  setForm({ ...form, plan_type: e.target.value })
                }
                className="w-full rounded-lg border border-slate-300 focus:ring-2 focus:ring-slate-300 px-3 py-2 text-sm"
              >
                <option value="monthly">Monthly</option>
                <option value="yearly">Yearly</option>
              </select>
            </Field>

            <Field label="Apple IAP product ID (App Store Connect)">
              <input
                type="text"
                value={form.apple_product_id}
                onChange={(e) =>
                  setForm({ ...form, apple_product_id: e.target.value })
                }
                placeholder="e.g. com.orderzhouse.subscription.monthly"
                className="w-full rounded-lg border border-slate-300 focus:ring-2 focus:ring-slate-300 px-3 py-2 text-sm font-mono"
              />
              <p className="text-xs text-slate-500 mt-1">
                Auto-renewable subscription product id. Leave empty if this plan
                is company / offline only.
              </p>
            </Field>

            <div className="sticky bottom-0 bg-white pt-4 flex justify-end gap-2.5">
              <button
                type="button"
                onClick={() => setOpen(false)}
                className="h-9 px-3 rounded-full border border-slate-200 hover:bg-slate-50 inline-flex items-center gap-2 text-sm text-slate-700"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="h-9 px-3 rounded-full border inline-flex items-center gap-2 text-sm"
                style={{ borderColor: PRIMARY, color: PRIMARY }}
              >
                Save
              </button>
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
}

function Field({ label, children, required }) {
  return (
    <label className="block space-y-2">
      <span className="text-sm font-medium text-slate-700">
        {label} {required && <span className="text-red-500">*</span>}
      </span>
      {children}
    </label>
    
  );
  
}

function Modal({ title, onClose, children }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-3 sm:p-6 overflow-auto">
      <div className="relative w-full max-w-lg sm:max-w-xl md:max-w-2xl lg:max-w-3xl rounded-2xl border border-slate-200 bg-white p-5 sm:p-6 shadow-xl my-6">
        <div className="mb-4 flex items-center justify-between border-b border-slate-200 pb-3">
          <h2 className="text-lg sm:text-xl font-semibold text-slate-800">
            {title}
          </h2>
          <button
            onClick={onClose}
            className="w-9 h-9 grid place-items-center rounded-full border border-slate-200 hover:bg-slate-50 text-slate-600"
            title="Close"
          >
            <FiX />
          </button>
        </div>
        <div className="max-h-[75vh] overflow-y-auto">{children}</div>
      </div>
    </div>
    
  );
}
