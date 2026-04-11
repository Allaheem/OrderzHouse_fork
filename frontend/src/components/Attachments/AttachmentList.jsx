import React, { useCallback, useState } from "react";
import { Paperclip, Image, FileText, File, Loader2 } from "lucide-react";
import API from "../../api/client.js";

/**
 * Normalize one attachment to { href, displayName, fileId? }.
 * Supports URL strings (legacy) and objects: { url, file_url, id, file_name, ... }.
 */
function normalizeAttachmentItem(item) {
  if (item == null) return null;
  if (typeof item === "string") {
    const s = item.trim();
    if (!s) return null;
    return { href: s, displayName: null, fileId: null };
  }
  if (typeof item === "object") {
    const href = String(
      item.url ?? item.path ?? item.file_url ?? item.href ?? ""
    ).trim();
    if (!href) return null;
    const displayName =
      item.name ||
      item.file_name ||
      item.filename ||
      item.originalname ||
      null;
    const rawId = item.id ?? item.file_id ?? null;
    const fileId =
      rawId != null && /^\d+$/.test(String(rawId)) ? Number(rawId) : null;
    return { href, displayName, fileId };
  }
  return null;
}

function fileNameFromContentDisposition(cd) {
  if (!cd) return null;
  const m = /filename\*=UTF-8''([^;]+)|filename="?([^";]+)"?/i.exec(cd);
  const v = m?.[1] || m?.[2];
  if (!v) return null;
  try {
    return decodeURIComponent(v);
  } catch {
    return v;
  }
}

/**
 * AttachmentList
 * Reusable display for file attachments.
 *
 * @param {Object} props
 * @param {string|string[]|object[]} props.attachments - URLs, JSON string, or objects with url + optional name.
 * @param {string} [props.title] - Optional title, defaults to "Attachments".
 * @param {boolean} [props.compact] - Optional compact mode (smaller icons).
 * @param {string|number} [props.projectId] - When set (numeric project), click uses authenticated API download
 *   so freelancers/clients can fetch chat uploads & deliveries without relying on Cloudinary in a new tab.
 */
export default function AttachmentList({
  attachments,
  title = "Attachments",
  compact = false,
  projectId = null,
}) {
  const [busyKey, setBusyKey] = useState(null);

  const numericProjectId =
    projectId != null && /^\d+$/.test(String(projectId)) ? String(projectId) : null;

  const downloadThroughApi = useCallback(
    async (norm, index) => {
      if (!numericProjectId || norm.fileId == null) return false;
      const key = `${numericProjectId}-${norm.fileId}-${index}`;
      setBusyKey(key);
      try {
        const res = await API.get(
          `/projects/${numericProjectId}/files/${norm.fileId}/download`,
          { responseType: "blob" }
        );
        const cd = res?.headers?.["content-disposition"];
        const fromHeader = fileNameFromContentDisposition(cd);
        const label =
          fromHeader ||
          (norm.displayName
            ? String(norm.displayName)
            : (() => {
                const noQuery = String(norm.href).replace(/\?.*$/, "");
                const last = noQuery.split("/").filter(Boolean).pop();
                return last ? decodeURIComponent(last) : "attachment";
              })());

        const blob =
          res?.data instanceof Blob ? res.data : new Blob([res.data]);
        const blobUrl = window.URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = blobUrl;
        a.download = label;
        document.body.appendChild(a);
        a.click();
        a.remove();
        window.URL.revokeObjectURL(blobUrl);
        return true;
      } catch (e) {
        console.error("AttachmentList download:", e);
        return false;
      } finally {
        setBusyKey(null);
      }
    },
    [numericProjectId]
  );

  if (!attachments) return null;

  let raw = [];
  if (Array.isArray(attachments)) {
    raw = attachments;
  } else if (typeof attachments === "string") {
    try {
      const parsed = JSON.parse(attachments);
      raw = Array.isArray(parsed) ? parsed : [attachments];
    } catch {
      raw = [attachments];
    }
  }

  const files = raw.map(normalizeAttachmentItem).filter(Boolean);
  if (files.length === 0) return null;

  const getFileIcon = (href) => {
    const lower = (href || "").toLowerCase();
    if (/\.(jpeg|jpg|gif|png|webp|svg)(\?|$)/i.test(lower))
      return <Image className="w-5 h-5 text-emerald-600" />;
    if (/\.pdf(\?|$)/i.test(lower)) return <FileText className="w-5 h-5 text-rose-600" />;
    if (/\.(doc|docx|txt|rtf)(\?|$)/i.test(lower))
      return <FileText className="w-5 h-5 text-blue-600" />;
    return <File className="w-5 h-5 text-slate-600" />;
  };

  const getFileName = ({ href, displayName }) => {
    if (displayName) return String(displayName);
    const noQuery = String(href).replace(/\?.*$/, "");
    const last = noQuery.split("/").filter(Boolean).pop();
    if (last) return decodeURIComponent(last);
    try {
      const name = new URL(href).pathname.split("/").pop();
      return decodeURIComponent(name) || "attachment";
    } catch {
      return "attachment";
    }
  };

  const showHeader = title !== null && title !== "";

  return (
    <div className={showHeader ? "pt-6 border-t border-slate-200" : ""}>
      {showHeader ? (
        <div className="flex items-center gap-2 mb-4">
          <Paperclip className="w-5 h-5 text-slate-600" />
          <h3 className="text-lg font-semibold text-slate-900">{title}</h3>
        </div>
      ) : null}

      <div className="flex flex-wrap gap-3">
        {files.map((norm, i) => {
          const label = getFileName(norm);
          const rowKey =
            numericProjectId && norm.fileId != null
              ? `${numericProjectId}-${norm.fileId}-${i}`
              : null;
          const isBusy = rowKey != null && busyKey === rowKey;

          return (
            <a
              key={i}
              href={norm.href}
              target="_blank"
              rel="noopener noreferrer"
              title={label}
              className="group flex flex-col items-center w-20"
              onClick={async (e) => {
                if (!numericProjectId || norm.fileId == null) return;
                e.preventDefault();
                const ok = await downloadThroughApi(norm, i);
                if (!ok) {
                  window.open(norm.href, "_blank", "noopener,noreferrer");
                }
              }}
            >
              <div
                className={`${
                  compact ? "w-12 h-12" : "w-14 h-14"
                } rounded-xl bg-slate-100 flex items-center justify-center mb-2 group-hover:bg-slate-200 transition-colors`}
              >
                {isBusy ? (
                  <Loader2 className="w-5 h-5 text-slate-500 animate-spin" />
                ) : (
                  getFileIcon(norm.href)
                )}
              </div>
              <span className="text-xs text-slate-600 text-center truncate w-full">
                {label.substring(0, 12)}
                {label.length > 12 ? "..." : ""}
              </span>
            </a>
          );
        })}
      </div>
    </div>
  );
}
