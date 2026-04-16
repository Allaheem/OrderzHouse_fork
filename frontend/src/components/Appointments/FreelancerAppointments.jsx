import React, { useState, useEffect } from 'react';
import { useSelector } from 'react-redux';
import { 
  Calendar, 
  Plus, 
  AlertCircle, 
  Clock, 
  User, 
  BarChart3,
  CheckCircle,
  XCircle,
  RefreshCw,
  Video,
  Building,
  CheckSquare,
  History
} from 'lucide-react';
import { useAppointments } from './hook/useAppointments';
import CreateAppointmentModal from './CreateAppointmentModal';

const FreelancerAppointments = () => {
  const { userData } = useSelector((state) => state.auth);
  const {
    appointments,
    loading,
    error,
    setError,
    fetchMyAppointments,
    createAppointment,
    rescheduleAppointment,
    markAppointmentCompleted 
  } = useAppointments();

  const [showAddModal, setShowAddModal] = useState(false);
  const [activeTab, setActiveTab] = useState('active');
  const [completedAppointments, setCompletedAppointments] = useState([]);

  useEffect(() => {
    fetchMyAppointments();
    loadCompletedAppointments();
  }, []);

  const loadCompletedAppointments = async () => {
    try {
      const completedFromDB = appointments.filter(app => app.status === 'completed');
      setCompletedAppointments(completedFromDB);
      
      localStorage.setItem('freelancerCompletedAppointments', JSON.stringify(completedFromDB));
    } catch (_) {
      const savedCompleted = localStorage.getItem('freelancerCompletedAppointments');
      if (savedCompleted) {
        setCompletedAppointments(JSON.parse(savedCompleted));
      }
    }
  };

  const markAsComplete = async (appointment) => {
    try {
      const result = await markAppointmentCompleted(appointment.id);
      if (!result.success) {
        alert(result.error);
        return;
      }

      const completedAppointment = {
        ...appointment,
        status: 'completed'
      };

      setCompletedAppointments(prev => [...prev, completedAppointment]);
      fetchMyAppointments();
      
      alert(`Appointment marked as completed!`);
    } catch (_) {
      alert('Failed to mark appointment as completed');
    }
  };

  const activeAppointments = appointments.filter(app => app.status !== 'completed');
  const allAppointments = [...activeAppointments, ...completedAppointments];

  const canCreateAppointment = () => {
    const activeAppointments = appointments.filter(apt => 
      apt.status === 'pending' || apt.status === 'accepted'
    );
    return activeAppointments.length === 0;
  };

  const handleReschedule = async (appointmentId, newDate) => {
    const result = await rescheduleAppointment(appointmentId, newDate);
    if (!result.success) {
      alert(result.error);
    }
  };

  // Statistics for freelancer
  const stats = {
    total: allAppointments.length,
    pending: activeAppointments.filter(apt => apt.status === 'pending').length,
    accepted: activeAppointments.filter(apt => apt.status === 'accepted').length,
    rejected: activeAppointments.filter(apt => apt.status === 'rejected').length,
    completed: completedAppointments.length,
    upcoming: activeAppointments.filter(apt => 
      apt.status === 'accepted' && new Date(apt.appointment_date) > new Date()
    ).length,
  };

  const StatCard = ({ title, value, icon, color, description }) => (
    <div className="bg-white rounded-xl border border-teal-200 p-6 shadow-sm">
      <div className="flex items-center justify-between mb-2">
        <div>
          <p className="text-sm font-medium text-gray-600">{title}</p>
          <h3 className="text-2xl font-bold text-gray-900 mt-1">{value}</h3>
        </div>
        <div className={`p-3 rounded-lg ${color}`}>
          {icon}
        </div>
      </div>
      {description && (
        <p className="text-xs text-gray-500 mt-2">{description}</p>
      )}
    </div>
  );

  const getTypeIcon = (type) => {
    return type === 'online' ? 
      <Video className="w-4 h-4 text-teal-600" /> : 
      <Building className="w-4 h-4 text-teal-700" />;
  };

  const getStatusColor = (status, appointmentDate) => {
    const isPast = new Date(appointmentDate) < new Date();
    const isCompleted = status === 'completed';
    
    if (isCompleted) {
      return {
        bg: 'bg-teal-50',
        text: 'text-teal-700',
        border: 'border-teal-200',
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
          bg: 'bg-green-50',
          text: 'text-green-700',
          border: 'border-green-200',
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
      default: 
        return {
          bg: 'bg-gray-50',
          text: 'text-gray-700',
          border: 'border-gray-200',
          label: 'Unknown'
        };
    }
  };

  const MainAppointmentsTable = ({ appointments, title, showActions = true, showCompleteButton = true }) => (
    <div className="bg-white rounded-2xl shadow-lg border border-teal-200 overflow-hidden">
      <div className="px-6 py-4 border-b border-teal-200 bg-gradient-to-r from-teal-50 to-teal-100">
        <h3 className="text-lg font-semibold text-gray-900">{title}</h3>
        <p className="text-sm text-gray-600 mt-1">{appointments.length} appointments</p>
      </div>
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead>
            <tr className="bg-teal-50 border-b border-teal-200">
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900 uppercase tracking-wider">
                Date & Time
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
          <tbody className="divide-y divide-teal-200">
            {appointments.map((appointment) => {
              const statusInfo = getStatusColor(appointment.status, appointment.appointment_date);
              const isPast = new Date(appointment.appointment_date) < new Date();
              const isCompleted = appointment.status === 'completed';
              
              return (
                <tr 
                  key={appointment.id} 
                  className={`hover:bg-teal-50 transition-colors ${
                    isCompleted ? 'bg-teal-25' : isPast ? 'bg-orange-25' : 'bg-white'
                  }`}
                >
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div className="flex items-center space-x-3">
                      <div className={`w-2 h-8 rounded-full ${
                        isCompleted ? 'bg-teal-400' : 
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
                        {!isCompleted && appointment.status === 'pending' && (
                          <button
                            onClick={() => handleReschedule(appointment.id, prompt('Enter new date and time (YYYY-MM-DDTHH:MM):', appointment.appointment_date))}
                            className="p-2 rounded-lg bg-teal-50 text-teal-600 hover:bg-teal-100 transition-colors"
                            title="Reschedule Appointment"
                          >
                            <RefreshCw className="w-4 h-4" />
                          </button>
                        )}

                        {showCompleteButton && appointment.status === 'accepted' && !isCompleted && (
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
                <h1 className="text-3xl font-bold text-gray-900">My Appointments</h1>
                <p className="text-gray-600 mt-2">Manage your scheduled meetings and appointments</p>
              </div>
            </div>
            
            {canCreateAppointment() ? (
              <button
                onClick={() => setShowAddModal(true)}
                className="flex items-center space-x-3 px-6 py-3 bg-gradient-to-r from-teal-500 to-teal-600 text-white rounded-xl hover:from-teal-600 hover:to-teal-700 transition-all shadow-lg"
              >
                <Plus className="w-5 h-5" />
                <span className="font-semibold">New Appointment</span>
              </button>
            ) : (
              <div className="flex items-center space-x-2 px-4 py-2 bg-yellow-100 text-yellow-800 rounded-lg">
                <AlertCircle className="w-5 h-5" />
                <div>
                  <p className="text-sm font-medium">Active Appointment</p>
                  <p className="text-xs">Complete current appointment to schedule new one</p>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Statistics */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <StatCard
            title="Total Appointments"
            value={stats.total}
            icon={<Calendar className="w-6 h-6 text-teal-600" />}
            color="bg-teal-100"
            description="All your appointments"
          />
          <StatCard
            title="Pending"
            value={stats.pending}
            icon={<AlertCircle className="w-6 h-6 text-yellow-600" />}
            color="bg-yellow-100"
            description="Waiting for approval"
          />
          <StatCard
            title="Accepted"
            value={stats.accepted}
            icon={<User className="w-6 h-6 text-green-600" />}
            color="bg-green-100"
            description="Confirmed appointments"
          />
          <StatCard
            title="Completed"
            value={stats.completed}
            icon={<History className="w-6 h-6 text-blue-600" />}
            color="bg-blue-100"
            description="Finished meetings"
          />
        </div>

        {/* Quick Actions */}
        {canCreateAppointment() && stats.total === 0 && (
          <div className="bg-gradient-to-r from-teal-500 to-teal-600 rounded-xl p-6 mb-6 text-white">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-xl font-bold mb-2">Ready to schedule your first appointment?</h3>
                <p className="text-teal-100">Book a meeting with the admin to discuss your projects and opportunities.</p>
              </div>
              <button
                onClick={() => setShowAddModal(true)}
                className="px-6 py-3 bg-white text-teal-600 rounded-lg hover:bg-teal-50 transition-colors font-semibold"
              >
                Schedule Now
              </button>
            </div>
          </div>
        )}

        {/* Navigation Tabs */}
        <div className="bg-white rounded-2xl shadow-lg p-2 mb-8 border border-teal-200">
          <div className="flex space-x-2">
            {[
              { id: 'active', label: 'Active Appointments', count: activeAppointments.length },
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

        <div className="space-y-8">
          {activeTab === 'active' && (
            <MainAppointmentsTable 
              appointments={activeAppointments} 
              title="Active Appointments"
              showActions={true}
              showCompleteButton={true}
            />
          )}

          {/* Completed Appointments */}
          {activeTab === 'completed' && (
            <MainAppointmentsTable 
              appointments={completedAppointments} 
              title="Completed Appointments"
              showActions={false}
              showCompleteButton={false}
            />
          )}
        </div>

        {/* Help Section */}
        {allAppointments.length > 0 && (
          <div className="bg-teal-50 border border-teal-200 rounded-xl p-6 mt-6">
            <div className="flex items-start space-x-4">
              <div className="p-2 bg-teal-100 rounded-lg">
                <BarChart3 className="w-6 h-6 text-teal-600" />
              </div>
              <div>
                <h3 className="text-lg font-semibold text-teal-900 mb-2">Appointment Guidelines</h3>
                <ul className="text-teal-800 text-sm space-y-1">
                  <li>• You can only have one active (pending/accepted) appointment at a time</li>
                  <li>• Pending appointments can be rescheduled</li>
                  <li>• Once accepted, appointments cannot be cancelled</li>
                  <li>• Rejected appointments can be re-requested</li>
                  <li>• Contact admin for urgent schedule changes</li>
                  <li>• Complete appointments to book new ones</li>
                </ul>
              </div>
            </div>
          </div>
        )}

        {/* Add Appointment Modal */}
        {showAddModal && (
          <CreateAppointmentModal 
            onClose={() => setShowAddModal(false)}
            onSuccess={() => {
              setShowAddModal(false);
              fetchMyAppointments();
            }}
            isAdmin={false}
          />
        )}
      </div>
    </div>
  );
};

export default FreelancerAppointments;