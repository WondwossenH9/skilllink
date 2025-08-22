import React from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { LogOut, User, Plus, Search, GitBranch } from 'lucide-react';

const Header: React.FC = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/');
  };

  return (
    <header className="bg-white shadow-sm border-b border-gray-200">
      <div className="container mx-auto px-4">
        <div className="flex items-center justify-between h-16">
          {/* Logo */}
          <Link to="/" className="flex items-center space-x-2">
            <GitBranch className="h-8 w-8 text-primary-600" />
            <span className="text-xl font-bold text-gray-900">SkillLink</span>
          </Link>

          {/* Navigation */}
          <nav className="hidden md:flex items-center space-x-6">
            <Link
              to="/skills"
              className="flex items-center space-x-1 text-gray-700 hover:text-primary-600"
            >
              <Search className="h-4 w-4" />
              <span>Browse Skills</span>
            </Link>

            {user && (
              <>
                <Link
                  to="/create-skill"
                  className="flex items-center space-x-1 text-gray-700 hover:text-primary-600"
                >
                  <Plus className="h-4 w-4" />
                  <span>Add Skill</span>
                </Link>
                <Link
                  to="/my-skills"
                  className="text-gray-700 hover:text-primary-600"
                >
                  My Skills
                </Link>
                <Link
                  to="/matches"
                  className="text-gray-700 hover:text-primary-600"
                >
                  Matches
                </Link>
              </>
            )}
          </nav>

          {/* User menu */}
          <div className="flex items-center space-x-4">
            {user ? (
              <div className="flex items-center space-x-3">
                <Link
                  to="/profile"
                  className="flex items-center space-x-2 text-gray-700 hover:text-primary-600"
                >
                  <User className="h-4 w-4" />
                  <span className="hidden sm:inline">{user.firstName}</span>
                </Link>
                <button
                  onClick={handleLogout}
                  className="flex items-center space-x-1 text-gray-700 hover:text-red-600 transition-colors"
                >
                  <LogOut className="h-4 w-4" />
                  <span className="hidden sm:inline">Logout</span>
                </button>
              </div>
            ) : (
              <div className="flex items-center space-x-3">
                <Link
                  to="/login"
                  className="text-gray-700 hover:text-primary-600"
                >
                  Login
                </Link>
                <Link
                  to="/register"
                  className="btn btn-primary"
                >
                  Sign Up
                </Link>
              </div>
            )}
          </div>
        </div>
      </div>
    </header>
  );
};

export default Header;
