const request = require('supertest');
const app = require('../src/server');

describe('Integration Tests', () => {
  describe('Health Check', () => {
    test('should return healthy status', async () => {
      const response = await request(app)
        .get('/api/health');
      
      expect(response.status).toBe(200);
      expect(response.body.status).toBe('healthy');
      expect(response.body.timestamp).toBeDefined();
      expect(response.body.version).toBeDefined();
    });
  });

  describe('Skills API', () => {
    test('should return skills list', async () => {
      const response = await request(app)
        .get('/api/skills');
      
      expect(response.status).toBe(200);
      expect(response.body.skills).toBeDefined();
      expect(Array.isArray(response.body.skills)).toBe(true);
      expect(response.body.total).toBeDefined();
    });
  });

  describe('Authentication API', () => {
    test('should register a new user', async () => {
      const userData = {
        name: 'Test User',
        email: 'test@example.com',
        password: 'TestPassword123!'
      };

      const response = await request(app)
        .post('/api/auth/register')
        .send(userData);
      
      expect(response.status).toBe(201);
      expect(response.body.message).toBe('User registered successfully');
      expect(response.body.user).toBeDefined();
      expect(response.body.user.email).toBe(userData.email);
      expect(response.body.token).toBeDefined();
    });

    test('should login with valid credentials', async () => {
      const loginData = {
        email: 'test@example.com',
        password: 'TestPassword123!'
      };

      const response = await request(app)
        .post('/api/auth/login')
        .send(loginData);
      
      expect(response.status).toBe(200);
      expect(response.body.message).toBe('Login successful');
      expect(response.body.user).toBeDefined();
      expect(response.body.token).toBeDefined();
    });
  });

  describe('Error Handling', () => {
    test('should return 404 for non-existent routes', async () => {
      const response = await request(app)
        .get('/api/non-existent');
      
      expect(response.status).toBe(404);
      expect(response.body.error).toBe('Route not found');
    });

    test('should handle malformed JSON', async () => {
      const response = await request(app)
        .post('/api/auth/register')
        .set('Content-Type', 'application/json')
        .send('invalid json');
      
      expect(response.status).toBe(400);
    });
  });

  describe('Request Logging', () => {
    test('should log requests', async () => {
      // This test would need to be implemented with a mock logger
      // For now, we just ensure the endpoint responds
      const response = await request(app)
        .get('/api/health');
      
      expect(response.status).toBe(200);
    });
  });
});
