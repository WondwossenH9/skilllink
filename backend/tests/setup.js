// Test setup file
require('dotenv').config({ path: '.env.test' });

// Set test environment
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-jwt-secret-for-testing-only';

// Suppress console.log during tests unless debugging
if (!process.env.DEBUG_TESTS) {
  console.log = jest.fn();
  console.error = jest.fn();
}