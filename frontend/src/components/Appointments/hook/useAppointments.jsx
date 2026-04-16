import { useState } from 'react';
import { useSelector } from 'react-redux';
import API from '../../../api/client.js';

export const useAppointments = () => {
  const { token, userData } = useSelector((state) => state.auth);
  const [appointments, setAppointments] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const getConfig = () => ({
    headers: { 
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  });

  // Get all appointments (for admin)
  const fetchAllAppointments = async () => {
    setLoading(true);
    setError('');
    try {
      const response = await API.get("/appointments/get", getConfig());
      setAppointments(response.data.appointments || []);
      return { success: true, data: response.data };
    } catch (err) {
      const errorMsg = err.response?.data?.message || 'Failed to fetch appointments';
      setError(errorMsg);
      return { success: false, error: errorMsg };
    } finally {
      setLoading(false);
    }
  };

  // Get freelancer's appointments
  const fetchMyAppointments = async () => {
    setLoading(true);
    setError('');
    try {
      const response = await API.get("/appointments/my", getConfig());
      setAppointments(response.data.appointments || []);
      return { success: true, data: response.data };
    } catch (err) {
      const errorMsg = err.response?.data?.message || 'Failed to fetch your appointments';
      setError(errorMsg);
      return { success: false, error: errorMsg };
    } finally {
      setLoading(false);
    }
  };

  // Create appointment (for freelancer)
  const createAppointment = async (appointmentData) => {
    setLoading(true);
    setError('');
    try {
      const response = await API.post(
        "/appointments/", 
        appointmentData, 
        getConfig()
      );
      setAppointments(prev => [response.data.appointment, ...prev]);
      return { success: true, data: response.data };
    } catch (err) {
      const errorMsg = err.response?.data?.message || 'Failed to create appointment';
      setError(errorMsg);
      return { success: false, error: errorMsg };
    } finally {
      setLoading(false);
    }
  };

  // Create appointment by admin
  const createAppointmentByAdmin = async (appointmentData) => {
    setLoading(true);
    setError('');
    try {
      const response = await API.post(
        "/appointments/admin/appointments", 
        appointmentData, 
        getConfig()
      );
      setAppointments(prev => [response.data.appointment, ...prev]);
      return { success: true, data: response.data };
    } catch (err) {
      const errorMsg = err.response?.data?.message || 'Failed to create appointment';
      setError(errorMsg);
      return { success: false, error: errorMsg };
    } finally {
      setLoading(false);
    }
  };

  // Accept appointment
  const acceptAppointment = async (appointmentId) => {
    setError('');
    try {
      const response = await API.patch(
        `/appointments/accept/${appointmentId}`, 
        {}, 
        getConfig()
      );
      setAppointments(prev => 
        prev.map(apt => 
          apt.id === appointmentId ? { ...apt, status: 'accepted' } : apt
        )
      );
      return { success: true, data: response.data };
    } catch (err) {
      const errorMsg = err.response?.data?.message || 'Failed to accept appointment';
      setError(errorMsg);
      return { success: false, error: errorMsg };
    }
  };

  // Reject appointment
  const rejectAppointment = async (appointmentId) => {
    setError('');
    try {
      const response = await API.patch(
        `/appointments/reject/${appointmentId}`, 
        {}, 
        getConfig()
      );
      setAppointments(prev => 
        prev.map(apt => 
          apt.id === appointmentId ? { ...apt, status: 'rejected' } : apt
        )
      );
      return { success: true, data: response.data };
    } catch (err) {
      const errorMsg = err.response?.data?.message || 'Failed to reject appointment';
      setError(errorMsg);
      return { success: false, error: errorMsg };
    }
  };

  // Mark appointment as completed
  const markAppointmentCompleted = async (appointmentId) => {
  setError('');
  try {
    const response = await API.patch(
      `/appointments/complete/${appointmentId}`,
      {},
      getConfig()
    );

    // Update local state
    setAppointments(prev => 
      prev.map(apt => 
        apt.id === appointmentId ? { ...apt, status: 'completed' } : apt
      )
    );
    
    return { success: true, data: response.data };
  } catch (err) {
    const errorMsg = err.response?.data?.message || 'Failed to mark appointment as completed';
    setError(errorMsg);
    return { success: false, error: errorMsg };
  }
};

  // Reschedule appointment
  const rescheduleAppointment = async (appointmentId, newDate) => {
    setError('');
    try {
      const response = await API.patch(
        `/appointments/reschedule/${appointmentId}`, 
        { appointment_date: newDate },
        getConfig()
      );
      setAppointments(prev => 
        prev.map(apt => 
          apt.id === appointmentId ? { ...apt, appointment_date: newDate } : apt
        )
      );
      return { success: true, data: response.data };
    } catch (err) {
      const errorMsg = err.response?.data?.message || 'Failed to reschedule appointment';
      setError(errorMsg);
      return { success: false, error: errorMsg };
    }
  };

  return {
    appointments,
    loading,
    error,
    setError,
    fetchAllAppointments,
    fetchMyAppointments,
    createAppointment,
    acceptAppointment,
    rejectAppointment,
    rescheduleAppointment,
    createAppointmentByAdmin,
    markAppointmentCompleted
  };
};