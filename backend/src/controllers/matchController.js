const { Match, Skill, User } = require('../models');

const createMatch = async (req, res) => {
  try {
    const { offerSkillId, requestSkillId, message } = req.body;

    // Verify skills exist and are active
    const offerSkill = await Skill.findOne({
      where: { id: offerSkillId, type: 'offer', isActive: true },
      include: [{ association: 'user', attributes: ['id'] }]
    });

    const requestSkill = await Skill.findOne({
      where: { id: requestSkillId, type: 'request', isActive: true },
      include: [{ association: 'user', attributes: ['id'] }]
    });

    if (!offerSkill || !requestSkill) {
      return res.status(404).json({ error: 'One or both skills not found' });
    }

    // User can't match their own skills
    if (offerSkill.user.id === req.user.id || requestSkill.user.id === req.user.id) {
      return res.status(400).json({ error: 'Cannot match your own skills' });
    }

    // Check if match already exists
    const existingMatch = await Match.findOne({
      where: {
        offerSkillId,
        requestSkillId,
        requesterId: req.user.id,
      }
    });

    if (existingMatch) {
      return res.status(400).json({ error: 'Match already exists' });
    }

    const match = await Match.create({
      offerSkillId,
      requestSkillId,
      requesterId: req.user.id,
      offererId: offerSkill.user.id,
      message: message || '',
    });

    const matchWithDetails = await Match.findByPk(match.id, {
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
    });

    res.status(201).json({
      message: 'Match created successfully',
      match: matchWithDetails,
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
        $or: [
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
