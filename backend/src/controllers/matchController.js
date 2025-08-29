const { Match, Skill, User } = require('../models');
const { Op } = require('sequelize');

// Helper functions (moved to top to avoid hoisting issues)
const calculateLevelCompatibility = (level1, level2) => {
  const levels = { 'beginner': 1, 'intermediate': 2, 'advanced': 3 };
  const diff = Math.abs(levels[level1] - levels[level2]);
  
  if (diff === 0) return 1.0;
  if (diff === 1) return 0.8;
  return 0.3;
};

const calculateLocationCompatibility = (location1, location2) => {
  if (location1 === location2) return 1.0;
  if (location1 === 'both' || location2 === 'both') return 0.8;
  return 0.2;
};

const calculateSkillQuality = (skill) => {
  let score = 0.5;

  if (skill.description && skill.description.length > 50) score += 0.2;
  if (skill.description && skill.description.length > 100) score += 0.1;
  if (skill.tags && skill.tags.length > 0) score += 0.1;
  if (skill.tags && skill.tags.length > 2) score += 0.1;
  if (skill.duration) score += 0.1;

  return Math.min(score, 1.0);
};

// Enhanced validation for match compatibility
const validateMatchCompatibility = async (offerSkill, requestSkill, currentUserId) => {
  // Check if skills are from different users
  if (offerSkill.userId === requestSkill.userId) {
    return { isValid: false, error: 'Cannot match skills from the same user' };
  }

  // Check if current user owns one of the skills
  const isCurrentUserInvolved = offerSkill.userId === currentUserId || requestSkill.userId === currentUserId;
  if (!isCurrentUserInvolved) {
    return { isValid: false, error: 'You must own one of the skills to create a match' };
  }

  // Check level compatibility
  const levelCompatibility = calculateLevelCompatibility(offerSkill.level, requestSkill.level);
  if (levelCompatibility < 0.3) {
    return { isValid: false, error: 'Skill levels are too different for an effective match' };
  }

  // Check location compatibility
  const locationCompatibility = calculateLocationCompatibility(offerSkill.location, requestSkill.location);
  if (locationCompatibility < 0.2) {
    return { isValid: false, error: 'Location preferences are incompatible' };
  }

  // Check if users have minimum ratings (optional but recommended)
  const offerUserRating = offerSkill.user.rating || 0;
  const requestUserRating = requestSkill.user.rating || 0;
  const totalOfferRatings = offerSkill.user.totalRatings || 0;
  const totalRequestRatings = requestSkill.user.totalRatings || 0;

  // Warn about low-rated users but don't block
  if ((offerUserRating < 3.0 && totalOfferRatings > 5) || (requestUserRating < 3.0 && totalRequestRatings > 5)) {
    console.warn(`Low-rated user in match: Offer user rating: ${offerUserRating}, Request user rating: ${requestUserRating}`);
  }

  return { isValid: true };
};

// Calculate overall match compatibility score
const calculateMatchCompatibilityScore = (offerSkill, requestSkill) => {
  let score = 0;
  const weights = {
    levelCompatibility: 0.25,
    locationCompatibility: 0.20,
    categoryMatch: 0.15,
    userRatingBalance: 0.20,
    skillQuality: 0.20
  };

  // Level compatibility
  const levelScore = calculateLevelCompatibility(offerSkill.level, requestSkill.level);
  score += levelScore * weights.levelCompatibility;

  // Location compatibility
  const locationScore = calculateLocationCompatibility(offerSkill.location, requestSkill.location);
  score += locationScore * weights.locationCompatibility;

  // Category match (same category is better)
  const categoryScore = offerSkill.category === requestSkill.category ? 1.0 : 0.5;
  score += categoryScore * weights.categoryMatch;

  // User rating balance (similar ratings are better)
  const offerRating = offerSkill.user.rating || 0;
  const requestRating = requestSkill.user.rating || 0;
  const ratingDiff = Math.abs(offerRating - requestRating);
  const ratingBalanceScore = Math.max(0, 1 - (ratingDiff / 5));
  score += ratingBalanceScore * weights.userRatingBalance;

  // Skill quality (based on description, tags, etc.)
  const offerQuality = calculateSkillQuality(offerSkill);
  const requestQuality = calculateSkillQuality(requestSkill);
  const qualityScore = (offerQuality + requestQuality) / 2;
  score += qualityScore * weights.skillQuality;

  return Math.round(score * 100) / 100;
};

