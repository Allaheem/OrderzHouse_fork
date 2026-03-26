// components/Projects/ProjectCard.jsx
import { Link } from "react-router-dom";
import { useSelector } from "react-redux";
import { safeStringMatch } from "../../utils/safeStringMatch";

export default function ProjectCard({
  project,
  theme = "#F97316",
  linkBase = "projects",
  priceField = "price",
  hasApplied: hasAppliedProp = false,
}) {
  const {
    id,
    title,
    cover_pic,
    cover,
    image,
    offersVideo,
    tags = [],
    offers,
  } = project;

  // Get current user ID to check if they've applied
  const currentUserId = useSelector((state) => state?.auth?.userId) || 
                        (typeof window !== "undefined" ? localStorage.getItem("userId") : null);
  const roleId =
    useSelector((state) => state?.auth?.userData?.role_id) ||
    (typeof window !== "undefined" ? Number(localStorage.getItem("roleId") || 0) : 0);
  const isStaff = Number(roleId) === 1;
  
  // Check if current user has applied to this project
  const hasApplied = (() => {
    // Use prop from parent (preferred - most reliable)
    if (hasAppliedProp === true) {
      return true;
    }
    
    // Check explicit fields
    if (project?.has_applied === true || project?.is_applied === true || project?.hasApplied === true) {
      return true;
    }
    
    // Check if user has an offer in the offers array
    if (currentUserId && Array.isArray(offers) && offers.length > 0) {
      return offers.some(offer => {
        const offerUserId = offer?.freelancer_id || offer?.user_id || offer?.userId;
        return String(offerUserId) === String(currentUserId);
      });
    }
    
    return false;
  })();


  const to = `/${linkBase}/${id}`;
  const isRotatedDemo =
    project?.is_rotated_demo === true ||
    project?.source_type === "tender_vault" ||
    project?.is_actionable === false ||
    (typeof id === "string" && (String(id).startsWith("TVX-") || String(id).startsWith("TV-")));
 const projectType = (project?.project_type ?? project?.type ?? "").toLowerCase();

const toNumber = (v) => {
  if (v === null || v === undefined || v === "") return null;
  if (typeof v === "number") return Number.isFinite(v) ? v : null;
  if (typeof v === "string") {
    const m = safeStringMatch(v, /(\d+(\.\d+)?)/);
    return m ? Number(m[1]) : null;
  }
  return null;
};

// ✅ نحاول نلتقط min/max من أي اسم محتمل في الداتا
const minBid =
  toNumber(project?.min_budget) ??
  toNumber(project?.min_price) ??
  toNumber(project?.budget_min) ??
  toNumber(project?.bidding_min) ??
  toNumber(project?.min_bid) ??
  toNumber(project?.min_bid_amount);

const maxBid =
  toNumber(project?.max_budget) ??
  toNumber(project?.max_price) ??
  toNumber(project?.budget_max) ??
  toNumber(project?.bidding_max) ??
  toNumber(project?.max_bid) ??
  toNumber(project?.max_bid_amount);

// Get price values based on project type
const fixedPrice = toNumber(
  project?.budget ??
  project?.price ??
  project?.amount ??
  project?.[priceField]
);

const hourlyRate = toNumber(project?.hourly_rate);

// ✅ label + value based on project_type
let priceLabel = "Price";
let displayPrice = "Price not available";

if (projectType === "fixed") {
  priceLabel = "Price";
  if (fixedPrice !== null) {
    displayPrice = `${fixedPrice} JD`;
  }
} else if (projectType === "hourly") {
  priceLabel = "Price";
  if (hourlyRate !== null) {
    displayPrice = `${hourlyRate} JD`;
  }
} else if (projectType === "bidding") {
  priceLabel = "Bidding";
  if (minBid !== null && maxBid !== null) {
    displayPrice = `(${minBid} JD - ${maxBid} JD)`;
  } else if (minBid !== null) {
    displayPrice = `(${minBid} JD - ${maxBid ?? minBid} JD)`;
  } else if (maxBid !== null) {
    displayPrice = `(${minBid ?? maxBid} JD - ${maxBid} JD)`;
  }
} else {
  // Fallback for unknown types or missing project_type
  if (fixedPrice !== null) {
    displayPrice = `${fixedPrice} JD`;
  } else if (hourlyRate !== null) {
    displayPrice = `${hourlyRate} JD`;
  }
}

  const firstAttachment =
    Array.isArray(project.attachments) && project.attachments.length > 0
      ? project.attachments[0]
      : null;

  const attachmentCoverUrl = (() => {
    if (!firstAttachment) return null;
    if (typeof firstAttachment === "string") return firstAttachment;
    if (typeof firstAttachment === "object") {
      return (
        firstAttachment.url ||
        firstAttachment.path ||
        firstAttachment.file_url ||
        null
      );
    }
    return null;
  })();

  const coverSrc =
    cover_pic ||
    cover ||
    image ||
    attachmentCoverUrl ||
    "/placeholder.svg?height=200&width=320";

  let offerBlock = null;
  if (!linkBase.startsWith("tasks") && Array.isArray(offers) && offers.length) {
    const offer = offers[0];
    const freelancer = offer?.freelancer || {};
    offerBlock = (
      <div className="mt-2 p-2 rounded-lg border border-orange-200 bg-orange-50 flex flex-col gap-1">
        <div className="text-xs font-semibold text-orange-700">
          Offer Submitted
        </div>
        <div className="flex flex-wrap gap-2 text-xs text-slate-700">
          <span>
            Value:{" "}
            <span className="font-bold">{offer?.bid_amount != null ? `${offer.bid_amount} JD` : "—"}</span>
          </span>
          <span>
            Rating:{" "}
            <span className="font-bold">{freelancer?.rating ?? "—"}</span>
          </span>
          <span>
            Completed Jobs:{" "}
            <span className="font-bold">
              {freelancer?.completed_jobs ?? "—"}
            </span>
          </span>
          <span>
            Avg. Delivery:{" "}
            <span className="font-bold">
              {freelancer?.avg_delivery_time ?? "—"}
            </span>
          </span>
        </div>
      </div>
    );
  }

  return (
    <article className="group relative">
      <Link to={to} state={{ project }} className="block" title={title}>
        <div className="aspect-[16/9] w-full bg-slate-100 overflow-hidden rounded-xl relative">
          <img
            src={coverSrc}
            alt={title}
            className="w-full h-full object-cover group-hover:scale-[1.02] transition-transform duration-500"
          />
          {isRotatedDemo && isStaff && (
            <div className="absolute top-2 right-2 z-10 px-2 py-1 rounded text-[10px] font-medium bg-slate-900/70 text-white">
              Internal: Tender Vault
            </div>
          )}
          {hasApplied && (
            <div 
              className="absolute inset-0 z-20 pointer-events-none overflow-hidden"
            >
              <div
                className="absolute top-[20px] left-[-30%] right-[-30%] rotate-[-12deg] px-8 py-2 text-white font-bold text-xs sm:text-sm tracking-wider uppercase shadow-xl whitespace-nowrap text-center"
                style={{
                  background: "linear-gradient(135deg, rgba(249, 115, 22, 0.95) 0%, rgba(220, 38, 38, 0.95) 100%)",
                  textShadow: "2px 2px 4px rgba(0, 0, 0, 0.9)",
                  letterSpacing: "2px",
                  borderTop: "3px solid rgba(255, 255, 255, 0.4)",
                  borderBottom: "3px solid rgba(255, 255, 255, 0.4)",
                }}
              >
                Already Applied
              </div>
            </div>
          )}
        </div>
      </Link>

      <div className="p-3 px-1">
        <h3
          className="mt-1 text-[15px] text-slate-800 line-clamp-2"
          title={title}
        >
          <Link to={to} state={{ project }} className="hover:underline">
            {title}
          </Link>
        </h3>

        <div className="mt-2 flex items-center justify-between text-sm">
         <span className="text-slate-500">{priceLabel}</span>

          <span className="font-semibold text-slate-900">{displayPrice}</span>
        </div>

        {offerBlock}

        {offersVideo && !linkBase.startsWith("tasks") && (
          <div className="mt-2 flex items-center gap-1.5 text-xs text-slate-700">
            🎥 Offers video consultations
          </div>
        )}

        {tags.length > 0 && (
          <div className="mt-1 flex flex-wrap gap-1">
            {tags.slice(0, 5).map((t) => (
              <span
                key={t}
                className="text-[10px] px-2 py-0.5 rounded-full bg-black/65 text-white"
              >
                {t}
              </span>
            ))}
          </div>
        )}
      </div>
    </article>
  );
}
