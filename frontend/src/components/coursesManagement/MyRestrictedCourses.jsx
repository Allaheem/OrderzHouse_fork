import React, { useState, useEffect } from 'react';
import API from "../../api/client.js";
import { useSelector } from 'react-redux';
import { Link } from 'react-router-dom';
import { toast } from 'react-toastify';
import { BookOpen, Search, DollarSign, Eye } from 'lucide-react';

const MyRestrictedCourses = () => {
  const { token } = useSelector((state) => state.auth);
  const [courses, setCourses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    const fetchMyCourses = async () => {
      if (!token) return;
      try {
        setLoading(true);
        const res = await API.get("/courses/accessible", {
          headers: { Authorization: `Bearer ${token}` },
        });
        setCourses(res.data.courses || []);
      } catch (err) {
        setError(err.response?.data?.message || 'Failed to load courses.');
        toast.error('Failed to load courses.');
      } finally {
        setLoading(false);
      }
    };

    fetchMyCourses();
  }, [token]);

  const filteredCourses = courses.filter(course =>
    course.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
    course.description.toLowerCase().includes(searchTerm.toLowerCase())
  );

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="animate-spin h-10 w-10 border-4 border-blue-600 rounded-full"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 p-6">
      <div className="max-w-7xl mx-auto">
        <div className="bg-white rounded-2xl shadow-lg p-8 mb-8 border border-gray-200">
          <div className="flex items-center space-x-6">
            <div className="p-4 rounded-2xl bg-gradient-to-br from-blue-500 to-indigo-600">
              <BookOpen className="w-8 h-8 text-white" />
            </div>
            <div>
              <h1 className="text-3xl font-bold text-gray-900">My Courses</h1>
              <p className="text-gray-600 mt-2">Courses you have access to</p>
            </div>
          </div>
        </div>

        {error && (
          <div className="bg-red-50 border border-red-200 text-red-700 px-6 py-4 rounded-2xl mb-8 flex items-center shadow-lg">
            <span>{error}</span>
          </div>
        )}

        <div className="bg-white rounded-2xl shadow-lg p-6 mb-8 border border-gray-200">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
            <input
              type="text"
              placeholder="Search my courses..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
            />
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredCourses.map((course) => (
            <div key={course.id} className="bg-white rounded-2xl shadow-lg p-6 border border-gray-200 hover:shadow-md transition-shadow">
              <h3 className="text-xl font-bold text-gray-900 mb-2">{course.title}</h3>
              <p className="text-gray-600 mb-4 line-clamp-2">{course.description}</p>
              <div className="flex items-center justify-between text-sm text-gray-500 mb-4">
                <span className="flex items-center">
                  <DollarSign className="w-4 h-4 mr-1" />
                  ${course.price}
                </span>
              </div>
              <Link
                to={`/course/${course.id}`}
                className="flex items-center justify-center w-full px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
              >
                <Eye className="w-4 h-4 mr-2" />
                View Course
              </Link>
            </div>
          ))}
        </div>

        {filteredCourses.length === 0 && !loading && (
          <div className="bg-white rounded-2xl shadow-lg p-12 text-center border border-gray-200">
            <BookOpen className="w-16 h-16 text-gray-400 mx-auto mb-4" />
            <h3 className="text-xl font-semibold text-gray-900 mb-2">No Accessible Courses</h3>
            <p className="text-gray-600 mb-6">
              You don't have access to any courses yet. Contact your administrator.
            </p>
          </div>
        )}
      </div>
    </div>
  );
};

export default MyRestrictedCourses;
