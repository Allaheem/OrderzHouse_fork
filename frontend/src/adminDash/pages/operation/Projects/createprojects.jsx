import { useState, useEffect } from "react";
import { useSelector } from "react-redux";
import { useNavigate } from "react-router-dom";
import { getAllFreelancers, createAdminProject } from "../../api/adminRole4";
import { ArrowLeft, Plus, Users } from "lucide-react";

/** غيّر إلى true عند تفعيل نوع المشروع "Hourly Rate" */
const ENABLE_HOURLY_PROJECT_TYPE = false;

export default function CreateAdminProject() {
  const { userData } = useSelector((state) => state.auth);
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    admin_category: "",
    title: "",
    description: "",
    project_type: "fixed",
    budget: "",
    budget_min: "",
    budget_max: "",
    hourly_rate: "",
    duration_type: "days",
    duration_days: "",
    duration_hours: "",
    sub_category_id: "",
    sub_sub_category_id: "",
    assigned_freelancer_id: "",
  });
  const [freelancers, setFreelancers] = useState([]);
  const [loading, setLoading] = useState(false);
  const [freelancersLoading, setFreelancersLoading] = useState(false);
  const [error, setError] = useState("");

  // Check if user has role_id = 4
  useEffect(() => {
    if (userData?.role_id !== 4) {
      navigate("/admin/dashboard");
    }
  }, [userData, navigate]);

  // Fetch all freelancers when component mounts
  useEffect(() => {
    if (userData?.role_id !== 4) return;

    const fetchFreelancers = async () => {
      try {
        setFreelancersLoading(true);
        const data = await getAllFreelancers();
        
        if (data.success) {
          setFreelancers(data.freelancers);
        }
      } catch (_) {
      } finally {
        setFreelancersLoading(false);
      }
    };

    fetchFreelancers();
  }, [userData]);

  useEffect(() => {
    if (!ENABLE_HOURLY_PROJECT_TYPE && formData.project_type === "hourly") {
      setFormData((prev) => ({ ...prev, project_type: "fixed" }));
    }
  }, [ENABLE_HOURLY_PROJECT_TYPE, formData.project_type]);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
    
    // Clear error when user starts typing
    if (error) setError("");
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError("");

    try {
      // Validate required fields
      if (!formData.admin_category) {
        throw new Error("Please select a project category");
      }
      
      if (!formData.title || formData.title.length < 10) {
        throw new Error("Title must be at least 10 characters long");
      }
      
      if (!formData.description || formData.description.length < 100) {
        throw new Error("Description must be at least 100 characters long");
      }
      
      // For Government and CV projects, freelancer assignment is required
      if (
        (formData.admin_category === "Government Project" || 
         formData.admin_category === "CV/Resume Project") && 
        !formData.assigned_freelancer_id
      ) {
        throw new Error("Please select a freelancer for this project category");
      }

      const data = await createAdminProject(formData);

      if (data.success) {
        // Redirect to project details or dashboard
        navigate("/admin-role-4/dashboard");
      } else {
        throw new Error(data.message || "Failed to create project");
      }
    } catch (err) {
      setError(err.message || "Failed to create project. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  if (userData?.role_id !== 4) {
    return <div>Access denied. Only Admin Viewers can access this page.</div>;
  }

  return (
    <div className="p-6">
      <div className="mb-6">
        <button
          onClick={() => navigate("/admin-role-4/dashboard")}
          className="inline-flex items-center text-blue-600 hover:text-blue-800 mb-4"
        >
          <ArrowLeft className="h-4 w-4 mr-1" />
          Back to Dashboard
        </button>
        <h1 className="text-2xl font-bold text-gray-900">Create New Project</h1>
        <p className="text-gray-600 mt-1">Create a new project as an admin viewer</p>
      </div>

      {error && (
        <div className="mb-6 bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
          {error}
        </div>
      )}

      <div className="bg-white rounded-xl shadow p-6">
        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Project Category */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Project Category <span className="text-red-500">*</span>
            </label>
            <select
              name="admin_category"
              value={formData.admin_category}
              onChange={handleChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
            >
              <option value="">Select a category</option>
              <option value="Government Project">Government Project</option>
              <option value="CV/Resume Project">CV/Resume Project</option>
              <option value="Other">Other</option>
            </select>
          </div>

          {/* Title */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Project Title <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              name="title"
              value={formData.title}
              onChange={handleChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="Enter project title (min 10 characters)"
              required
            />
          </div>

          {/* Description */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Description <span className="text-red-500">*</span>
            </label>
            <textarea
              name="description"
              value={formData.description}
              onChange={handleChange}
              rows={6}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="Describe the project in detail (min 100 characters)"
              required
            />
          </div>

          {/* Project Type */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Project Type <span className="text-red-500">*</span>
            </label>
            <select
              name="project_type"
              value={formData.project_type}
              onChange={handleChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
            >
              <option value="fixed">Fixed Price</option>
              {ENABLE_HOURLY_PROJECT_TYPE && <option value="hourly">Hourly Rate</option>}
              <option value="bidding">Bidding</option>
            </select>
          </div>

          {/* Budget Fields */}
          {formData.project_type === "fixed" && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Fixed Budget ($) <span className="text-red-500">*</span>
              </label>
              <input
                type="number"
                name="budget"
                value={formData.budget}
                onChange={handleChange}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="Enter fixed budget amount"
                min="1"
              />
            </div>
          )}

          {formData.project_type === "bidding" && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Minimum Budget ($) <span className="text-red-500">*</span>
                </label>
                <input
                  type="number"
                  name="budget_min"
                  value={formData.budget_min}
                  onChange={handleChange}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Enter minimum budget"
                  min="1"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Maximum Budget ($) <span className="text-red-500">*</span>
                </label>
                <input
                  type="number"
                  name="budget_max"
                  value={formData.budget_max}
                  onChange={handleChange}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Enter maximum budget"
                  min="1"
                />
              </div>
            </div>
          )}

          {ENABLE_HOURLY_PROJECT_TYPE && formData.project_type === "hourly" && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Hourly Rate ($) <span className="text-red-500">*</span>
              </label>
              <input
                type="number"
                name="hourly_rate"
                value={formData.hourly_rate}
                onChange={handleChange}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="Enter hourly rate"
                min="1"
                step="0.01"
              />
            </div>
          )}

          {/* Duration */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Duration Type <span className="text-red-500">*</span>
            </label>
            <select
              name="duration_type"
              value={formData.duration_type}
              onChange={handleChange}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
            >
              <option value="days">Days</option>
              <option value="hours">Hours</option>
            </select>
          </div>

          {formData.duration_type === "days" && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Duration (Days) <span className="text-red-500">*</span>
              </label>
              <input
                type="number"
                name="duration_days"
                value={formData.duration_days}
                onChange={handleChange}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="Enter number of days"
                min="1"
              />
            </div>
          )}

          {formData.duration_type === "hours" && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Duration (Hours) <span className="text-red-500">*</span>
              </label>
              <input
                type="number"
                name="duration_hours"
                value={formData.duration_hours}
                onChange={handleChange}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="Enter number of hours"
                min="1"
              />
            </div>
          )}

          {/* Freelancer Assignment (for Government and CV projects) */}
          {(formData.admin_category === "Government Project" || 
            formData.admin_category === "CV/Resume Project") && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Assign Freelancer <span className="text-red-500">*</span>
              </label>
              
              {freelancersLoading ? (
                <div className="text-gray-500">Loading freelancers...</div>
              ) : (
                <>
                  <select
                    name="assigned_freelancer_id"
                    value={formData.assigned_freelancer_id}
                    onChange={handleChange}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    required
                  >
                    <option value="">Select a freelancer</option>
                    {freelancers.map((freelancer) => (
                      <option key={freelancer.id} value={freelancer.id}>
                        {freelancer.username} ({freelancer.first_name} {freelancer.last_name})
                      </option>
                    ))}
                  </select>
                  
                  {freelancers.length === 0 && (
                    <p className="text-sm text-gray-500 mt-2">
                      No freelancers available. Freelancers must be verified to appear in this list.
                    </p>
                  )}
                </>
              )}
            </div>
          )}

          {/* Submit Button */}
          <div className="flex items-center justify-end gap-3 pt-4">
            <button
              type="button"
              onClick={() => navigate("/admin-role-4/dashboard")}
              className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50"
              disabled={loading}
            >
              Cancel
            </button>
            <button
              type="submit"
              className="inline-flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50"
              disabled={loading}
            >
              {loading ? (
                <>
                  <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                  Creating...
                </>
              ) : (
                <>
                  <Plus className="h-4 w-4 mr-1" />
                  Create Project
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}