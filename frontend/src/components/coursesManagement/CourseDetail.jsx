import React, { useState, useEffect } from 'react';
import API from "../../api/client.js";
import { useParams, Link, useNavigate } from 'react-router-dom';
import { useSelector } from 'react-redux';
import { toast } from 'react-toastify';
import { ArrowLeft, BookOpen, Download, Clock, DollarSign, AlertCircle, Lock } from 'lucide-react';

const isSafeMaterialUrl = (value) => {
  if (!value || typeof value !== 'string') return false;
  try {
    const parsed = new URL(value);
    return parsed.protocol === 'http:' || parsed.protocol === 'https:';
  } catch {
    return false;
  }
};

const CourseDetail = () => {
  const { id } = useParams();
  const { token, userData } = useSelector((state) => state.auth);
  const navigate = useNavigate();
  const [course, setCourse] = useState(null);
  const [materials, setMaterials] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [hasAccess, setHasAccess] = useState(false);
  const [checkingAccess, setCheckingAccess] = useState(true);
  useEffect(() => {
    const fetchData = async () => {
      if (!token || !id) return;
      try {
        const accessRes = await API.get(`/courses/check-access/${id}`, {
          headers: { Authorization: `Bearer ${token}` },
        });
        setHasAccess(accessRes.data.hasAccess);

        if (accessRes.data.hasAccess || userData?.role_id === 1) {
          const [courseRes, materialsRes] = await Promise.all([
            API.get(`/courses/view/${id}`, {
              headers: { Authorization: `Bearer ${token}` },
            }),
            API.get(`/courses/${id}/materials`, {
              headers: { Authorization: `Bearer ${token}` },
            }),
          ]);
          setCourse(courseRes.data.course);
          setMaterials(materialsRes.data.materials || []);
        }
      } catch (err) {
        console.error('Error fetching course data:', err);
        if (err.response?.status === 403) {
          setError('Access Denied');
        } else {
          setError(err.response?.data?.message || 'Failed to load course.');
        }
      } finally {
        setLoading(false);
        setCheckingAccess(false);
      }
    };

    fetchData();
  }, [id, token, userData?.role_id]);

  if (checkingAccess) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="animate-spin h-10 w-10 border-4 border-blue-600 rounded-full"></div>
      </div>
    );
  }

  if (!hasAccess && userData?.role_id !== 1) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 flex items-center justify-center p-4">
        <div className="bg-white rounded-2xl shadow-lg p-8 max-w-md w-full text-center border border-gray-200">
          <Lock className="w-16 h-16 text-red-500 mx-auto mb-4" />
          <h2 className="text-2xl font-bold text-gray-900 mb-4">Access Denied</h2>
          <p className="text-gray-600 mb-6">You don't have permission to access this course.</p>
          <Link
            to="/my-courses"
            className="inline-flex items-center px-6 py-3 bg-blue-600 text-white rounded-xl hover:bg-blue-700 transition-colors"
          >
            <ArrowLeft className="w-5 h-5 mr-2" />
            Back to My Courses
          </Link>
        </div>
      </div>
    );
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="animate-spin h-10 w-10 border-4 border-blue-600 rounded-full"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center p-6">
        <div className="bg-white rounded-2xl shadow-lg p-8 max-w-md w-full text-center border border-red-200">
          <AlertCircle className="w-16 h-16 text-red-500 mx-auto mb-4" />
          <h2 className="text-2xl font-bold text-gray-900 mb-4">Error</h2>
          <p className="text-gray-600 mb-6">{error}</p>
          <button
            onClick={() => navigate(-1)}
            className="px-6 py-3 bg-blue-600 text-white rounded-xl hover:bg-blue-700 transition-colors"
          >
            Go Back
          </button>
        </div>
      </div>
    );
  }

  if (!course) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center p-6">
        <div className="bg-white rounded-2xl shadow-lg p-8 max-w-md w-full text-center border border-gray-200">
          <BookOpen className="w-16 h-16 text-gray-400 mx-auto mb-4" />
          <h2 className="text-2xl font-bold text-gray-900 mb-4">Course Not Found</h2>
          <p className="text-gray-600 mb-6">The requested course could not be found.</p>
          <Link
            to="/my-courses"
            className="px-6 py-3 bg-blue-600 text-white rounded-xl hover:bg-blue-700 transition-colors"
          >
            Back to Courses
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100">
      <header className="bg-white shadow-sm">
        <div className="max-w-7xl mx-auto px-4 py-6">
          <button
            onClick={() => navigate(-1)}
            className="flex items-center text-blue-600 mb-4 hover:text-blue-800 transition-colors"
          >
            <ArrowLeft className="w-5 h-5 mr-1" /> Back
          </button>
          <div className="flex flex-col lg:flex-row gap-8">
            <div className="flex-1">
              <h1 className="text-3xl font-bold">{course.title}</h1>
              <p className="text-gray-600 mt-2">{course.description}</p>
              <div className="flex flex-wrap gap-6 mt-4 text-gray-600">
                <span className="flex items-center"><DollarSign className="w-5 h-5 mr-1" />${course.price}</span>
                <span className="flex items-center"><Clock className="w-5 h-5 mr-1" />10 hours</span>
                <span className="flex items-center"><BookOpen className="w-5 h-5 mr-1" />{materials.length} materials</span>
              </div>
            </div>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 py-8">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div className="lg:col-span-2">
            <h2 className="text-2xl font-bold mb-6">Course Content</h2>
            <div className="bg-white rounded-lg shadow-sm">
              {materials.length > 0 ? (
                materials.map((material) => (
                  <div key={material.id} className="p-6 border-b last:border-b-0 hover:bg-gray-50">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center">
                        <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center mr-3">
                          <BookOpen className="w-4 h-4 text-blue-600" />
                        </div>
                        <div>
                          <h3 className="font-semibold">{material.title}</h3>
                          <p className="text-sm text-gray-500">Type: {material.file_type || 'N/A'}</p>
                        </div>
                      </div>
                      {isSafeMaterialUrl(material.file_url) ? (
                        <a
                          href={material.file_url}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="text-blue-600 hover:text-blue-800 transition-colors"
                          title="Download Material"
                        >
                          <Download className="w-5 h-5" />
                        </a>
                      ) : (
                        <button
                          type="button"
                          onClick={() => toast.error('Material link is unavailable')}
                          className="text-gray-400 cursor-not-allowed"
                          title="Unavailable material link"
                        >
                          <Download className="w-5 h-5" />
                        </button>
                      )}
                    </div>
                  </div>
                ))
              ) : (
                <div className="p-6 text-center text-gray-500">
                  No materials available for this course yet.
                </div>
              )}
            </div>
          </div>

          <div className="lg:col-span-1">
            <div className="bg-white p-6 rounded-lg shadow-sm">
              <h3 className="font-bold mb-4">Course Information</h3>
              <ul className="space-y-2 text-sm text-gray-600">
                <li><strong>ID:</strong> {course.id}</li>
                <li><strong>Created:</strong> {new Date(course.created_at).toLocaleDateString()}</li>
              </ul>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
};

export default CourseDetail;
