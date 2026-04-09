import { useState, useEffect, useMemo } from "react";
import { Link, useNavigate } from "react-router-dom";
import { useSelector } from "react-redux";
import API from "../../api/client.js";
import { io } from "socket.io-client";
import toast, { Toaster } from "react-hot-toast";
import {
  Bell,
  CheckCircle,
  CheckCircle2,
  Filter,
  Search,
  Trash2,
  Clock,
  AlertCircle,
  Star,
  ArrowLeft,
  Volume2,
  VolumeX,
} from "lucide-react";

export default function NotificationsPage() {
  const [notifications, setNotifications] = useState([]);
  const [filteredNotifications, setFilteredNotifications] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [filter, setFilter] = useState("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedNotifications, setSelectedNotifications] = useState(new Set());
  const [selectAll, setSelectAll] = useState(false);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [mute, setMute] = useState(false);

  const { token } = useSelector((state) => ({
    token: state.auth.token,
  }));

  const navigate = useNavigate();
  // ✅ Theme accents (مثل ContactUs)
  const ORANGE_GRAD = "from-orange-500 to-rose-500";
  const VIOLET_GRAD = "from-violet-500 to-indigo-600";
  const AMBER_GRAD = "from-amber-400 to-orange-600";

  // ✅ Route resolver (بدون تشات)
  const getNotificationRoute = (n) => {
    const id = n.related_entity_id;

    // حسب entity_type
    switch (n.entity_type) {
      case "project":
        return `/projects/${id}`;

      case "task":
        return `/tasks/${id}`;

      case "offer":
        return `/offers/${id}`; // عدّلها حسب صفحاتك

      case "escrow":
        return `/escrow/${id}`; // عدّلها حسب صفحاتك

      case "review":
        return `/profile`; // أو صفحة reviews

      case "system":
        return `/notifications`;

      default:
        break;
    }

    // fallback حسب type
    switch (n.type) {
      case "project_created":
      case "project_status_changed":
      case "work_submitted":
      case "work_approved":
      case "work_revision_requested":
        return `/projects/${id}`;

      case "offer_submitted":
      case "offer_approved":
      case "offer_rejected":
        return `/offers/${id}`;

      case "review_submitted":
        return `/profile`;

      default:
        return null;
    }
  };

  // Socket setup for live notifications
  useEffect(() => {
    if (!token) return;
    const socket = io(API.defaults.baseURL || "http://localhost:5050", {
      auth: { token },
      transports: ["websocket"],
    });

    socket.on("notification:new", (data) => {
      setNotifications((prev) => [data, ...prev]);
      setFilteredNotifications((prev) => [data, ...prev]);
      if (!mute) {
        const audio = new Audio("/sounds/notification.mp3");
        audio.play();
        toast.success(data.message, {
          icon: "🔔",
          duration: 4000,
        });
      }
    });

    return () => socket.disconnect();
  }, [token, mute]);

  // Fetch notifications
  const fetchNotifications = async () => {
    if (!token) {
      setError("Please login to view notifications");
      setLoading(false);
      return;
    }

    try {
      setLoading(true);
      const response = await API.get("/notifications", {
        headers: { authorization: `Bearer ${token}` },
        params: { limit: 100, offset: 0, unreadOnly: false },
      });

      if (response.data.success) {
        setNotifications(response.data.notifications);
        setFilteredNotifications(response.data.notifications);
      }
    } catch (error) {
      console.error("Error fetching notifications:", error);
      setError("Failed to load notifications");
    } finally {
      setLoading(false);
    }
  };

  // Mark as read
  const markAsRead = async (id) => {
    try {
      await API.put(
        `/notifications/${id}/read`,
        {},
        {
          headers: { authorization: `Bearer ${token}` },
        }
      );
      setNotifications((prev) =>
        prev.map((n) => (n.id === id ? { ...n, read_status: true } : n))
      );
    } catch (err) {
      console.error("Error marking notification as read:", err);
    }
  };

  // Mark all as read
  const markAllAsRead = async () => {
    try {
      await API.put(
        "/notifications/read-all",
        {},
        {
          headers: { authorization: `Bearer ${token}` },
        }
      );
      setNotifications((prev) => prev.map((n) => ({ ...n, read_status: true })));
    } catch (err) {
      console.error("Error marking all as read:", err);
    }
  };

  // Delete single notification
  const deleteNotification = async (id) => {
    try {
      await API.delete(`/notifications/${id}`, {
        headers: { authorization: `Bearer ${token}` },
      });
      setNotifications((prev) => prev.filter((n) => n.id !== id));
      setSelectedNotifications((prev) => {
        const newSet = new Set(prev);
        newSet.delete(id);
        return newSet;
      });
    } catch (err) {
      console.error("Error deleting notification:", err);
    }
  };

  // Delete selected notifications
  const deleteSelectedNotifications = async () => {
    try {
      await Promise.all(
        Array.from(selectedNotifications).map((id) =>
          API.delete(`/notifications/${id}`, {
            headers: { authorization: `Bearer ${token}` },
          })
        )
      );
      setNotifications((prev) =>
        prev.filter((n) => !selectedNotifications.has(n.id))
      );
      setSelectedNotifications(new Set());
      setSelectAll(false);
      setShowDeleteConfirm(false);
    } catch (err) {
      console.error("Error deleting notifications:", err);
    }
  };

  // Filter and search logic
  useEffect(() => {
    let filtered = notifications;
    if (filter === "unread") filtered = filtered.filter((n) => !n.read_status);
    if (filter === "read") filtered = filtered.filter((n) => n.read_status);
    if (searchQuery) {
      const query = searchQuery.toLowerCase();
      filtered = filtered.filter(
        (n) =>
          n.message?.toLowerCase().includes(query) ||
          n.type?.toLowerCase().includes(query)
      );
    }
    setFilteredNotifications(filtered);
  }, [notifications, filter, searchQuery]);

  useEffect(() => {
    fetchNotifications();
  }, [token]);

  const toggleSelection = (id) => {
    setSelectedNotifications((prev) => {
      const newSet = new Set(prev);
      newSet.has(id) ? newSet.delete(id) : newSet.add(id);
      return newSet;
    });
  };

  const toggleSelectAll = () => {
    if (selectAll) {
      setSelectedNotifications(new Set());
    } else {
      setSelectedNotifications(new Set(filteredNotifications.map((n) => n.id)));
    }
    setSelectAll(!selectAll);
  };

  const getNotificationIcon = (type) => {
    switch (type) {
      case "project_created":
        return (
          <div
            className={`w-11 h-11 rounded-xl flex items-center justify-center bg-gradient-to-br ${VIOLET_GRAD} shadow-[0_12px_30px_rgba(99,102,241,0.20)]`}
          >
            <CheckCircle2 className="h-5 w-5 text-white" />
          </div>
        );

      case "review_submitted":
        return (
          <div
            className={`w-11 h-11 rounded-xl flex items-center justify-center bg-gradient-to-br ${AMBER_GRAD} shadow-[0_12px_30px_rgba(245,158,11,0.18)]`}
          >
            <Star className="h-5 w-5 text-white" />
          </div>
        );

      case "work_submitted":
        return (
          <div
            className={`w-11 h-11 rounded-xl flex items-center justify-center bg-gradient-to-br ${ORANGE_GRAD} shadow-[0_12px_30px_rgba(249,115,22,0.25)]`}
          >
            <CheckCircle2 className="h-5 w-5 text-white" />
          </div>
        );

      default:
        return (
          <div className="w-11 h-11 rounded-xl flex items-center justify-center bg-slate-100 border border-slate-200">
            <Bell className="h-5 w-5 text-slate-500" />
          </div>
        );
    }
  };

  const formatDate = (dateString) => {
    const date = new Date(dateString);
    const now = new Date();
    const diff = Math.abs(now - date);
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));

    if (days === 0)
      return `Today at ${date.toLocaleTimeString([], {
        hour: "2-digit",
        minute: "2-digit",
      })}`;
    if (days === 1)
      return `Yesterday at ${date.toLocaleTimeString([], {
        hour: "2-digit",
        minute: "2-digit",
      })}`;
    if (days < 7) return `${days} days ago`;
    return date.toLocaleDateString();
  };

  // Group by date
  const groupedNotifications = useMemo(() => {
    return filteredNotifications.reduce((groups, n) => {
      const date = new Date(n.created_at).toDateString();
      if (!groups[date]) groups[date] = [];
      groups[date].push(n);
      return groups;
    }, {});
  }, [filteredNotifications]);

  if (!token) {
    return (
      <div className="relative min-h-screen overflow-hidden bg-white pt-24 md:pt-28">
        <div className="pointer-events-none absolute -top-28 left-[-80px] h-[360px] w-[360px] rounded-full bg-yellow-300/25 blur-3xl" />
        <div className="pointer-events-none absolute -top-28 right-[-90px] h-[380px] w-[380px] rounded-full bg-orange-400/20 blur-3xl" />

        <div className="relative z-10 min-h-screen flex items-center justify-center px-4">
          <div className="max-w-md w-full bg-white/80 backdrop-blur-sm rounded-2xl shadow-[0_25px_70px_rgba(15,23,42,0.08)] border border-orange-100/60 p-8 text-center">
            <div className="mx-auto mb-4 w-14 h-14 rounded-2xl flex items-center justify-center bg-gradient-to-br from-violet-500 to-indigo-600 shadow-[0_12px_30px_rgba(99,102,241,0.20)]">
              <Bell className="h-7 w-7 text-white" />
            </div>
            <h2
              className="text-2xl font-bold text-slate-900 mb-2"
              style={{ fontFamily: "'Merriweather', serif" }}
            >
              Sign In Required
            </h2>
            <p className="text-slate-600 mb-6">
              Please sign in to view your notifications
            </p>
            <Link
              to="/login"
              className="inline-flex items-center justify-center w-full px-6 py-3 rounded-xl font-semibold text-white bg-gradient-to-br from-orange-500 to-rose-500 hover:brightness-110 active:scale-[0.98] transition"
            >
              Sign In
            </Link>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="relative min-h-screen overflow-hidden bg-white pt-24 md:pt-28">
      <Toaster position="top-right" />

      {/* Background glow مثل ContactUs */}
      <div className="pointer-events-none absolute -top-28 left-[-80px] h-[360px] w-[360px] rounded-full bg-yellow-300/25 blur-3xl" />
      <div className="pointer-events-none absolute -top-28 right-[-90px] h-[380px] w-[380px] rounded-full bg-orange-400/20 blur-3xl" />

      <div className="relative z-10 pt-10">
        {/* Header */}
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="bg-white/80 backdrop-blur-sm rounded-2xl shadow-[0_25px_70px_rgba(15,23,42,0.08)] border border-orange-100/60 p-6 flex items-center justify-between">
            <div className="flex items-center gap-3">
              <button
                onClick={() => navigate(-1)}
                className="p-2 rounded-xl hover:bg-slate-50 transition border border-slate-200"
              >
                <ArrowLeft className="h-5 w-5 text-slate-700" />
              </button>

              <div>
                <h1
                  className="text-2xl font-bold text-slate-900 flex items-center gap-2"
                  style={{ fontFamily: "'Merriweather', serif" }}
                >
                  Notifications
                  {notifications.some((n) => !n.read_status) && (
                    <span className="w-2 h-2 bg-orange-500 rounded-full animate-pulse"></span>
                  )}
                </h1>
                <p className="text-sm text-slate-600">
                  Keep track of everything happening in your account.
                </p>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <button
                onClick={() => setMute(!mute)}
                className={`p-2 rounded-xl transition border ${
                  mute
                    ? "bg-white/80 border-slate-200 text-slate-700 hover:bg-slate-50"
                    : "text-white border-transparent bg-gradient-to-br from-orange-500 to-rose-500 hover:brightness-110"
                }`}
                title={mute ? "Unmute" : "Mute notifications"}
              >
                {mute ? (
                  <VolumeX className="h-5 w-5" />
                ) : (
                  <Volume2 className="h-5 w-5" />
                )}
              </button>

              {selectedNotifications.size > 0 && (
                <>
                  <button
                    onClick={() => setShowDeleteConfirm(true)}
                    className="p-2 text-rose-600 hover:bg-rose-50 rounded-xl transition border border-rose-200"
                    title="Delete selected"
                  >
                    <Trash2 className="h-5 w-5" />
                  </button>
                  <span className="text-sm text-slate-600">
                    {selectedNotifications.size} selected
                  </span>
                </>
              )}

              <button
                onClick={markAllAsRead}
                className="px-4 py-2 rounded-xl font-semibold text-white bg-gradient-to-br from-violet-500 to-indigo-600 hover:brightness-110 active:scale-[0.98] transition"
              >
                Mark all as read
              </button>
            </div>
          </div>
        </div>

        {/* Main */}
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          {/* Filters */}
          <div className="bg-white/80 backdrop-blur-sm rounded-2xl shadow-[0_25px_70px_rgba(15,23,42,0.08)] border border-orange-100/60 p-6 mb-6 flex flex-col sm:flex-row justify-between gap-4">
            <div className="flex items-center gap-4">
              <button
                onClick={toggleSelectAll}
                className="px-4 py-2 rounded-xl border border-slate-200 text-slate-700 hover:bg-slate-50 transition font-semibold"
              >
                {selectAll ? "Unselect all" : "Select all"}
              </button>

              <div className="relative">
                <Filter className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
                <select
                  value={filter}
                  onChange={(e) => setFilter(e.target.value)}
                  className="pl-10 pr-8 py-2 border border-slate-200 rounded-xl bg-white/90
                             focus:ring-2 focus:ring-orange-300/70 focus:border-orange-300 focus:outline-none"
                >
                  <option value="all">All notifications</option>
                  <option value="unread">Unread</option>
                  <option value="read">Read</option>
                </select>
              </div>

              <div className="hidden sm:block text-sm text-slate-600">
                {filteredNotifications.length} of {notifications.length} total
              </div>
            </div>

            <div className="relative sm:max-w-xs w-full">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-slate-400" />
              <input
                type="text"
                placeholder="Search notifications..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-slate-200 rounded-xl bg-white/90
                           focus:ring-2 focus:ring-indigo-300/60 focus:border-indigo-300 focus:outline-none"
              />
            </div>
          </div>

          {/* Notifications List */}
          <div className="bg-white/80 backdrop-blur-sm rounded-2xl shadow-[0_25px_70px_rgba(15,23,42,0.08)] border border-orange-100/60 overflow-hidden">
            {loading ? (
              <div className="p-12 text-center">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-orange-500 mx-auto"></div>
                <p className="mt-4 text-slate-600">Loading notifications...</p>
              </div>
            ) : error ? (
              <div className="p-12 text-center">
                <div className="mx-auto mb-4 w-14 h-14 rounded-2xl flex items-center justify-center bg-rose-100 border border-rose-200">
                  <AlertCircle className="h-7 w-7 text-rose-600" />
                </div>
                <p className="text-slate-600 mb-4">{error}</p>
                <button
                  onClick={fetchNotifications}
                  className="px-4 py-2 rounded-xl font-semibold text-white bg-gradient-to-br from-orange-500 to-rose-500 hover:brightness-110 active:scale-[0.98] transition"
                >
                  Try Again
                </button>
              </div>
            ) : Object.keys(groupedNotifications).length === 0 ? (
              <div className="p-12 text-center">
                <div className="mx-auto mb-4 w-14 h-14 rounded-2xl flex items-center justify-center bg-slate-100 border border-slate-200">
                  <Bell className="h-7 w-7 text-slate-500" />
                </div>
                <h3 className="text-lg font-semibold text-slate-900 mb-2">
                  No notifications yet
                </h3>
                <p className="text-slate-600">
                  You’ll see updates here when they arrive
                </p>
              </div>
            ) : (
              Object.entries(groupedNotifications).map(([date, group]) => (
                <div key={date}>
                  <div className="px-6 py-3 bg-white/60 border-b border-orange-100/60">
                    <h3 className="text-sm font-semibold text-slate-600">
                      {date}
                    </h3>
                  </div>

                  {group.map((n) => (
                    <div
                      key={n.id}
                      onClick={async () => {
                        const route = getNotificationRoute(n);
                        if (!n.read_status) await markAsRead(n.id);
                        if (route) navigate(route);
                      }}
                      className={`px-6 py-5 cursor-pointer transition-colors border-b border-orange-100/60 ${
                        !n.read_status
                          ? "bg-orange-50/60 hover:bg-orange-50"
                          : "hover:bg-slate-50/60"
                      }`}
                    >
                      <div className="flex items-start gap-4">
                        <input
                          type="checkbox"
                          checked={selectedNotifications.has(n.id)}
                          onChange={() => toggleSelection(n.id)}
                          onClick={(e) => e.stopPropagation()}
                          className="h-4 w-4 text-orange-500 border-slate-300 focus:ring-orange-400 mt-1"
                        />

                        <div className="flex-shrink-0">
                          {getNotificationIcon(n.type)}
                        </div>

                        <div className="flex-1">
                          <p className="text-slate-800 line-clamp-2 font-medium">
                            {n.message}
                          </p>
                          <div className="flex items-center text-sm text-slate-500 mt-2">
                            <Clock className="h-4 w-4 mr-1" />
                            <span>{formatDate(n.created_at)}</span>
                          </div>
                        </div>

                        <div className="flex gap-2 ml-4">
                          {!n.read_status && (
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                markAsRead(n.id);
                              }}
                              className="p-2 rounded-xl border border-slate-200 text-slate-700 hover:bg-slate-50 transition"
                              title="Mark as read"
                            >
                              <CheckCircle className="h-4 w-4" />
                            </button>
                          )}
                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              deleteNotification(n.id);
                            }}
                            className="p-2 rounded-xl border border-rose-200 text-rose-600 hover:bg-rose-50 transition"
                            title="Delete"
                          >
                            <Trash2 className="h-4 w-4" />
                          </button>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              ))
            )}
          </div>
        </div>
      </div>

      {/* Delete Confirmation */}
      {showDeleteConfirm && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl p-6 max-w-md w-full shadow-[0_25px_70px_rgba(15,23,42,0.18)] border border-orange-100/60">
            <h3 className="text-lg font-bold text-slate-900 mb-3">
              Delete Notifications
            </h3>
            <p className="text-slate-600 mb-6">
              Are you sure you want to delete {selectedNotifications.size} selected
              notification(s)? This action cannot be undone.
            </p>
            <div className="flex justify-end gap-3">
              <button
                onClick={() => setShowDeleteConfirm(false)}
                className="px-4 py-2 text-slate-700 border border-slate-200 rounded-xl hover:bg-slate-50 transition font-semibold"
              >
                Cancel
              </button>
              <button
                onClick={deleteSelectedNotifications}
                className="px-4 py-2 rounded-xl font-semibold text-white bg-gradient-to-br from-rose-500 to-orange-500 hover:brightness-110 active:scale-[0.98] transition"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}