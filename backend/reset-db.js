const { User, Skill, Match } = require('./src/models');
const bcrypt = require('bcryptjs');

async function resetDatabase() {
  try {
    console.log('🔄 Clearing database...');
    
    await Match.destroy({ where: {} });
    await Skill.destroy({ where: {} });
    await User.destroy({ where: {} });
    
    console.log('✅ Database cleared');
    
    const simon = await User.create({
      username: 'simon',
      email: 'simon@test.com',
      password: 'password123',
      firstName: 'Simon',
      lastName: 'Johnson',
      bio: 'Experienced software developer',
      rating: 4.8,
      totalRatings: 15
    });
    
    const nati = await User.create({
      username: 'nati',
      email: 'nati@test.com',
      password: 'password123',
      firstName: 'Nati',
      lastName: 'Smith',
      bio: 'Passionate educator',
      rating: 4.6,
      totalRatings: 12
    });
    
    await Skill.bulkCreate([
      {
        title: 'JavaScript Programming',
        description: 'I can teach JavaScript from beginner to advanced level.',
        category: 'Technology',
        type: 'offer',
        level: 'advanced',
        duration: '2 hours',
        location: 'online',
        tags: ['javascript', 'programming'],
        userId: simon.id,
        isActive: true
      },
      {
        title: 'Mathematics Tutoring',
        description: 'I need help with advanced calculus.',
        category: 'Education',
        type: 'request',
        level: 'intermediate',
        duration: '1.5 hours',
        location: 'online',
        tags: ['mathematics', 'calculus'],
        userId: simon.id,
        isActive: true
      },
      {
        title: 'English Language Teaching',
        description: 'I can teach English as a second language.',
        category: 'Education',
        type: 'offer',
        level: 'advanced',
        duration: '1 hour',
        location: 'online',
        tags: ['english', 'language'],
        userId: nati.id,
        isActive: true
      },
      {
        title: 'Web Development Help',
        description: 'I need help learning web development basics.',
        category: 'Technology',
        type: 'request',
        level: 'beginner',
        duration: '2 hours',
        location: 'online',
        tags: ['web-development', 'html'],
        userId: nati.id,
        isActive: true
      }
    ]);
    
    console.log('✅ Test data created successfully');
    console.log('Simon: simon@test.com / password123');
    console.log('Nati: nati@test.com / password123');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

resetDatabase();
