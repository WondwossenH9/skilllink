const express = require('express');
const { 
  createSkill, 
  getSkills, 
  getSkillById, 
  updateSkill, 
  deleteSkill,
  getUserSkills,
  findSkillMatches,
  getSkillRecommendations
} = require('../controllers/skillController');
const { authenticate, optionalAuth } = require('../middleware/auth');
const { skillValidation, handleValidationErrors } = require('../middleware/validation');

const router = express.Router();

router.get('/', optionalAuth, getSkills);
router.get('/recommendations', authenticate, getSkillRecommendations);
router.get('/my-skills', authenticate, getUserSkills);

router.get('/:id', optionalAuth, getSkillById);
router.get('/:id/matches', optionalAuth, findSkillMatches);
router.post('/', authenticate, skillValidation, handleValidationErrors, createSkill);
router.put('/:id', authenticate, skillValidation, handleValidationErrors, updateSkill);
router.delete('/:id', authenticate, deleteSkill);

module.exports = router;
