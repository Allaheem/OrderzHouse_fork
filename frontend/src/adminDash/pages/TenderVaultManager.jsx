import React, { useState, useEffect, useMemo } from "react";
import { useSelector } from "react-redux";
import { useNavigate } from "react-router-dom";
import API from "../../api/client.js";
import { useToast } from "../../components/toast/ToastProvider";
import {
  Archive,
  FileText,
  Search,
  Plus,
  Edit,
  Trash2,
  Info,
  ChevronDown,
  ChevronUp,
} from "lucide-react";
import TenderDetailsModal from "./components/TenderDetailsModal.jsx";

/* ---------- Theme ---------- */
const T = { primary: "#C2410C", dark: "#9A3412", ring: "rgba(15,23,42,.10)" };

const cx = (...a) => a.filter(Boolean).join(" ");

function ProjectsHero({ title, subtitle, eyebrow = "CLIENT" }) {
  return (
    <div
      className="relative overflow-hidden rounded-3xl p-4 sm:p-5 lg:p-6 text-white shadow-sm bg-gradient-to-b from-orange-400 to-red-500"
    >
      <div className="absolute -right-20 -top-16 h-56 w-56 rounded-full bg-white/10 blur-2xl" />
      <div className="absolute left-6 -bottom-24 h-56 w-56 rounded-full bg-black/10 blur-2xl" />

      <div className="relative">
        <div className="text-[10px] uppercase tracking-[0.22em] text-white/70 font-semibold">
          {eyebrow}
        </div>
        <h2 className="mt-2 text-[18px] sm:text-[22px] lg:text-[26px] font-extrabold leading-tight text-white">
          {title}
        </h2>
        {subtitle ? (
          <p className="mt-2 text-[12px] sm:text-sm text-white/80 max-w-2xl">
            {subtitle}
          </p>
        ) : null}
      </div>
    </div>
  );
}

