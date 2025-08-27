import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { MessageSquare, Check, X, Clock, Star, User } from 'lucide-react';
import { matchService, MatchFilters } from '../../services/matchService';
import { Match } from '../../types';
import toast from 'react-hot-toast';

const MatchesPage: React.FC = () => {
  const [matches, setMatches] = useState<Match[]>([]);
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState<MatchFilters>({});
  const [updatingId, setUpdatingId] = useState<string | null>(null);

  useEffect(() => {
    fetchMatches();
  }, [filters]);

  const fetchMatches = async () => {
    try {
      setLoading(true);
      const response = await matchService.getMatches(filters);
      setMatches(response.matches);
    } catch (error) {
      toast.error('Failed to load matches');
    } finally {
      setLoading(false);
    }
  };

  const handleUpdateStatus = async (matchId: string, status: 'accepted' | 'rejected' | 'completed') => {
    try {
      setUpdatingId(matchId);
      const response = await matchService.updateMatchStatus(matchId, status);
      setMatches(prev => prev.map(match => 
        match.id === matchId ? response.match : match
      ));
      toast.success(`Match ${status} successfully`);
    } catch (error) {
      toast.error(`Failed to ${status} match`);
    } finally {
      setUpdatingId(null);
    }
  };

  const getStatusBadge = (status: string) => {
    const colors = {
      pending: 'bg-yellow-100 text-yellow-800',
      accepted: 'bg-green-100 text-green-800',
      rejected: 'bg-red-100 text-red-800',
      completed: 'bg-blue-100 text-blue-800',
    };
    
    return (
      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${colors[status as keyof typeof colors]}`}>
        {status.charAt(0).toUpperCase() + status.slice(1)}
      </span>
    );
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'pending':
        return <Clock className="h-4 w-4" />;
      case 'accepted':
        return <Check className="h-4 w-4" />;
      case 'rejected':
        return <X className="h-4 w-4" />;
      case 'completed':
        return <Star className="h-4 w-4" />;
      default:
        return <MessageSquare className="h-4 w-4" />;
    }
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
          <h1 className="text-3xl font-bold text-gray-900">My Matches</h1>
          <p className="mt-2 text-gray-600">View and manage your skill exchange requests</p>
        </div>
      </div>

      {/* Filters */}
      <div className="bg-white rounded-lg shadow p-6">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Filter by Type
            </label>
            <select
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary-500"
              value={filters.type || ''}
              onChange={(e) => setFilters(prev => ({ ...prev, type: e.target.value as 'sent' | 'received' || undefined }))}
            >
              <option value="">All Matches</option>
              <option value="sent">Sent Requests</option>
              <option value="received">Received Requests</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Filter by Status
            </label>
            <select
              className="w-full border border-gray-300 rounded-md px-3 py-2 focus:outline-none focus:ring-2 focus:ring-primary-500"
              value={filters.status || ''}
              onChange={(e) => setFilters(prev => ({ ...prev, status: e.target.value as any || undefined }))}
            >
              <option value="">All Statuses</option>
              <option value="pending">Pending</option>
              <option value="accepted">Accepted</option>
              <option value="rejected">Rejected</option>
              <option value="completed">Completed</option>
            </select>
          </div>

          <div className="flex items-end">
            <button
              onClick={() => setFilters({})}
              className="w-full px-4 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50"
            >
              Clear Filters
            </button>
          </div>
        </div>
      </div>

      {/* Matches List */}
      {matches.length === 0 ? (
        <div className="text-center py-12">
          <div className="text-gray-400 mb-4">
            <MessageSquare className="h-12 w-12 mx-auto" />
          </div>
          <h3 className="text-lg font-medium text-gray-900 mb-2">No matches found</h3>
          <p className="text-gray-600 mb-6">
            {filters.type || filters.status 
              ? 'Try adjusting your filters or browse skills to create new matches.'
              : 'Start by browsing skills and creating match requests.'
            }
          </p>
          <Link
            to="/skills"
            className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-primary-600 hover:bg-primary-700"
          >
            Browse Skills
          </Link>
        </div>
      ) : (
        <div className="space-y-4">
          {matches.map((match) => {
            // Skip rendering if match data is incomplete
            if (!match?.offerSkill?.user || !match?.requestSkill?.user) {
              return null;
            }
            return (
            <div key={match.id} className="bg-white rounded-lg shadow p-6">
              <div className="flex items-start justify-between mb-4">
                <div className="flex items-center space-x-3">
                  {getStatusIcon(match.status)}
                  {getStatusBadge(match.status)}
                </div>
                <div className="text-sm text-gray-500">
                  {new Date(match.createdAt).toLocaleDateString()}
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-4">
                {/* Offer Skill */}
                <div className="border border-gray-200 rounded-lg p-4">
                  <h3 className="font-medium text-gray-900 mb-2">Offering</h3>
                  <div className="flex items-center mb-2">
                    <div className="w-8 h-8 bg-primary-100 rounded-full flex items-center justify-center text-primary-600 font-semibold text-sm">
                      {match.offerSkill.user ? `${match.offerSkill.user.firstName?.charAt(0) || 'U'}${match.offerSkill.user.lastName?.charAt(0) || 'N'}` : 'UN'}
                    </div>
                    <div className="ml-2">
                      <p className="text-sm font-medium text-gray-900">
                        {match.offerSkill.user ? `${match.offerSkill.user.firstName || 'Unknown'} ${match.offerSkill.user.lastName || 'User'}` : 'Unknown User'}
                      </p>
                      <div className="flex items-center">
                        <Star className="h-3 w-3 text-yellow-400 mr-1" />
                        <span className="text-xs text-gray-500">
                          {match.offerSkill.user?.rating ? match.offerSkill.user.rating.toFixed(1) : '0.0'} ({match.offerSkill.user?.totalRatings || 0})
                        </span>
                      </div>
                    </div>
                  </div>
                  <h4 className="font-medium text-gray-900">{match.offerSkill.title}</h4>
                  <p className="text-sm text-gray-600 line-clamp-2">{match.offerSkill.description}</p>
                </div>

                {/* Request Skill */}
                <div className="border border-gray-200 rounded-lg p-4">
                  <h3 className="font-medium text-gray-900 mb-2">Requesting</h3>
                  <div className="flex items-center mb-2">
                    <div className="w-8 h-8 bg-primary-100 rounded-full flex items-center justify-center text-primary-600 font-semibold text-sm">
                      {match.requestSkill.user ? `${match.requestSkill.user.firstName?.charAt(0) || 'U'}${match.requestSkill.user.lastName?.charAt(0) || 'N'}` : 'UN'}
                    </div>
                    <div className="ml-2">
                      <p className="text-sm font-medium text-gray-900">
                        {match.requestSkill.user ? `${match.requestSkill.user.firstName || 'Unknown'} ${match.requestSkill.user.lastName || 'User'}` : 'Unknown User'}
                      </p>
                      <div className="flex items-center">
                        <Star className="h-3 w-3 text-yellow-400 mr-1" />
                        <span className="text-xs text-gray-500">
                          {match.requestSkill.user?.rating ? match.requestSkill.user.rating.toFixed(1) : '0.0'} ({match.requestSkill.user?.totalRatings || 0})
                        </span>
                      </div>
                    </div>
                  </div>
                  <h4 className="font-medium text-gray-900">{match.requestSkill.title}</h4>
                  <p className="text-sm text-gray-600 line-clamp-2">{match.requestSkill.description}</p>
                </div>
              </div>

              {match.message && (
                <div className="bg-gray-50 rounded-lg p-4 mb-4">
                  <h4 className="font-medium text-gray-900 mb-2">Message</h4>
                  <p className="text-gray-700">{match.message}</p>
                </div>
              )}

              {/* Actions */}
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-4">
                  <Link
                    to={`/skills/${match.offerSkill.id}`}
                    className="text-primary-600 hover:text-primary-700 text-sm font-medium"
                  >
                    View Offer →
                  </Link>
                  <Link
                    to={`/skills/${match.requestSkill.id}`}
                    className="text-primary-600 hover:text-primary-700 text-sm font-medium"
                  >
                    View Request →
                  </Link>
                </div>

                {/* Status Actions */}
                {match.status === 'pending' && match.offerer?.id === match.offerSkill.user?.id && (
                  <div className="flex items-center space-x-2">
                    <button
                      onClick={() => handleUpdateStatus(match.id, 'accepted')}
                      disabled={updatingId === match.id}
                      className="inline-flex items-center px-3 py-1 border border-transparent text-sm font-medium rounded-md text-white bg-green-600 hover:bg-green-700 disabled:opacity-50"
                    >
                      <Check className="h-3 w-3 mr-1" />
                      Accept
                    </button>
                    <button
                      onClick={() => handleUpdateStatus(match.id, 'rejected')}
                      disabled={updatingId === match.id}
                      className="inline-flex items-center px-3 py-1 border border-transparent text-sm font-medium rounded-md text-white bg-red-600 hover:bg-red-700 disabled:opacity-50"
                    >
                      <X className="h-3 w-3 mr-1" />
                      Reject
                    </button>
                  </div>
                )}

                {match.status === 'accepted' && (
                  <button
                    onClick={() => handleUpdateStatus(match.id, 'completed')}
                    disabled={updatingId === match.id}
                    className="inline-flex items-center px-3 py-1 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-50"
                  >
                    <Star className="h-3 w-3 mr-1" />
                    Mark Complete
                  </button>
                )}
              </div>
            </div>
            );
          })}
        </div>
      )}

      {/* Stats */}
      {matches.length > 0 && (
        <div className="bg-white rounded-lg shadow p-6">
          <h2 className="text-lg font-semibold text-gray-900 mb-4">Match Summary</h2>
          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div className="text-center">
              <div className="text-2xl font-bold text-primary-600">{matches.length}</div>
              <div className="text-sm text-gray-600">Total Matches</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-yellow-600">
                {matches.filter(m => m.status === 'pending').length}
              </div>
              <div className="text-sm text-gray-600">Pending</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-green-600">
                {matches.filter(m => m.status === 'accepted').length}
              </div>
              <div className="text-sm text-gray-600">Active</div>
            </div>
            <div className="text-center">
              <div className="text-2xl font-bold text-blue-600">
                {matches.filter(m => m.status === 'completed').length}
              </div>
              <div className="text-sm text-gray-600">Completed</div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default MatchesPage;
