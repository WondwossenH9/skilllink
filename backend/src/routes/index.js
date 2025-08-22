const express = require('express');
const authRoutes = require('./auth');
const skillRoutes = require('./skills');
const matchRoutes = require('./matches');

const router = express.Router();

router.use('/auth', authRoutes);
router.use('/skills', skillRoutes);
router.use('/matches', matchRoutes);

// Health check endpoint
router.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    message: 'SkillLink API is running',
    timestamp: new Date().toISOString()
  });
});

module.exports = router;
