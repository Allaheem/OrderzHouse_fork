// src/adminDash/pages/people/Admins.jsx
import { useEffect, useState } from "react";
import { useSelector } from "react-redux";
import { useOutletContext } from "react-router-dom";
import API from "../../api/axios.js";
import { Search, ShieldCheck, UserPlus, X } from "lucide-react";
import PeopleTable from "../Tables";

// Permissions options for new admin
const PERMISSION_DEFS = [
  { key: "overview", label: "Overview / Dashboard" },
  { key: "admins", label: "Manage admins" },
  { key: "clients", label: "Manage clients" },
  { key: "freelancers", label: "Manage freelancers" },
  // { key: "courses", label: "Manage courses" },
  { key: "categories", label: "Manage categories" },
  { key: "verifications", label: "Verify freelancers" },
  { key: "projects", label: "Manage projects" },
  // { key: "tasks", label: "Manage tasks" },
  { key: "blogs", label: "Manage blogs" },
  { key: "payments", label: "Manage payments" },
  { key: "plans", label: "Manage plans" },
  { key: "analytics", label: "View analytics" },
];

function getInitialPermissions() {
  const base = {};
  PERMISSION_DEFS.forEach((p) => {
    // Enable Overview by default, others off
    base[p.key] = p.key === "overview";
  });
  return base;
}

/* =======================================================
   Admins Page
======================================================= */
export default function Admins() {
  const { roleId, token } = useSelector((state) => state.auth);
  const { setTopBarRight, clearTopBarRight } = useOutletContext() || {};

  const [tableRefreshKey, setTableRefreshKey] = useState(0);
  const [isModalOpen, setIsModalOpen] = useState(false);

  // Put "Add admin" button in top bar
  useEffect(() => {
    if (!setTopBarRight) return;

    const button = (
      <button
        type="button"
        onClick={() => setIsModalOpen(true)}
        className="inline-flex items-center gap-2 rounded-full bg-[#028090] px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-[#026678] active:scale-[0.97] transition"
      >
        <UserPlus className="w-4 h-4" />
        <span>Add admin</span>
      </button>
    );

    setTopBarRight(button);

    return () => {
      clearTopBarRight && clearTopBarRight();
    };
  }, [setTopBarRight, clearTopBarRight]);

  // Protect route
  if (!token) {
    return (
      <div className="text-center mt-10 text-red-500">
        Please log in to access this page.
      </div>
    );
  }

  if (Number(roleId) !== 1) {
    return (
      <div className="text-center mt-10 text-red-500">
        Access denied: Admins only.
      </div>
    );
  }

  return (
    <>
      <PeopleTable
        key={tableRefreshKey}
        title="Admins"
        endpoint="/admUser/role/1"
        getOnePath={(id) => `/admUser/${id}`}
        token={token}
        columns={[
          {
            label: "Profile",
            key: "profile_pic_url",
            render: (row) =>
              row.profile_pic_url ? (
                <div className="w-10 h-10 rounded-full overflow-hidden">
                  <img
                    src={row.profile_pic_url}
                    alt={
                      `${row.first_name || ""} ${row.last_name || ""}`.trim() ||
                      "Admin"
                    }
                    className="w-full h-full object-cover"
                  />
                </div>
              ) : (
                <div className="w-10 h-10 rounded-full bg-gray-200 flex items-center justify-center">
                  <span className="text-gray-400 text-xs font-semibold">
                    {(row.first_name || row.username || "A")
                      .toString()
                      .charAt(0)
                      .toUpperCase()}
                  </span>
                </div>
              ),
          },
          { label: "ID", key: "id" },
          {
            label: "Name",
            key: "name",
            render: (row) =>
              `${row.first_name || ""} ${row.last_name || ""}`.trim() ||
              row.name ||
              "-",
          },
          { label: "Username", key: "username" },
          { label: "Email", key: "email" },
          { label: "Phone", key: "phone_number" },
          { label: "Country", key: "country" },
          {
            label: "Verified",
            key: "is_verified",
            render: (row) => (row.is_verified ? "✓ Yes" : "✗ No"),
          },
        ]}
        formFields={[
          { key: "first_name", label: "First Name", required: true },
          { key: "last_name", label: "Last Name", required: true },
          { key: "username", label: "Username", required: true },
          { key: "email", label: "Email", type: "email", required: true },
          {
            key: "password",
            label: "Password",
            type: "password",
            placeholder: "Leave blank to keep current",
          },
          {
            key: "phone_number",
            label: "Phone Number",
            type: "tel",
            placeholder: "07xxxxxxxx",
          },
          { key: "country", label: "Country" },
          { key: "bio", label: "Bio / Notes", type: "textarea" },
          {
            key: "is_verified",
            label: "Verified",
            type: "select",
            options: [
              { value: true, label: "Yes" },
              { value: false, label: "No" },
            ],
            defaultValue: false,
          },
        ]}
        filters={[]}
        crudConfig={{ showExpand: false, showEdit: true, showDelete: true }}
      />

      {isModalOpen && (
        <AddAdminModal
          token={token}
          onClose={() => setIsModalOpen(false)}
          onCreated={() => {
            setIsModalOpen(false);
            setTableRefreshKey((k) => k + 1);
          }}
        />
      )}
    </>
  );
}

