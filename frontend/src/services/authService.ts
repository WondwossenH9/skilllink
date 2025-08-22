import api from './api';
import { User, LoginData, RegisterData } from '../types';

export const authService = {
  async login(data: LoginData): Promise<{ user: User; token: string }> {
    const response = await api.post('/auth/login', data);
    return response.data;
  },

  async register(data: RegisterData): Promise<{ user: User; token: string }> {
    const response = await api.post('/auth/register', data);
    return response.data;
  },

  async getProfile(): Promise<{ user: User }> {
    const response = await api.get('/auth/profile');
    return response.data;
  },

  async updateProfile(data: Partial<User>): Promise<{ user: User }> {
    const response = await api.put('/auth/profile', data);
    return response.data;
  },

  logout() {
    localStorage.removeItem('skilllink_token');
    localStorage.removeItem('skilllink_user');
  },

  getStoredToken(): string | null {
    return localStorage.getItem('skilllink_token');
  },

  getStoredUser(): User | null {
    const userStr = localStorage.getItem('skilllink_user');
    return userStr ? JSON.parse(userStr) : null;
  },

  storeAuth(token: string, user: User) {
    localStorage.setItem('skilllink_token', token);
    localStorage.setItem('skilllink_user', JSON.stringify(user));
  },
};
