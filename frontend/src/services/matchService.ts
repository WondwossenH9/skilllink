import api from './api';
import { Match } from '../types';

export interface MatchFilters {
  status?: 'pending' | 'accepted' | 'rejected' | 'completed';
  type?: 'sent' | 'received';
}

export const matchService = {
  async getMatches(filters: MatchFilters = {}): Promise<{ matches: Match[] }> {
    const response = await api.get('/matches', { params: filters });
    return response.data;
  },

  async createMatch(data: {
    offerSkillId: string;
    requestSkillId: string;
    message?: string;
  }): Promise<{ match: Match }> {
    const response = await api.post('/matches', data);
    return response.data;
  },

  async updateMatchStatus(id: string, status: 'accepted' | 'rejected' | 'completed'): Promise<{ match: Match }> {
    const response = await api.put(`/matches/${id}/status`, { status });
    return response.data;
  },
};
