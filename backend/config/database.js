const { Sequelize } = require('sequelize');
require('dotenv').config();

// Use SQLite for local development if PostgreSQL connection fails
const sequelize = new Sequelize({
  dialect: 'sqlite',
  storage: './skilllink.db',
  logging: process.env.NODE_ENV === 'development' ? console.log : false,
  define: {
    timestamps: true,
    underscored: true,
  },
});

module.exports = sequelize;
