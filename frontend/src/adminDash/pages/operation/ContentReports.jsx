import { useCallback, useEffect, useState } from "react";
import API from "../../../api/client.js";
import { useToast } from "../../../components/toast/ToastProvider.jsx";

function nameFromUser(u) {
  if (!u) return "—";
  const fn = u.first_name || "";
  const ln = u.last_name || "";
  const n = `${fn} ${ln}`.trim();
  return n || `User #${u.id}`;
}

export default function ContentReports() {
  const toast = useToast();
  const [status, setStatus] = useState("open");
  const [reports, setReports] = useState([]);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const { data } = await API.get("/moderation/admin/reports", {
        params: { status: status === "all" ? "" : status, limit: 100, offset: 0 },
      });
      setReports(data.reports || []);
    } catch (e) {
      const msg = e?.response?.data?.message || e.message || "Failed to load reports";
      toast.error(msg);
      setReports([]);
    } finally {
      setLoading(false);
    }
  }, [status]);

  useEffect(() => {
    load();
  }, [load]);

  const updateStatus = async (id, next) => {
    try {
      await API.patch(`/moderation/admin/reports/${id}`, { status: next });
      toast.success("Updated");
      await load();
    } catch (e) {
      const msg = e?.response?.data?.message || e.message || "Update failed";
      toast.error(msg);
    }
  };

  return (
    <div className="p-6 max-w-7xl mx-auto">
      <div className="flex flex-wrap items-center justify-between gap-4 mb-6">
        <h1 className="text-2xl font-semibold text-gray-900">Content reports (UGC)</h1>
        <div className="flex items-center gap-2">
          <label className="text-sm text-gray-600">Status</label>
          <select
            className="border border-gray-300 rounded-lg px-3 py-2 text-sm"
            value={status}
            onChange={(e) => setStatus(e.target.value)}
          >
            <option value="all">All</option>
            <option value="open">Open</option>
            <option value="reviewed">Reviewed</option>
            <option value="dismissed">Dismissed</option>
          </select>
          <button
            type="button"
            onClick={() => load()}
            className="px-3 py-2 text-sm rounded-lg bg-gray-100 hover:bg-gray-200"
          >
            Refresh
          </button>
        </div>
      </div>

      <p className="text-sm text-gray-600 mb-4">
        Reports submitted from the mobile app (project chat). Mark as reviewed when handled, or dismissed if not actionable.
      </p>

      {loading ? (
        <p className="text-gray-500">Loading…</p>
      ) : reports.length === 0 ? (
        <p className="text-gray-500">No reports in this filter.</p>
      ) : (
        <div className="overflow-x-auto border border-gray-200 rounded-lg">
          <table className="min-w-full text-sm">
            <thead className="bg-gray-50 text-left">
              <tr>
                <th className="px-3 py-2 font-medium">ID</th>
                <th className="px-3 py-2 font-medium">Created</th>
                <th className="px-3 py-2 font-medium">Reporter</th>
                <th className="px-3 py-2 font-medium">Reported</th>
                <th className="px-3 py-2 font-medium">Project</th>
                <th className="px-3 py-2 font-medium">Status</th>
                <th className="px-3 py-2 font-medium">Note / excerpt</th>
                <th className="px-3 py-2 font-medium">Actions</th>
              </tr>
            </thead>
            <tbody>
              {reports.map((r) => (
                <tr key={r.id} className="border-t border-gray-100 align-top">
                  <td className="px-3 py-2 whitespace-nowrap">{r.id}</td>
                  <td className="px-3 py-2 whitespace-nowrap text-gray-600">
                    {r.created_at ? new Date(r.created_at).toLocaleString() : "—"}
                  </td>
                  <td className="px-3 py-2">{nameFromUser(r.reporter)}</td>
                  <td className="px-3 py-2">{nameFromUser(r.reported)}</td>
                  <td className="px-3 py-2 whitespace-nowrap">{r.project_id ?? "—"}</td>
                  <td className="px-3 py-2">
                    <span className="inline-flex px-2 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
                      {r.status}
                    </span>
                  </td>
                  <td className="px-3 py-2 max-w-md text-gray-700">
                    <div className="line-clamp-3">
                      {r.reporter_note ? <span className="font-medium">Note: </span> : null}
                      {r.reporter_note || ""}
                      {r.message_excerpt ? (
                        <div className="mt-1 text-gray-600 whitespace-pre-wrap break-words">
                          {r.message_excerpt.length > 400
                            ? `${r.message_excerpt.slice(0, 400)}…`
                            : r.message_excerpt}
                        </div>
                      ) : null}
                    </div>
                  </td>
                  <td className="px-3 py-2 whitespace-nowrap">
                    {r.status === "open" ? (
                      <div className="flex flex-col gap-1">
                        <button
                          type="button"
                          className="text-xs px-2 py-1 rounded bg-emerald-600 text-white hover:bg-emerald-700"
                          onClick={() => updateStatus(r.id, "reviewed")}
                        >
                          Reviewed
                        </button>
                        <button
                          type="button"
                          className="text-xs px-2 py-1 rounded bg-gray-200 text-gray-800 hover:bg-gray-300"
                          onClick={() => updateStatus(r.id, "dismissed")}
                        >
                          Dismiss
                        </button>
                      </div>
                    ) : (
                      <span className="text-gray-400 text-xs">—</span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
