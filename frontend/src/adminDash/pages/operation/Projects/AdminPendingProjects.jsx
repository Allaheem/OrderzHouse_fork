import { useState, useEffect, useMemo } from "react";
import { useSelector } from "react-redux";
import API from "../../../../api/client.js";
import { useToast } from "../../../../components/toast/ToastProvider";
import {
  Check,
  X,
  Clock,
  Loader2,
  Eye,
  DollarSign,
  Calendar,
  CreditCard,
  FileText,
  Image as ImageIcon,
  Download,
  ExternalLink,
} from "lucide-react";

/* ---------- Theme ---------- */
const T = { primary: "#C2410C", dark: "#9A3412", ring: "rgba(15,23,42,.10)" };

const cx = (...a) => a.filter(Boolean).join(" ");

const actionBtnBase =
  "inline-flex items-center justify-center gap-2 h-9 sm:h-10 px-3 sm:px-4 rounded-full text-xs font-semibold whitespace-nowrap " +
  "transition shadow-sm active:scale-[0.98] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-orange-200/70 " +
  "disabled:opacity-60 disabled:pointer-events-none";

const actionBtnVar = {
  primary:
    "text-white bg-gradient-to-b from-orange-500 to-red-500 hover:from-orange-600 hover:to-red-600 hover:shadow",
  outline:
    "bg-white text-slate-700 border border-slate-200 hover:bg-slate-50",
  success:
    "text-white bg-gradient-to-b from-green-500 to-green-600 hover:from-green-600 hover:to-green-700",
  danger:
    "text-white bg-gradient-to-b from-red-500 to-red-600 hover:from-red-600 hover:to-red-700",
};

function ActionButton({ variant = "outline", className = "", ...props }) {
  return (
    <button
      type="button"
      className={`${actionBtnBase} ${actionBtnVar[variant] ?? actionBtnVar.outline} ${className}`.trim()}
      {...props}
    />
  );
}