const createMatch = async (req, res) => {
  try {
    const { offerSkillId, requestSkillId, message } = req.body;

    // Verify skills exist and are active
    const offerSkill = await Skill.findOne({
      where: { id: offerSkillId, isActive: true },
      include: [{ association: 'user', attributes: ['id', 'rating', 'totalRatings'] }]
    });

    const requestSkill = await Skill.findOne({
      where: { id: requestSkillId, isActive: true },
      include: [{ association: 'user', attributes: ['id', 'rating', 'totalRatings'] }]
    });

    if (!offerSkill || !requestSkill) {
      return res.status(404).json({ error: 'One or both skills not found' });
    }

    // Enhanced validation checks
    const validationResult = await validateMatchCompatibility(offerSkill, requestSkill, req.user.id);
    if (!validationResult.isValid) {
      return res.status(400).json({ error: validationResult.error });
    }

    // User can't match their own skills with each other
    if (offerSkill.user.id === req.user.id && requestSkill.user.id === req.user.id) {
      return res.status(400).json({ error: 'Cannot match your own skills with each other' });
    }

    // Determine who is the offerer and who is the requester
    const isCurrentUserOffering = offerSkill.user.id === req.user.id;
    const requesterId = isCurrentUserOffering ? requestSkill.user.id : req.user.id;
    const offererId = isCurrentUserOffering ? req.user.id : offerSkill.user.id;

    // Check if match already exists
    const existingMatch = await Match.findOne({
      where: {
        offerSkillId,
        requestSkillId,
        requesterId,
      }
    });

    if (existingMatch) {
      return res.status(400).json({ error: 'Match already exists' });
    }

    // Calculate match compatibility score
    const compatibilityScore = calculateMatchCompatibilityScore(offerSkill, requestSkill);

    const match = await Match.create({
      offerSkillId,
      requestSkillId,
      requesterId,
      offererId,
      message: message || '',
      compatibilityScore, // Add compatibility score to match
    });

    const matchWithDetails = await Match.findByPk(match.id, {
      include: [
        {
          association: 'offerSkill',
          attributes: ['id', 'title', 'description', 'level', 'category', 'location'],
          include: [{ association: 'user', attributes: ['id', 'username', 'firstName', 'lastName', 'rating'] }]
        },
        {
          association: 'requestSkill',
          attributes: ['id', 'title', 'description', 'level', 'category', 'location'],
          include: [{ association: 'user', attributes: ['id', 'username', 'firstName', 'lastName', 'rating'] }]
        },
        {
          association: 'requester',
          attributes: ['id', 'username', 'firstName', 'lastName'],
        },
        {
          association: 'offerer',
          attributes: ['id', 'username', 'firstName', 'lastName'],
        }
      ],
    });

    res.status(201).json({
      message: 'Match created successfully',
      match: matchWithDetails,
      compatibilityScore,
    });
  } catch (error) {
    console.error('Create match error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

const getMatches = async (req, res) => {
  try {
    const { status, type } = req.query;

    let whereClause = {};
    
    if (type === 'received') {
      whereClause.offererId = req.user.id;
    } else if (type === 'sent') {
      whereClause.requesterId = req.user.id;
    } else {
      whereClause = {
        [Op.or]: [
          { offererId: req.user.id },
          { requesterId: req.user.id }
        ]
      };
    }

    if (status) {
      whereClause.status = status;
    }

    const matches = await Match.findAll({
      where: whereClause,
      include: [
        {
          association: 'offerSkill',
          attributes: ['id', 'title', 'description'],
          include: [{ association: 'user', attributes: ['id', 'username', 'firstName', 'lastName'] }]
        },
        {
          association: 'requestSkill',
          attributes: ['id', 'title', 'description'],
          include: [{ association: 'user', attributes: ['id', 'username', 'firstName', 'lastName'] }]
        },
        {
          association: 'requester',
          attributes: ['id', 'username', 'firstName', 'lastName'],
        },
        {
          association: 'offerer',
          attributes: ['id', 'username', 'firstName', 'lastName'],
        }
      ],
      order: [['createdAt', 'DESC']],
    });

    res.json({ matches });
  } catch (error) {
    console.error('Get matches error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

const updateMatchStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    const match = await Match.findOne({
      where: { id, offererId: req.user.id } // Only offerer can update status
    });

    if (!match) {
      return res.status(404).json({ error: 'Match not found' });
    }

    const updateData = { status };
    
    if (status === 'accepted') {
      updateData.acceptedAt = new Date();
    } else if (status === 'completed') {
      updateData.completedAt = new Date();
    }

    await match.update(updateData);

    const updatedMatch = await Match.findByPk(match.id, {
      include: [
        {
          association: 'offerSkill',
          attributes: ['id', 'title', 'description'],
        },
        {
          association: 'requestSkill',
          attributes: ['id', 'title', 'description'],
        },
        {
          association: 'requester',
          attributes: ['id', 'username', 'firstName', 'lastName'],
        },
        {
          association: 'offerer',
          attributes: ['id', 'username', 'firstName', 'lastName'],
        }
      ],
    });

    res.json({
      message: 'Match status updated successfully',
      match: updatedMatch,
    });
  } catch (error) {
    console.error('Update match status error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

module.exports = {
  createMatch,
  getMatches,
  updateMatchStatus,
};
