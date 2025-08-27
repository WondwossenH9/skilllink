import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { User, AuthContextType, RegisterData } from '../types';
import { authService } from '../services/authService';
import toast from 'react-hot-toast';

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

interface AuthProviderProps {
  children: ReactNode;
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [token, setToken] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Check for stored auth data on app load
    const storedToken = authService.getStoredToken();
    const storedUser = authService.getStoredUser();

    if (storedToken && storedUser) {
      setToken(storedToken);
      setUser(storedUser);
    }
    setLoading(false);
  }, []);

  const login = async (email: string, password: string) => {
    try {
      setLoading(true);
      const { user: userData, token: authToken } = await authService.login({
        email,
        password,
      });

      authService.storeAuth(authToken, userData);
      setUser(userData);
      setToken(authToken);

      toast.success('Logged in successfully!');
    } catch (error: any) {
      // Handle validation errors with detailed messages
      if (error.response?.data?.details) {
        const validationErrors = error.response.data.details;
        const errorMessages = validationErrors.map((err: any) => err.msg).join(', ');
        toast.error(errorMessages);
      } else {
        const errorMessage = error.response?.data?.error || 'Login failed';
        toast.error(errorMessage);
      }
      throw error;
    } finally {
      setLoading(false);
    }
  };

  const register = async (userData: RegisterData) => {
    try {
      setLoading(true);
      const { user: newUser, token: authToken } = await authService.register(userData);

      authService.storeAuth(authToken, newUser);
      setUser(newUser);
      setToken(authToken);

      toast.success('Account created successfully!');
    } catch (error: any) {
      // Handle validation errors with detailed messages
      if (error.response?.data?.details) {
        const validationErrors = error.response.data.details;
        const errorMessages = validationErrors.map((err: any) => err.msg).join(', ');
        toast.error(errorMessages);
      } else {
        const errorMessage = error.response?.data?.error || 'Registration failed';
        toast.error(errorMessage);
      }
      throw error;
    } finally {
      setLoading(false);
    }
  };

  const logout = () => {
    authService.logout();
    setUser(null);
    setToken(null);
    toast.success('Logged out successfully');
  };

  const value: AuthContextType = {
    user,
    token,
    login,
    register,
    logout,
    loading,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};
