const { DataTypes } = require('sequelize');
const sequelize = require('../../config/database');

const Skill = sequelize.define('Skill', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  title: {
    type: DataTypes.STRING,
    allowNull: false,
    validate: {
      len: [5, 100],
    },
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
  category: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  type: {
    type: DataTypes.ENUM('offer', 'request'),
    allowNull: false,
  },
  level: {
    type: DataTypes.ENUM('beginner', 'intermediate', 'advanced'),
    defaultValue: 'beginner',
  },
  duration: {
    type: DataTypes.STRING, // e.g., "2 hours", "1 week"
    allowNull: true,
  },
  location: {
    type: DataTypes.ENUM('online', 'in-person', 'both'),
    defaultValue: 'online',
  },
  isActive: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },
  tags: {
    type: DataTypes.JSON,
    defaultValue: [],
  },
});

module.exports = Skill;
