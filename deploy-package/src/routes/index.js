const express = require('express');
const authRoutes = require('./auth');
const skillRoutes = require('./skills');
const matchRoutes = require('./matches');
const sequelize = require('../../config/database');

const router = express.Router();

router.use('/auth', authRoutes);
router.use('/skills', skillRoutes);
router.use('/matches', matchRoutes);

// Health check endpoint with database connectivity
router.get('/health', async (req, res) => {
  try {
    // Test database connection
    await sequelize.authenticate();
    
    res.json({ 
      status: 'OK', 
      message: 'SkillLink API is running',
      database: 'connected',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Health check failed:', error);
    res.status(503).json({ 
      status: 'ERROR', 
      message: 'SkillLink API is running but database is not connected',
      database: 'disconnected',
      timestamp: new Date().toISOString()
    });
  }
});

module.exports = router;
