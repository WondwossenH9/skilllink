import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { BrowserRouter } from 'react-router-dom';
import { AuthProvider } from '../contexts/AuthContext';
import App from '../App';

// Mock the AuthContext
jest.mock('../contexts/AuthContext', () => ({
  AuthProvider: ({ children }: { children: React.ReactNode }) => <div>{children}</div>,
  useAuth: () => ({
    user: null,
    login: jest.fn(),
    logout: jest.fn(),
    register: jest.fn()
  })
}));

// Mock react-hot-toast
jest.mock('react-hot-toast', () => ({
  Toaster: () => <div data-testid="toaster" />,
  toast: {
    success: jest.fn(),
    error: jest.fn()
  }
}));

describe('App Component', () => {
  test('renders without crashing', () => {
    render(<App />);
    
    // Check if the toaster is rendered
    expect(screen.getByTestId('toaster')).toBeInTheDocument();
  });

  test('has proper CSS classes applied', () => {
    const { container } = render(<App />);
    
    // Check if the main app div has the expected classes
    const appDiv = container.querySelector('.App');
    expect(appDiv).toHaveClass('min-h-screen', 'bg-gray-50');
  });
});