export default function TenderVaultManager() {
  const { userData, token } = useSelector((s) => s.auth);
  const navigate = useNavigate();
  const toast = useToast();
  const [tenders, setTenders] = useState([]);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState("stored");
  const [searchQuery, setSearchQuery] = useState("");
  const [pagination, setPagination] = useState({ page: 1, limit: 20, total: 0, totalPages: 0 });
  const [selectedTender, setSelectedTender] = useState(null);
  const [updating, setUpdating] = useState(false);
  const [rotationStatus, setRotationStatus] = useState(null); // { totalPublishedTenders, minimumRequired, rotationActive }
  const [showRotationHelp, setShowRotationHelp] = useState(false);
  const isDevOrAdmin =
    (typeof import.meta !== "undefined" && import.meta.env && import.meta.env.DEV) ||
    Number(userData?.role_id) === 1;

  // Pagination
  const PAGE_SIZE = 10;
  const [page, setPage] = useState(1);

  // Check permission
  useEffect(() => {
    if (userData?.role_id !== 2 || !userData?.can_manage_tender_vault) {
      toast.error("Access denied. You do not have permission to manage tender vault.");
      navigate("/client");
    }
  }, [userData, navigate, toast]);

  useEffect(() => {
    fetchTenders();
  }, [activeTab, searchQuery, page]);

  const fetchRotationStatus = async () => {
    if (!token) return;
    try {
      const res = await API.get("/tender-vault/rotation-status", {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.data?.success) {
        setRotationStatus(res.data);
      }
    } catch (_) {}
  };

  useEffect(() => {
    if (!token) return;
    fetchRotationStatus();
  }, [token]);

  const formatDateTime = (value) => {
    if (!value) return "—";
    const d = new Date(value);
    if (Number.isNaN(d.getTime())) return "—";
    return d.toLocaleString();
  };

  const formatDurationFromSeconds = (seconds) => {
    if (seconds == null || seconds <= 0) return "Expired";
    const hrs = Math.floor(seconds / 3600);
    const mins = Math.floor((seconds % 3600) / 60);
    return `${hrs}h ${mins}m`;
  };

  const fetchTenders = async () => {
    try {
      setLoading(true);
      const res = await API.get("/tender-vault/projects", {
        params: {
          status: activeTab,
          q: searchQuery,
          page: page,
          limit: PAGE_SIZE,
        },
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.data?.success) {
        setTenders(res.data.tenders || []);
        setPagination(res.data.pagination || { page: 1, limit: PAGE_SIZE, total: 0, totalPages: 0 });
      } else {
        toast.error(res.data?.message || "Failed to load tender vault projects");
        setTenders([]);
      }
    } catch (err) {
      console.error("Failed to fetch tenders:", err);
      if (err.response?.status === 403) {
        toast.error("Access denied. You do not have permission to manage tender vault.");
        navigate("/client");
      } else if (err.response?.status === 200 && err.response?.data?.success) {
        setTenders([]);
      } else {
        toast.error("Failed to load tender vault projects");
        setTenders([]);
      }
    } finally {
      setLoading(false);
    }
  };

  const handleStatusChange = async (tender, newStatus) => {
    const id = tender?.id;
    if (!id) return;

    try {
      setUpdating(true);
      const res = await API.patch(`/tender-vault/projects/${id}/status`, { status: newStatus });
      if (res.data?.success) {
        toast.success(`Tender status updated to ${newStatus}`);
        fetchTenders();
        if (selectedTender?.id === id) {
          setSelectedTender({ ...selectedTender, status: newStatus });
        }
      }
    } catch (err) {
      toast.error(err.response?.data?.message || "Failed to update status");
    } finally {
      setUpdating(false);
    }
  };

  const handleDelete = async (tender) => {
    const id = tender?.id;
    if (!id) return;

    if (!window.confirm("Are you sure you want to delete this tender?")) return;
    try {
      setUpdating(true);
      const res = await API.delete(`/tender-vault/projects/${id}`);
      if (res.data?.success) {
        toast.success("Tender deleted successfully");
        fetchTenders();
        if (selectedTender?.id === id) {
          setSelectedTender(null);
        }
      }
    } catch (err) {
      toast.error(err.response?.data?.message || "Failed to delete tender");
    } finally {
      setUpdating(false);
    }
  };

  const handleView = (tender) => {
    setSelectedTender(tender);
  };

  const handleEdit = (tender) => {
    navigate(`/client/tender-vault/${tender.id}/edit`);
  };

  const handlePublish = (tender) => {
    handleStatusChange(tender, "published");
  };

  const handleUnpublish = (tender) => {
    handleStatusChange(tender, "stored");
  };

  const handleArchive = (tender) => {
    handleStatusChange(tender, "archived");
  };

  const refreshVaultData = async () => {
    await Promise.all([fetchTenders(), fetchRotationStatus()]);
  };

  const runRotationTest = async () => {
    try {
      setUpdating(true);
      const res = await API.post(
        "/api/admin/tender-vault/test-run-rotation",
        {},
        { headers: { Authorization: `Bearer ${token}` } }
      );
      const data = res.data || {};
      if (data.success) {
        if (data.skipped) {
          toast.error(data.message || data.reason || "Rotation skipped.");
        } else {
          toast.success(
            `Rotation test complete. Batch #${data.batch_id || "—"} selected ${data.selected_count || 0}.`
          );
        }
        await refreshVaultData();
      } else {
        toast.error(data.message || "Failed to run rotation test.");
      }
    } catch (err) {
      toast.error(err.response?.data?.message || "Failed to run rotation test.");
    } finally {
      setUpdating(false);
    }
  };

  const expireCurrentBatchTest = async () => {
    try {
      setUpdating(true);
      const res = await API.post(
        "/api/admin/tender-vault/test-expire-current-batch",
        {},
        { headers: { Authorization: `Bearer ${token}` } }
      );
      const data = res.data || {};
      if (data.success) {
        toast.success(
          data.expired
            ? `Expired batch #${data.batch_id}.`
            : data.message || "No active batch."
        );
        await refreshVaultData();
      } else {
        toast.error(data.message || "Failed to expire current batch.");
      }
    } catch (err) {
      toast.error(err.response?.data?.message || "Failed to expire current batch.");
    } finally {
      setUpdating(false);
    }
  };

  const jdInt = (value) => {
    if (value == null || value === "") return null;
    const n = Math.round(Number(value));
    return Number.isFinite(n) ? n : null;
  };

  /** Whole JD only — no decimals in listing UI */
  const formatJD = (value) => {
    const n = jdInt(value);
    if (n === null) return "—";
    return `${n} JD`;
  };

  const formatBudget = (tender) => {
    const min = jdInt(tender.budget_min);
    const max = jdInt(tender.budget_max);
    if (min != null && max != null) {
      return `${min} - ${max} JD`;
    }
    if (min != null) {
      return `From ${min} JD`;
    }
    if (max != null) {
      return `Up to ${max} JD`;
    }
    return "—";
  };

  // Format date
  const formatDate = (dateString) => {
    if (!dateString) return "—";
    try {
      return new Date(dateString).toLocaleDateString("en-US", {
        year: "numeric",
        month: "short",
        day: "numeric",
      });
    } catch {
      return "—";
    }
  };

  // Format duration (single column: integer days)
  // Get status badge class
  const getStatusBadgeClass = (status) => {
    if (!status) return "bg-slate-100 text-slate-800";
    switch (status.toLowerCase()) {
      case "published":
        return "bg-green-100 text-green-800";
      case "stored":
        return "bg-blue-100 text-blue-800";
      case "archived":
        return "bg-slate-100 text-slate-800";
      default:
        return "bg-amber-100 text-amber-800";
    }
  };

  // Pagination calculations
  const totalPages = Math.ceil(tenders.length / PAGE_SIZE);
  const startIndex = (page - 1) * PAGE_SIZE;
  const endIndex = startIndex + PAGE_SIZE;
  const pageItems = tenders.slice(startIndex, endIndex);
  const showingStart = tenders.length > 0 ? startIndex + 1 : 0;
  const showingEnd = Math.min(endIndex, tenders.length);

  // Reset to page 1 when data changes
  useEffect(() => {
    if (tenders.length > 0 && page > totalPages) {
      setPage(1);
    }
  }, [tenders.length, totalPages, page]);

  // Loading skeleton rows
  const SkeletonRow = () => (
    <tr>
      {[...Array(8)].map((_, i) => (
        <td key={i} className="px-4 py-3">
          <div className="h-4 bg-slate-200 rounded animate-pulse" />
        </td>
      ))}
    </tr>
  );

  return (
    <>
      <div className="space-y-5">
        <ProjectsHero
          eyebrow="CLIENT"
          title="Tender Vault"
          subtitle="Manage stored, published, and rotating tenders."
        />

        {rotationStatus && (
          <>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
              <div className="rounded-xl border border-slate-200 bg-white p-3">
                <div className="text-xs text-slate-500">Stored</div>
                <div className="text-xl font-bold text-slate-900">{rotationStatus.stored_count ?? 0}</div>
              </div>
              <div className="rounded-xl border border-slate-200 bg-white p-3">
                <div className="text-xs text-slate-500">Published</div>
                <div className="text-xl font-bold text-slate-900">{rotationStatus.published_count ?? 0}</div>
              </div>
              <div className="rounded-xl border border-slate-200 bg-white p-3">
                <div className="text-xs text-slate-500">Eligible</div>
                <div className="text-xl font-bold text-slate-900">{rotationStatus.eligible_count ?? 0}</div>
              </div>
              <div className="rounded-xl border border-slate-200 bg-white p-3">
                <div className="text-xs text-slate-500">Visible Now</div>
                <div className="text-xl font-bold text-slate-900">{rotationStatus.visible_now_count ?? 0}</div>
              </div>
            </div>

            <div className="rounded-xl border border-slate-200 bg-white px-4 py-3">
              <div className="flex flex-wrap items-center justify-between gap-3">
                <div className="flex items-center gap-2">
                  <span className={`inline-flex h-2 w-2 rounded-full ${rotationStatus.rotation_active ? "bg-emerald-500" : "bg-amber-500"}`} />
                  <span className="text-sm font-semibold text-slate-900">
                    {rotationStatus.rotation_active ? "Rotation Active" : "Rotation Inactive"}
                  </span>
                  {!rotationStatus.rotation_active && (
                    <span className="text-xs text-slate-500">Needs {rotationStatus.minimum_threshold} eligible</span>
                  )}
                </div>
                <button
                  type="button"
                  onClick={() => setShowRotationHelp((v) => !v)}
                  className="inline-flex items-center gap-1.5 text-xs text-slate-600 hover:text-slate-900"
                >
                  <Info className="w-4 h-4" />
                  How it works
                  {showRotationHelp ? <ChevronUp className="w-3.5 h-3.5" /> : <ChevronDown className="w-3.5 h-3.5" />}
                </button>
              </div>

              <div className="mt-3 grid grid-cols-2 md:grid-cols-5 gap-2 text-xs">
                <div className="rounded-lg bg-slate-50 px-3 py-2"><span className="text-slate-500">Cycle</span><div className="font-semibold text-slate-900">#{rotationStatus.current_cycle ?? 1}</div></div>
                <div className="rounded-lg bg-slate-50 px-3 py-2"><span className="text-slate-500">Visible</span><div className="font-semibold text-slate-900">{rotationStatus.visible_now_count ?? 0}</div></div>
                <div className="rounded-lg bg-slate-50 px-3 py-2"><span className="text-slate-500">Ends in</span><div className="font-semibold text-slate-900">{formatDurationFromSeconds(rotationStatus.active_batch_remaining_seconds)}</div></div>
                <div className="rounded-lg bg-slate-50 px-3 py-2"><span className="text-slate-500">Progress</span><div className="font-semibold text-slate-900">{rotationStatus.cycle_completion_percent ?? 0}%</div></div>
                <div className="rounded-lg bg-slate-50 px-3 py-2"><span className="text-slate-500">Next run</span><div className="font-semibold text-slate-900">{formatDateTime(rotationStatus.next_rotation_estimate)}</div></div>
              </div>

              {showRotationHelp && (
                <div className="mt-3 border-t border-slate-100 pt-3 text-xs text-slate-600 leading-5">
                  Published tenders join the eligible pool. Every 12h, 50-70 tenders are exposed for 12h. No tender repeats within a cycle until all eligible tenders are shown once.
                </div>
              )}
            </div>
          </>
        )}

        {/* Header: Search + New Tender */}
        <div className="flex flex-wrap items-center gap-3">
          <div className="relative flex-1 min-w-[200px]">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
            <input
              type="text"
              placeholder="Search tenders..."
              value={searchQuery}
              onChange={(e) => {
                setSearchQuery(e.target.value);
                setPage(1);
              }}
              className="w-full pl-10 pr-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-orange-500 focus:border-orange-500"
            />
          </div>
          <button
            type="button"
            onClick={() => navigate("/client/tender-vault/new")}
            className="inline-flex items-center gap-2 px-4 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700 transition font-semibold shrink-0"
          >
            <Plus className="w-4 h-4" />
            New Tender
          </button>
          {isDevOrAdmin && (
            <>
              <button
                type="button"
                onClick={runRotationTest}
                disabled={updating}
                className="inline-flex items-center gap-2 px-3 py-2 border border-slate-300 text-slate-700 rounded-lg hover:bg-slate-50 transition text-sm"
                title="Dev/Admin: runs real exposure rotation service"
              >
                Run Rotation Test
              </button>
              <button
                type="button"
                onClick={expireCurrentBatchTest}
                disabled={updating}
                className="inline-flex items-center gap-2 px-3 py-2 border border-slate-300 text-slate-700 rounded-lg hover:bg-slate-50 transition text-sm"
                title="Dev/Admin: force expire active exposure batch"
              >
                Expire Current Batch
              </button>
            </>
          )}
        </div>

        {/* Status Tabs */}
        <div className="flex gap-2 border-b border-slate-200">
          {[
            { key: "stored", label: "Stored" },
            { key: "published", label: "Published" },
            { key: "archived", label: "Archived" },
          ].map((tab) => (
            <button
              key={tab.key}
              onClick={() => {
                setActiveTab(tab.key);
                setPage(1);
              }}
              className={`px-4 py-2 font-semibold text-sm border-b-2 transition ${
                activeTab === tab.key
                  ? "border-orange-600 text-orange-600"
                  : "border-transparent text-slate-600 hover:text-slate-900"
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>

        {/* Table */}
        <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-slate-50 border-b border-slate-200">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                    Title
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                    Status
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                    Budget Range
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                    Created At
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                    Visible Now
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                    Shown In Cycle
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                    Exposure Stats
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-semibold text-slate-700 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {loading ? (
                  <>
                    <SkeletonRow />
                    <SkeletonRow />
                    <SkeletonRow />
                    <SkeletonRow />
                    <SkeletonRow />
                  </>
                ) : pageItems.length === 0 ? (
                  <tr>
                    <td colSpan="8" className="px-4 py-8 text-center text-slate-500">
                      {searchQuery ? (
                        <>
                          No tenders match your search "{searchQuery}" in {activeTab} status.
                        </>
                      ) : (
                        <>No tenders found in {activeTab} status.</>
                      )}
                      <div className="mt-4">
                        <button
                          onClick={() => navigate("/client/tender-vault/new")}
                          className="inline-flex items-center gap-2 px-4 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700 transition"
                        >
                          <Plus className="w-4 h-4" />
                          New Tender
                        </button>
                      </div>
                    </td>
                  </tr>
                ) : (
                  pageItems.map((tender) => (
                      <tr
                        key={tender.id}
                        className="hover:bg-slate-50 cursor-pointer"
                        onClick={() => handleView(tender)}
                      >
                        <td className="px-4 py-3">
                          <div className="text-sm font-medium text-slate-900 max-w-xs truncate" title={tender.title}>
                            {tender.title || "Untitled Tender"}
                          </div>
                        </td>
                        <td className="px-4 py-3">
                          <span
                            className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium ${getStatusBadgeClass(
                              tender.status
                            )}`}
                          >
                            {tender.status ? tender.status.charAt(0).toUpperCase() + tender.status.slice(1) : "—"}
                          </span>
                        </td>
                        <td className="px-4 py-3 text-sm text-slate-600">
                          {formatBudget(tender)}
                        </td>
                        <td className="px-4 py-3 text-sm text-slate-600">
                          {formatDate(tender.created_at)}
                        </td>
                        <td className="px-4 py-3 text-sm">
                          <span className={tender.currently_visible ? "inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800" : "inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-xs font-medium bg-slate-100 text-slate-700"}>
                            <span className={`h-1.5 w-1.5 rounded-full ${tender.currently_visible ? "bg-green-600" : "bg-slate-400"}`} />
                            {tender.currently_visible ? "On" : "Off"}
                          </span>
                        </td>
                        <td className="px-4 py-3 text-sm">
                          <span className={tender.shown_in_current_cycle ? "inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-xs font-medium bg-purple-100 text-purple-800" : "inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-xs font-medium bg-slate-100 text-slate-700"}>
                            <span className={`h-1.5 w-1.5 rounded-full ${tender.shown_in_current_cycle ? "bg-purple-600" : "bg-slate-400"}`} />
                            {tender.shown_in_current_cycle ? "Done" : "Pending"}
                          </span>
                        </td>
                        <td className="px-4 py-3 text-xs">
                          <button
                            type="button"
                            className="px-2.5 py-1 rounded-full border border-slate-200 bg-slate-50 text-slate-700 hover:bg-slate-100"
                            title={`Total: ${tender.exposure_count ?? 0}\nLast: ${formatDate(tender.last_exposed_at)}\nCycle: ${tender.last_shown_cycle_number ?? "—"}`}
                          >
                            View stats
                          </button>
                        </td>
                        <td className="px-4 py-3">
                          <div className="flex items-center gap-2" onClick={(e) => e.stopPropagation()}>
                            {activeTab === "stored" && (
                              <button
                                onClick={() => handlePublish(tender)}
                                disabled={updating}
                                className="p-2 text-green-600 hover:text-green-700 hover:bg-green-50 rounded-lg transition"
                                title="Publish"
                              >
                                <FileText className="w-4 h-4" />
                              </button>
                            )}
                            {activeTab === "published" && (
                              <button
                                onClick={() => handleUnpublish(tender)}
                                disabled={updating}
                                className="p-2 text-blue-600 hover:text-blue-700 hover:bg-blue-50 rounded-lg transition"
                                title="Unpublish"
                              >
                                <Archive className="w-4 h-4" />
                              </button>
                            )}
                            {tender.status !== "archived" && (
                              <button
                                onClick={() => handleArchive(tender)}
                                disabled={updating}
                                className="p-2 text-orange-600 hover:text-orange-700 hover:bg-orange-50 rounded-lg transition"
                                title="Archive"
                              >
                                <Archive className="w-4 h-4" />
                              </button>
                            )}
                            <button
                              onClick={() => handleEdit(tender)}
                              disabled={updating}
                              className="p-2 text-slate-600 hover:text-slate-900 hover:bg-slate-100 rounded-lg transition"
                              title="Edit"
                            >
                              <Edit className="w-4 h-4" />
                            </button>
                            <button
                              onClick={() => handleDelete(tender)}
                              disabled={updating}
                              className="p-2 text-red-600 hover:text-red-700 hover:bg-red-50 rounded-lg transition"
                              title="Delete"
                            >
                              <Trash2 className="w-4 h-4" />
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))
                )}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          {tenders.length > 0 && (
            <div className="px-4 py-4 border-t border-slate-200 bg-slate-50 flex items-center justify-between">
              <div className="text-sm text-slate-600">
                Showing <span className="font-medium">{showingStart}</span>–
                <span className="font-medium">{showingEnd}</span> of{" "}
                <span className="font-medium">{tenders.length}</span>
              </div>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
                  disabled={page === 1}
                  className="px-3 py-1.5 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-lg hover:bg-slate-50 disabled:opacity-50 disabled:cursor-not-allowed transition"
                >
                  Previous
                </button>
                <div className="flex items-center gap-1">
                  {Array.from({ length: totalPages }, (_, i) => i + 1).map((pageNum) => (
                    <button
                      key={pageNum}
                      onClick={() => setPage(pageNum)}
                      className={`px-3 py-1.5 text-sm font-medium rounded-lg transition ${
                        page === pageNum
                          ? "bg-orange-500 text-white"
                          : "text-slate-700 bg-white border border-slate-300 hover:bg-slate-50"
                      }`}
                    >
                      {pageNum}
                    </button>
                  ))}
                </div>
                <button
                  onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                  disabled={page === totalPages}
                  className="px-3 py-1.5 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-lg hover:bg-slate-50 disabled:opacity-50 disabled:cursor-not-allowed transition"
                >
                  Next
                </button>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Tender Details Modal */}
      {selectedTender && (
        <TenderDetailsModal
          tender={selectedTender}
          onClose={() => setSelectedTender(null)}
          onEdit={() => {
            setSelectedTender(null);
            handleEdit(selectedTender);
          }}
          onPublish={() => handlePublish(selectedTender)}
          onUnpublish={() => handleUnpublish(selectedTender)}
          onArchive={() => handleArchive(selectedTender)}
          onDelete={() => {
            handleDelete(selectedTender);
            setSelectedTender(null);
          }}
          updating={updating}
        />
      )}
    </>
  );
}
