import React, { useState, useEffect } from 'react';
import { useSelector } from 'react-redux';
import { 
  Calendar, 
  Plus, 
  CheckCircle, 
  XCircle, 
  RefreshCw, 
  User, 
  Video, 
  Building, 
  Clock, 
  AlertCircle, 
  Archive,
  Eye,
  Download,
  CheckSquare,
  History
} from 'lucide-react';
import { useAppointments } from './hook/useAppointments';
import CreateAppointmentModal from './CreateAppointmentModal';
import RescheduleModal from './RescheduleModal';

const AdminAppointments = () => {
  const { userData } = useSelector((state) => state.auth);
  const {
    appointments,
    loading,
    error,
    setError,
    fetchAllAppointments,
    acceptAppointment,
    rejectAppointment,
    rescheduleAppointment,
    createAppointmentByAdmin,
    markAppointmentCompleted 
  } = useAppointments();

  const [showAddModal, setShowAddModal] = useState(false);
  const [rescheduleAppointmentId, setRescheduleAppointmentId] = useState(null);
  const [activeTab, setActiveTab] = useState('all'); 
  const [completedAppointments, setCompletedAppointments] = useState([]);

  const colors = {
    primary: '#028090',    
    secondary: '#01535e',
    accent: '#026a77',
    warning: '#0296a9', 
    danger: '#03adc2',   
    dark: '#03c3db',     
    light: '#e6f7fa'     
  };

  useEffect(() => {
    fetchAllAppointments();
    loadCompletedAppointments();
  }, []);

  const loadCompletedAppointments = async () => {
    try {
      const completedFromDB = appointments.filter(app => app.status === 'completed');
      setCompletedAppointments(completedFromDB);
      
      localStorage.setItem('completedAppointments', JSON.stringify(completedFromDB));
    } catch (_) {
      const savedCompleted = localStorage.getItem('completedAppointments');
      if (savedCompleted) {
        setCompletedAppointments(JSON.parse(savedCompleted));
      }
    }
  };

  const saveCompletedAppointments = (completed) => {
    setCompletedAppointments(completed);
    localStorage.setItem('completedAppointments', JSON.stringify(completed));
  };

  const markAsComplete = async (appointment) => {
    try {
      const now = new Date();
      
      const result = await markAppointmentCompleted(appointment.id);
      
      if (!result.success) {
        alert(result.error);
        return;
      }

      const completedAppointment = {
        ...appointment,
        completed_at: now.toISOString(),
        completed_by: userData?.id,
        status: 'completed'
      };

      const updatedCompleted = [...completedAppointments, completedAppointment];
      saveCompletedAppointments(updatedCompleted);

      await fetchAllAppointments();
      
      alert(`Appointment marked as completed!`);
    } catch (_) {
      alert('Failed to mark appointment as completed');
    }
  };

  const categorizeAppointments = () => {
    const now = new Date();
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const activeAppointments = appointments.filter(appointment => {
      return appointment.status !== 'completed';
    });

    return activeAppointments.reduce((acc, appointment) => {
      const appointmentDate = new Date(appointment.appointment_date);
      const isToday = appointmentDate.toDateString() === now.toDateString();
      const isPast = appointmentDate < now;
      
      if (isToday) {
        acc.today.push(appointment);
      } else if (isPast) {
        acc.past.push(appointment);
      } else {
        acc.upcoming.push(appointment);
      }
      
      return acc;
    }, { today: [], upcoming: [], past: [] });
  };

  const { today, upcoming, past } = categorizeAppointments();
  
  const allActiveAppointments = [...today, ...upcoming, ...past];

  const handleAccept = async (appointmentId) => {
    const result = await acceptAppointment(appointmentId);
    if (!result.success) {
      alert(result.error);
    }
  };

  const handleReject = async (appointmentId) => {
    const result = await rejectAppointment(appointmentId);
    if (!result.success) {
      alert(result.error);
    }
  };

  const handleReschedule = async (appointmentId, newDate) => {
    const result = await rescheduleAppointment(appointmentId, newDate);
    if (result.success) {
      setRescheduleAppointmentId(null);
      fetchAllAppointments();
    } else {
      alert(result.error);
    }
  };

  const isDateValid = (dateTime) => {
    const selectedDate = new Date(dateTime);
    const now = new Date();
    return selectedDate > now;
  };

  const getStatusColor = (status, appointmentDate) => {
    const isPast = new Date(appointmentDate) < new Date();
    
    const isCompleted = status === 'completed';
    
    if (isCompleted) {
      return {
        bg: 'bg-gray-100',
        text: 'text-gray-700',
        border: 'border-gray-300',
        label: 'Completed'
      };
    }

    if (isPast && status !== 'completed') {
      return {
        bg: 'bg-orange-50',
        text: 'text-orange-700',
        border: 'border-orange-200',
        label: 'Expired'
      };
    }

    switch(status) {
      case 'accepted': 
        return {
          bg: 'bg-teal-50',
          text: 'text-teal-700',
          border: 'border-teal-200',
          label: 'Accepted'
        };
      case 'rejected': 
        return {
          bg: 'bg-red-50',
          text: 'text-red-700',
          border: 'border-red-200',
          label: 'Rejected'
        };
      case 'pending': 
        return {
          bg: 'bg-yellow-50',
          text: 'text-yellow-700',
          border: 'border-yellow-200',
          label: 'Pending'
        };
      case 'completed':
        return {
          bg: 'bg-blue-100',
          text: 'text-blue-700',
          border: 'border-blue-300',
          label: 'Completed'
        };
      default: 
        return {
          bg: 'bg-gray-100',
          text: 'text-gray-700',
          border: 'border-gray-300',
          label: 'Unknown'
        };
    }
  };

  const getTypeIcon = (type) => {
    return type === 'online' ? 
      <Video className="w-4 h-4" style={{ color: colors.primary }} /> : 
      <Building className="w-4 h-4" style={{ color: colors.secondary }} />;
  };

  const MainAppointmentsTable = ({ appointments, title, showActions = true, showCompleteButton = true }) => (
    <div className="bg-white rounded-2xl shadow-lg border border-gray-200 overflow-hidden">
      <div className="px-6 py-4 border-b border-gray-200 bg-gradient-to-r from-gray-50 to-gray-100">
        <h3 className="text-lg font-semibold text-gray-900">{title}</h3>
        <p className="text-sm text-gray-600 mt-1">{appointments.length} appointments</p>
      </div>
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead>
            <tr className="bg-gray-50 border-b border-gray-200">
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900 uppercase tracking-wider">
                Date & Time
              </th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900 uppercase tracking-wider">
                Freelancer
              </th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900 uppercase tracking-wider">
                Type
              </th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900 uppercase tracking-wider">
                Status
              </th>
              {showActions && (
                <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900 uppercase tracking-wider">
                  Actions
                </th>
              )}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200">
            {appointments.map((appointment) => {
              const statusInfo = getStatusColor(appointment.status, appointment.appointment_date);
              const isPast = new Date(appointment.appointment_date) < new Date();
              const isCompleted = appointment.status === 'completed';
              
              return (
                <tr 
                  key={appointment.id} 
                  className={`hover:bg-gray-50 transition-colors ${
                    isCompleted ? 'bg-gray-25' : isPast ? 'bg-orange-25' : 'bg-white'
                  }`}
                >
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center space-x-3">
                      <div className={`w-2 h-8 rounded-full ${
                        isCompleted ? 'bg-gray-400' : 
                        isPast ? 'bg-orange-400' : 
                        'bg-teal-500'
                      }`}></div>
                      <div>
                        <div className="text-sm font-medium text-gray-900">
                          {new Date(appointment.appointment_date).toLocaleDateString()}
                        </div>
                        <div className="text-sm text-gray-500 flex items-center space-x-1">
                          <Clock className="w-4 h-4" />
                          <span>
                            {new Date(appointment.appointment_date).toLocaleTimeString([], {
                              hour: '2-digit',
                              minute: '2-digit'
                            })}
                          </span>
                        </div>
                        {isPast && !isCompleted && (
                          <div className="text-xs text-orange-600 mt-1">⚠️ Past appointment</div>
                        )}
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center space-x-3">
                      <div className="w-10 h-10 bg-gradient-to-br from-teal-500 to-teal-700 rounded-full flex items-center justify-center">
                        <User className="w-5 h-5 text-white" />
                      </div>
                      <div>
                        <div className="text-sm font-semibold text-gray-900">
                          {appointment.first_name} {appointment.last_name}
                        </div>
                        <div className="text-sm text-gray-500">{appointment.freelancer_email}</div>
                        {appointment.freelancer_phone && (
                          <div className="text-xs text-gray-400">{appointment.freelancer_phone}</div>
                        )}
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className={`inline-flex items-center space-x-2 px-3 py-2 rounded-full ${
                      appointment.appointment_type === 'online' ? 'bg-teal-50' : 'bg-teal-100'
                    }`}>
                      {getTypeIcon(appointment.appointment_type)}
                      <span className={`text-sm font-medium ${
                        appointment.appointment_type === 'online' ? 'text-teal-700' : 'text-teal-800'
                      }`}>
                        {appointment.appointment_type === 'online' ? 'Online' : 'In Company'}
                      </span>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <span className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold border ${statusInfo.bg} ${statusInfo.text} ${statusInfo.border}`}>
                      {statusInfo.label}
                    </span>
                  </td>
                  {showActions && (
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center space-x-2">
                        {appointment.status === 'pending' && !isCompleted && (
                          <>
                            <button
                              onClick={() => handleAccept(appointment.id)}
                              className="p-2 rounded-lg bg-teal-50 text-teal-600 hover:bg-teal-100 transition-colors"
                              title="Accept Appointment"
                            >
                              <CheckCircle className="w-4 h-4" />
                            </button>
                            <button
                              onClick={() => handleReject(appointment.id)}
                              className="p-2 rounded-lg bg-red-50 text-red-600 hover:bg-red-100 transition-colors"
                              title="Reject Appointment"
                            >
                              <XCircle className="w-4 h-4" />
                            </button>
                          </>
                        )}

                        {!isCompleted && (
                          <button
                            onClick={() => setRescheduleAppointmentId(appointment.id)}
                            className="p-2 rounded-lg bg-teal-50 text-teal-600 hover:bg-teal-100 transition-colors"
                            title="Reschedule Appointment"
                          >
                            <RefreshCw className="w-4 h-4" />
                          </button>
                        )}

                        {showCompleteButton && !isCompleted && (
                          <button
                            onClick={() => markAsComplete(appointment)}
                            className="p-2 rounded-lg bg-teal-50 text-teal-600 hover:bg-teal-100 transition-colors"
                            title="Mark as Completed"
                          >
                            <CheckSquare className="w-4 h-4" />
                          </button>
                        )}
                      </div>
                    </td>
                  )}
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );

  const stats = [
    { 
      label: 'Active Appointments', 
      value: allActiveAppointments.length, 
      color: colors.primary,
      icon: Calendar
    },
    { 
      label: "Today's Appointments", 
      value: today.length, 
      color: colors.secondary,
      icon: Clock
    },
    { 
      label: 'Upcoming', 
      value: upcoming.length, 
      color: colors.accent,
      icon: Eye
    },
    { 
      label: 'Completed', 
      value: completedAppointments.length, 
      color: colors.dark,
      icon: History
    }
  ];

  if (loading && appointments.length === 0) {
    return (
      <div className="min-h-screen bg-white p-6 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-teal-600 mx-auto mb-4"></div>
          <p className="text-teal-600">Loading appointments...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-white p-6">
      <div className="max-w-7xl mx-auto">
        
        {/* Header */}
        <div className="bg-white rounded-2xl shadow-lg p-8 mb-8 border border-teal-200">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-6">
              <div className="p-4 rounded-2xl bg-gradient-to-br from-teal-500 to-teal-700">
                <Calendar className="w-8 h-8 text-white" />
              </div>
              <div>
                <h1 className="text-3xl font-bold text-gray-900">Appointments Management</h1>
                <p className="text-gray-600 mt-2">Complete system with real-time validation and archiving</p>
              </div>
            </div>
            
            <button
              onClick={() => setShowAddModal(true)}
              className="flex items-center space-x-3 px-6 py-3 bg-gradient-to-r from-teal-500 to-teal-600 text-white rounded-xl hover:from-teal-600 hover:to-teal-700 transition-all shadow-lg"
            >
              <Plus className="w-5 h-5" />
              <span className="font-semibold">New Appointment</span>
            </button>
          </div>
        </div>

        {/* Statistics */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          {stats.map((stat, index) => (
            <div key={index} className="bg-white rounded-2xl p-6 shadow-lg border border-teal-200 hover:shadow-xl transition-shadow">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm font-medium text-gray-600">{stat.label}</p>
                  <h3 className="text-2xl font-bold text-gray-900 mt-1">{stat.value}</h3>
                </div>
                <div className="p-3 rounded-xl" style={{ backgroundColor: `${stat.color}20` }}>
                  <stat.icon className="w-6 h-6" style={{ color: stat.color }} />
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Navigation Tabs */}
        <div className="bg-white rounded-2xl shadow-lg p-2 mb-8 border border-teal-200">
          <div className="flex space-x-2">
            {[
              { id: 'all', label: 'All Appointments', count: allActiveAppointments.length },
              { id: 'today', label: "Today's Schedule", count: today.length },
              { id: 'completed', label: 'Completed', count: completedAppointments.length }
            ].map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex items-center space-x-3 px-6 py-3 rounded-xl font-semibold transition-all ${
                  activeTab === tab.id
                    ? 'bg-gradient-to-r from-teal-500 to-teal-700 text-white shadow-lg'
                    : 'text-gray-600 hover:text-gray-900 hover:bg-teal-50'
                }`}
              >
                <span>{tab.label}</span>
                <span className={`px-2 py-1 rounded-full text-xs ${
                  activeTab === tab.id ? 'bg-white text-teal-600' : 'bg-teal-200 text-teal-600'
                }`}>
                  {tab.count}
                </span>
              </button>
            ))}
          </div>
        </div>

        {/* Error Message */}
        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 px-6 py-4 rounded-2xl mb-8 flex items-center shadow-lg">
            <AlertCircle className="w-6 h-6 mr-4" />
            <span className="flex-1">{error}</span>
            <button
              onClick={() => setError('')}
              className="text-red-600 hover:text-red-800 text-2xl font-bold"
            >
              ×
            </button>
          </div>
        )}

        {/* Content Based on Active Tab */}
        <div className="space-y-8">
          {/* All Active Appointments */}
          {activeTab === 'all' && (
            <MainAppointmentsTable 
              appointments={allActiveAppointments} 
              title="All Active Appointments - Management Panel"
              showActions={true}
              showCompleteButton={true}
            />
          )}

          {/* Today's Appointments */}
          {activeTab === 'today' && (
            <div className="space-y-6">
              <div className="bg-gradient-to-r from-teal-50 to-teal-100 rounded-2xl p-6 border border-teal-200">
                <div className="flex items-center justify-between">
                  <div>
                    <h2 className="text-2xl font-bold text-gray-900">Today's Schedule</h2>
                    <p className="text-gray-600 mt-1">
                      {new Date().toLocaleDateString('en-US', { 
                        weekday: 'long', 
                        year: 'numeric', 
                        month: 'long', 
                        day: 'numeric' 
                      })}
                    </p>
                  </div>
                  <div className="text-3xl font-bold text-teal-600">
                    {today.length} {today.length === 1 ? 'Appointment' : 'Appointments'}
                  </div>
                </div>
              </div>
              
              {today.length > 0 ? (
                <MainAppointmentsTable 
                  appointments={today} 
                  title="Today's Appointments - Priority Management"
                  showActions={true}
                  showCompleteButton={true}
                />
              ) : (
                <div className="bg-white rounded-2xl shadow-lg p-12 text-center border border-teal-200">
                  <Calendar className="w-16 h-16 text-teal-400 mx-auto mb-4" />
                  <h3 className="text-xl font-semibold text-gray-900 mb-2">No Appointments Today</h3>
                  <p className="text-gray-600 mb-6">There are no appointments scheduled for today.</p>
                  <button
                    onClick={() => setShowAddModal(true)}
                    className="px-6 py-3 bg-gradient-to-r from-teal-500 to-teal-600 text-white rounded-xl hover:from-teal-600 hover:to-teal-700 transition-all"
                  >
                    Schedule New Appointment
                  </button>
                </div>
              )}
            </div>
          )}

          {/* Completed Appointments */}
          {activeTab === 'completed' && (
            <div className="space-y-6">
              <div className="bg-gradient-to-r from-teal-100 to-teal-200 rounded-2xl p-6 border border-teal-300">
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-4">
                    <History className="w-8 h-8 text-teal-600" />
                    <div>
                      <h2 className="text-2xl font-bold text-gray-900">Completed Appointments</h2>
                      <p className="text-gray-600 mt-1">Historical record of all completed appointments</p>
                    </div>
                  </div>
                  <button 
                    onClick={() => {
                      const dataStr = JSON.stringify(completedAppointments, null, 2);
                      const dataBlob = new Blob([dataStr], { type: 'application/json' });
                      const url = URL.createObjectURL(dataBlob);
                      const link = document.createElement('a');
                      link.href = url
                      link.download = 'completed-appointments.json';
                      link.click();
                    }}
                    className="flex items-center space-x-2 px-4 py-2 bg-teal-600 text-white rounded-lg hover:bg-teal-700 transition-colors"
                  >
                    <Download className="w-4 h-4" />
                    <span>Export Data</span>
                  </button>
                </div>
              </div>
              
              {completedAppointments.length > 0 ? (
                <MainAppointmentsTable 
                  appointments={completedAppointments} 
                  title="Completed Appointments Archive"
                  showActions={false}
                  showCompleteButton={false}
                />
              ) : (
                <div className="bg-white rounded-2xl shadow-lg p-12 text-center border border-teal-200">
                  <History className="w-16 h-16 text-teal-400 mx-auto mb-4" />
                  <h3 className="text-xl font-semibold text-gray-900 mb-2">No Completed Appointments</h3>
                  <p className="text-gray-600">Mark appointments as complete to see them here.</p>
                </div>
              )}
            </div>
          )}
        </div>

        {showAddModal && (
          <CreateAppointmentModal 
            onClose={() => setShowAddModal(false)}
            onSuccess={() => {
              setShowAddModal(false);
              fetchAllAppointments();
            }}
            isAdmin={true}
            validateDate={isDateValid}
          />
        )}

        {/* Reschedule Modal */}
        {rescheduleAppointmentId && (
          <RescheduleModal
            appointmentId={rescheduleAppointmentId}
            onClose={() => setRescheduleAppointmentId(null)}
            onSuccess={(newDate) => handleReschedule(rescheduleAppointmentId, newDate)}
            validateDate={isDateValid}
          />
        )}
      </div>
    </div>
  );
};

export default AdminAppointments;