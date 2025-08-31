const { Sequelize } = require('sequelize');
require('dotenv').config();

const isProd = process.env.NODE_ENV === 'production';

const getPgUrl = () => {
  if (process.env.DATABASE_URL) return process.env.DATABASE_URL;
  const { DB_USER, DB_PASS, DB_HOST, DB_PORT = 5432, DB_NAME } = process.env;
  if (DB_USER && DB_PASS && DB_HOST && DB_NAME) {
    return `postgres://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}`;
  }
  throw new Error('DATABASE_URL or DB_* env vars are required in production');
};

const sequelize = isProd
  ? new Sequelize(getPgUrl(), {
      dialect: 'postgres',
      logging: false,
      define: { timestamps: true, underscored: true },
      pool: { max: 5, min: 0, acquire: 30000, idle: 10000 },
    })
  : new Sequelize({
      dialect: 'sqlite',
      storage: './skilllink.db',
      logging: process.env.NODE_ENV === 'development' ? console.log : false,
      define: { timestamps: true, underscored: true },
    });

module.exports = sequelize;
