import { useEffect, useMemo, useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import {
  Settings,
  Mail,
  MapPin,
  Phone,
  Star,
} from "lucide-react";
import { useToast } from "../../components/toast/ToastProvider";
import API from "../api/axios";

const THEME = {
  BG: "#F6F7FB",
  CARD_SHADOW: "0 10px 30px rgba(15,23,42,0.06)",
  RING: "rgba(15,23,42,0.10)",
  PRIMARY: "#6366F1",
  PRIMARY_DARK: "#4F46E5",
  MUTED: "#64748B",
};

export default function Profile() {
  const { showToast } = useToast();

  const navigate = useNavigate();
  const { pathname } = useLocation();

  const roleBase = useMemo(() => {
    const seg = (pathname.split("/")[1] || "").toLowerCase();
    return ["admin", "client", "freelancer", "partner"].includes(seg)
      ? `/${seg}`
      : "/admin";
  }, [pathname]);

  const [profile, setProfile] = useState(null);
  const [fetchLoading, setFetchLoading] = useState(true);

  useEffect(() => {
    fetchUserProfile();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const fetchUserProfile = async () => {
    try {
      setFetchLoading(true);
      const res = await API.get("/users/getUserdata");
      const data = res.data;

      if (data?.success && data?.user) {
        setProfile(data.user);
      } else {
        showToast(data?.message || "Failed to load profile", "error");
      }
    } catch (_) {
      showToast("Error loading profile", "error");
    } finally {
      setFetchLoading(false);
    }
  };

  const roleTitle = (role_id) => {
    if (role_id === 1) return "Admin";
    if (role_id === 2) return "Client";
    if (role_id === 3) return "Freelancer";
    return "User";
  };

  const vm = useMemo(() => {
    const p = profile || {};

    const fullName =
      [p.first_name, p.last_name].filter(Boolean).join(" ") ||
      p.username ||
      "—";

    const location = p.country || "—";
    const title = roleTitle(p.role_id);

    const rating5 = Number(p.rating || 0);
    const rating10 = Math.max(0, Math.min(10, rating5 * 2));

    const phone = p.phone_number || "—";
    const email = p.email || "—";
    const address = p.country || "—";
    const site = "—";

    return {
      fullName,
      location,
      title,
      rating10,
      rating5,
      phone,
      email,
      address,
      site,
      birthday: "—",
      gender: "—",
      profilePic: p.profile_pic_url || "",
    };
  }, [profile]);

  const formatRating = (n) => {
    const v = Number.isFinite(n) ? n : 0;
    return v.toFixed(1).replace(".", ",");
  };

  const Card = ({ className = "", children }) => (
    <div
      className={`rounded-[26px] bg-white ${className}`}
      style={{ boxShadow: THEME.CARD_SHADOW }}
    >
      {children}
    </div>
  );

  const SectionTitle = ({ children }) => (
    <p className="text-[11px] font-semibold tracking-[0.18em] uppercase text-slate-400">
      {children}
    </p>
  );

  const StarRow = ({ value5 }) => {
    const v = Math.max(0, Math.min(5, Number(value5 || 0)));
    const full = Math.floor(v);
    const hasHalf = v - full >= 0.5;
    const orangeAccent = "#ea580c"; /* orange-600 */

    return (
      <div className="flex items-center gap-1">
        {Array.from({ length: 5 }).map((_, i) => {
          const isFull = i < full;
          const isHalf = i === full && hasHalf;

          if (isHalf) {
            return (
              <span key={i} className="relative inline-block w-4 h-4">
                <Star
                  className="absolute inset-0 w-4 h-4"
                  style={{ stroke: "#CBD5E1" }}
                />
                <span
                  className="absolute inset-0 overflow-hidden"
                  style={{ width: "50%" }}
                >
                  <Star
                    className="w-4 h-4"
                    style={{
                      stroke: orangeAccent,
                      fill: orangeAccent,
                    }}
                  />
                </span>
              </span>
            );
          }

          return (
            <Star
              key={i}
              className="w-4 h-4"
              style={{
                stroke: isFull ? orangeAccent : "#CBD5E1",
                fill: isFull ? orangeAccent : "transparent",
              }}
            />
          );
        })}
      </div>
    );
  };


  if (fetchLoading) {
    return (
      <div
        className="min-h-[420px] grid place-items-center"
        style={{ background: THEME.BG, color: THEME.MUTED }}
      >
        Loading profile…
      </div>
    );
  }

  return (
    <div className="min-h-screen " style={{ background: THEME.BG }}>
      <div className="mx-auto w-full">
        {/* Hero */}
        <div className="rounded-[26px] overflow-hidden mb-5 sm:mb-6">
          <div className="relative bg-gradient-to-b from-orange-400 to-red-500 px-5 sm:px-6 py-5 sm:py-6 text-white">
            <div className="absolute inset-0 bg-black/10 pointer-events-none" aria-hidden="true" />
            <div className="relative text-[11px] font-semibold tracking-[0.18em] uppercase text-white/85">
              PROFILE
            </div>

            <div className="relative mt-2 flex items-start justify-between gap-4">
              <div className="min-w-0">
                <h1 className="text-[18px] sm:text-2xl font-extrabold leading-tight truncate text-white">
                  {vm.fullName}
                </h1>

                <div className="mt-1 flex items-center gap-2 text-[12px] text-white/85">
                  <MapPin className="w-4 h-4" />
                  <span className="truncate">{vm.location}</span>
                  <span className="opacity-70">•</span>
                  <span className="font-semibold">{vm.title}</span>
                </div>
              </div>
            </div>

            <div className="relative mt-4 flex items-center gap-2">
              <span className="text-[18px] font-extrabold">{formatRating(vm.rating10)}</span>
              <StarRow value5={vm.rating5} />
            </div>
          </div>
        </div>

        {/* Body */}
        <div className="grid grid-cols-1 gap-5 sm:gap-6">
          {/* About Section */}
          <Card className="relative p-4 sm:p-6">
            <button
              type="button"
              onClick={() => navigate(`${roleBase}/editprofile`)}
              className="absolute right-4 top-4 inline-flex h-10 w-10 items-center justify-center rounded-xl border border-slate-200 bg-white shadow-sm hover:bg-slate-50 transition"
              aria-label="Settings"
              title="Settings"
            >
              <Settings className="h-5 w-5 text-slate-700" />
            </button>

            {/* About Content */}
            <div className="pt-6">
              <div className="space-y-7">
                {/* Contact */}
                <div>
                  <SectionTitle>Contact information</SectionTitle>

                  <div className="mt-4 grid grid-cols-1 sm:grid-cols-[160px_1fr] gap-y-3 text-[13px]">
                    <div className="flex items-center gap-2 text-slate-500">
                      <Phone className="w-4 h-4" />
                      Phone:
                    </div>
                    <div className="font-semibold text-slate-900">{vm.phone}</div>

                    <div className="flex items-center gap-2 text-slate-500">
                      <MapPin className="w-4 h-4" />
                      Address:
                    </div>
                    <div className="text-slate-700">{vm.address}</div>

                    <div className="flex items-center gap-2 text-slate-500">
                      <Mail className="w-4 h-4" />
                      E-mail:
                    </div>
                    <div className="font-semibold text-slate-900">{vm.email}</div>
                  </div>
                </div>
              </div>
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
}
