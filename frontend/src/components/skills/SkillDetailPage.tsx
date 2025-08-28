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
  const [selectedOfferSkill, setSelectedOfferSkill] = useState<Skill | null>(null);

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
    if (!user || !skill || !selectedOfferSkill) return;

    try {
      setMatchLoading(true);
      
      // Determine which skill is offered and which is requested
      let offerSkillId, requestSkillId;
      
      if (skill.type === 'offer') {
        // Current user is viewing someone else's offer skill
        // They want to learn this skill, so they offer one of their own skills in exchange
        offerSkillId = selectedOfferSkill.id; // Current user's skill (what they're offering)
        requestSkillId = skill.id; // The skill they want to learn
      } else {
        // Current user is viewing someone else's request skill
        // They want to fulfill this request by offering their skill
        offerSkillId = selectedOfferSkill.id; // Current user's skill (what they're offering)
        requestSkillId = skill.id; // The skill they want to fulfill
      }

      const response = await matchService.createMatch({
        offerSkillId,
        requestSkillId,
        message: matchMessage,
      });
      
      toast.success('Match request sent successfully!');
      setShowMatchModal(false);
      setMatchMessage('');
      setSelectedOfferSkill(null);
      
      // Optionally refresh the potential matches
      fetchPotentialMatches();
    } catch (error: any) {
      const errorMessage = error.response?.data?.error || 'Failed to create match';
      toast.error(errorMessage);
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

  const renderPotentialMatches = () => {
    if (potentialMatches.length === 0) {
      return (
        <div className="text-center py-8">
          <p className="text-gray-500">No potential matches found for this skill.</p>
        </div>
      );
    }

    return (
      <div className="space-y-4">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Potential Matches</h3>
        {potentialMatches.map((match) => (
          <div key={match.id} className="border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow">
            <div className="flex items-start justify-between">
              <div className="flex-1">
                <div className="flex items-center mb-2">
                  <div className="w-8 h-8 bg-primary-100 rounded-full flex items-center justify-center text-primary-600 font-semibold text-sm">
                    {match.user ? `${match.user.firstName?.charAt(0) || 'U'}${match.user.lastName?.charAt(0) || 'N'}` : 'UN'}
                  </div>
                  <div className="ml-2">
                    <p className="text-sm font-medium text-gray-900">
                      {match.user ? `${match.user.firstName || 'Unknown'} ${match.user.lastName || 'User'}` : 'Unknown User'}
                    </p>
                    <div className="flex items-center">
                      <Star className="h-3 w-3 text-yellow-400 mr-1" />
                      <span className="text-xs text-gray-500">
                        {match.user?.rating ? match.user.rating.toFixed(1) : '0.0'} ({match.user?.totalRatings || 0})
                      </span>
                    </div>
                  </div>
                </div>
                
                <div className="flex items-center gap-2 mb-2">
                  <h4 className="font-medium text-gray-900">{match.title}</h4>
                  {getStatusBadge(match.type)}
                  {getLevelBadge(match.level)}
                </div>
                
                <p className="text-sm text-gray-600 line-clamp-2 mb-2">{match.description}</p>
                
                <div className="flex items-center gap-4 text-xs text-gray-500">
                  <div className="flex items-center">
                    <MapPin className="h-3 w-3 mr-1" />
                    {match.location}
                  </div>
                  {match.duration && (
                    <div className="flex items-center">
                      <Clock className="h-3 w-3 mr-1" />
                      {match.duration}
                    </div>
                  )}
                </div>
              </div>
              
              <div className="ml-4 text-right">
                {match.matchScore !== undefined && (
                  <div className="mb-2">
                    <div className="text-sm font-medium text-gray-900">
                      Match Score: {match.matchScore.toFixed(2)}
                    </div>
                    <div className="w-16 h-2 bg-gray-200 rounded-full overflow-hidden">
                      <div 
                        className={`h-full rounded-full ${
                          match.matchScore >= 0.8 ? 'bg-green-500' :
                          match.matchScore >= 0.6 ? 'bg-yellow-500' :
                          'bg-red-500'
                        }`}
                        style={{ width: `${match.matchScore * 100}%` }}
                      />
                    </div>
                  </div>
                )}
                
                {match.user?.id === user?.id ? (
                  <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                    Your Skill
                  </span>
                ) : (
                  <button
                    onClick={() => handleMatchWithSkill(match)}
                    className="inline-flex items-center px-3 py-1 rounded-md text-sm font-medium bg-primary-600 text-white hover:bg-primary-700 transition-colors"
                  >
                    <MessageSquare className="h-3 w-3 mr-1" />
                    Match
                  </button>
                )}
              </div>
            </div>
          </div>
        ))}
      </div>
    );
  };

  const handleMatchWithSkill = (selectedSkill: Skill) => {
    if (!user) {
      toast.error('Please log in to create matches');
      return;
    }

    // Check if the selected skill belongs to the current user
    if (selectedSkill.user.id === user.id) {
      // User is selecting their own skill to offer
      setSelectedOfferSkill(selectedSkill);
      setShowMatchModal(true);
    } else {
      // User is selecting someone else's skill - this shouldn't happen in normal flow
      toast.error('Invalid match selection');
    }
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
          {renderPotentialMatches()}
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
                    {skill.user.rating ? skill.user.rating.toFixed(1) : '0.0'} ({skill.user.totalRatings || 0} ratings)
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
          <div className="bg-white rounded-lg p-6 w-full max-w-md mx-4">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Create Match</h3>
            
            <div className="space-y-4 mb-4">
              <div className="border border-gray-200 rounded-lg p-3">
                <h4 className="font-medium text-gray-900 mb-2">Skill Exchange</h4>
                <div className="space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-gray-600">You offer:</span>
                    <span className="text-sm font-medium text-green-600">
                      {selectedOfferSkill?.title}
                    </span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-gray-600">You receive:</span>
                    <span className="text-sm font-medium text-blue-600">
                      {skill?.title}
                    </span>
                  </div>
                </div>
                
                {/* Compatibility indicators */}
                {selectedOfferSkill && skill && (
                  <div className="mt-3 pt-3 border-t border-gray-200">
                    <h5 className="text-xs font-medium text-gray-700 mb-2">Compatibility</h5>
                    <div className="space-y-1">
                      <div className="flex items-center justify-between text-xs">
                        <span>Level:</span>
                        <span className={`px-2 py-1 rounded ${
                          selectedOfferSkill.level === skill.level ? 'bg-green-100 text-green-800' :
                          Math.abs(['beginner', 'intermediate', 'advanced'].indexOf(selectedOfferSkill.level) - 
                                  ['beginner', 'intermediate', 'advanced'].indexOf(skill.level)) === 1 ? 
                          'bg-yellow-100 text-yellow-800' : 'bg-red-100 text-red-800'
                        }`}>
                          {selectedOfferSkill.level} ↔ {skill.level}
                        </span>
                      </div>
                      <div className="flex items-center justify-between text-xs">
                        <span>Location:</span>
                        <span className={`px-2 py-1 rounded ${
                          selectedOfferSkill.location === skill.location ? 'bg-green-100 text-green-800' :
                          selectedOfferSkill.location === 'both' || skill.location === 'both' ? 
                          'bg-yellow-100 text-yellow-800' : 'bg-red-100 text-red-800'
                        }`}>
                          {selectedOfferSkill.location} ↔ {skill.location}
                        </span>
                      </div>
                      <div className="flex items-center justify-between text-xs">
                        <span>Category:</span>
                        <span className={`px-2 py-1 rounded ${
                          selectedOfferSkill.category === skill.category ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'
                        }`}>
                          {selectedOfferSkill.category === skill.category ? 'Same' : 'Different'}
                        </span>
                      </div>
                    </div>
                  </div>
                )}
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Message (optional)
                </label>
                <textarea
                  value={matchMessage}
                  onChange={(e) => setMatchMessage(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-transparent"
                  rows={3}
                  placeholder="Add a personal message to your match request..."
                />
              </div>
            </div>
            
            <div className="flex justify-end space-x-3">
              <button
                onClick={() => {
                  setShowMatchModal(false);
                  setMatchMessage('');
                  setSelectedOfferSkill(null);
                }}
                className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 rounded-md hover:bg-gray-200 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={handleCreateMatch}
                disabled={matchLoading}
                className="px-4 py-2 text-sm font-medium text-white bg-primary-600 rounded-md hover:bg-primary-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                {matchLoading ? 'Creating...' : 'Create Match'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default SkillDetailPage;
