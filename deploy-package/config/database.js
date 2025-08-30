const { Sequelize } = require('sequelize');
require('dotenv').config();

let sequelize;

if (process.env.NODE_ENV === 'production') {
  // Use PostgreSQL in production
  sequelize = new Sequelize(process.env.DATABASE_URL, {
    dialect: 'postgres',
    logging: false,
    define: {
      timestamps: true,
      underscored: true,
    },
    pool: {
      max: 5,
      min: 0,
      acquire: 30000,
      idle: 10000
    }
  });
} else {
  // Use SQLite for local development
  sequelize = new Sequelize({
    dialect: 'sqlite',
    storage: './skilllink.db',
    logging: process.env.NODE_ENV === 'development' ? console.log : false,
    define: {
      timestamps: true,
      underscored: true,
    },
  });
}

module.exports = sequelize;
