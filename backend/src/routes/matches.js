const express = require('express');
const { createMatch, getMatches, updateMatchStatus } = require('../controllers/matchController');
const { authenticate } = require('../middleware/auth');
const { matchValidation, handleValidationErrors } = require('../middleware/validation');

const router = express.Router();

router.get('/', authenticate, getMatches);
router.post('/', authenticate, matchValidation, handleValidationErrors, createMatch);
router.put('/:id/status', authenticate, updateMatchStatus);

module.exports = router;
