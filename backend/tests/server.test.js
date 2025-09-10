const request = require('supertest');
const app = require('../src/server');
const { sequelize } = require('../src/models');

// Setup test environment
beforeAll(async () => {
  // Use test database
  process.env.NODE_ENV = 'test';
  
  // Sync database
  await sequelize.sync({ force: true });
});

afterAll(async () => {
  // Clean up
  await sequelize.close();
});

describe('Health Check', () => {
  test('GET /health should return 200 and health status', async () => {
    const response = await request(app)
      .get('/health')
      .expect(200);

    expect(response.body).toHaveProperty('status', 'healthy');
    expect(response.body).toHaveProperty('timestamp');
    expect(response.body).toHaveProperty('environment');
    expect(response.body).toHaveProperty('database', 'connected');
  });
});

describe('API Routes', () => {
  test('GET /api should return 404 for undefined routes', async () => {
    const response = await request(app)
      .get('/api/nonexistent')
      .expect(404);

    expect(response.body).toHaveProperty('error', 'Route not found');
  });
});

describe('Security Headers', () => {
  test('Should include security headers in response', async () => {
    const response = await request(app)
      .get('/health')
      .expect(200);

    // Helmet should add these security headers
    expect(response.headers).toHaveProperty('x-dns-prefetch-control');
    expect(response.headers).toHaveProperty('x-frame-options');
    expect(response.headers).toHaveProperty('x-download-options');
    expect(response.headers).toHaveProperty('x-content-type-options');
  });
});