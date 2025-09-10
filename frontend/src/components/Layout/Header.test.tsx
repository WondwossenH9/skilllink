import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { BrowserRouter } from 'react-router-dom';
import Header from '../components/Layout/Header';

// Mock the useAuth hook
jest.mock('../contexts/AuthContext', () => ({
  useAuth: () => ({
    user: null,
    logout: jest.fn()
  })
}));

// Mock react-router-dom useNavigate
const mockNavigate = jest.fn();
jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useNavigate: () => mockNavigate
}));

describe('Header Component', () => {
  beforeEach(() => {
    mockNavigate.mockClear();
  });

  test('renders header with logo', () => {
    render(
      <BrowserRouter>
        <Header />
      </BrowserRouter>
    );
    
    expect(screen.getByText('SkillLink')).toBeInTheDocument();
    expect(screen.getByText('Browse Skills')).toBeInTheDocument();
  });

  test('shows login and signup when user is not authenticated', () => {
    render(
      <BrowserRouter>
        <Header />
      </BrowserRouter>
    );
    
    expect(screen.getByText('Login')).toBeInTheDocument();
    expect(screen.getByText('Sign Up')).toBeInTheDocument();
  });

  test('has proper navigation structure', () => {
    render(
      <BrowserRouter>
        <Header />
      </BrowserRouter>
    );
    
    const header = screen.getByRole('banner');
    expect(header).toBeInTheDocument();
    expect(header).toHaveClass('bg-white', 'shadow-sm', 'border-b', 'border-gray-200');
  });
});