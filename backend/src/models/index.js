const { Sequelize } = require('sequelize');
const config = require('../config/config');

const env = process.env.NODE_ENV || 'development';
const dbConfig = config[env];

let sequelize;
if (env === 'development') {
  sequelize = new Sequelize(dbConfig);
} else {
  sequelize = new Sequelize(
    dbConfig.database,
    dbConfig.username,
    dbConfig.password,
    {
      host: dbConfig.host,
      port: dbConfig.port,
      dialect: dbConfig.dialect,
      dialectOptions: dbConfig.dialectOptions,
      logging: false
    }
  );
}

const User = require('./User');
const Skill = require('./Skill');
const Match = require('./Match');
const Rating = require('./Rating');

// Initialize models with sequelize
const UserModel = User(sequelize);
const SkillModel = Skill(sequelize);
const MatchModel = Match(sequelize);
const RatingModel = Rating(sequelize);

// Define associations
UserModel.hasMany(SkillModel, { foreignKey: 'userId', as: 'skills' });
SkillModel.belongsTo(UserModel, { foreignKey: 'userId', as: 'user' });

// Match associations
MatchModel.belongsTo(SkillModel, { foreignKey: 'offerSkillId', as: 'offerSkill' });
MatchModel.belongsTo(SkillModel, { foreignKey: 'requestSkillId', as: 'requestSkill' });
MatchModel.belongsTo(UserModel, { foreignKey: 'requesterId', as: 'requester' });
MatchModel.belongsTo(UserModel, { foreignKey: 'offererId', as: 'offerer' });

// Rating associations
RatingModel.belongsTo(UserModel, { foreignKey: 'raterId', as: 'rater' });
RatingModel.belongsTo(UserModel, { foreignKey: 'ratedUserId', as: 'ratedUser' });
RatingModel.belongsTo(MatchModel, { foreignKey: 'matchId', as: 'match' });

// Reverse associations
UserModel.hasMany(MatchModel, { foreignKey: 'requesterId', as: 'requestedMatches' });
UserModel.hasMany(MatchModel, { foreignKey: 'offererId', as: 'offeredMatches' });
UserModel.hasMany(RatingModel, { foreignKey: 'raterId', as: 'givenRatings' });
UserModel.hasMany(RatingModel, { foreignKey: 'ratedUserId', as: 'receivedRatings' });

SkillModel.hasMany(MatchModel, { foreignKey: 'offerSkillId', as: 'offerMatches' });
SkillModel.hasMany(MatchModel, { foreignKey: 'requestSkillId', as: 'requestMatches' });

MatchModel.hasMany(RatingModel, { foreignKey: 'matchId', as: 'ratings' });

module.exports = {
  sequelize,
  User: UserModel,
  Skill: SkillModel,
  Match: MatchModel,
  Rating: RatingModel,
};
