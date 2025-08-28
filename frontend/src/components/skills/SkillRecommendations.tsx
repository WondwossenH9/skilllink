import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Star, MapPin, Clock, Tag, TrendingUp, User } from 'lucide-react';
import { skillService } from '../../services/skillService';
import { Skill } from '../../types';
import toast from 'react-hot-toast';

interface SkillRecommendationsProps {
  limit?: number;
  showPreferences?: boolean;
}

const SkillRecommendations: React.FC<SkillRecommendationsProps> = ({ 
  limit = 5, 
  showPreferences = false 
}) => {
  const navigate = useNavigate();
  const [recommendations, setRecommendations] = useState<Skill[]>([]);
  const [preferences, setPreferences] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchRecommendations();
  }, []);

  const fetchRecommendations = async () => {
    try {
      setLoading(true);
      const response = await skillService.getSkillRecommendations();
      setRecommendations(response.recommendations.slice(0, limit));
      setPreferences(response.preferences);
    } catch (error) {
      console.error('Failed to load recommendations:', error);
      toast.error('Failed to load recommendations');
    } finally {
      setLoading(false);
    }
  };

  const getStatusBadge = (type: string) => {
    const isOffer = type === 'offer';
    return (
      <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${
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
      <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${colors[level as keyof typeof colors]}`}>
        {level}
      </span>
    );
  };

  if (loading) {
    return (
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <div className="animate-pulse">
          <div className="h-6 bg-gray-200 rounded w-1/3 mb-4"></div>
          <div className="space-y-3">
            {[...Array(limit)].map((_, i) => (
              <div key={i} className="h-20 bg-gray-200 rounded"></div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  if (recommendations.length === 0) {
    return (
      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
          <TrendingUp className="h-5 w-5 mr-2 text-primary-600" />
          Recommended for You
        </h3>
        <p className="text-gray-500 text-center py-8">
          No recommendations available yet. Add some skills to get personalized recommendations!
        </p>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
      <h3 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
        <TrendingUp className="h-5 w-5 mr-2 text-primary-600" />
        Recommended for You
      </h3>

      {showPreferences && preferences && (
        <div className="mb-6 p-4 bg-gray-50 rounded-lg">
          <h4 className="text-sm font-medium text-gray-900 mb-3">Your Preferences</h4>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-xs">
            <div>
              <span className="text-gray-600">Top Categories:</span>
              <div className="flex flex-wrap gap-1 mt-1">
                {preferences.topCategories.slice(0, 3).map((category: string) => (
                  <span key={category} className="px-2 py-1 bg-primary-100 text-primary-800 rounded">
                    {category}
                  </span>
                ))}
              </div>
            </div>
            <div>
              <span className="text-gray-600">Preferred Types:</span>
              <div className="flex flex-wrap gap-1 mt-1">
                {preferences.preferredTypes.map((type: string) => (
                  <span key={type} className="px-2 py-1 bg-blue-100 text-blue-800 rounded">
                    {type}
                  </span>
                ))}
              </div>
            </div>
            <div>
              <span className="text-gray-600">Skill Levels:</span>
              <div className="flex flex-wrap gap-1 mt-1">
                {preferences.preferredLevels.map((level: string) => (
                  <span key={level} className="px-2 py-1 bg-green-100 text-green-800 rounded">
                    {level}
                  </span>
                ))}
              </div>
            </div>
            <div>
              <span className="text-gray-600">Top Tags:</span>
              <div className="flex flex-wrap gap-1 mt-1">
                {preferences.topTags.slice(0, 3).map((tag: string) => (
                  <span key={tag} className="px-2 py-1 bg-gray-100 text-gray-800 rounded">
                    {tag}
                  </span>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}

      <div className="space-y-4">
        {recommendations.map((skill) => (
          <div 
            key={skill.id} 
            className="border border-gray-200 rounded-lg p-4 hover:shadow-md transition-shadow cursor-pointer"
            onClick={() => navigate(`/skills/${skill.id}`)}
          >
            <div className="flex items-start justify-between">
              <div className="flex-1">
                <div className="flex items-center mb-2">
                  <div className="w-8 h-8 bg-primary-100 rounded-full flex items-center justify-center text-primary-600 font-semibold text-sm">
                    {skill.user ? `${skill.user.firstName?.charAt(0) || 'U'}${skill.user.lastName?.charAt(0) || 'N'}` : 'UN'}
                  </div>
                  <div className="ml-2">
                    <p className="text-sm font-medium text-gray-900">
                      {skill.user ? `${skill.user.firstName || 'Unknown'} ${skill.user.lastName || 'User'}` : 'Unknown User'}
                    </p>
                    <div className="flex items-center">
                      <Star className="h-3 w-3 text-yellow-400 mr-1" />
                      <span className="text-xs text-gray-500">
                        {skill.user?.rating ? skill.user.rating.toFixed(1) : '0.0'} ({skill.user?.totalRatings || 0})
                      </span>
                    </div>
                  </div>
                </div>
                
                <div className="flex items-center gap-2 mb-2">
                  <h4 className="font-medium text-gray-900">{skill.title}</h4>
                  {getStatusBadge(skill.type)}
                  {getLevelBadge(skill.level)}
                </div>
                
                <p className="text-sm text-gray-600 line-clamp-2 mb-2">{skill.description}</p>
                
                <div className="flex items-center gap-4 text-xs text-gray-500">
                  <div className="flex items-center">
                    <MapPin className="h-3 w-3 mr-1" />
                    {skill.location}
                  </div>
                  {skill.duration && (
                    <div className="flex items-center">
                      <Clock className="h-3 w-3 mr-1" />
                      {skill.duration}
                    </div>
                  )}
                  {skill.tags && skill.tags.length > 0 && (
                    <div className="flex items-center">
                      <Tag className="h-3 w-3 mr-1" />
                      {skill.tags.slice(0, 2).join(', ')}
                    </div>
                  )}
                </div>
              </div>
              
              <div className="ml-4 text-right">
                {skill.recommendationScore !== undefined && (
                  <div className="mb-2">
                    <div className="text-sm font-medium text-gray-900">
                      Match: {skill.recommendationScore.toFixed(2)}
                    </div>
                    <div className="w-16 h-2 bg-gray-200 rounded-full overflow-hidden">
                      <div 
                        className={`h-full rounded-full ${
                          skill.recommendationScore >= 0.8 ? 'bg-green-500' :
                          skill.recommendationScore >= 0.6 ? 'bg-yellow-500' :
                          'bg-red-500'
                        }`}
                        style={{ width: `${skill.recommendationScore * 100}%` }}
                      />
                    </div>
                  </div>
                )}
                
                <span className="text-xs text-primary-600 font-medium">View Details →</span>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default SkillRecommendations;
