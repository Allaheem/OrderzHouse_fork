import { useEffect, useState } from "react";
import API from "../../api/client.js";

export default function LiveActivity() {
  const primary = "rgb(2, 128, 144)";
  const primaryDark = "rgb(0, 90, 100)";
  const primaryLight = "rgb(0, 170, 180)";

  // REAL DATABASE VALUES
  const [total, setTotal] = useState(0);
  const [processing, setProcessing] = useState(0);
  const [clients, setClients] = useState(0);
  const [freelancers, setFreelancers] = useState(0);

  // For animations
  const [pulseTotal, setPulseTotal] = useState(false);
  const [pulseProcessing, setPulseProcessing] = useState(false);
  const [pulseClients, setPulseClients] = useState(false);
  const [pulseFreelancers, setPulseFreelancers] = useState(false);

  // ========= FETCH REAL DATA FROM DATABASE =========
  const fetchStats = async () => {
    try {
      const res = await API.get("/api/public-stats");
      const data = res.data;

      // Add pulse animation when values update
      setPulseTotal(true);
      setPulseProcessing(true);
      setPulseClients(true);
      setPulseFreelancers(true);

      setTimeout(() => {
        setPulseTotal(false);
        setPulseProcessing(false);
        setPulseClients(false);
        setPulseFreelancers(false);
      }, 250);

      // Set real values
      setTotal(data.totalProjects);
      setProcessing(data.processing);
      setClients(data.clients);
      setFreelancers(data.freelancers);

    } catch (err) {
      console.error("Stats fetch error:", err);
    }
  };

  // Fetch ON LOAD
  useEffect(() => {
    fetchStats();
  }, []);

  // Auto refresh every 45s
  useEffect(() => {
    const interval = setInterval(() => {
      fetchStats();
    }, 45000);

    return () => clearInterval(interval);
  }, []);

  // Format numbers
  const fmt = (n) => n.toLocaleString();

  return (
    <section className="py-6 sm:py-8">
      <div className="max-w-7xl mx-auto">
        <div className="rounded-2xl flex flex-row sm:flex-col items-stretch gap-4 sm:gap-6 justify-between">

<div className="flex flex-wrap gap-4 justify-center sm:flex-nowrap sm:justify-end">

            {/* ==== TOTAL PROJECTS ==== */}
            <div
              className={`rounded-xl bg-white p-4 sm:p-5 min-w-[160px] text-center transition-transform duration-200 ${
                pulseTotal ? "scale-[1.02]" : ""
              }`}
            >
              <div className="text-sm text-slate-500">Total projects</div>
              <div className="mt-2 text-2xl sm:text-3xl font-extrabold"
                style={{ color: primary }}>
                {fmt(total)}
              </div>
            </div>

            {/* ==== PROCESSING ==== */}
            <div
              className={`rounded-xl bg-white ring-1 ring-black/5 p-4 sm:p-5 min-w-[160px] text-center transition-transform duration-200 ${
                pulseProcessing ? "scale-[1.02]" : ""
              }`}
              style={{ boxShadow: `0 1px 6px rgba(2,128,144,0.04)` }}
            >
              <div className="text-sm text-slate-500">Projects in Progress</div>
              <div className="mt-2 text-2xl sm:text-3xl font-extrabold"
                style={{ color: primaryDark }}>
                {fmt(processing)}
              </div>
            </div>

            {/* ==== CLIENTS ==== */}
            <div
              className={`rounded-xl bg-white ring-1 ring-black/5 p-4 sm:p-5 min-w-[160px] text-center transition-transform duration-200 ${
                pulseClients ? "scale-[1.02]" : ""
              }`}
              style={{ boxShadow: `0 1px 6px rgba(2,128,144,0.05)` }}
            >
              <div className="text-sm text-slate-500">Total clients</div>
              <div className="mt-2 text-2xl sm:text-3xl font-extrabold"
                style={{ color: primary }}>
                {fmt(clients)}
              </div>
            </div>

            {/* ==== FREELANCERS ==== */}
            <div
              className={`rounded-xl bg-white ring-1 ring-black/5 p-4 sm:p-5 min-w-[160px] text-center transition-transform duration-200 ${
                pulseFreelancers ? "scale-[1.02]" : ""
              }`}
              style={{ boxShadow: `0 1px 6px rgba(2,128,144,0.04)` }}
            >
              <div className="text-sm text-slate-500">Total freelancers</div>
              <div className="mt-2 text-2xl sm:text-3xl font-extrabold"
                style={{ color: primaryDark }}>
                {fmt(freelancers)}
              </div>
            </div>

          </div>

        </div>
      </div>
    </section>
  );
}
