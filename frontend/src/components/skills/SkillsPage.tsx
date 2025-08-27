import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { Search, Filter, Plus, MapPin, Clock, Star } from 'lucide-react';
import { skillService, SkillFilters } from '../../services/skillService';
import { Skill } from '../../types';
import toast from 'react-hot-toast';

const SkillsPage: React.FC = () => {
  const [skills, setSkills] = useState<Skill[]>([]);
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState<SkillFilters>({
    page: 1,
    limit: 12,
  });
  const [pagination, setPagination] = useState({
    page: 1,
    limit: 12,
    total: 0,
    pages: 0,
  });

  const categories = [
    'Technology', 'Language', 'Music', 'Art', 'Cooking', 
    'Fitness', 'Business', 'Education', 'Crafts', 'Other'
  ];

  const levels = ['beginner', 'intermediate', 'advanced'];
  const locations = ['online', 'in-person', 'both'];
  const types = ['offer', 'request'];

  useEffect(() => {
    fetchSkills();
  }, [filters]);

  const fetchSkills = async () => {
    try {
      setLoading(true);
      const response = await skillService.getSkills(filters);
      setSkills(response.skills);
      setPagination(response.pagination);
    } catch (error) {
      toast.error('Failed to load skills');
    } finally {
      setLoading(false);
    }
  };

  const handleFilterChange = (key: keyof SkillFilters, value: any) => {
    setFilters(prev => ({
      ...prev,
      [key]: value,
      page: 1, // Reset to first page when filters change
    }));
  };

  const handlePageChange = (page: number) => {
    setFilters(prev => ({ ...prev, page }));
  };

  const getStatusBadge = (type: string) => {
    const isOffer = type === 'offer';
    return (
      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
        isOffer 
          ? 'bg-green-100 text-green-800' 
          : 'bg-blue-100 text-blue-800'
      }`}>
        {isOffer ? 'Offering' : 'Seeking'}
      </span>
    );
  };

  const getLevelBadge = (level: string) => {
    const colors = {
      beginner: 'bg-yellow-100 text-yellow-800',
      intermediate: 'bg-orange-100 text-orange-800',
      advanced: 'bg-red-100 text-red-800',
    };
    
    return (
      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${colors[level as keyof typeof colors]}`}>
        {level.charAt(0).toUpperCase() + level.slice(1)}
      </span>
    );
  };

  if (loading && skills.length === 0) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Browse Skills</h1>
          <p className="mt-2 text-gray-600">Find skills to learn or people to teach</p>
        </div>
        <Link
          to="/create-skill"
          className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-primary-600 hover:bg-primary-700"
        >
          <Plus className="h-4 w-4 mr-2" />
          Post Skill
        </Link>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-lg shadow p-6">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {/* Search */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Search
            </label>
            <div className="relative">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
              <input
                type="text"
                placeholder="Search skills..."
                className="pl-10 w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary-500"
                value={filters.search || ''}
                onChange={(e) => handleFilterChange('search', e.target.value)}
              />
            </div>
          </div>

          {/* Type */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Type
            </label>
            <select
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary-500"
              value={filters.type || ''}
              onChange={(e) => handleFilterChange('type', e.target.value || undefined)}
            >
              <option value="">All Types</option>
              {types.map(type => (
                <option key={type} value={type}>
                  {type.charAt(0).toUpperCase() + type.slice(1)}
                </option>
              ))}
            </select>
          </div>

          {/* Category */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Category
            </label>
            <select
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary-500"
              value={filters.category || ''}
              onChange={(e) => handleFilterChange('category', e.target.value || undefined)}
            >
              <option value="">All Categories</option>
              {categories.map(category => (
                <option key={category} value={category}>{category}</option>
              ))}
            </select>
          </div>

          {/* Level */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Level
            </label>
            <select
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary-500"
              value={filters.level || ''}
              onChange={(e) => handleFilterChange('level', e.target.value || undefined)}
            >
              <option value="">All Levels</option>
              {levels.map(level => (
                <option key={level} value={level}>
                  {level.charAt(0).toUpperCase() + level.slice(1)}
                </option>
              ))}
            </select>
          </div>
        </div>
      </div>

      {/* Skills Grid */}
      {skills.length === 0 ? (
        <div className="text-center py-12">
          <div className="text-gray-400 mb-4">
            <Search className="h-12 w-12 mx-auto" />
          </div>
          <h3 className="text-lg font-medium text-gray-900 mb-2">No skills found</h3>
          <p className="text-gray-600">Try adjusting your search criteria or be the first to post a skill!</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {skills.map((skill) => (
            <div key={skill.id} className="bg-white rounded-lg shadow-md overflow-hidden hover:shadow-lg transition-shadow">
              <div className="p-6">
                <div className="flex justify-between items-start mb-3">
                  {getStatusBadge(skill.type)}
                  {getLevelBadge(skill.level)}
                </div>
                
                <h3 className="text-lg font-semibold text-gray-900 mb-2">
                  {skill.title}
                </h3>
                
                <p className="text-gray-600 text-sm mb-4 line-clamp-3">
                  {skill.description}
                </p>
                
                <div className="flex items-center text-sm text-gray-500 mb-4">
                  <MapPin className="h-4 w-4 mr-1" />
                  {skill.location}
                  {skill.duration && (
                    <>
                      <span className="mx-2">•</span>
                      <Clock className="h-4 w-4 mr-1" />
                      {skill.duration}
                    </>
                  )}
                </div>
                
                <div className="flex items-center justify-between">
                  <div className="flex items-center">
                    <div className="w-8 h-8 bg-primary-100 rounded-full flex items-center justify-center text-primary-600 font-semibold text-sm">
                      {skill.user.firstName.charAt(0)}{skill.user.lastName.charAt(0)}
                    </div>
                    <div className="ml-2">
                      <p className="text-sm font-medium text-gray-900">
                        {skill.user.firstName} {skill.user.lastName}
                      </p>
                      <div className="flex items-center">
                        <Star className="h-3 w-3 text-yellow-400 mr-1" />
                        <span className="text-xs text-gray-500">
                          {skill.user.rating ? skill.user.rating.toFixed(1) : '0.0'} ({skill.user.totalRatings || 0})
                        </span>
                      </div>
                    </div>
                  </div>
                  
                  <Link
                    to={`/skills/${skill.id}`}
                    className="text-primary-600 hover:text-primary-700 text-sm font-medium"
                  >
                    View Details →
                  </Link>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Pagination */}
      {pagination.pages > 1 && (
        <div className="flex justify-center">
          <nav className="flex items-center space-x-2">
            <button
              onClick={() => handlePageChange(pagination.page - 1)}
              disabled={pagination.page === 1}
              className="px-3 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Previous
            </button>
            
            {Array.from({ length: pagination.pages }, (_, i) => i + 1).map((page) => (
              <button
                key={page}
                onClick={() => handlePageChange(page)}
                className={`px-3 py-2 text-sm font-medium rounded-md ${
                  page === pagination.page
                    ? 'bg-primary-600 text-white'
                    : 'text-gray-500 bg-white border border-gray-300 hover:bg-gray-50'
                }`}
              >
                {page}
              </button>
            ))}
            
            <button
              onClick={() => handlePageChange(pagination.page + 1)}
              disabled={pagination.page === pagination.pages}
              className="px-3 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Next
            </button>
          </nav>
        </div>
      )}
    </div>
  );
};

export default SkillsPage;
