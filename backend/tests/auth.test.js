const request = require('supertest');
const app = require('../src/server');
const { sequelize, User } = require('../src/models');
const bcrypt = require('bcryptjs');

// Setup test environment
beforeAll(async () => {
  process.env.NODE_ENV = 'test';
  await sequelize.sync({ force: true });
});

afterAll(async () => {
  await sequelize.close();
});

beforeEach(async () => {
  // Clean up users before each test
  await User.destroy({ where: {}, truncate: true });
});

describe('Auth Controller', () => {
  describe('POST /api/auth/register', () => {
    test('Should register a new user with valid data', async () => {
      const userData = {\n        username: 'testuser',\n        email: 'test@example.com',\n        password: 'password123',\n        firstName: 'Test',\n        lastName: 'User'\n      };\n\n      const response = await request(app)\n        .post('/api/auth/register')\n        .send(userData)\n        .expect(201);\n\n      expect(response.body).toHaveProperty('message', 'User registered successfully');\n      expect(response.body).toHaveProperty('user');\n      expect(response.body.user).toHaveProperty('id');\n      expect(response.body.user).toHaveProperty('username', userData.username);\n      expect(response.body.user).toHaveProperty('email', userData.email);\n      expect(response.body.user).not.toHaveProperty('password');\n    });\n\n    test('Should reject registration with invalid email', async () => {\n      const userData = {\n        username: 'testuser',\n        email: 'invalid-email',\n        password: 'password123',\n        firstName: 'Test',\n        lastName: 'User'\n      };\n\n      const response = await request(app)\n        .post('/api/auth/register')\n        .send(userData)\n        .expect(400);\n\n      expect(response.body).toHaveProperty('error', 'Validation failed');\n      expect(response.body).toHaveProperty('details');\n    });\n\n    test('Should reject registration with short password', async () => {\n      const userData = {\n        username: 'testuser',\n        email: 'test@example.com',\n        password: '123',\n        firstName: 'Test',\n        lastName: 'User'\n      };\n\n      const response = await request(app)\n        .post('/api/auth/register')\n        .send(userData)\n        .expect(400);\n\n      expect(response.body).toHaveProperty('error', 'Validation failed');\n    });\n  });\n\n  describe('POST /api/auth/login', () => {\n    beforeEach(async () => {\n      // Create a test user\n      const hashedPassword = await bcrypt.hash('password123', 10);\n      await User.create({\n        username: 'testuser',\n        email: 'test@example.com',\n        password: hashedPassword,\n        firstName: 'Test',\n        lastName: 'User'\n      });\n    });\n\n    test('Should login with valid credentials', async () => {\n      const loginData = {\n        email: 'test@example.com',\n        password: 'password123'\n      };\n\n      const response = await request(app)\n        .post('/api/auth/login')\n        .send(loginData)\n        .expect(200);\n\n      expect(response.body).toHaveProperty('message', 'Login successful');\n      expect(response.body).toHaveProperty('token');\n      expect(response.body).toHaveProperty('user');\n      expect(response.body.user).not.toHaveProperty('password');\n    });\n\n    test('Should reject login with invalid credentials', async () => {\n      const loginData = {\n        email: 'test@example.com',\n        password: 'wrongpassword'\n      };\n\n      const response = await request(app)\n        .post('/api/auth/login')\n        .send(loginData)\n        .expect(401);\n\n      expect(response.body).toHaveProperty('error', 'Invalid credentials');\n    });\n\n    test('Should reject login with invalid email format', async () => {\n      const loginData = {\n        email: 'invalid-email',\n        password: 'password123'\n      };\n\n      const response = await request(app)\n        .post('/api/auth/login')\n        .send(loginData)\n        .expect(400);\n\n      expect(response.body).toHaveProperty('error', 'Validation failed');\n    });\n  });\n});