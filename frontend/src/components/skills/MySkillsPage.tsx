import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { Plus, Edit, Trash2, Eye, MapPin, Clock, Tag } from 'lucide-react';
import { skillService } from '../../services/skillService';
import { Skill } from '../../types';
import toast from 'react-hot-toast';

const MySkillsPage: React.FC = () => {
  const [skills, setSkills] = useState<Skill[]>([]);
  const [loading, setLoading] = useState(true);
  const [deletingId, setDeletingId] = useState<string | null>(null);

  useEffect(() => {
    fetchMySkills();
  }, []);

  const fetchMySkills = async () => {
    try {
      setLoading(true);
      const response = await skillService.getUserSkills();
      setSkills(response.skills);
    } catch (error) {
      toast.error('Failed to load your skills');
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteSkill = async (skillId: string) => {
    if (!window.confirm('Are you sure you want to delete this skill?')) {
      return;
    }

    try {
      setDeletingId(skillId);
      await skillService.deleteSkill(skillId);
      setSkills(prev => prev.filter(skill => skill.id !== skillId));
      toast.success('Skill deleted successfully');
    } catch (error) {
      toast.error('Failed to delete skill');
    } finally {
      setDeletingId(null);
    }
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

  if (loading) {
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
          <h1 className="text-3xl font-bold text-gray-900">My Skills</h1>
          <p className="mt-2 text-gray-600">Manage your skill offers and requests</p>
        </div>
        <Link
          to="/create-skill"
          className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-primary-600 hover:bg-primary-700"
        >
          <Plus className="h-4 w-4 mr-2" />
          Add New Skill
        </Link>
      </div>

      {/* Skills List */}
      {skills.length === 0 ? (
        <div className="text-center py-12">
          <div className="text-gray-400 mb-4">
            <Plus className="h-12 w-12 mx-auto" />
          </div>
          <h3 className="text-lg font-medium text-gray-900 mb-2">No skills yet</h3>
          <p className="text-gray-600 mb-6">Start by creating your first skill offer or request.</p>
          <Link
            to="/create-skill"
            className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-primary-600 hover:bg-primary-700"
          >
            <Plus className="h-4 w-4 mr-2" />
            Create Your First Skill
          </Link>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {skills.map((skill) => (
            <div key={skill.id} className="bg-white rounded-lg shadow-md overflow-hidden">
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

                {skill.tags.length > 0 && (
                  <div className="flex flex-wrap gap-1 mb-4">
                    {skill.tags.slice(0, 3).map(tag => (
                      <span
                        key={tag}
                        className="inline-flex items-center px-2 py-1 rounded-full text-xs bg-gray-100 text-gray-700"
                      >
                        <Tag className="h-3 w-3 mr-1" />
                        {tag}
                      </span>
                    ))}
                    {skill.tags.length > 3 && (
                      <span className="text-xs text-gray-500">
                        +{skill.tags.length - 3} more
                      </span>
                    )}
                  </div>
                )}
                
                <div className="flex items-center justify-between">
                  <div className="text-xs text-gray-500">
                    Created {new Date(skill.createdAt).toLocaleDateString()}
                  </div>
                  
                  <div className="flex items-center space-x-2">
                    <Link
                      to={`/skills/${skill.id}`}
                      className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-full"
                      title="View Details"
                    >
                      <Eye className="h-4 w-4" />
                    </Link>
                    <button
                      onClick={() => handleDeleteSkill(skill.id)}
                      disabled={deletingId === skill.id}
                      className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-full disabled:opacity-50"
                      title="Delete Skill"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Stats */}
      {skills.length > 0 && (
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Your Skills Summary</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="text-center">
              <div className="text-2xl font-bold text-primary-600">{skills.length}</div>
              <div className="text-sm text-gray-600">Total Skills</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-green-600">
                {skills.filter(s => s.type === 'offer').length}
              </div>
              <div className="text-sm text-gray-600">Offers</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-blue-600">
                {skills.filter(s => s.type === 'request').length}
              </div>
              <div className="text-sm text-gray-600">Requests</div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default MySkillsPage;
