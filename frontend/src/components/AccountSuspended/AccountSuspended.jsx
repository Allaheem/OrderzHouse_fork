import { useState } from "react";
import { useDispatch, useSelector } from "react-redux";
import { Link, useNavigate } from "react-router-dom";
import {
  AlertTriangle,
  Shield,
  Mail,
  HelpCircle,
  LogOut,
  UserX,
  FileText,
  Home,
  User
} from "lucide-react";
import { disconnectSocket } from "../../services/socketService";
import { logout } from "../../slice/auth/authSlice";
import { clearProactiveRefresh } from "../../api/client";

const AccountSuspended = () => {
  const { userData } = useSelector((state) => state.auth);
  const navigate = useNavigate();
  const [showDetails, setShowDetails] = useState(false);
  const dispatch = useDispatch();

  const handleLogout = () => {
    disconnectSocket();
    clearProactiveRefresh();
    dispatch(logout());
    navigate("/", { replace: true });
  };

  

  if (!userData || !userData.is_deleted) {
    return (
      <div className="min-h-screen bg-gradient-to-b from-gray-50 to-gray-100 flex items-center justify-center px-4 py-12">
        <div className="max-w-md w-full bg-white rounded-2xl shadow-lg overflow-hidden">
          <div className="bg-blue-600 py-6 px-6 text-center">
            <div className="flex justify-center mb-4">
              <div className="p-3 bg-white/20 rounded-full">
                <User className="w-8 h-8 text-white" />
              </div>
            </div>
            <h1 className="text-2xl font-bold text-white">Account Active</h1>
            <p className="text-blue-100 mt-2">Your account is currently active</p>
          </div>
          <div className="px-6 py-8 text-center">
            <p className="text-gray-700 mb-6">There are no suspension issues with your account.</p>
            <Link 
              to="/dashboard"
              className="inline-flex items-center justify-center px-4 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors duration-200"
            >
              Go to Dashboard
            </Link>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-gray-50 to-gray-100 flex items-center justify-center px-4 py-12">
      <div className="max-w-md w-full bg-white rounded-2xl shadow-lg overflow-hidden">
        {/* Header */}
        <div className="bg-red-600 py-6 px-6 text-center">
          <div className="flex justify-center mb-4">
            <div className="p-3 bg-white/20 rounded-full">
              <Shield className="w-8 h-8 text-white" />
            </div>
          </div>
          <h1 className="text-2xl font-bold text-white">Account Suspended</h1>
          <p className="text-red-100 mt-2">Your account access has been restricted</p>
        </div>

        <div className="px-6 py-8">
          {/* Alert */}
          <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
            <div className="flex">
              <AlertTriangle className="w-5 h-5 text-red-600 mt-0.5 mr-3 flex-shrink-0" />
              <div>
                <h3 className="text-sm font-medium text-red-800">Suspension Notice</h3>
                <p className="text-sm text-red-700 mt-1">
                  Your account has been suspended for violating our platform policies.
                </p>
              </div>
            </div>
          </div>

          {/* Reason Summary */}
          <div className="mb-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-3">Reason for Suspension</h2>
            <p className="text-gray-700">
              {userData.reason_for_disruption || "Your account has been suspended due to violations of our terms of service."}
            </p>
            
            <button 
              onClick={() => setShowDetails(!showDetails)}
              className="flex items-center text-sm text-blue-600 hover:text-blue-800 mt-3"
            >
              {showDetails ? 'Hide additional information' : 'What should I do next?'} 
            </button>
            
            {showDetails && (
              <div className="mt-3 p-4 bg-gray-50 rounded-lg border border-gray-200">
                <p className="text-sm text-gray-700 mb-3">
                  To resolve this issue and potentially restore your account access, please contact our support team directly. They will be able to provide you with specific information about your case and guide you through the next steps.
                </p>
                <p className="text-sm text-gray-700">
                  Our support team is available to assist you with any questions or concerns you may have regarding your account status.
                </p>
              </div>
            )}
          </div>

          {/* Action Buttons */}
          <div className="space-y-3">
            <a
              href={`mailto:info@battechno.com?subject=Account Suspension Inquiry - User ID: ${userData.id}&body=Hello Support Team,%0D%0A%0D%0AMy account has been suspended and I would like more information about this decision.%0D%0A%0D%0AUser ID: ${userData.id}%0D%0AName: ${userData.first_name} ${userData.last_name}%0D%0AEmail: ${userData.email}%0D%0A%0D%0APlease provide me with details about my account suspension and what steps I can take to resolve this issue.%0D%0A%0D%0AThank you.`}
              className="w-full flex items-center justify-center px-4 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors duration-200"
            >
              <Mail className="w-5 h-5 mr-2" />
              Contact Support
            </a>
            
            <button
              onClick={handleLogout}
              className="w-full flex items-center justify-center px-4 py-3 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition-colors duration-200"
            >
              <LogOut className="w-5 h-5 mr-2" />
              Log Out
            </button>
          </div>

          {/* Help Resources */}
          <div className="mt-8 pt-6 border-t border-gray-200">
            <h3 className="text-sm font-medium text-gray-900 mb-3">Help Resources</h3>
            <div className="space-y-2">
              <Link to="/privacy" className="flex items-center text-sm text-gray-600 hover:text-gray-900">
                <HelpCircle className="w-4 h-4 mr-2" />
                Community Guidelines
              </Link>
              <Link to="/terms" className="flex items-center text-sm text-gray-600 hover:text-gray-900">
                <FileText className="w-4 h-4 mr-2" />
                Terms of Service
              </Link>
              <a
                href="mailto:info@battechno.com?subject=Account%20Suspension%20FAQ"
                className="flex items-center text-sm text-gray-600 hover:text-gray-900"
              >
                <UserX className="w-4 h-4 mr-2" />
                Account Suspension FAQ
              </a>
            </div>
          </div>
        </div>
        
      </div>
    </div>
  );
};

export default AccountSuspended;