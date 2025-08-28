import api from './api';
import { Skill, SkillFormData, PaginationData } from '../types';

export interface SkillsResponse {
  skills: Skill[];
  pagination: PaginationData;
}

export interface SkillFilters {
  category?: string;
  type?: 'offer' | 'request';
  level?: 'beginner' | 'intermediate' | 'advanced';
  location?: 'online' | 'in-person' | 'both';
  search?: string;
  page?: number;
  limit?: number;
}

export interface SkillRecommendationsResponse {
  recommendations: Skill[];
  preferences: {
    topCategories: string[];
    preferredTypes: string[];
    preferredLevels: string[];
    topTags: string[];
    categoryCount: Record<string, number>;
    typeCount: Record<string, number>;
    levelCount: Record<string, number>;
  };
}

export const skillService = {
  async getSkills(filters: SkillFilters = {}): Promise<SkillsResponse> {
    const response = await api.get('/skills', { params: filters });
    return response.data;
  },

  async getSkillById(id: string): Promise<{ skill: Skill }> {
    const response = await api.get(`/skills/${id}`);
    return response.data;
  },

  async getSkillMatches(id: string): Promise<{ matches: Skill[] }> {
    const response = await api.get(`/skills/${id}/matches`);
    return response.data;
  },

  async getSkillRecommendations(): Promise<SkillRecommendationsResponse> {
    const response = await api.get('/skills/recommendations');
    return response.data;
  },

  async createSkill(data: SkillFormData): Promise<{ skill: Skill }> {
    const response = await api.post('/skills', data);
    return response.data;
  },

  async updateSkill(id: string, data: Partial<SkillFormData>): Promise<{ skill: Skill }> {
    const response = await api.put(`/skills/${id}`, data);
    return response.data;
  },

  async deleteSkill(id: string): Promise<void> {
    await api.delete(`/skills/${id}`);
  },

  async getUserSkills(): Promise<{ skills: Skill[] }> {
    const response = await api.get('/skills/my-skills');
    return response.data;
  },
};
