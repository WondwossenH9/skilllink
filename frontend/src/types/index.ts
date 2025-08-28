export interface User {
  id: string;
  username: string;
  email: string;
  firstName: string;
  lastName: string;
  bio?: string;
  rating?: number;
  totalRatings?: number;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface Skill {
  id: string;
  title: string;
  description: string;
  category: string;
  type: 'offer' | 'request';
  level: 'beginner' | 'intermediate' | 'advanced';
  duration?: string;
  location: 'online' | 'in-person' | 'both';
  isActive: boolean;
  tags: string[];
  userId: string;
  user: User;
  matchScore?: number; // Added for match scoring
  recommendationScore?: number; // Added for recommendation scoring
  createdAt: string;
  updatedAt: string;
}

export interface Match {
  id: string;
  status: 'pending' | 'accepted' | 'rejected' | 'completed';
  message?: string;
  acceptedAt?: string;
  completedAt?: string;
  offerSkillId: string;
  requestSkillId: string;
  requesterId: string;
  offererId: string;
  compatibilityScore?: number; // Added for compatibility scoring
  offerSkill: Skill;
  requestSkill: Skill;
  requester: User;
  offerer: User;
  createdAt: string;
  updatedAt: string;
}

export interface Rating {
  id: string;
  score: number;
  comment?: string;
  raterId: string;
  ratedUserId: string;
  matchId: string;
  createdAt: string;
  updatedAt: string;
}

export interface AuthContextType {
  user: User | null;
  token: string | null;
  login: (email: string, password: string) => Promise<void>;
  register: (userData: RegisterData) => Promise<void>;
  logout: () => void;
  loading: boolean;
}

export interface RegisterData {
  username: string;
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  bio?: string;
}

export interface LoginData {
  email: string;
  password: string;
}

export interface SkillFormData {
  title: string;
  description: string;
  category: string;
  type: 'offer' | 'request';
  level: 'beginner' | 'intermediate' | 'advanced';
  duration?: string;
  location: 'online' | 'in-person' | 'both';
  tags: string[];
}

export interface PaginationData {
  page: number;
  limit: number;
  total: number;
  pages: number;
}

export interface ApiResponse<T> {
  data?: T;
  message?: string;
  error?: string;
  pagination?: PaginationData;
}
