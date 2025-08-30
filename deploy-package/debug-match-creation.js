const { Match, Skill, User } = require('./src/models');
const { Op } = require('sequelize');

async function debugMatchCreation() {
  try {
    console.log('🔍 Debugging match creation...');
    
    // Test 1: Check if skills exist
    const offerSkillId = '6f27bb44-cb32-4539-bd60-1d5d90af1c1d';
    const requestSkillId = '98df40eb-4e8e-4663-b0a7-00134f8a4d84';
    
    console.log('1. Checking if skills exist...');
    const offerSkill = await Skill.findOne({
      where: { id: offerSkillId, isActive: true },
      include: [{ association: 'user', attributes: ['id', 'rating', 'totalRatings'] }]
    });
    
    const requestSkill = await Skill.findOne({
      where: { id: requestSkillId, isActive: true },
      include: [{ association: 'user', attributes: ['id', 'rating', 'totalRatings'] }]
    });
    
    if (!offerSkill) {
      console.log('❌ Offer skill not found');
      return;
    }
    if (!requestSkill) {
      console.log('❌ Request skill not found');
      return;
    }
    
    console.log('✅ Both skills found');
    console.log('Offer skill:', offerSkill.title, 'User:', offerSkill.user.id);
    console.log('Request skill:', requestSkill.title, 'User:', requestSkill.user.id);
    
    // Test 2: Check if users exist
    const simonId = '209243bf-9636-484e-864e-6c4200383347';
    console.log('2. Checking if Simon exists...');
    const simon = await User.findByPk(simonId);
    if (!simon) {
      console.log('❌ Simon not found');
      return;
    }
    console.log('✅ Simon found:', simon.username);
    
    // Test 3: Try to create a simple match
    console.log('3. Attempting to create match...');
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
    
    // Test 4: Try to fetch the match with associations
    console.log('4. Testing match fetch with associations...');
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
    
    console.log('✅ Match with associations fetched successfully!');
    console.log('Offer skill title:', matchWithDetails.offerSkill.title);
    console.log('Request skill title:', matchWithDetails.requestSkill.title);
    
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

debugMatchCreation();
