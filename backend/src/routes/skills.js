const express = require('express');
const { 
  createSkill, 
  getSkills, 
  getSkillById, 
  updateSkill, 
  deleteSkill,
  getUserSkills 
} = require('../controllers/skillController');
const { authenticate, optionalAuth } = require('../middleware/auth');
const { skillValidation, handleValidationErrors } = require('../middleware/validation');

const router = express.Router();

router.get('/', optionalAuth, getSkills);
router.get('/my-skills', authenticate, getUserSkills);
router.get('/:id', optionalAuth, getSkillById);
router.post('/', authenticate, skillValidation, handleValidationErrors, createSkill);
router.put('/:id', authenticate, skillValidation, handleValidationErrors, updateSkill);
router.delete('/:id', authenticate, deleteSkill);

module.exports = router;
const { findSkillMatches } = require('../controllers/skillController');

router.get('/:id/matches', optionalAuth, findSkillMatches);

module.exports = router;
