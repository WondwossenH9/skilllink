import React from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { Search, Plus, Users } from 'lucide-react';

const HomePage: React.FC = () => {
  const { user } = useAuth();

  return (
    <div className="space-y-12">
      {/* Hero Section */}
      <div className="text-center">
        <h1 className="text-4xl font-bold text-gray-900 sm:text-5xl md:text-6xl">
          Welcome to{' '}
          <span className="text-primary-600">SkillLink</span>
        </h1>
        <p className="mt-3 max-w-md mx-auto text-base text-gray-500 sm:text-lg md:mt-5 md:text-xl md:max-w-3xl">
          A marketplace for skill swapping. Learn something new while teaching what you know best.
        </p>
        <div className="mt-5 max-w-md mx-auto sm:flex sm:justify-center md:mt-8">
          <div className="rounded-md shadow">
            <Link
              to="/skills"
              className="w-full flex items-center justify-center px-8 py-3 border border-transparent text-base font-medium rounded-md text-white bg-primary-600 hover:bg-primary-700 md:py-4 md:text-lg md:px-10"
            >
              Browse Skills
            </Link>
          </div>
          {!user && (
            <div className="mt-3 rounded-md shadow sm:mt-0 sm:ml-3">
              <Link
                to="/register"
                className="w-full flex items-center justify-center px-8 py-3 border border-transparent text-base font-medium rounded-md text-primary-600 bg-white hover:bg-gray-50 md:py-4 md:text-lg md:px-10"
              >
                Get Started
              </Link>
            </div>
          )}
        </div>
      </div>

      {/* Features */}
      <div className="py-12">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="lg:text-center">
            <h2 className="text-base text-primary-600 font-semibold tracking-wide uppercase">
              How it works
            </h2>
            <p className="mt-2 text-3xl leading-8 font-extrabold tracking-tight text-gray-900 sm:text-4xl">
              Share skills, learn together
            </p>
          </div>

          <div className="mt-10">
            <div className="space-y-10 md:space-y-0 md:grid md:grid-cols-3 md:gap-x-8 md:gap-y-10">
              <Link
                to={user ? "/create-skill" : "/register"}
                className="group text-center p-6 rounded-lg border-2 border-transparent hover:border-primary-300 hover:bg-primary-50 transition-all duration-200 cursor-pointer"
              >
                <div className="flex items-center justify-center h-12 w-12 rounded-md bg-primary-500 text-white mx-auto group-hover:bg-primary-600 transition-colors">
                  <Plus className="h-6 w-6" />
                </div>
                <div className="mt-5">
                  <h3 className="text-lg leading-6 font-medium text-gray-900 group-hover:text-primary-700">
                    Post Your Skills
                  </h3>
                  <p className="mt-2 text-base text-gray-500">
                    Share what you can teach or what you'd like to learn. From Excel basics to guitar lessons.
                  </p>
                  <div className="mt-4">
                    <span className="inline-flex items-center text-primary-600 font-medium group-hover:text-primary-700">
                      {user ? "Create Skill →" : "Get Started →"}
                    </span>
                  </div>
                </div>
              </Link>

              <Link
                to="/skills"
                className="group text-center p-6 rounded-lg border-2 border-transparent hover:border-primary-300 hover:bg-primary-50 transition-all duration-200 cursor-pointer"
              >
                <div className="flex items-center justify-center h-12 w-12 rounded-md bg-primary-500 text-white mx-auto group-hover:bg-primary-600 transition-colors">
                  <Search className="h-6 w-6" />
                </div>
                <div className="mt-5">
                  <h3 className="text-lg leading-6 font-medium text-gray-900 group-hover:text-primary-700">
                    Find Matches
                  </h3>
                  <p className="mt-2 text-base text-gray-500">
                    Browse available skills and connect with others who want to learn what you teach.
                  </p>
                  <div className="mt-4">
                    <span className="inline-flex items-center text-primary-600 font-medium group-hover:text-primary-700">
                      Browse Skills →
                    </span>
                  </div>
                </div>
              </Link>

              <Link
                to={user ? "/matches" : "/register"}
                className="group text-center p-6 rounded-lg border-2 border-transparent hover:border-primary-300 hover:bg-primary-50 transition-all duration-200 cursor-pointer"
              >
                <div className="flex items-center justify-center h-12 w-12 rounded-md bg-primary-500 text-white mx-auto group-hover:bg-primary-600 transition-colors">
                  <Users className="h-6 w-6" />
                </div>
                <div className="mt-5">
                  <h3 className="text-lg leading-6 font-medium text-gray-900 group-hover:text-primary-700">
                    Learn & Teach
                  </h3>
                  <p className="mt-2 text-base text-gray-500">
                    Exchange knowledge through one-on-one sessions, online or in person.
                  </p>
                  <div className="mt-4">
                    <span className="inline-flex items-center text-primary-600 font-medium group-hover:text-primary-700">
                      {user ? "View Matches →" : "Join Now →"}
                    </span>
                  </div>
                </div>
              </Link>
            </div>
          </div>
        </div>
      </div>

      {/* Call to Action */}
      {!user && (
        <div className="bg-primary-600 rounded-lg shadow-lg p-8 text-center">
          <h2 className="text-2xl font-bold text-white mb-4">
            Ready to Start Your Skill Exchange Journey?
          </h2>
          <p className="text-primary-100 mb-6 max-w-2xl mx-auto">
            Join thousands of learners and teachers who are already exchanging skills on SkillLink. 
            Create your account today and discover a world of knowledge sharing.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Link
              to="/register"
              className="inline-flex items-center justify-center px-6 py-3 border border-transparent text-base font-medium rounded-md text-primary-600 bg-white hover:bg-gray-50 transition-colors"
            >
              Create Account
            </Link>
            <Link
              to="/skills"
              className="inline-flex items-center justify-center px-6 py-3 border-2 border-white text-base font-medium rounded-md text-white hover:bg-primary-700 transition-colors"
            >
              Browse Skills
            </Link>
          </div>
        </div>
      )}

      {/* Stats Section */}
      <div className="bg-white rounded-lg shadow p-8">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 text-center">
          <div>
            <div className="text-3xl font-bold text-primary-600">100+</div>
            <div className="text-gray-600">Skills Available</div>
          </div>
          <div>
            <div className="text-3xl font-bold text-primary-600">50+</div>
            <div className="text-gray-600">Active Users</div>
          </div>
          <div>
            <div className="text-3xl font-bold text-primary-600">25+</div>
            <div className="text-gray-600">Successful Matches</div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default HomePage;
