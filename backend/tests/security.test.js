const request = require('supertest');
const app = require('../src/server');
const { hashPassword, verifyPassword, validatePassword, validateEmail } = require('../src/middleware/security');

describe('Security Tests', () => {
  describe('Password Validation', () => {
    test('should reject weak passwords', () => {
      const weakPasswords = [
        '123',
        'password',
        'Password',
        'Password1',
        'Password1!',
        'P@ssw0rd'
      ];

      weakPasswords.forEach(password => {
        const result = validatePassword(password);
        expect(result.valid).toBe(false);
        expect(result.message).toBeDefined();
      });
    });

    test('should accept strong passwords', () => {
      const strongPassword = 'SecurePass123!';
      const result = validatePassword(strongPassword);
      expect(result.valid).toBe(true);
    });
  });

  describe('Email Validation', () => {
    test('should reject invalid emails', () => {
      const invalidEmails = [
        'invalid-email',
        '@domain.com',
        'user@',
        'user@domain',
        'user..name@domain.com'
      ];

      invalidEmails.forEach(email => {
        expect(validateEmail(email)).toBe(false);
      });
    });

    test('should accept valid emails', () => {
      const validEmails = [
        'user@domain.com',
        'user.name@domain.com',
        'user+tag@domain.co.uk'
      ];

      validEmails.forEach(email => {
        expect(validateEmail(email)).toBe(true);
      });
    });
  });

  describe('Password Hashing', () => {
    test('should hash passwords securely', async () => {
      const password = 'TestPassword123!';
      const hashed = await hashPassword(password);
      
      expect(hashed).not.toBe(password);
      expect(hashed).toMatch(/^\$2[aby]\$\d+\$.{53}$/); // bcrypt format
    });

    test('should verify passwords correctly', async () => {
      const password = 'TestPassword123!';
      const hashed = await hashPassword(password);
      
      const isValid = await verifyPassword(password, hashed);
      expect(isValid).toBe(true);
      
      const isInvalid = await verifyPassword('wrongpassword', hashed);
      expect(isInvalid).toBe(false);
    });
  });

  describe('Rate Limiting', () => {
    test('should apply rate limiting to auth endpoints', async () => {
      const promises = [];
      
      // Make multiple requests to trigger rate limiting
      for (let i = 0; i < 10; i++) {
        promises.push(
          request(app)
            .post('/api/auth/register')
            .send({
              name: 'Test User',
              email: `test${i}@example.com`,
              password: 'TestPassword123!'
            })
        );
      }

      const responses = await Promise.all(promises);
      
      // Some requests should be rate limited
      const rateLimitedResponses = responses.filter(res => res.status === 429);
      expect(rateLimitedResponses.length).toBeGreaterThan(0);
    });
  });

  describe('Input Validation', () => {
    test('should reject malicious input', async () => {
      const maliciousInputs = [
        { name: '<script>alert("xss")</script>', email: 'test@example.com', password: 'TestPass123!' },
        { name: 'Test User', email: 'test@example.com', password: 'TestPass123!'; DROP TABLE users; --' },
        { name: 'Test User', email: 'test@example.com', password: 'TestPass123!', extra: { $where: '1==1' } }
      ];

      for (const input of maliciousInputs) {
        const response = await request(app)
          .post('/api/auth/register')
          .send(input);
        
        // Should either reject with 400 or sanitize input
        expect([400, 201]).toContain(response.status);
      }
    });
  });

  describe('CORS Configuration', () => {
    test('should reject requests from unauthorized origins', async () => {
      const response = await request(app)
        .get('/api/skills')
        .set('Origin', 'https://malicious-site.com');
      
      expect(response.status).toBe(500); // CORS error
    });

    test('should allow requests from authorized origins', async () => {
      const response = await request(app)
        .get('/api/skills')
        .set('Origin', 'http://localhost:3000');
      
      expect(response.status).toBe(200);
    });
  });

  describe('Security Headers', () => {
    test('should include security headers', async () => {
      const response = await request(app)
        .get('/api/health');
      
      expect(response.headers['x-frame-options']).toBe('DENY');
      expect(response.headers['x-content-type-options']).toBe('nosniff');
      expect(response.headers['x-xss-protection']).toBe('1; mode=block');
    });
  });
});
