// CreateProjectPage.jsx
import React, { useState } from "react";
import { useSelector } from "react-redux";
import { useNavigate } from "react-router-dom";
import { useToast } from "../../components/toast/ToastProvider";

import ProjectDetailsStep from "./steps/ProjectDetailsStep";
import ProjectFilesStep from "./steps/ProjectFilesStep";
import PaymentStep from "./steps/PaymentStep";
import ProjectCoverStep from "./steps/ProjectCoverStep";
import DevelopmentNoticeModal from "./steps/popUp";

import {
  createProjectApi,
  uploadProjectFilesApi,
  createProjectCheckoutSessionApi,
} from "./api/projects";
import API from "../../api/client.js";
import PageMeta from "../PageMeta.jsx";

const DEVELOPMENT_CATEGORY_ID = 3;

export default function CreateProjectPage() {
  const token = useSelector((state) => state.auth.token);
  const userData = useSelector((state) => state.auth.userData);
  const navigate = useNavigate();
  const { showToast } = useToast();

  const [step, setStep] = useState(1);
  const [coverPic, setCoverPic] = useState(null);
  const [projectData, setProjectData] = useState({});
  const [files, setFiles] = useState([]);
  const [isSubmitting, setIsSubmitting] = useState(false);

  const [showDevPopup, setShowDevPopup] = useState(false);

  const nextStep = () => setStep((p) => p + 1);
  const prevStep = () => setStep((p) => p - 1);

  const handleFinalSubmit = async () => {
    // Prevent duplicate submissions
    if (isSubmitting) {
      return;
    }

    if (!token) {
      showToast("You must be logged in", "error");
      return;
    }

    setIsSubmitting(true);

    try {
      // ============================
      // 1️⃣ BIDDING PROJECT → CREATE IMMEDIATELY (SKIP PAYMENT)
      // ============================
      if (projectData.project_type === "bidding") {
        // Bidding projects are created directly with status "bidding" and go to the pool
        // No payment step required
        const project = await createProjectApi(projectData, token);
        const projectId = project.id;

        if (files.length > 0) {
          await uploadProjectFilesApi(projectId, files, token);
        }

        showToast(
          "Bidding project created successfully and added to the pool",
          "success"
        );

        navigate(`/projects/success/${projectId}?lang=en`, { replace: true });
        return;
      }

      // ============================
      // 2️⃣ PAID PROJECT → STRIPE FIRST (or skip if permission granted)
      // ============================
      // Check if user can skip payment (internal clients)
      const canSkipPayment = userData?.can_post_without_payment === true && userData?.role_id === 2;
      
      if (canSkipPayment) {
        // Skip payment and create project directly
        const project = await createProjectApi(projectData, token);
        const projectId = project.id;

        if (files.length > 0) {
          await uploadProjectFilesApi(projectId, files, token);
        }

        showToast("Project posted successfully (payment skipped for internal client)", "success");
        navigate(`/projects/success/${projectId}?lang=en`, { replace: true });
        return;
      }

      const response = await createProjectCheckoutSessionApi(
        projectData,
        token
      );

      // Check if payment was skipped (backend response)
      if (response.skipPayment === true) {
        const projectId = response.project_id;

        // Upload files if any
        if (files.length > 0) {
          await uploadProjectFilesApi(projectId, files, token);
        }

        showToast("Project posted successfully", "success");
        navigate(`/projects/success/${projectId}?lang=en`, { replace: true });
        return;
      }

      // Normal flow: redirect to Stripe
      if (response.url) {
        window.location.href = response.url;
      } else {
        throw new Error("No payment URL or skipPayment flag in response");
      }

    } catch (err) {
      showToast(
        err.response?.data?.message || "Failed to proceed",
        "error"
      );
      setIsSubmitting(false);
    }
  };

  // Handle offline payment (CliQ or Cash)
  const handleOfflinePayment = async (method) => {
    if (isSubmitting) return;
    if (!token) {
      showToast("You must be logged in", "error");
      return;
    }

    setIsSubmitting(true);

    try {
      // First create the project
      const project = await createProjectApi(projectData, token);
      const projectId = project.id;

      // Upload files if any
      if (files.length > 0) {
        await uploadProjectFilesApi(projectId, files, token);
      }

      // Then set offline payment method
      const { data } = await API.post(
        `/projects/${projectId}/offline-payment`,
        { method },
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );

      showToast(
        data.message || "Project created. Waiting for admin approval.",
        "success"
      );
      navigate(`/projects/success/${projectId}?lang=en`, { replace: true });
    } catch (err) {
      showToast(
        err.response?.data?.message || "Failed to create project with offline payment",
        "error"
      );
      setIsSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 pt-28">
      <PageMeta title="Create Project – OrderzHouse" description="Post a new project and find freelancers on OrderzHouse." />
      <div className="max-w-5xl mx-auto px-4 py-12 -mt-2 relative z-10">

        {step === 1 && (
          <ProjectDetailsStep
            projectData={projectData}
            setProjectData={setProjectData}
            onNext={() => {
              if (Number(projectData.category_id) === DEVELOPMENT_CATEGORY_ID) {
                setShowDevPopup(true);
              } else {
                nextStep();
              }
            }}
          />
        )}

        {step === 2 && (
          <ProjectCoverStep
            coverPic={coverPic}
            setCoverPic={setCoverPic}
            onNext={nextStep}
            onBack={prevStep}
          />
        )}

        {step === 3 && (
          <ProjectFilesStep
            files={files}
            setFiles={setFiles}
            onNext={() => {
              if (projectData.project_type === "bidding") {
                handleFinalSubmit();
              } else {
                nextStep();
              }
            }}
            onBack={prevStep}
          />
        )}

        {step === 4 && projectData.project_type !== "bidding" && !(userData?.can_post_without_payment === true && userData?.role_id === 2) && (
          <PaymentStep
            projectData={projectData}
            onBack={prevStep}
            onSubmit={handleFinalSubmit}
            isSubmitting={isSubmitting}
            onOfflinePayment={handleOfflinePayment}
          />
        )}
        {step === 4 && projectData.project_type !== "bidding" && userData?.can_post_without_payment === true && userData?.role_id === 2 && (
          <div className="bg-white rounded-lg border border-slate-200 p-6">
            <div className="text-center space-y-4">
              <div className="inline-flex items-center gap-2 px-3 py-1 bg-orange-100 text-orange-700 rounded-full text-sm font-semibold">
                Internal posting enabled — payment step skipped
              </div>
              <p className="text-slate-600">Your project will be created without payment.</p>
              <div className="flex gap-3 justify-center">
                <button
                  onClick={prevStep}
                  className="px-4 py-2 border border-slate-300 rounded-lg hover:bg-slate-50 transition"
                >
                  Back
                </button>
                <button
                  onClick={handleFinalSubmit}
                  disabled={isSubmitting}
                  className="px-4 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700 disabled:opacity-50 transition"
                >
                  {isSubmitting ? "Creating..." : "Create Project"}
                </button>
              </div>
            </div>
          </div>
        )}

      </div>

      {showDevPopup && (
        <DevelopmentNoticeModal
          onClose={() => setShowDevPopup(false)}
          onConfirm={() => {
            setShowDevPopup(false);
            nextStep();
          }}
        />
      )}
    </div>
  );
}
