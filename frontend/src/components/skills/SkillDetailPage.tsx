import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, MapPin, Clock, Star, Tag, MessageSquare, User } from 'lucide-react';
import { skillService } from '../../services/skillService';
import { matchService } from '../../services/matchService';
import { useAuth } from '../../contexts/AuthContext';
import { Skill } from '../../types';
import toast from 'react-hot-toast';

const SkillDetailPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { user } = useAuth();
  const [skill, setSkill] = useState<Skill | null>(null);
  const [loading, setLoading] = useState(true);
  const [matchLoading, setMatchLoading] = useState(false);
  const [showMatchModal, setShowMatchModal] = useState(false);
  const [matchMessage, setMatchMessage] = useState('');
  const [potentialMatches, setPotentialMatches] = useState<Skill[]>([]);

  useEffect(() => {
    if (id) {
      fetchSkill();
      fetchPotentialMatches();
    }
  }, [id]);

  const fetchSkill = async () => {
    try {
      setLoading(true);
      const response = await skillService.getSkillById(id!);
      setSkill(response.skill);
    } catch (error) {
      toast.error('Failed to load skill details');
      navigate('/skills');
    } finally {
      setLoading(false);
    }
  };

  const fetchPotentialMatches = async () => {
    try {
      const response = await skillService.getSkillMatches(id!);
      setPotentialMatches(response.matches);
    } catch (error) {
      console.error('Failed to load potential matches');
    }
  };

  const handleCreateMatch = async () => {
    if (!user || !skill) return;

    try {
      setMatchLoading(true);
      await matchService.createMatch({
        offerSkillId: skill.type === 'offer' ? skill.id : '', // This would need to be selected from potential matches
        requestSkillId: skill.type === 'request' ? skill.id : '', // This would need to be selected from potential matches
        message: matchMessage,
      });
      toast.success('Match request sent successfully!');
      setShowMatchModal(false);
      setMatchMessage('');
    } catch (error) {
      toast.error('Failed to create match');
    } finally {
      setMatchLoading(false);
    }
  };

  const getStatusBadge = (type: string) => {
    const isOffer = type === 'offer';
    return (
      <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${
        isOffer 
          ? 'bg-green-100 text-green-800' 
          : 'bg-blue-100 text-blue-800'
      }`}>
        {isOffer ? 'Offering to Teach' : 'Seeking to Learn'}
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
      <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium ${colors[level as keyof typeof colors]}`}>
        {level.charAt(0).toUpperCase() + level.slice(1)} Level
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

  if (!skill) {
    return (
      <div className="text-center py-12">
        <h2 className="text-xl font-semibold text-gray-900 mb-2">Skill not found</h2>
        <p className="text-gray-600">The skill you're looking for doesn't exist or has been removed.</p>
      </div>
    );
  }

  const isOwnSkill = user?.id === skill.user.id;

  return (
    <div className="max-w-4xl mx-auto">
      {/* Header */}
      <div className="flex items-center mb-6">
        <button
          onClick={() => navigate(-1)}
          className="mr-4 p-2 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-full"
        >
          <ArrowLeft className="h-5 w-5" />
        </button>
        <div className="flex-1">
          <h1 className="text-3xl font-bold text-gray-900">{skill.title}</h1>
          <div className="flex items-center mt-2 space-x-4">
            {getStatusBadge(skill.type)}
            {getLevelBadge(skill.level)}
          </div>
        </div>
        {!isOwnSkill && user && (
          <button
            onClick={() => setShowMatchModal(true)}
            className="inline-flex items-center px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700"
          >
            <MessageSquare className="h-4 w-4 mr-2" />
            Request Match
          </button>
        )}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Main Content */}
        <div className="lg:col-span-2 space-y-6">
          {/* Skill Details */}
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">About this skill</h2>
            <p className="text-gray-700 leading-relaxed mb-6">{skill.description}</p>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
              <div className="flex items-center text-gray-600">
                <MapPin className="h-5 w-5 mr-2" />
                <span>{skill.location.charAt(0).toUpperCase() + skill.location.slice(1)}</span>
              </div>
              {skill.duration && (
                <div className="flex items-center text-gray-600">
                  <Clock className="h-5 w-5 mr-2" />
                  <span>{skill.duration}</span>
                </div>
              )}
            </div>

            {skill.tags.length > 0 && (
              <div>
                <h3 className="text-sm font-medium text-gray-700 mb-2">Tags</h3>
                <div className="flex flex-wrap gap-2">
                  {skill.tags.map(tag => (
                    <span
                      key={tag}
                      className="inline-flex items-center px-3 py-1 rounded-full text-sm bg-gray-100 text-gray-700"
                    >
                      <Tag className="h-3 w-3 mr-1" />
                      {tag}
                    </span>
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* Potential Matches */}
          {potentialMatches.length > 0 && (
            <div className="bg-white rounded-lg shadow p-6">
              <h2 className="text-xl font-semibold text-gray-900 mb-4">Potential Matches</h2>
              <div className="space-y-4">
                {potentialMatches.slice(0, 3).map(match => (
                  <div key={match.id} className="border border-gray-200 rounded-lg p-4">
                    <div className="flex justify-between items-start mb-2">
                      <h3 className="font-medium text-gray-900">{match.title}</h3>
                      <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${
                        match.type === 'offer' 
                          ? 'bg-green-100 text-green-800' 
                          : 'bg-blue-100 text-blue-800'
                      }`}>
                        {match.type === 'offer' ? 'Offering' : 'Seeking'}
                      </span>
                    </div>
                    <p className="text-gray-600 text-sm mb-3 line-clamp-2">{match.description}</p>
                    <div className="flex items-center justify-between">
                      <div className="flex items-center">
                        <div className="w-6 h-6 bg-primary-100 rounded-full flex items-center justify-center text-primary-600 font-semibold text-xs">
                          {match.user.firstName.charAt(0)}{match.user.lastName.charAt(0)}
                        </div>
                        <span className="ml-2 text-sm text-gray-700">
                          {match.user.firstName} {match.user.lastName}
                        </span>
                      </div>
                      <button
                        onClick={() => navigate(`/skills/${match.id}`)}
                        className="text-primary-600 hover:text-primary-700 text-sm font-medium"
                      >
                        View Details →
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* User Profile */}
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">About the {skill.type === 'offer' ? 'teacher' : 'learner'}</h2>
            <div className="flex items-center mb-4">
              <div className="w-12 h-12 bg-primary-100 rounded-full flex items-center justify-center text-primary-600 font-semibold text-lg">
                {skill.user.firstName.charAt(0)}{skill.user.lastName.charAt(0)}
              </div>
              <div className="ml-3">
                <h3 className="font-medium text-gray-900">
                  {skill.user.firstName} {skill.user.lastName}
                </h3>
                <div className="flex items-center">
                  <Star className="h-4 w-4 text-yellow-400 mr-1" />
                  <span className="text-sm text-gray-600">
                    {skill.user.rating.toFixed(1)} ({skill.user.totalRatings} ratings)
                  </span>
                </div>
              </div>
            </div>
            {skill.user.bio && (
              <p className="text-gray-700 text-sm">{skill.user.bio}</p>
            )}
          </div>

          {/* Skill Stats */}
          <div className="bg-white rounded-lg shadow p-6">
            <h2 className="text-lg font-semibold text-gray-900 mb-4">Skill Information</h2>
            <div className="space-y-3">
              <div className="flex justify-between">
                <span className="text-gray-600">Category</span>
                <span className="font-medium">{skill.category}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Level</span>
                <span className="font-medium">{skill.level.charAt(0).toUpperCase() + skill.level.slice(1)}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-gray-600">Location</span>
                <span className="font-medium">{skill.location.charAt(0).toUpperCase() + skill.location.slice(1)}</span>
              </div>
              {skill.duration && (
                <div className="flex justify-between">
                  <span className="text-gray-600">Duration</span>
                  <span className="font-medium">{skill.duration}</span>
                </div>
              )}
              <div className="flex justify-between">
                <span className="text-gray-600">Posted</span>
                <span className="font-medium">
                  {new Date(skill.createdAt).toLocaleDateString()}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Match Modal */}
      {showMatchModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 max-w-md w-full mx-4">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Request a Match</h3>
            <p className="text-gray-600 mb-4">
              Send a message to {skill.user.firstName} about this skill exchange.
            </p>
            <textarea
              value={matchMessage}
              onChange={(e) => setMatchMessage(e.target.value)}
              placeholder="Introduce yourself and explain why you're interested in this skill exchange..."
              rows={4}
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary-500 mb-4"
            />
            <div className="flex justify-end space-x-3">
              <button
                onClick={() => setShowMatchModal(false)}
                className="px-4 py-2 text-gray-700 border border-gray-300 rounded-md hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                onClick={handleCreateMatch}
                disabled={matchLoading}
                className="px-4 py-2 bg-primary-600 text-white rounded-md hover:bg-primary-700 disabled:opacity-50"
              >
                {matchLoading ? 'Sending...' : 'Send Request'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default SkillDetailPage;
