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

    // Find potential matches
    // For offers, find requests in same category
    // For requests, find offers in same category
    const oppositeType = skill.type === 'offer' ? 'request' : 'offer';
    
    const matches = await Skill.findAll({
      where: {
        type: oppositeType,
        category: skill.category,
        isActive: true,
        userId: { [Op.not]: skill.userId }, // Exclude own skills
      },
      include: [
        {
          association: 'user',
          attributes: ['id', 'username', 'firstName', 'lastName', 'rating'],
        }
      ],
      order: [['createdAt', 'DESC']],
      limit: 10,
    });

    res.json({ matches });
  } catch (error) {
    console.error('Find skill matches error:', error);
    res.status(500).json({ error: 'Server error' });
  }
};

module.exports = {
  createSkill,
  getSkills,
  getSkillById,
  updateSkill,
  deleteSkill,
  getUserSkills,
  findSkillMatches,
};