function ProjectsHero({ title, subtitle, eyebrow = "ADMIN" }) {
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

export default function AdminPendingProjects() {
  const { token } = useSelector((s) => s.auth);
  const toast = useToast();
  const [projects, setProjects] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedProject, setSelectedProject] = useState(null);
  const [approvingId, setApprovingId] = useState(null);
  const [rejectingId, setRejectingId] = useState(null);
  const [showRejectReason, setShowRejectReason] = useState(false);
  const [rejectReason, setRejectReason] = useState("");

  useEffect(() => {
    fetchPendingProjects();
  }, []);

  const fetchPendingProjects = async () => {
    try {
      setLoading(true);
      const { data } = await API.get("/projects/admin/projects/pending", {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (data.success) {
        setProjects(data.projects || []);
      }
    } catch (err) {
      toast.error(err.response?.data?.message || "Failed to load pending projects");
    } finally {
      setLoading(false);
    }
  };

  const handleApprove = async (projectId) => {
    if (!projectId || !Number.isInteger(Number(projectId))) {
      toast.error("Missing or invalid project id");
      return;
    }

    try {
      setApprovingId(projectId);
      const { data } = await API.post(
        `/projects/admin/projects/${projectId}/approve`,
        {},
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );
      if (data.success) {
        toast.success("Project approved successfully");
        setProjects((prev) => prev.filter((p) => p.id !== projectId));
        if (selectedProject?.id === projectId) {
          setSelectedProject(null);
        }
      }
    } catch (err) {
      toast.error(err.response?.data?.message || "Failed to approve project");
    } finally {
      setApprovingId(null);
    }
  };

  const handleReject = async () => {
    if (!selectedProject?.id) return;
    const projectId = selectedProject.id;

    if (!projectId || !Number.isInteger(Number(projectId))) {
      toast.error("Missing or invalid project id");
      return;
    }

    if (!rejectReason.trim()) {
      toast.error("Please provide a reason for rejection");
      return;
    }

    try {
      setRejectingId(projectId);
      const { data } = await API.post(
        `/projects/admin/projects/${projectId}/reject`,
        { reason: rejectReason },
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );
      if (data.success) {
        toast.success("Project rejected");
        setProjects((prev) => prev.filter((p) => p.id !== projectId));
        setSelectedProject(null);
        setShowRejectReason(false);
        setRejectReason("");
      }
    } catch (err) {
      toast.error(err.response?.data?.message || "Failed to reject project");
    } finally {
      setRejectingId(null);
    }
  };

  // Helper to format JD currency
  const formatJD = (value, { noDecimals = false } = {}) => {
    if (value == null || value === undefined || value === "") return "—";
    const num = Number(value);
    if (isNaN(num)) return "—";
    
    if (noDecimals) {
      const rounded = Math.round(num);
      return `${rounded} JD`;
    }
    
    // Show up to 2 decimals, but strip trailing zeros
    const formatted = num.toFixed(2);
    // Remove trailing zeros and decimal point if not needed
    const cleaned = formatted.replace(/\.?0+$/, "");
    return `${cleaned} JD`;
  };

  const formatBudget = (project, { noDecimals = false } = {}) => {
    if (project.project_type === "fixed") {
      return formatJD(project.budget, { noDecimals });
    }
    if (project.project_type === "hourly") {
      const rate = project.hourly_rate || 0;
      const hours = project.duration_hours || project.total_hours || 0;
      const rateFormatted = formatJD(rate, { noDecimals });
      return hours > 0 ? `${rateFormatted}/hr (${hours}h)` : `${rateFormatted}/hr`;
    }
    if (project.project_type === "bidding") {
      const min = project.budget_min || 0;
      const max = project.budget_max || 0;
      if (min > 0 && max > 0) {
        return `${formatJD(min, { noDecimals })} - ${formatJD(max, { noDecimals })}`;
      }
      return "—";
    }
    return "—";
  };

  const formatDuration = (project) => {
    if (project.duration_days && project.duration_days > 0) {
      return `Duration: ${project.duration_days} day${project.duration_days !== 1 ? "s" : ""}`;
    }
    if (project.duration_hours && project.duration_hours > 0) {
      return `Duration: ${project.duration_hours} hour${project.duration_hours !== 1 ? "s" : ""}`;
    }
    return null;
  };

  const formatPaymentMethod = (method) => {
    if (!method) return "—";
    return method.charAt(0).toUpperCase() + method.slice(1);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <Loader2 className="w-8 h-8 animate-spin text-orange-500" />
      </div>
    );
  }

  return (
    <>
      <div className="space-y-5">
        <ProjectsHero
          eyebrow="ADMIN"
          title="Pending Approvals"
          subtitle="Review and approve or reject projects with offline payments."
        />

        {projects.length === 0 ? (
          <div className="bg-white rounded-xl border border-slate-200 p-12 text-center">
            <Clock className="w-12 h-12 text-slate-400 mx-auto mb-4" />
            <p className="text-lg font-semibold text-slate-700 mb-2">No pending approvals</p>
            <p className="text-slate-500">All projects have been reviewed.</p>
          </div>
        ) : (
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {projects.map((project) => (
              <div
                key={project.id}
                className="bg-white rounded-2xl border border-slate-200 shadow-sm hover:shadow-md transition-shadow overflow-hidden cursor-pointer flex flex-col"
                style={{ minHeight: "420px" }}
                onClick={() => setSelectedProject(project)}
              >
                {/* Cover Image */}
                <div className="relative h-[140px] w-full overflow-hidden bg-gradient-to-b from-orange-400 to-red-500 shrink-0">
                  {project.cover_pic ? (
                    <img
                      src={project.cover_pic}
                      alt={project.title}
                      className="h-full w-full object-cover"
                    />
                  ) : (
                    <div className="absolute inset-0 bg-gradient-to-b from-orange-400 to-red-500" />
                  )}
                  <div className="absolute top-3 left-3">
                    <span className="inline-flex items-center px-2.5 py-1 rounded-full text-[10px] font-semibold uppercase tracking-wide bg-white/90 text-orange-600">
                      Pending
                    </span>
                  </div>
                </div>

                {/* Content */}
                <div className="p-4 flex flex-col flex-1">
                  <h3
                    className="text-sm font-extrabold text-slate-900 mb-2 line-clamp-2"
                    style={{ wordBreak: "break-word", overflowWrap: "anywhere" }}
                  >
                    {project.title}
                  </h3>

                  {/* Category badges */}
                  <div className="flex flex-wrap items-center gap-1.5 mb-2">
                    {project.category_name && (
                      <span className="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-medium bg-orange-100 text-orange-800">
                        {project.category_name}
                      </span>
                    )}
                    {project.sub_sub_category_name && (
                      <span className="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-medium bg-orange-50 text-orange-700 border border-orange-200">
                        {project.sub_sub_category_name}
                      </span>
                    )}
                  </div>

                  {/* IDs */}
                  <div className="text-[10px] text-slate-500 mb-2">
                    <span>ID: #{project.id}</span>
                    <span className="mx-1">•</span>
                    <span>Client: #{project.user_id}</span>
                  </div>

                  {/* Payment method */}
                  <div className="mb-2">
                    <span className="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-medium bg-blue-100 text-blue-800">
                      {formatPaymentMethod(project.payment_method)}
                    </span>
                  </div>

                  {/* Budget */}
                  <div className="mb-2">
                    <span className="text-xs font-semibold text-slate-900">
                      {formatBudget(project, { noDecimals: true })}
                    </span>
                  </div>

                  {/* Duration */}
                  {formatDuration(project) && (
                    <div className="mb-2">
                      <span className="text-xs text-slate-600">{formatDuration(project)}</span>
                    </div>
                  )}

                  {/* Skills */}
                  {project.preferred_skills && Array.isArray(project.preferred_skills) && project.preferred_skills.length > 0 && (
                    <div className="flex flex-wrap items-center gap-1 mb-2">
                      {project.preferred_skills.slice(0, 4).map((skill, idx) => (
                        <span
                          key={idx}
                          className="inline-flex items-center px-1.5 py-0.5 rounded text-[9px] font-medium bg-slate-100 text-slate-700"
                        >
                          {skill}
                        </span>
                      ))}
                      {project.preferred_skills.length > 4 && (
                        <span className="text-[9px] text-slate-500">
                          +{project.preferred_skills.length - 4} more
                        </span>
                      )}
                    </div>
                  )}

                  {/* Description preview */}
                  {project.description && (
                    <p
                      className="text-xs text-slate-600 line-clamp-2 mb-3 flex-1"
                      style={{ wordBreak: "break-word", overflowWrap: "anywhere" }}
                    >
                      {project.description}
                    </p>
                  )}

                  <div className="mt-auto pt-3 border-t border-slate-100 shrink-0">
                    <ActionButton
                      variant="outline"
                      className="w-full"
                      onClick={(e) => {
                        e.stopPropagation();
                        setSelectedProject(project);
                      }}
                    >
                      <Eye className="w-4 h-4" />
                      View
                    </ActionButton>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Project Details Modal */}
      {selectedProject && (
        <div
          className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4"
          onClick={(e) => {
            if (e.target === e.currentTarget) {
              setSelectedProject(null);
              setShowRejectReason(false);
              setRejectReason("");
            }
          }}
        >
          <div
            className="bg-white rounded-xl shadow-xl max-w-3xl w-full max-h-[80vh] flex flex-col"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Header */}
            <div className="sticky top-0 bg-white border-b border-slate-200 p-6 z-10">
              <div className="flex items-start justify-between gap-4">
                <div className="flex-1 min-w-0">
                  <h3
                    className="text-xl font-extrabold text-slate-900 mb-3"
                    style={{ wordBreak: "break-word", overflowWrap: "anywhere" }}
                  >
                    {selectedProject.title}
                  </h3>
                  <div className="flex flex-wrap items-center gap-2 mb-2">
                    <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold uppercase tracking-wide bg-amber-100 text-amber-800">
                      Pending Approval
                    </span>
                    <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold bg-blue-100 text-blue-800">
                      {formatPaymentMethod(selectedProject.payment_method)}
                    </span>
                  </div>
                  <div className="text-xs text-slate-500">
                    <span>Project ID: #{selectedProject.id}</span>
                    <span className="mx-2">•</span>
                    <span>Client ID: #{selectedProject.user_id}</span>
                    {selectedProject.client_name && (
                      <>
                        <span className="mx-2">•</span>
                        <span>{selectedProject.client_name}</span>
                      </>
                    )}
                  </div>
                </div>
                <button
                  onClick={() => {
                    setSelectedProject(null);
                    setShowRejectReason(false);
                    setRejectReason("");
                  }}
                  className="w-8 h-8 grid place-items-center rounded-full hover:bg-slate-100 text-slate-600 shrink-0"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>
            </div>

            {/* Body */}
            <div className="p-6 space-y-6 max-h-[calc(80vh-200px)] overflow-y-auto">
              {/* Cover Image */}
              {selectedProject.cover_pic && (
                <div className="rounded-xl overflow-hidden border border-slate-200">
                  <img
                    src={selectedProject.cover_pic}
                    alt={selectedProject.title}
                    className="w-full h-64 object-cover"
                  />
                </div>
              )}

              {/* Category & Sub-sub Category */}
              {(selectedProject.category_name || selectedProject.sub_sub_category_name) && (
                <div>
                  <h4 className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-2">
                    Category
                  </h4>
                  <div className="flex flex-wrap gap-2">
                    {selectedProject.category_name && (
                      <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-orange-100 text-orange-800">
                        {selectedProject.category_name}
                      </span>
                    )}
                    {selectedProject.sub_sub_category_name && (
                      <span className="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium bg-orange-50 text-orange-700 border border-orange-200">
                        {selectedProject.sub_sub_category_name}
                      </span>
                    )}
                  </div>
                </div>
              )}

              {/* Description */}
              {selectedProject.description && (
                <div>
                  <h4 className="text-sm font-semibold text-slate-900 mb-2">Description</h4>
                  <p
                    className="text-sm text-slate-600 whitespace-pre-wrap"
                    style={{ wordBreak: "break-word", overflowWrap: "anywhere" }}
                  >
                    {selectedProject.description}
                  </p>
                </div>
              )}

              {/* Budget & Details */}
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <h4 className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-1">
                    Budget
                  </h4>
                  <p className="text-sm font-semibold text-slate-900">{formatBudget(selectedProject)}</p>
                </div>
                <div>
                  <h4 className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-1">
                    Type
                  </h4>
                  <p className="text-sm font-semibold text-slate-900 capitalize">
                    {selectedProject.project_type || "—"}
                  </p>
                </div>
                {formatDuration(selectedProject) && (
                  <div>
                    <h4 className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-1">
                      Duration
                    </h4>
                    <p className="text-sm text-slate-600">{formatDuration(selectedProject)}</p>
                  </div>
                )}
                {selectedProject.created_at && (
                  <div>
                    <h4 className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-1">
                      Created
                    </h4>
                    <p className="text-sm text-slate-600">
                      {new Date(selectedProject.created_at).toLocaleString()}
                    </p>
                  </div>
                )}
              </div>

              {/* Skills */}
              {selectedProject.preferred_skills && Array.isArray(selectedProject.preferred_skills) && selectedProject.preferred_skills.length > 0 && (
                <div>
                  <h4 className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-2">
                    Preferred Skills
                  </h4>
                  <div className="flex flex-wrap gap-2">
                    {selectedProject.preferred_skills.map((skill, idx) => (
                      <span
                        key={idx}
                        className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-slate-100 text-slate-700"
                      >
                        {skill}
                      </span>
                    ))}
                  </div>
                </div>
              )}

              {/* Attachments */}
              <div>
                <h4 className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-2">
                  Attachments
                </h4>
                {selectedProject.attachments && selectedProject.attachments.length > 0 ? (
                  <div className="space-y-2">
                    {selectedProject.attachments.map((file, idx) => (
                      <a
                        key={file.id || idx}
                        href={file.url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="flex items-center gap-3 p-3 rounded-lg border border-slate-200 hover:bg-slate-50 transition"
                      >
                        <FileText className="w-5 h-5 text-slate-400 shrink-0" />
                        <span className="flex-1 text-sm text-slate-700 truncate">{file.name}</span>
                        <ExternalLink className="w-4 h-4 text-slate-400 shrink-0" />
                      </a>
                    ))}
                  </div>
                ) : (
                  <p className="text-sm text-slate-500">No attachments</p>
                )}
              </div>

              {/* Reject Reason Input */}
              {showRejectReason && (
                <div>
                  <h4 className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-2">
                    Rejection Reason
                  </h4>
                  <textarea
                    value={rejectReason}
                    onChange={(e) => setRejectReason(e.target.value)}
                    placeholder="Enter reason for rejection..."
                    className="w-full h-24 px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-200/70 resize-none text-sm"
                  />
                </div>
              )}
            </div>

            {/* Footer */}
            <div className="sticky bottom-0 bg-white border-t border-slate-200 p-4">
              <div className="flex gap-3 justify-center">
                <ActionButton
                  variant="success"
                  onClick={() => handleApprove(selectedProject.id)}
                  disabled={approvingId === selectedProject.id || rejectingId === selectedProject.id}
                  className="flex-1 max-w-[200px]"
                >
                  {approvingId === selectedProject.id ? (
                    <Loader2 className="w-4 h-4 animate-spin" />
                  ) : (
                    <Check className="w-4 h-4" />
                  )}
                  Approve
                </ActionButton>
                {!showRejectReason ? (
                  <ActionButton
                    variant="danger"
                    onClick={() => setShowRejectReason(true)}
                    disabled={approvingId === selectedProject.id || rejectingId === selectedProject.id}
                    className="flex-1 max-w-[200px]"
                  >
                    <X className="w-4 h-4" />
                    Reject
                  </ActionButton>
                ) : (
                  <>
                    <ActionButton
                      variant="outline"
                      onClick={() => {
                        setShowRejectReason(false);
                        setRejectReason("");
                      }}
                      className="flex-1 max-w-[200px]"
                    >
                      Cancel
                    </ActionButton>
                    <ActionButton
                      variant="danger"
                      onClick={handleReject}
                      disabled={
                        !rejectReason.trim() ||
                        approvingId === selectedProject.id ||
                        rejectingId === selectedProject.id
                      }
                      className="flex-1 max-w-[200px]"
                    >
                      {rejectingId === selectedProject.id ? (
                        <Loader2 className="w-4 h-4 animate-spin" />
                      ) : (
                        <X className="w-4 h-4" />
                      )}
                      Confirm Reject
                    </ActionButton>
                  </>
                )}
              </div>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
