const { Match, Skill, User } = require('./src/models');
const { Op } = require('sequelize');

async function debugValidation() {
  try {
    console.log('🔍 Debugging validation step by step...');
    
    const offerSkillId = '6f27bb44-cb32-4539-bd60-1d5d90af1c1d';
    const requestSkillId = '98df40eb-4e8e-4663-b0a7-00134f8a4d84';
    const simonId = '209243bf-9636-484e-864e-6c4200383347';
    
    console.log('1. Fetching skills...');
    const offerSkill = await Skill.findOne({
      where: { id: offerSkillId, isActive: true },
      include: [{ association: 'user', attributes: ['id', 'rating', 'totalRatings'] }]
    });
    
    const requestSkill = await Skill.findOne({
      where: { id: requestSkillId, isActive: true },
      include: [{ association: 'user', attributes: ['id', 'rating', 'totalRatings'] }]
    });
    
    console.log('Offer skill:', offerSkill.title, 'User:', offerSkill.user.id);
    console.log('Request skill:', requestSkill.title, 'User:', requestSkill.user.id);
    console.log('Simon ID:', simonId);
    
    console.log('2. Testing validateMatchCompatibility...');
    
    // Test the exact validation logic from the controller
    if (offerSkill.userId === requestSkill.userId) {
      console.log('❌ Validation failed: Cannot match skills from the same user');
      return;
    }
    
    const isCurrentUserInvolved = offerSkill.userId === simonId || requestSkill.userId === simonId;
    if (!isCurrentUserInvolved) {
      console.log('❌ Validation failed: You must own one of the skills to create a match');
      return;
    }
    
    console.log('3. Testing level compatibility...');
    const levelCompatibility = calculateLevelCompatibility(offerSkill.level, requestSkill.level);
    console.log('Level compatibility:', levelCompatibility);
    
    if (levelCompatibility < 0.3) {
      console.log('❌ Validation failed: Skill levels are too different for an effective match');
      return;
    }
    
    console.log('4. Testing location compatibility...');
    const locationCompatibility = calculateLocationCompatibility(offerSkill.location, requestSkill.location);
    console.log('Location compatibility:', locationCompatibility);
    
    if (locationCompatibility < 0.2) {
      console.log('❌ Validation failed: Location preferences are incompatible');
      return;
    }
    
    console.log('5. Testing self-match prevention...');
    if (offerSkill.user.id === simonId && requestSkill.user.id === simonId) {
      console.log('❌ Validation failed: Cannot match your own skills with each other');
      return;
    }
    
    console.log('6. Testing existing match check...');
    const existingMatch = await Match.findOne({
      where: {
        offerSkillId,
        requestSkillId,
        requesterId: simonId,
      }
    });
    
    if (existingMatch) {
      console.log('❌ Validation failed: Match already exists');
      return;
    }
    
    console.log('✅ All validations passed!');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error('Stack:', error.stack);
    process.exit(1);
  }
}

// Helper functions
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

debugValidation();
