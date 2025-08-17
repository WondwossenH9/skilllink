const User = require('./User');
const Skill = require('./Skill');
const Match = require('./Match');
const Rating = require('./Rating');

// Define associations
User.hasMany(Skill, { foreignKey: 'userId', as: 'skills' });
Skill.belongsTo(User, { foreignKey: 'userId', as: 'user' });

// Match associations
Match.belongsTo(Skill, { foreignKey: 'offerSkillId', as: 'offerSkill' });
Match.belongsTo(Skill, { foreignKey: 'requestSkillId', as: 'requestSkill' });
Match.belongsTo(User, { foreignKey: 'requesterId', as: 'requester' });
Match.belongsTo(User, { foreignKey: 'offererId', as: 'offerer' });

// Rating associations
Rating.belongsTo(User, { foreignKey: 'raterId', as: 'rater' });
Rating.belongsTo(User, { foreignKey: 'ratedUserId', as: 'ratedUser' });
Rating.belongsTo(Match, { foreignKey: 'matchId', as: 'match' });

// Reverse associations
User.hasMany(Match, { foreignKey: 'requesterId', as: 'requestedMatches' });
User.hasMany(Match, { foreignKey: 'offererId', as: 'offeredMatches' });
User.hasMany(Rating, { foreignKey: 'raterId', as: 'givenRatings' });
User.hasMany(Rating, { foreignKey: 'ratedUserId', as: 'receivedRatings' });

Skill.hasMany(Match, { foreignKey: 'offerSkillId', as: 'offerMatches' });
Skill.hasMany(Match, { foreignKey: 'requestSkillId', as: 'requestMatches' });

Match.hasMany(Rating, { foreignKey: 'matchId', as: 'ratings' });

module.exports = {
  User,
  Skill,
  Match,
  Rating,
};
