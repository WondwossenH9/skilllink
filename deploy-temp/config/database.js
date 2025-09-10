const { Sequelize } = require('sequelize');
require('dotenv').config();

const isProd = process.env.NODE_ENV === 'production';

// Simplified database configuration
const sequelize = isProd && process.env.DATABASE_URL
  ? new Sequelize(process.env.DATABASE_URL, {
      dialect: 'postgres',
      logging: false,
      define: { timestamps: true, underscored: true },
      pool: { max: 5, min: 0, acquire: 30000, idle: 10000 },
      dialectOptions: {
        ssl: process.env.DB_SSL === 'require' ? { rejectUnauthorized: false } : false
      }
    })
  : new Sequelize({
      dialect: 'sqlite',
      storage: './skilllink.db',
      logging: process.env.NODE_ENV === 'development' ? console.log : false,
      define: { timestamps: true, underscored: true },
    });

module.exports = sequelize;
