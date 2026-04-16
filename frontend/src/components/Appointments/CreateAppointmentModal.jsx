import React, { useState, useEffect } from "react";
import { X, Calendar, MessageCircle, User, AlertCircle } from "lucide-react";
import { useAppointments } from "./hook/useAppointments";
import API from "../../api/client.js";
import { useSelector } from "react-redux";

const CreateAppointmentModal = ({ onClose, onSuccess, isAdmin, validateDate }) => {
  const { createAppointment, createAppointmentByAdmin, loading, error } = useAppointments();
  const { token } = useSelector((state) => state.auth);
  const [freelancers, setFreelancers] = useState([]);
  const [formData, setFormData] = useState({
    freelancer_id: "",
    appointment_date: "",
    message: "",
    appointment_type: "online",
  });
  const [dateError, setDateError] = useState("");

  useEffect(() => {
    if (isAdmin) {
      const fetchFreelancers = async () => {
        try {
          const response = await API.get("/users/allfreelance", {
            headers: { Authorization: `Bearer ${token}` },
          });
          setFreelancers(response.data.freelancers || []);
        } catch (_) {
        }
      };
      fetchFreelancers();
    }
  }, [isAdmin, token]);

  const validateDateTime = (dateTime) => {
    if (!dateTime) return true;
    const selectedDate = new Date(dateTime);
    const now = new Date();

    if (selectedDate <= now) {
      setDateError(
        "Cannot schedule appointments in the past. Please select a future date and time."
      );
      return false;
    }

    setDateError("");
    return true;
  };

  const handleDateChange = (e) => {
    const newDate = e.target.value;
    setFormData((prev) => ({
      ...prev,
      appointment_date: newDate,
    }));

    validateDateTime(newDate);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!validateDateTime(formData.appointment_date)) {
      return;
    }

    if (isAdmin) {
      if (!formData.freelancer_id) {
        alert("Please select a freelancer");
        return;
      }
      const result = await createAppointmentByAdmin(formData);
      if (result.success) {
        onSuccess();
      }
    } else {
      const result = await createAppointment(formData);
      if (result.success) {
        onSuccess();
      }
    }
  };

  const handleChange = (e) => {
    setFormData((prev) => ({
      ...prev,
      [e.target.name]: e.target.value,
    }));
  };

  const getMinDateTime = () => {
    const now = new Date();
    now.setMinutes(now.getMinutes() + 1);
    return now.toISOString().slice(0, 16);
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-xl max-w-md w-full p-6">
        <div className="flex items-center justify-between mb-6">
          <h2 className="text-xl font-semibold text-gray-900 flex items-center">
            <Calendar className="w-6 h-6 mr-2 text-teal-600" />
            {isAdmin ? "Create Appointment (Admin)" : "Request New Appointment"}
          </h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 transition-colors"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        {error && (
          <div className="bg-red-50 text-red-700 p-3 rounded-lg mb-4">
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Freelancer Selection (Admin only) */}
          {isAdmin && (
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2 flex items-center">
                <User className="w-4 h-4 mr-2" />
                Select Freelancer
              </label>
              <select
                name="freelancer_id"
                value={formData.freelancer_id}
                onChange={handleChange}
                required
                className="w-full px-3 py-2 border border-teal-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-teal-500"
              >
                <option value="">Choose a freelancer</option>
                {freelancers.map((freelancer) => (
                  <option key={freelancer.id} value={freelancer.id}>
                    {freelancer.first_name} {freelancer.last_name} ({freelancer.email})
                  </option>
                ))}
              </select>
            </div>
          )}

          {/* Appointment Type */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Appointment Type
            </label>
            <div className="grid grid-cols-2 gap-3">
              <button
                type="button"
                onClick={() =>
                  setFormData((prev) => ({ ...prev, appointment_type: "online" }))
                }
                className={`p-3 border rounded-lg text-center transition-all ${
                  formData.appointment_type === "online"
                    ? "border-teal-500 bg-teal-50 text-teal-700"
                    : "border-teal-300 text-teal-600 hover:border-teal-400"
                }`}
              >
                🌐 Online
              </button>
              <button
                type="button"
                onClick={() =>
                  setFormData((prev) => ({ ...prev, appointment_type: "in_company" }))
                }
                className={`p-3 border rounded-lg text-center transition-all ${
                  formData.appointment_type === "in_company"
                    ? "border-teal-500 bg-teal-50 text-teal-700"
                    : "border-teal-300 text-teal-600 hover:border-teal-400"
                }`}
              >
                🏢 In Company
              </button>
            </div>
          </div>

          {/* Date & Time with Validation */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Date & Time *
            </label>
            <input
              type="datetime-local"
              name="appointment_date"
              value={formData.appointment_date}
              onChange={handleDateChange}
              required
              min={getMinDateTime()}
              className={`w-full px-3 py-2 border rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-teal-500 ${
                dateError ? "border-red-300" : "border-teal-300"
              }`}
            />
            {dateError && (
              <div className="flex items-center space-x-2 mt-2 text-red-600 text-sm">
                <AlertCircle className="w-4 h-4" />
                <span>{dateError}</span>
              </div>
            )}
            <p className="text-xs text-gray-500 mt-1">
              Must be a future date and time
            </p>
          </div>

          {/* Message */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2 flex items-center">
              <MessageCircle className="w-4 h-4 mr-2" />
              Message (Optional)
            </label>
            <textarea
              name="message"
              value={formData.message}
              onChange={handleChange}
              rows="3"
              placeholder="Add any additional information..."
              className="w-full px-3 py-2 border border-teal-300 rounded-lg focus:ring-2 focus:ring-teal-500 focus:border-teal-500 resize-none"
            />
          </div>

          {/* Buttons */}
          <div className="flex space-x-3 pt-4">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 px-4 py-2 border border-teal-300 text-teal-700 rounded-lg hover:bg-teal-50 transition-colors"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={
                loading ||
                !formData.appointment_date ||
                (isAdmin && !formData.freelancer_id) ||
                !!dateError
              }
              className="flex-1 px-4 py-2 bg-teal-600 text-white rounded-lg hover:bg-teal-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              {loading
                ? "Creating..."
                : isAdmin
                ? "Create Appointment"
                : "Request Appointment"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default CreateAppointmentModal;
