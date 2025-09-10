const { DataTypes } = require('sequelize');

const Match = (sequelize) => sequelize.define('Match', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  offerSkillId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'Skills',
      key: 'id',
    },
  },
  requestSkillId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'Skills',
      key: 'id',
    },
  },
  requesterId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'Users',
      key: 'id',
    },
  },
  offererId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'Users',
      key: 'id',
    },
  },
  status: {
    type: DataTypes.ENUM('pending', 'accepted', 'rejected', 'completed', 'cancelled'),
    defaultValue: 'pending',
  },
  message: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  compatibilityScore: {
    type: DataTypes.DECIMAL(3, 2),
    allowNull: true,
    validate: {
      min: 0,
      max: 1,
    },
  },
  createdAt: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  },
  updatedAt: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  },
}, {
  indexes: [
    {
      fields: ['status'],
    },
    {
      fields: ['requesterId'],
    },
    {
      fields: ['offererId'],
    },
  ],
});

module.exports = Match;
