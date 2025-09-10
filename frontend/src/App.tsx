import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import { AuthProvider } from './contexts/AuthContext';
import Layout from './components/Layout';
import HomePage from './components/pages/HomePage';
import LoginPage from './components/auth/LoginPage';
import RegisterPage from './components/auth/RegisterPage';
import SkillsPage from './components/skills/SkillsPage';
import SkillDetailPage from './components/skills/SkillDetailPage';
import CreateSkillPage from './components/skills/CreateSkillPage';
import MySkillsPage from './components/skills/MySkillsPage';
import MatchesPage from './components/matches/MatchesPage';
import ProfilePage from './components/auth/ProfilePage';
import ProtectedRoute from './components/auth/ProtectedRoute';

function App() {
  return (
    <AuthProvider>
      <Router>
        <div className="App min-h-screen bg-gray-50">
          <Toaster
            position="top-right"
            toastOptions={{
              duration: 4000,
              style: {
                background: '#363636',
                color: '#fff',
              },
            }}
          />
          <Routes>
            <Route path="/login" element={<LoginPage />} />
            <Route path="/register" element={<RegisterPage />} />
            <Route path="/" element={<Layout />}>
              <Route index element={<HomePage />} />
              <Route path="skills" element={<SkillsPage />} />
              <Route path="skills/:id" element={<SkillDetailPage />} />
              <Route path="create-skill" element={
                <ProtectedRoute>
                  <CreateSkillPage />
                </ProtectedRoute>
              } />
              <Route path="my-skills" element={
                <ProtectedRoute>
                  <MySkillsPage />
                </ProtectedRoute>
              } />
              <Route path="matches" element={
                <ProtectedRoute>
                  <MatchesPage />
                </ProtectedRoute>
              } />
              <Route path="profile" element={
                <ProtectedRoute>
                  <ProfilePage />
                </ProtectedRoute>
              } />
              <Route path="*" element={<Navigate to="/" replace />} />
            </Route>
          </Routes>
        </div>
      </Router>
    </AuthProvider>
  );
}

export default App;
