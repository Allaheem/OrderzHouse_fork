import React, { useState, useEffect } from "react";
import { useSelector } from "react-redux";
import { useNavigate, useParams } from "react-router-dom";
import { useToast } from "../../components/toast/ToastProvider";
import API from "../../api/client.js";
import { ArrowLeft, Archive, FileText, Calendar, User, Globe, DollarSign, Clock, Package, Hash } from "lucide-react";

export default function TenderDetails() {
  const { id } = useParams();
  const { userData, token } = useSelector((s) => s.auth);
  const navigate = useNavigate();
  const toast = useToast();
  const [tender, setTender] = useState(null);
  const [loading, setLoading] = useState(true);
  const [updating, setUpdating] = useState(false);

  useEffect(() => {
    if (userData?.role_id !== 2 || !userData?.can_manage_tender_vault) {
      toast.error("Access denied. You do not have permission to manage tender vault.");
      navigate("/client/tender-vault");
      return;
    }

    fetchTender();
  }, [id, userData, navigate, toast]);

  const fetchTender = async () => {
    try {
      setLoading(true);
      const res = await API.get(`/tender-vault/projects/${id}`, {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      });
      if (res.data?.success) {
        setTender(res.data.tender);
      } else {
        throw new Error("Failed to load tender");
      }
    } catch (err) {
      if (err.response?.status === 403) {
        toast.error("Access denied. You do not have permission to manage tender vault.");
        navigate("/client/tender-vault");
      } else if (err.response?.status === 404) {
        toast.error("Tender not found");
        navigate("/client/tender-vault");
      } else {
        toast.error("Failed to load tender details");
      }
    } finally {
      setLoading(false);
    }
  };

  const handleStatusChange = async (newStatus) => {
    if (!window.confirm(`Are you sure you want to change status to ${newStatus}?`)) return;
    
    try {
      setUpdating(true);
      const res = await API.patch(`/tender-vault/projects/${id}/status`, 
        { status: newStatus },
        {
          headers: {
            Authorization: `Bearer ${token}`,
          },
        }
      );
      if (res.data?.success) {
        toast.success(`Tender status updated to ${newStatus}`);
        fetchTender();
      }
    } catch (err) {
      toast.error(err.response?.data?.message || "Failed to update status");
    } finally {
      setUpdating(false);
    }
  };

  if (loading) {
    return (
      <div className="text-center py-12 text-slate-500">Loading tender details...</div>
    );
  }

  if (!tender) {
    return (
      <div className="text-center py-12 text-slate-500">Tender not found</div>
    );
  }

  // Helper function to format value or show dash
  const formatValue = (value) => {
    if (value === null || value === undefined || value === '') return '—';
    return value;
  };

  /** Budget line: whole JD integers only, e.g. "149 - 318 JD" */
  const formatBudgetRangeJd = (min, max, currency = "JD") => {
    const a = min != null && min !== "" ? Math.round(Number(min)) : null;
    const b = max != null && max !== "" ? Math.round(Number(max)) : null;
    const cur = currency && String(currency).trim() ? String(currency).trim() : "JD";
    if (a != null && Number.isFinite(a) && b != null && Number.isFinite(b)) {
      return `${a} - ${b} ${cur}`;
    }
    if (a != null && Number.isFinite(a)) return `${a} ${cur}`;
    if (b != null && Number.isFinite(b)) return `${b} ${cur}`;
    return "—";
  };

  // Helper function to format date
  const formatDate = (dateString) => {
    if (!dateString) return '—';
    try {
      return new Date(dateString).toLocaleString();
    } catch {
      return dateString;
    }
  };

  // Helper function to format date only
  const formatDateOnly = (dateString) => {
    if (!dateString) return '—';
    try {
      return new Date(dateString).toLocaleDateString();
    } catch {
      return dateString;
    }
  };

  // Parse attachments (ensure it's an array)
  const attachments = Array.isArray(tender.attachments) ? tender.attachments : [];
  
  // Parse metadata (ensure it's an object)
  const metadata = tender.metadata && typeof tender.metadata === 'object' ? tender.metadata : {};
  
  // Safely get subcategory IDs from API response or metadata fallback
  const subCategoryId = tender.sub_category_id || metadata.sub_category_id || null;
  const subSubCategoryId = tender.sub_sub_category_id || metadata.sub_sub_category_id || null;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <button
          onClick={() => navigate("/client/tender-vault")}
          className="p-2 text-slate-600 hover:text-slate-900 hover:bg-slate-100 rounded-lg transition"
          title="Back to Tender Vault"
        >
          <ArrowLeft className="w-5 h-5" />
        </button>
        <div className="flex-1">
          <h1 className="text-2xl font-bold text-slate-900">{formatValue(tender.title)}</h1>
          <div className="flex items-center gap-4 mt-2">
            <p className="text-sm text-slate-600">
              Tender ID: <span className="font-mono font-semibold">#{tender.id}</span>
            </p>
          </div>
        </div>
      </div>

      {/* Status Badge */}
      <div className={`inline-flex items-center gap-2 px-4 py-2 rounded-lg border-2 font-semibold text-sm ${
        tender.status === 'published' ? 'border-green-500 bg-green-50 text-green-700' : 
        tender.status === 'active' ? 'border-purple-500 bg-purple-50 text-purple-700' :
        tender.status === 'stored' ? 'border-blue-500 bg-blue-50 text-blue-700' : 
        tender.status === 'expired' ? 'border-red-500 bg-red-50 text-red-700' :
        'border-slate-500 bg-slate-50 text-slate-700'
      }`}>
        {tender.status === 'published' && <FileText className="w-4 h-4" />}
        {tender.status === 'active' && <Package className="w-4 h-4" />}
        {tender.status === 'stored' && <Archive className="w-4 h-4" />}
        {tender.status === 'archived' && <Archive className="w-4 h-4" />}
        {tender.status === 'expired' && <Archive className="w-4 h-4" />}
        {tender.status ? tender.status.charAt(0).toUpperCase() + tender.status.slice(1) : '—'}
      </div>

      {/* Main Details Card */}
      <div className="bg-white rounded-lg border border-slate-200 p-6 space-y-6">
        {/* Description */}
        <div>
          <h3 className="text-sm font-semibold text-slate-700 mb-2 flex items-center gap-2">
            <FileText className="w-4 h-4" />
            Description
          </h3>
          <p className="text-slate-600 whitespace-pre-wrap leading-relaxed">
            {formatValue(tender.description)}
          </p>
        </div>

        {/* Details Grid - Two Column Layout */}
        <div className="grid md:grid-cols-2 gap-6 pt-6 border-t border-slate-200">
          {/* Category */}
          <div>
            <h4 className="text-xs font-semibold text-slate-500 uppercase mb-1 flex items-center gap-2">
              <Package className="w-3 h-3" />
              Category
            </h4>
            <p className="text-slate-900">{formatValue(tender.category_name)}</p>
            {/* Subcategory can come from API response or metadata */}
            {(tender.sub_category_name || subCategoryId) && (
              <p className="text-sm text-slate-600 mt-1">
                Sub: {tender.sub_category_name || `ID: ${subCategoryId}`}
              </p>
            )}
            {(tender.sub_sub_category_name || subSubCategoryId) && (
              <p className="text-sm text-slate-600 mt-1">
                Sub-Sub: {tender.sub_sub_category_name || `ID: ${subSubCategoryId}`}
              </p>
            )}
          </div>

          {/* Country */}
          <div>
            <h4 className="text-xs font-semibold text-slate-500 uppercase mb-1 flex items-center gap-2">
              <Globe className="w-3 h-3" />
              Country
            </h4>
            <p className="text-slate-900">{formatValue(tender.country)}</p>
          </div>

          {/* Budget Range */}
          <div>
            <h4 className="text-xs font-semibold text-slate-500 uppercase mb-1 flex items-center gap-2">
              <DollarSign className="w-3 h-3" />
              Budget Range
            </h4>
            <p className="text-slate-900">
              {formatBudgetRangeJd(tender.budget_min, tender.budget_max, tender.currency || "JD")}
            </p>
          </div>

          {/* Duration */}
          <div>
            <h4 className="text-xs font-semibold text-slate-500 uppercase mb-1 flex items-center gap-2">
              <Clock className="w-3 h-3" />
              Duration
            </h4>
            <p className="text-slate-900">
              {tender.duration_value && tender.duration_unit
                ? `${tender.duration_value} ${tender.duration_unit}`
                : '—'}
            </p>
          </div>

          {/* Created By */}
          <div>
            <h4 className="text-xs font-semibold text-slate-500 uppercase mb-1 flex items-center gap-2">
              <User className="w-3 h-3" />
              Created By
            </h4>
            <p className="text-slate-900">{formatValue(tender.creator_name)}</p>
            {tender.creator_email && (
              <p className="text-sm text-slate-600 mt-1">{tender.creator_email}</p>
            )}
            {tender.created_by && (
              <p className="text-xs text-slate-500 mt-1">User ID: {tender.created_by}</p>
            )}
          </div>

          {/* Created At */}
          <div>
            <h4 className="text-xs font-semibold text-slate-500 uppercase mb-1 flex items-center gap-2">
              <Calendar className="w-3 h-3" />
              Created At
            </h4>
            <p className="text-slate-900">{formatDate(tender.created_at)}</p>
          </div>

          {/* Updated At */}
          <div>
            <h4 className="text-xs font-semibold text-slate-500 uppercase mb-1 flex items-center gap-2">
              <Calendar className="w-3 h-3" />
              Updated At
            </h4>
            <p className="text-slate-900">{formatDate(tender.updated_at)}</p>
          </div>

          {/* Rotation System Fields (if active) */}
          {tender.status === 'active' && (
            <>
              {tender.display_start_time && (
                <div>
                  <h4 className="text-xs font-semibold text-slate-500 uppercase mb-1">Display Start</h4>
                  <p className="text-slate-900">{formatDate(tender.display_start_time)}</p>
                </div>
              )}
              {tender.display_end_time && (
                <div>
                  <h4 className="text-xs font-semibold text-slate-500 uppercase mb-1">Display End</h4>
                  <p className="text-slate-900">{formatDate(tender.display_end_time)}</p>
                </div>
              )}
            </>
          )}
          {tender.usage_count !== undefined && (
            <div>
              <h4 className="text-xs font-semibold text-slate-500 uppercase mb-1">Usage Count</h4>
              <p className="text-slate-900">
                {tender.usage_count} / {tender.max_usage || 4}
              </p>
            </div>
          )}
          {tender.cycle_number !== undefined && tender.cycle_number > 0 && (
            <div>
              <h4 className="text-xs font-semibold text-slate-500 uppercase mb-1">Current Cycle</h4>
              <p className="text-slate-900">Cycle #{tender.cycle_number}</p>
              {tender.client_public_id && (
                <p className="text-xs text-slate-600 mt-1">Client ID: <span className="font-mono">{tender.client_public_id}</span></p>
              )}
              {tender.cycle_status && (
                <p className="text-xs text-slate-600 mt-1">Status: <span className="capitalize font-semibold">{tender.cycle_status}</span></p>
              )}
            </div>
          )}
          {tender.temporary_archived_until && (
            <div>
              <h4 className="text-xs font-semibold text-slate-500 uppercase mb-1">Temporarily Archived Until</h4>
              <p className="text-slate-900">{formatDate(tender.temporary_archived_until)}</p>
            </div>
          )}
        </div>

        {/* Attachments Section */}
        <div className="pt-6 border-t border-slate-200">
          <h4 className="text-xs font-semibold text-slate-500 uppercase mb-3 flex items-center gap-2">
            <FileText className="w-4 h-4" />
            Attachments
          </h4>
          {attachments.length > 0 ? (
            <div className="space-y-2">
              {attachments.map((attachment, index) => (
                <div key={index} className="flex items-start gap-3 p-2 bg-slate-50 rounded-lg border border-slate-200">
                  {attachment.url && (attachment.type === "image" || /\.(jpe?g|png|webp|gif)(\?|$)/i.test(attachment.url)) ? (
                    <a href={attachment.url} target="_blank" rel="noopener noreferrer" className="shrink-0 rounded-md overflow-hidden border border-slate-200 bg-white">
                      <img src={attachment.url} alt="" className="w-32 h-20 object-cover" loading="lazy" />
                    </a>
                  ) : null}
                  {attachment.url ? (
                    <a
                      href={attachment.url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-blue-600 hover:text-blue-800 underline flex items-center gap-2 min-w-0"
                    >
                      <FileText className="w-4 h-4 shrink-0" />
                      <span className="truncate">{attachment.name || attachment.filename || `Attachment ${index + 1}`}</span>
                    </a>
                  ) : (
                    <span className="text-slate-700">
                      {attachment.name || attachment.filename || `Attachment ${index + 1}`}
                    </span>
                  )}
                </div>
              ))}
            </div>
          ) : (
            <p className="text-slate-500 italic">No attachments</p>
          )}
        </div>

        {/* Metadata Section */}
        {Object.keys(metadata).length > 0 && (
          <div className="pt-6 border-t border-slate-200">
            <h4 className="text-xs font-semibold text-slate-500 uppercase mb-3 flex items-center gap-2">
              <Hash className="w-4 h-4" />
              Metadata
            </h4>
            <div className="bg-slate-50 rounded-lg p-4 border border-slate-200">
              {metadata.sub_category_id && (
                <div className="mb-2">
                  <span className="text-xs font-semibold text-slate-600">Subcategory ID: </span>
                  <span className="text-slate-900">{metadata.sub_category_id}</span>
                </div>
              )}
              <div className="space-y-1">
                {Object.entries(metadata).filter(([key]) => key !== "generated_label").map(([key, value]) => {
                  if (key === 'sub_category_id') return null; // Already shown above
                  return (
                    <div key={key} className="flex items-start gap-2">
                      <span className="text-xs font-semibold text-slate-600 min-w-[120px]">{key}:</span>
                      <span className="text-slate-900 break-words">
                        {typeof value === 'object' ? JSON.stringify(value, null, 2) : String(value)}
                      </span>
                    </div>
                  );
                })}
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Actions */}
      <div className="flex items-center gap-3 flex-wrap">
        {/* Only show action buttons for non-active, non-expired tenders */}
        {tender.status === 'stored' && (
          <button
            onClick={() => handleStatusChange('published')}
            disabled={updating}
            className="inline-flex items-center gap-2 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 disabled:opacity-50 transition"
          >
            <FileText className="w-4 h-4" />
            Publish
          </button>
        )}
        {tender.status === 'published' && (
          <button
            onClick={() => handleStatusChange('stored')}
            disabled={updating}
            className="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 transition"
          >
            Unpublish
          </button>
        )}
        {tender.status !== 'archived' && tender.status !== 'active' && tender.status !== 'expired' && (
          <button
            onClick={() => handleStatusChange('archived')}
            disabled={updating}
            className="inline-flex items-center gap-2 px-4 py-2 bg-slate-600 text-white rounded-lg hover:bg-slate-700 disabled:opacity-50 transition"
          >
            <Archive className="w-4 h-4" />
            Archive
          </button>
        )}
        {tender.status === 'archived' && (
          <button
            onClick={() => handleStatusChange('stored')}
            disabled={updating}
            className="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 transition"
          >
            Restore to Stored
          </button>
        )}
        {(tender.status === 'active' || tender.status === 'expired') && (
          <p className="text-sm text-slate-500 italic">
            {tender.status === 'active' 
              ? 'This tender is currently active in rotation. Status changes are managed automatically.'
              : 'This tender has reached maximum usage and cannot be modified.'}
          </p>
        )}
      </div>
    </div>
  );
}
