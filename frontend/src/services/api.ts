import axios, { AxiosResponse } from 'axios';
import toast from 'react-hot-toast';

const API_BASE_URL = 'http://localhost:3001/api';

// Create axios instance
const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to add auth token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('skilllink_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor to handle errors
api.interceptors.response.use(
  (response: AxiosResponse) => {
    return response;
  },
  (error) => {
    if (error.response) {
      const { status, data } = error.response;
      
      if (status === 401) {
        // Unauthorized - remove token and redirect to login
        localStorage.removeItem('skilllink_token');
        localStorage.removeItem('skilllink_user');
        window.location.href = '/login';
        return Promise.reject(error);
      }
      
      if (status >= 500) {
        // Server errors
        toast.error('Server error. Please try again later.');
      }
    } else if (error.request) {
      // Network error
      toast.error('Network error. Please check your connection.');
    } else {
      // Other errors
      toast.error('An unexpected error occurred.');
    }
    
    return Promise.reject(error);
  }
);

export default api;
