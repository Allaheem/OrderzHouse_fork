import { useState } from "react";
import { Mail, Phone, MapPin } from "lucide-react";
import emailjs from "@emailjs/browser";

import GradientButton from "../buttons/GradientButton.jsx";

export default function ContactUsPage() {
  const [formData, setFormData] = useState({
    name: "",
    email: "",
    phone: "",
    subject: "",
    message: "",
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitStatus, setSubmitStatus] = useState(null);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({
      ...prev,
      [name]: value,
    }));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    setIsSubmitting(true);
    setSubmitStatus(null);

    const serviceID = import.meta.env.VITE_EMAILJS_SERVICE_ID;
    const templateID = import.meta.env.VITE_EMAILJS_TEMPLATE_ID;
    const publicKey = import.meta.env.VITE_EMAILJS_PUBLIC_KEY;

    const templateParams = {
      from_name: formData.name,
      from_email: formData.email,
      phone_number: formData.phone,
      subject: formData.subject,
      message: formData.message,
    };

    emailjs
      .send(serviceID, templateID, templateParams, publicKey)
      .then(() => {
        setSubmitStatus("success");
        setFormData({ name: "", email: "", phone: "", subject: "", message: "" });
      })
      .catch(() => {
        setSubmitStatus("error");
      })
      .finally(() => {
        setIsSubmitting(false);
      });
  };

  return (
    <div className="relative min-h-screen overflow-hidden bg-white">
    <div className="pointer-events-none absolute -top-28 left-[-80px] h-[360px] w-[360px] rounded-full bg-yellow-300/25 blur-3xl" />
          <div className="pointer-events-none absolute -top-28 right-[-90px] h-[380px] w-[380px] rounded-full bg-orange-400/20 blur-3xl" />
          {/* Glow خفيف تحت عشان الامتداد السفلي */}
      <div className="relative z-10 pt-16">
        <section className="py-16 text-center">
          <h1 className="text-5xl font-bold mb-4 text-slate-900" style={{ fontFamily: "'Merriweather', serif" }}>
            Get in <span className="bg-gradient-to-r from-orange-600 via-amber-500 to-orange-600 bg-clip-text text-transparent">Touch</span>
          </h1>
          <p
            className="text-slate-600 max-w-xl mx-auto"
            style={{ fontFamily: "'Merriweather', serif" }}
          >
            Have questions or need assistance? We're here to help you with anything you need.
          </p>
        </section>

        <section className="pb-20">
          <div className="max-w-7xl mx-auto px-6 grid grid-cols-1 xl:grid-cols-3 gap-12">
            {/* Info */}
            <div className="bg-white/80 backdrop-blur-sm rounded-2xl p-8 shadow-[0_25px_70px_rgba(15,23,42,0.08)] border border-orange-100/60">
              <h2 className="text-2xl font-bold mb-8 text-slate-800" style={{ fontFamily: "'Merriweather', serif" }}>
                Contact Information
              </h2>

              <div className="space-y-6">
                <div className="flex items-start">
                  <div className="flex-shrink-0 w-12 h-12 rounded-xl flex items-center justify-center mr-4 bg-gradient-to-br from-orange-500 to-rose-500 shadow-[0_12px_30px_rgba(249,115,22,0.25)]">
                    <Phone className="w-5 h-5 text-white" />
                  </div>
                  <div>
                    <h3 className="font-bold text-slate-800 mb-2">Phone Number</h3>
                    <p className="text-slate-600">+962 791 433 341</p>
                  </div>
                </div>

                <div className="flex items-start">
                  <div className="flex-shrink-0 w-12 h-12 rounded-xl flex items-center justify-center mr-4 bg-gradient-to-br from-violet-500 to-indigo-600 shadow-[0_12px_30px_rgba(99,102,241,0.20)]">
                    <Mail className="w-5 h-5 text-white" />
                  </div>
                  <div>
                    <h3 className="font-bold text-slate-800 mb-2">Email Address</h3>
                    <p className="text-slate-600">info@battechno.com</p>
                  </div>
                </div>

                <div className="flex items-start">
                  <div className="flex-shrink-0 w-12 h-12 rounded-xl flex items-center justify-center mr-4 bg-gradient-to-br from-amber-400 to-orange-600 shadow-[0_12px_30px_rgba(245,158,11,0.18)]">
                    <MapPin className="w-5 h-5 text-white" />
                  </div>
                  <div>
                    <h3 className="font-bold text-slate-800 mb-2">Office Location</h3>
                    <p className="text-slate-600">Amman, Madinah Street</p>
                    <p className="text-slate-600">Al-Basem Complex 2, Office 405</p>
                  </div>
                </div>
              </div>
            </div>

            {/* Contact Form */}
            <div className="xl:col-span-2 bg-white/80 backdrop-blur-sm rounded-2xl p-8 shadow-[0_25px_70px_rgba(15,23,42,0.08)] border border-orange-100/60">
              <h2 className="text-2xl font-bold mb-8 text-slate-800" style={{ fontFamily: "'Merriweather', serif" }}>
                Send us a Message
              </h2>

              {submitStatus === "success" && (
                <div className="mb-6 p-4 bg-emerald-50 text-emerald-800 rounded-xl border border-emerald-200">
                  Your message has been sent successfully!
                </div>
              )}
              {submitStatus === "error" && (
                <div className="mb-6 p-4 bg-rose-50 text-rose-800 rounded-xl border border-rose-200">
                  Something went wrong. Please try again.
                </div>
              )}

              <form onSubmit={handleSubmit} className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <input
                    type="text"
                    name="name"
                    value={formData.name}
                    onChange={handleChange}
                    required
                    placeholder="Full Name *"
                    className="w-full px-4 py-3 rounded-xl bg-white/90 border border-slate-200
                               focus:ring-2 focus:ring-orange-300/70 focus:border-orange-300 focus:outline-none"
                  />
                  <input
                    type="email"
                    name="email"
                    value={formData.email}
                    onChange={handleChange}
                    required
                    placeholder="Email Address *"
                    className="w-full px-4 py-3 rounded-xl bg-white/90 border border-slate-200
                               focus:ring-2 focus:ring-indigo-300/60 focus:border-indigo-300 focus:outline-none"
                  />
                </div>

                <input
                  type="text"
                  name="phone"
                  value={formData.phone}
                  onChange={handleChange}
                  placeholder="Phone Number"
                  className="w-full px-4 py-3 rounded-xl bg-white/90 border border-slate-200
                             focus:ring-2 focus:ring-orange-300/70 focus:border-orange-300 focus:outline-none"
                />

                <select
                  name="subject"
                  value={formData.subject}
                  onChange={handleChange}
                  required
                  className="w-full px-4 py-3 rounded-xl bg-white/90 border border-slate-200
                             focus:ring-2 focus:ring-orange-300/70 focus:border-orange-300 focus:outline-none"
                >
                  <option value="">Select a subject *</option>
                  <option value="general">General Inquiry</option>
                  <option value="support">Technical Support</option>
                  <option value="partnership">Partnership</option>
                  <option value="feedback">Feedback</option>
                </select>

                <textarea
                  name="message"
                  value={formData.message}
                  onChange={handleChange}
                  required
                  rows="4"
                  placeholder="Your Message *"
                  className="w-full px-4 py-3 rounded-xl bg-white/90 border border-slate-200
                             focus:ring-2 focus:ring-indigo-300/60 focus:border-indigo-300 focus:outline-none"
                />

                {/* Keep your existing button component (no logic changes) */}
                <GradientButton
                  type="submit"
                  className="w-full md:w-auto px-6 py-3 font-semibold"
                  disabled={isSubmitting}
                >
                  {isSubmitting ? "Sending..." : "Send Message"}
                </GradientButton>

                
              </form>
            </div>
          </div>
        </section>
      </div>
    </div>
  );
}
