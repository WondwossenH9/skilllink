const AWS = require('aws-sdk');
const logger = require('../utils/logger');

// Initialize AWS SDK
AWS.config.update({ region: process.env.AWS_REGION || 'us-east-1' });
const secretsManager = new AWS.SecretsManager();

// Cache for secrets to avoid repeated API calls
let secretsCache = {};
let cacheExpiry = 0;
const CACHE_DURATION = 5 * 60 * 1000; // 5 minutes

/**
 * Retrieve secrets from AWS Secrets Manager
 * @param {string} secretName - Name of the secret to retrieve
 * @returns {Promise<Object>} - Parsed secret value
 */
async function getSecret(secretName) {
  try {
    // Check cache first
    if (secretsCache[secretName] && Date.now() < cacheExpiry) {
      return secretsCache[secretName];
    }

    logger.info(`Retrieving secret: ${secretName}`);
    
    const params = {
      SecretId: secretName,
      VersionStage: 'AWSCURRENT'
    };

    const result = await secretsManager.getSecretValue(params).promise();
    const secretValue = JSON.parse(result.SecretString);
    
    // Cache the result
    secretsCache[secretName] = secretValue;
    cacheExpiry = Date.now() + CACHE_DURATION;
    
    logger.info(`Successfully retrieved secret: ${secretName}`);
    return secretValue;
    
  } catch (error) {
    logger.error(`Failed to retrieve secret ${secretName}:`, error);
    
    // Fallback to environment variables for development
    if (process.env.NODE_ENV === 'development') {
      logger.warn(`Falling back to environment variables for ${secretName}`);
      return getFallbackConfig(secretName);
    }
    
    throw new Error(`Failed to retrieve secret ${secretName}: ${error.message}`);
  }
}

/**
 * Get fallback configuration from environment variables
 * @param {string} secretName - Name of the secret
 * @returns {Object} - Fallback configuration
 */
function getFallbackConfig(secretName) {
  if (secretName.includes('db-credentials')) {
    return {
      username: process.env.DB_USER || 'skilllink_user',
      password: process.env.DB_PASSWORD || 'dev_password',
      host: process.env.DB_HOST || 'localhost',
      port: process.env.DB_PORT || '5432',
      database: process.env.DB_NAME || 'skilllink',
      url: process.env.DATABASE_URL || 'postgresql://skilllink_user:dev_password@localhost:5432/skilllink'
    };
  }
  
  if (secretName.includes('app-secrets')) {
    return {
      jwt_secret: process.env.JWT_SECRET || 'dev-jwt-secret-change-in-production',
      jwt_expire: process.env.JWT_EXPIRE || '7d',
      node_env: process.env.NODE_ENV || 'development',
      port: process.env.PORT || '3001',
      frontend_url: process.env.FRONTEND_URL || 'http://localhost:3000',
      rate_limit_window_ms: process.env.RATE_LIMIT_WINDOW_MS || '900000',
      rate_limit_max_requests: process.env.RATE_LIMIT_MAX_REQUESTS || '100'
    };
  }
  
  return {};
}

/**
 * Get database configuration from secrets
 * @returns {Promise<Object>} - Database configuration
 */
async function getDatabaseConfig() {
  const projectName = process.env.PROJECT_NAME || 'skilllink';
  const environment = process.env.ENVIRONMENT || 'dev';
  const secretName = `${projectName}-${environment}-db-credentials`;
  
  return await getSecret(secretName);
}

/**
 * Get application configuration from secrets
 * @returns {Promise<Object>} - Application configuration
 */
async function getAppConfig() {
  const projectName = process.env.PROJECT_NAME || 'skilllink';
  const environment = process.env.ENVIRONMENT || 'dev';
  const secretName = `${projectName}-${environment}-app-secrets`;
  
  return await getSecret(secretName);
}

/**
 * Clear secrets cache (useful for testing or when secrets are rotated)
 */
function clearSecretsCache() {
  secretsCache = {};
  cacheExpiry = 0;
  logger.info('Secrets cache cleared');
}

module.exports = {
  getSecret,
  getDatabaseConfig,
  getAppConfig,
  clearSecretsCache
};
