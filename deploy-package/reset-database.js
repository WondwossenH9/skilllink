const { User, Skill, Match } = require('./src/models');
const bcrypt = require('bcryptjs');

async function resetDatabase() {
  try {
    console.log('🔄 Clearing database...');
    
    // Clear all data
    await Match.destroy({ where: {} });
    await Skill.destroy({ where: {} });
    await User.destroy({ where: {} });
    
    console.log('✅ Database cleared successfully');
    
    // Create test users
    console.log('👥 Creating test users...');
    
    const hashedPassword = await bcrypt.hash('password123', 10);
    
    // Create Simon
    const simon = await User.create({
      username: 'simon',
      email: 'simon@test.com',
      password: hashedPassword,
      firstName: 'Simon',
      lastName: 'Johnson',
      bio: 'Experienced software developer and math tutor',
      rating: 4.8,
      totalRatings: 15
    });
    
    // Create Nati
    const nati = await User.create({
      username: 'nati',
      email: 'nati@test.com',
      password: hashedPassword,
      firstName: 'Nati',
      lastName: 'Smith',
      bio: 'Passionate educator and language enthusiast',
      rating: 4.6,
      totalRatings: 12
    });
    
    console.log('✅ Test users created');
    
    // Create skills for Simon
    console.log('📚 Creating skills for Simon...');
    
    const simonSkills = await Skill.bulkCreate([
      {
        title: 'JavaScript Programming',
        description: 'I can teach JavaScript from beginner to advanced level. Experienced with modern frameworks like React and Node.js.',
        category: 'Technology',
        type: 'offer',
        level: 'advanced',
        duration: '2 hours',
        location: 'online',
        tags: ['javascript', 'programming', 'web-development'],
        userId: simon.id,
        isActive: true
      },
      {
        title: 'Mathematics Tutoring',
        description: 'I need help with advanced calculus and linear algebra. Looking for someone who can explain complex concepts clearly.',
        category: 'Education',
        type: 'request',
        level: 'intermediate',
        duration: '1.5 hours',
        location: 'online',
        tags: ['mathematics', 'calculus', 'algebra'],
        userId: simon.id,
        isActive: true
      }
    ]);
    
    // Create skills for Nati
    console.log('📚 Creating skills for Nati...');
    
    const natiSkills = await Skill.bulkCreate([
      {
        title: 'English Language Teaching',
        description: 'I can teach English as a second language. Experienced with grammar, pronunciation, and conversation practice.',
        category: 'Education',
        type: 'offer',
        level: 'advanced',
        duration: '1 hour',
        location: 'online',
        tags: ['english', 'language', 'teaching'],
        userId: nati.id,
        isActive: true
      },
      {
        title: 'Web Development Help',
        description: 'I need help learning web development basics. Looking for someone to guide me through HTML, CSS, and JavaScript.',
        category: 'Technology',
        type: 'request',
        level: 'beginner',
        duration: '2 hours',
        location: 'online',
        tags: ['web-development', 'html', 'css', 'javascript'],
        userId: nati.id,
        isActive: true
      }
    ]);
    
    console.log('✅ Skills created successfully');
    
    // Display the created data
    console.log('\n📊 Database Summary:');
    console.log('Users:', await User.count());
    console.log('Skills:', await Skill.count());
    console.log('Matches:', await Match.count());
    
    console.log('\n👤 Test Users:');
    console.log('Simon (simon@test.com) - Password: password123');
    console.log('Nati (nati@test.com) - Password: password123');
    
    console.log('\n🎯 Perfect Match Scenario:');
    console.log('Simon offers: JavaScript Programming (Technology, offer)');
    console.log('Nati requests: Web Development Help (Technology, request)');
    console.log('Simon requests: Mathematics Tutoring (Education, request)');
    console.log('Nati offers: English Language Teaching (Education, offer)');
    
    console.log('\n✅ Database reset complete!');
    process.exit(0);
    
  } catch (error) {
    console.error('❌ Error resetting database:', error);
    process.exit(1);
  }
}

resetDatabase();
