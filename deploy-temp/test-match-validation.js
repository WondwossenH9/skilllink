const { Match, Skill, User } = require('./src/models');
const { Op } = require('sequelize');

async function testMatchValidation() {
  try {
    console.log('🔍 Testing match validation step by step...');
    
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
    
    console.log('Offer skill user ID:', offerSkill.user.id);
    console.log('Request skill user ID:', requestSkill.user.id);
    console.log('Simon ID:', simonId);
    console.log('Are they the same?', offerSkill.user.id === requestSkill.user.id);
    
    console.log('2. Testing validation logic...');
    
    // Test the validation logic manually
    if (offerSkill.userId === requestSkill.userId) {
      console.log('❌ Validation failed: Same user');
      return;
    }
    
    const isCurrentUserInvolved = offerSkill.userId === simonId || requestSkill.userId === simonId;
    console.log('Is current user involved?', isCurrentUserInvolved);
    
    if (!isCurrentUserInvolved) {
      console.log('❌ Validation failed: User not involved');
      return;
    }
    
    console.log('3. Testing level compatibility...');
    const levelCompatibility = calculateLevelCompatibility(offerSkill.level, requestSkill.level);
    console.log('Level compatibility:', levelCompatibility);
    
    if (levelCompatibility < 0.3) {
      console.log('❌ Validation failed: Level incompatibility');
      return;
    }
    
    console.log('4. Testing location compatibility...');
    const locationCompatibility = calculateLocationCompatibility(offerSkill.location, requestSkill.location);
    console.log('Location compatibility:', locationCompatibility);
    
    if (locationCompatibility < 0.2) {
      console.log('❌ Validation failed: Location incompatibility');
      return;
    }
    
    console.log('5. Testing self-match prevention...');
    const isSelfMatch = offerSkill.user.id === simonId && requestSkill.user.id === simonId;
    console.log('Is self match?', isSelfMatch);
    
    if (isSelfMatch) {
      console.log('❌ Validation failed: Self match');
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
    
    console.log('Existing match found?', !!existingMatch);
    
    if (existingMatch) {
      console.log('❌ Validation failed: Match already exists');
      return;
    }
    
    console.log('✅ All validations passed!');
    
    // Test the actual match creation
    console.log('7. Testing match creation...');
    const match = await Match.create({
      offerSkillId,
      requestSkillId,
      requesterId: simonId,
      offererId: offerSkill.user.id,
      message: 'Test match',
      compatibilityScore: 0.75,
    });
    
    console.log('✅ Match created successfully!');
    console.log('Match ID:', match.id);
    
    // Clean up
    await match.destroy();
    console.log('✅ Test match cleaned up');
    
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

testMatchValidation();