/* =======================================================
   Add Admin Modal (search + permissions)
======================================================= */
function AddAdminModal({ token, onClose, onCreated }) {
  const [query, setQuery] = useState("");
  const [results, setResults] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [selected, setSelected] = useState(null);
  const [permissions, setPermissions] = useState(() => getInitialPermissions());
  const [saving, setSaving] = useState(false);

  const resetState = () => {
    setQuery("");
    setResults([]);
    setSelected(null);
    setPermissions(getInitialPermissions());
    setError("");
  };

  const handleSearch = async (e) => {
    e.preventDefault();
    const q = query.trim();
    if (!q) return;

    setError("");
    setLoading(true);

    try {
      const { data } = await API.get("/admUser/search", {
        params: { q },
        headers: token ? { Authorization: `Bearer ${token}` } : {},
      });

      const list =
        (Array.isArray(data) && data) ||
        data?.users ||
        data?.items ||
        data?.results ||
        data?.data ||
        data?.list ||
        [];

      const arr = Array.isArray(list) ? list : [];
      setResults(arr);

      if (!arr.length) {
        setError("No users found for this search.");
      }
    } catch (_) {
      setError(
        "Failed to search users. Please check the /admUser/search endpoint in your backend."
      );
      setResults([]);
    } finally {
      setLoading(false);
    }
  };

  const togglePermission = (key) => {
    setPermissions((prev) => ({ ...prev, [key]: !prev[key] }));
  };

  const handleCreate = async () => {
    if (!selected) return;

    const id = selected.id ?? selected._id ?? selected.user_id;
    if (!id) {
      setError("Selected user does not have id / _id / user_id field.");
      return;
    }

    setSaving(true);
    setError("");

    try {
      await API.put(
        `/admUser/${id}`,
        {
          role_id: 1, // promote to admin
          permissions,
        },
        {
          headers: token ? { Authorization: `Bearer ${token}` } : {},
        }
      );

      resetState();
      if (typeof onCreated === "function") onCreated();
    } catch (_) {
      setError(
        "Failed to promote user to admin. Please check the /admUser/:id endpoint."
      );
    } finally {
      setSaving(false);
    }
  };

  const selectedId = selected
    ? selected.id ?? selected._id ?? selected.user_id
    : null;

  return (
    <div className="fixed inset-0 z-[10000] flex items-center justify-center">
      {/* الخلفية المعتمة – تغطي كل شيء بما فيه الناف بار والسايد بار */}
      <button
        type="button"
        className="absolute inset-0 bg-black/40 backdrop-blur-sm"
        onClick={() => {
          resetState();
          onClose && onClose();
        }}
      />

      {/* صندوق المودال */}
      <div className="relative w-full max-w-5xl rounded-2xl bg-white shadow-2xl border border-slate-200 max-h-[90vh] overflow-hidden flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-slate-200">
          <div>
            <h2 className="text-lg font-semibold text-slate-800 flex items-center gap-2">
              <ShieldCheck className="w-5 h-5 text-[#028090]" />
              <span>Add Admin</span>
            </h2>
            <p className="text-xs text-slate-500 mt-0.5">
              Search an existing account and give it specific permissions.
            </p>
          </div>
          <button
            type="button"
            onClick={() => {
              resetState();
              onClose && onClose();
            }}
            className="w-9 h-9 grid place-items-center rounded-full border border-slate-200 hover:bg-slate-50 text-slate-600"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto px-5 py-4">
          <div className="grid gap-6 md:grid-cols-[1.6fr,1.4fr]">
            {/* Search column */}
            <div className="space-y-3">
              <h3 className="font-medium text-slate-800 text-sm">
                1. Search account
              </h3>

              <form onSubmit={handleSearch} className="flex gap-2">
                <div className="relative flex-1">
                  <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                  <input
                    type="text"
                    value={query}
                    onChange={(e) => setQuery(e.target.value)}
                    placeholder="Name, email or user ID…"
                    className="w-full pl-9 pr-3 py-2.5 rounded-xl border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-[#028090]/40 focus:border-[#028090]"
                  />
                </div>
                <button
                  type="submit"
                  className="px-4 py-2.5 rounded-xl text-sm font-medium text-white bg-[#028090] hover:bg-[#026678] transition"
                >
                  Search
                </button>
              </form>

              {loading && (
                <div className="text-sm text-slate-500 mt-1">
                  Searching users…
                </div>
              )}

              {error && !loading && (
                <div className="text-xs text-rose-600 bg-rose-50 border border-rose-100 rounded-lg px-3 py-2 mt-1">
                  {error}
                </div>
              )}

              <div className="mt-2 space-y-2 max-h-64 overflow-y-auto pr-1">
                {results.map((u) => {
                  const idVal = u.id ?? u._id ?? u.user_id;
                  const name =
                    `${u.first_name || ""} ${u.last_name || ""}`.trim() ||
                    u.name ||
                    u.username ||
                    "User";
                  const email = u.email || u.phone_number || u.phone || "";

                  const isActive = selectedId && selectedId === idVal;

                  return (
                    <button
                      key={idVal}
                      type="button"
                      onClick={() => setSelected(u)}
                      className={`w-full text-left rounded-xl border px-3 py-2.5 text-sm flex items-center justify-between gap-2 transition ${
                        isActive
                          ? "border-[#028090] bg-[#e0f7f9]"
                          : "border-slate-200 hover:bg-slate-50"
                      }`}
                    >
                      <div className="flex items-center gap-3 min-w-0">
                        <div className="w-8 h-8 rounded-full bg-slate-200 flex items-center justify-center text-xs font-semibold text-slate-700">
                          {name.charAt(0).toUpperCase()}
                        </div>
                        <div className="min-w-0">
                          <div className="text-[13px] font-medium text-slate-800 truncate">
                            {name}
                          </div>
                          {email && (
                            <div className="text-[11px] text-slate-500 truncate">
                              {email}
                            </div>
                          )}
                        </div>
                      </div>
                      <div className="text-[11px] text-slate-500 shrink-0">
                        ID: {String(idVal || "").slice(0, 8) || "—"}
                      </div>
                    </button>
                  );
                })}

                {!loading && !results.length && !error && (
                  <div className="text-xs text-slate-500">
                    No results yet. Type a keyword and click Search.
                  </div>
                )}
              </div>
            </div>

            {/* Permissions column */}
            <div className="space-y-3">
              <h3 className="font-medium text-slate-800 text-sm">
                2. Permissions
              </h3>
              {selected ? (
                <div className="rounded-xl border border-slate-200 bg-slate-50 px-3 py-2 text-xs text-slate-700">
                  User{" "}
                  <span className="font-semibold">
                    {`${selected.first_name || ""} ${
                      selected.last_name || ""
                    }`.trim() ||
                      selected.name ||
                      selected.username ||
                      "User"}
                  </span>{" "}
                  will be promoted to admin with the permissions you enable
                  below.
                </div>
              ) : (
                <div className="rounded-xl border border-dashed border-slate-200 px-3 py-2 text-xs text-slate-500">
                  Select a user from the left column first.
                </div>
              )}

              <p className="text-xs text-slate-500">
                Toggle which sections this admin can access. Leave others
                disabled.
              </p>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 mt-2">
                {PERMISSION_DEFS.map((perm) => {
                  const active = !!permissions[perm.key];
                  return (
                    <button
                      key={perm.key}
                      type="button"
                      onClick={() => togglePermission(perm.key)}
                      className={`text-left rounded-xl border text-xs px-3 py-2.5 transition ${
                        active
                          ? "border-[#028090] bg-[#e0f7f9] text-slate-800 shadow-sm"
                          : "border-slate-200 bg-white text-slate-700 hover:border-slate-300"
                      }`}
                    >
                      <div className="flex items-center gap-2">
                        <span
                          className={`w-4 h-4 inline-flex items-center justify-center rounded border text-[10px] ${
                            active
                              ? "border-[#028090] bg-[#028090] text-white"
                              : "border-slate-300 text-transparent"
                          }`}
                        >
                          ✓
                        </span>
                        <span className="font-medium">{perm.label}</span>
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="px-5 py-3 border-t border-slate-200 bg-slate-50 flex items-center justify-between gap-3">
          <div className="text-[11px] text-slate-500">
            When you click{" "}
            <span className="font-semibold">&quot;Add as admin&quot;</span> we
            will send <span className="font-semibold">role_id = 1</span> and a{" "}
            <span className="font-semibold">permissions</span> object to your
            backend.
          </div>
          <div className="flex gap-2">
            <button
              type="button"
              onClick={() => {
                resetState();
                onClose && onClose();
              }}
              className="px-4 py-2.5 rounded-xl border border-slate-300 text-sm text-slate-700 hover:bg-slate-100"
            >
              Cancel
            </button>
            <button
              type="button"
              disabled={!selected || saving}
              onClick={handleCreate}
              className={`px-4 py-2.5 rounded-xl text-sm font-medium text-white transition ${
                !selected || saving
                  ? "bg-slate-400 cursor-not-allowed"
                  : "bg-[#028090] hover:bg-[#026678]"
              }`}
            >
              {saving ? "Saving…" : "Add as admin"}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
