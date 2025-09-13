require('dotenv').config();
const secrets = require('./secrets');
const logger = require('../utils/logger');

// Database configuration with secrets management
const getDatabaseConfig = async () => {
  try {
    if (process.env.NODE_ENV === 'development') {
      return {
        development: {
          dialect: 'sqlite',
          storage: './dev.sqlite3'
        }
      };
    }

    // For production, get credentials from AWS Secrets Manager
    const dbConfig = await secrets.getDatabaseConfig();
    
    return {
      production: {
        username: dbConfig.username,
        password: dbConfig.password,
        database: dbConfig.database,
        host: dbConfig.host,
        port: parseInt(dbConfig.port),
        dialect: 'postgres',
        dialectOptions: {
          ssl: { require: true, rejectUnauthorized: false }
        },
        logging: (sql) => logger.debug(sql),
        pool: {
          max: 5,
          min: 0,
          acquire: 30000,
          idle: 10000
        }
      }
    };
  } catch (error) {
    logger.error('Failed to get database configuration:', error);
    
    // Fallback to environment variables
    logger.warn('Falling back to environment variables for database config');
    return {
      production: {
        username: process.env.DB_USER,
        password: process.env.DB_PASSWORD,
        database: process.env.DB_NAME,
        host: process.env.DB_HOST,
        port: process.env.DB_PORT,
        dialect: 'postgres',
        dialectOptions: {
          ssl: { require: true, rejectUnauthorized: false }
        }
      }
    };
  }
};

// Export a function that returns the configuration
module.exports = getDatabaseConfig;
