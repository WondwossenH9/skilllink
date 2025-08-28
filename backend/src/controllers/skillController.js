const { Skill, User, Match } = require('../models');
const { Op } = require('sequelize');

const createSkill = async (req, res) => {
  try {
    const { title, description, category, type, level, duration, location, tags } = req.body;

    const skill = await Skill.create({
      title,
      description,
      category,
      type,
      level: level || 'beginner',
      duration,
      location: location || 'online',
      tags: tags || [],
      userId: req.user.id,
    });

    const skillWithUser = await Skill.findByPk(skill.id, {
      include: [
        {
          association: 'user',
          attributes: ['id', 'username', 'firstName', 'lastName'],
        }
      ],
    });

    res.status(201).json({
      message: 'Skill created successfully',
      skill: skillWithUser,
    });
  } catch (error) {
    console.error('Create skill error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

const getSkills = async (req, res) => {
  try {
    const { 
      type, 
      category, 
      level, 
      location, 
      search, 
      page = 1, 
      limit = 10 
    } = req.query;

    const offset = (page - 1) * limit;
    
    let whereClause = { isActive: true };
    
    // Add filters
    if (type) whereClause.type = type;
    if (category) whereClause.category = category;
    if (level) whereClause.level = level;
    if (location) whereClause.location = location;
    
    // Add search
    if (search) {
      whereClause[Op.or] = [
        { title: { [Op.iLike]: `%${search}%` } },
        { description: { [Op.iLike]: `%${search}%` } },
        { category: { [Op.iLike]: `%${search}%` } },
      ];
    }

    const { count, rows: skills } = await Skill.findAndCountAll({
      where: whereClause,
      include: [
        {
          association: 'user',
          attributes: ['id', 'username', 'firstName', 'lastName', 'rating'],
        }
      ],
      order: [['createdAt', 'DESC']],
      limit: parseInt(limit),
      offset: parseInt(offset),
    });

    res.json({
      skills,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: count,
        pages: Math.ceil(count / limit),
      },
    });
  } catch (error) {
    console.error('Get skills error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

const getSkillById = async (req, res) => {
  try {
    const { id } = req.params;

    const skill = await Skill.findOne({
      where: { id, isActive: true },
      include: [
        {
          association: 'user',
          attributes: ['id', 'username', 'firstName', 'lastName', 'rating', 'bio'],
        }
      ],
    });

    if (!skill) {
      return res.status(404).json({ error: 'Skill not found' });
    }

    res.json({ skill });
  } catch (error) {
    console.error('Get skill by ID error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

const updateSkill = async (req, res) => {
  try {
    const { id } = req.params;
    const { title, description, category, level, duration, location, tags } = req.body;

    const skill = await Skill.findOne({
      where: { id, userId: req.user.id, isActive: true }
    });

    if (!skill) {
      return res.status(404).json({ error: 'Skill not found' });
    }

    await skill.update({
      title: title || skill.title,
      description: description || skill.description,
      category: category || skill.category,
      level: level || skill.level,
      duration: duration || skill.duration,
      location: location || skill.location,
      tags: tags || skill.tags,
    });

    const updatedSkill = await Skill.findByPk(skill.id, {
      include: [
        {
          association: 'user',
          attributes: ['id', 'username', 'firstName', 'lastName'],
        }
      ],
    });

    res.json({
      message: 'Skill updated successfully',
      skill: updatedSkill,
    });
  } catch (error) {
    console.error('Update skill error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

const deleteSkill = async (req, res) => {
  try {
    const { id } = req.params;

    const skill = await Skill.findOne({
      where: { id, userId: req.user.id, isActive: true }
    });

    if (!skill) {
      return res.status(404).json({ error: 'Skill not found' });
    }

    await skill.update({ isActive: false });

    res.json({ message: 'Skill deleted successfully' });
  } catch (error) {
    console.error('Delete skill error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

const getUserSkills = async (req, res) => {
  try {
    const skills = await Skill.findAll({
      where: { userId: req.user.id, isActive: true },
      include: [
        {
          association: 'user',
          attributes: ['id', 'username', 'firstName', 'lastName'],
        }
      ],
      order: [['createdAt', 'DESC']],
    });

    res.json({ skills });
  } catch (error) {
    console.error('Get user skills error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Add search and match suggestion functionality
const findSkillMatches = async (req, res) => {
  try {
    const { id } = req.params;
    
    const skill = await Skill.findByPk(id);
    if (!skill) {
      return res.status(404).json({ error: 'Skill not found' });
    }

    // Simple test - just return the skill itself with a default score
    const matches = [{
      ...skill.toJSON(),
      matchScore: 0.8,
      user: skill.user || { id: 'unknown', username: 'Unknown', firstName: 'Unknown', lastName: 'User', rating: 0, totalRatings: 0 }
    }];

    res.json({ matches });
  } catch (error) {
    console.error('Find skill matches error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Sophisticated matching algorithm
const calculateMatchScore = (sourceSkill, targetSkill) => {
  let score = 0;
  const weights = {
    levelCompatibility: 0.25,
    locationCompatibility: 0.20,
    userRating: 0.25,
    skillDemand: 0.15,
    tagOverlap: 0.10,
    recency: 0.05
  };

  // 1. Level Compatibility (25% weight)
  const levelScore = calculateLevelCompatibility(sourceSkill.level, targetSkill.level);
  score += levelScore * weights.levelCompatibility;

  // 2. Location Compatibility (20% weight)
  const locationScore = calculateLocationCompatibility(sourceSkill.location, targetSkill.location);
  score += locationScore * weights.locationCompatibility;

  // 3. User Rating (25% weight)
  const ratingScore = calculateRatingScore(targetSkill.user.rating, targetSkill.user.totalRatings);
  score += ratingScore * weights.userRating;

  // 4. Skill Demand (15% weight) - Higher demand for requests, higher supply for offers
  const demandScore = calculateDemandScore(sourceSkill.type, targetSkill.type);
  score += demandScore * weights.skillDemand;

  // 5. Tag Overlap (10% weight)
  const tagScore = calculateTagOverlap(sourceSkill.tags, targetSkill.tags);
  score += tagScore * weights.tagOverlap;

  // 6. Recency (5% weight) - Prefer newer skills
  const recencyScore = calculateRecencyScore(targetSkill.createdAt);
  score += recencyScore * weights.recency;

  return Math.round(score * 100) / 100; // Round to 2 decimal places
};

// Calculate level compatibility
const calculateLevelCompatibility = (level1, level2) => {
  const levels = { 'beginner': 1, 'intermediate': 2, 'advanced': 3 };
  const diff = Math.abs(levels[level1] - levels[level2]);
  
  if (diff === 0) return 1.0; // Same level - perfect match
  if (diff === 1) return 0.8; // Adjacent levels - good match
  return 0.3; // Far apart levels - poor match
};

// Calculate location compatibility
const calculateLocationCompatibility = (location1, location2) => {
  if (location1 === location2) return 1.0; // Same preference
  if (location1 === 'both' || location2 === 'both') return 0.8; // One flexible
  return 0.2; // Incompatible preferences
};

// Calculate rating score
const calculateRatingScore = (rating, totalRatings) => {
  // Handle null/undefined values
  const userRating = rating || 0;
  const userTotalRatings = totalRatings || 0;
  
  if (userTotalRatings < 3) return 0.5; // Default score for new users
  
  // Normalize rating (0-5 scale) and factor in number of ratings
  const normalizedRating = userRating / 5;
  const confidenceFactor = Math.min(userTotalRatings / 10, 1); // More ratings = higher confidence
  
  return normalizedRating * 0.7 + confidenceFactor * 0.3;
};

// Calculate demand score
const calculateDemandScore = (sourceType, targetType) => {
  // Higher score for request-offer pairs (demand-supply)
  if (sourceType === 'request' && targetType === 'offer') return 1.0;
  if (sourceType === 'offer' && targetType === 'request') return 1.0;
  return 0.5; // Same type pairs
};

// Calculate tag overlap
const calculateTagOverlap = (tags1, tags2) => {
  // Handle null/undefined tags
  if (!tags1 || !tags2 || !Array.isArray(tags1) || !Array.isArray(tags2) || tags1.length === 0 || tags2.length === 0) {
    return 0.5; // Default score for no tags
  }
  
  const set1 = new Set(tags1.map(tag => tag.toLowerCase()));
  const set2 = new Set(tags2.map(tag => tag.toLowerCase()));
  
  const intersection = new Set([...set1].filter(x => set2.has(x)));
  const union = new Set([...set1, ...set2]);
  
  return intersection.size / union.size;
};

// Calculate recency score
const calculateRecencyScore = (createdAt) => {
  const now = new Date();
  const created = new Date(createdAt);
  const daysDiff = (now - created) / (1000 * 60 * 60 * 24);
  
  if (daysDiff <= 7) return 1.0; // Very recent
  if (daysDiff <= 30) return 0.8; // Recent
  if (daysDiff <= 90) return 0.6; // Moderately recent
  return 0.4; // Old
};

// Calculate score for user's own skills (for exchange purposes)
const calculateUserSkillScore = (sourceSkill, userSkill) => {
  let score = 0;
  const weights = {
    levelCompatibility: 0.30,
    locationCompatibility: 0.25,
    categoryRelevance: 0.25,
    skillQuality: 0.20
  };

  // Level compatibility
  const levelScore = calculateLevelCompatibility(sourceSkill.level, userSkill.level);
  score += levelScore * weights.levelCompatibility;

  // Location compatibility
  const locationScore = calculateLocationCompatibility(sourceSkill.location, userSkill.location);
  score += locationScore * weights.locationCompatibility;

  // Category relevance (same category gets higher score)
  const categoryScore = sourceSkill.category === userSkill.category ? 1.0 : 0.5;
  score += categoryScore * weights.categoryRelevance;

  // Skill quality (based on description length, tags, etc.)
  const qualityScore = calculateSkillQuality(userSkill);
  score += qualityScore * weights.skillQuality;

  return Math.round(score * 100) / 100;
};

// Calculate skill quality based on various factors
const calculateSkillQuality = (skill) => {
  let score = 0.5; // Base score

  // Description quality (longer descriptions are better)
  if (skill.description && skill.description.length > 50) score += 0.2;
  if (skill.description && skill.description.length > 100) score += 0.1;

  // Tags quality
  if (skill.tags && skill.tags.length > 0) score += 0.1;
  if (skill.tags && skill.tags.length > 2) score += 0.1;

  // Duration specified
  if (skill.duration) score += 0.1;

  return Math.min(score, 1.0);
};

// Get personalized skill recommendations for a user
const getSkillRecommendations = async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Get user's existing skills and preferences
    const userSkills = await Skill.findAll({
      where: { userId, isActive: true },
      attributes: ['id', 'category', 'type', 'level', 'tags'],
    });

    // Get user's match history to understand preferences
    const userMatches = await Match.findAll({
      where: {
        [Op.or]: [
          { requesterId: userId },
          { offererId: userId }
        ],
        status: { [Op.in]: ['accepted', 'completed'] }
      },
      include: [
        { association: 'offerSkill', attributes: ['category', 'type', 'level', 'tags'] },
        { association: 'requestSkill', attributes: ['category', 'type', 'level', 'tags'] }
      ]
    });

    // Analyze user preferences
    const preferences = analyzeUserPreferences(userSkills, userMatches);
    
    // Find recommended skills based on preferences
    const recommendations = await Skill.findAll({
      where: {
        isActive: true,
        userId: { [Op.not]: userId }, // Not user's own skills
        category: { [Op.in]: preferences.topCategories },
        type: { [Op.in]: preferences.preferredTypes },
        level: { [Op.in]: preferences.preferredLevels }
      },
      include: [
        {
          association: 'user',
          attributes: ['id', 'username', 'firstName', 'lastName', 'rating', 'totalRatings'],
        }
      ],
      order: [['createdAt', 'DESC']],
      limit: 20,
    });

    // Score and rank recommendations
    const scoredRecommendations = recommendations.map(skill => {
      const score = calculateRecommendationScore(skill, preferences, userSkills);
      return { ...skill.toJSON(), recommendationScore: score };
    });

    // Sort by recommendation score
    scoredRecommendations.sort((a, b) => b.recommendationScore - a.recommendationScore);

    res.json({ 
      recommendations: scoredRecommendations.slice(0, 10),
      preferences 
    });
  } catch (error) {
    console.error('Get skill recommendations error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

// Analyze user preferences based on skills and match history
const analyzeUserPreferences = (userSkills, userMatches) => {
  const categoryCount = {};
  const typeCount = { offer: 0, request: 0 };
  const levelCount = { beginner: 0, intermediate: 0, advanced: 0 };
  const tagCount = {};

  // Analyze user's own skills
  userSkills.forEach(skill => {
    categoryCount[skill.category] = (categoryCount[skill.category] || 0) + 1;
    typeCount[skill.type]++;
    levelCount[skill.level]++;
    
    if (skill.tags) {
      skill.tags.forEach(tag => {
        tagCount[tag] = (tagCount[tag] || 0) + 1;
      });
    }
  });

  // Analyze successful matches
  userMatches.forEach(match => {
    const offerSkill = match.offerSkill;
    const requestSkill = match.requestSkill;
    
    // Count categories from successful matches
    categoryCount[offerSkill.category] = (categoryCount[offerSkill.category] || 0) + 0.5;
    categoryCount[requestSkill.category] = (categoryCount[requestSkill.category] || 0) + 0.5;
    
    // Count levels from successful matches
    levelCount[offerSkill.level] = (levelCount[offerSkill.level] || 0) + 0.5;
    levelCount[requestSkill.level] = (levelCount[requestSkill.level] || 0) + 0.5;
  });

  // Get top categories
  const topCategories = Object.entries(categoryCount)
    .sort(([,a], [,b]) => b - a)
    .slice(0, 5)
    .map(([category]) => category);

  // Get preferred types (opposite of what user offers)
  const preferredTypes = typeCount.offer > typeCount.request ? ['request'] : ['offer'];

  // Get preferred levels
  const preferredLevels = Object.entries(levelCount)
    .sort(([,a], [,b]) => b - a)
    .slice(0, 2)
    .map(([level]) => level);

  // Get top tags
  const topTags = Object.entries(tagCount)
    .sort(([,a], [,b]) => b - a)
    .slice(0, 10)
    .map(([tag]) => tag);

  return {
    topCategories,
    preferredTypes,
    preferredLevels,
    topTags,
    categoryCount,
    typeCount,
    levelCount
  };
};

// Calculate recommendation score based on user preferences
const calculateRecommendationScore = (skill, preferences, userSkills) => {
  let score = 0;
  const weights = {
    categoryMatch: 0.30,
    typePreference: 0.25,
    levelMatch: 0.20,
    tagOverlap: 0.15,
    userRating: 0.10
  };

  // Category match
  const categoryScore = preferences.topCategories.includes(skill.category) ? 1.0 : 0.3;
  score += categoryScore * weights.categoryMatch;

  // Type preference
  const typeScore = preferences.preferredTypes.includes(skill.type) ? 1.0 : 0.5;
  score += typeScore * weights.typePreference;

  // Level match
  const levelScore = preferences.preferredLevels.includes(skill.level) ? 1.0 : 0.5;
  score += levelScore * weights.levelMatch;

  // Tag overlap
  const tagScore = calculateTagOverlap(skill.tags, preferences.topTags);
  score += tagScore * weights.tagOverlap;

  // User rating
  const ratingScore = calculateRatingScore(skill.user.rating, skill.user.totalRatings);
  score += ratingScore * weights.userRating;

  return Math.round(score * 100) / 100;
};

module.exports = {
  createSkill,
  getSkills,
  getSkillById,
  updateSkill,
  deleteSkill,
  getUserSkills,
  findSkillMatches,
  getSkillRecommendations,
};
