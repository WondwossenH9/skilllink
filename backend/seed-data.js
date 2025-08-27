const { User, Skill, Match } = require('./src/models');
const bcrypt = require('bcryptjs');

const seedData = async () => {
  try {
    console.log('🌱 Starting to seed data...');

    // Clear existing data
    await Match.destroy({ where: {} });
    await Skill.destroy({ where: {} });
    await User.destroy({ where: {} });

    console.log('🗑️  Cleared existing data');

    // Create test users
    const users = await User.bulkCreate([
      {
        username: 'john_doe',
        email: 'john@example.com',
        password: await bcrypt.hash('password123', 12),
        firstName: 'John',
        lastName: 'Doe',
        bio: 'Software developer with 5+ years of experience. Passionate about teaching and learning new technologies.',
        rating: 4.8,
        totalRatings: 12,
      },
      {
        username: 'sarah_smith',
        email: 'sarah@example.com',
        password: await bcrypt.hash('password123', 12),
        firstName: 'Sarah',
        lastName: 'Smith',
        bio: 'Graphic designer and art enthusiast. Love sharing creative skills and learning from others.',
        rating: 4.9,
        totalRatings: 8,
      },
      {
        username: 'mike_wilson',
        email: 'mike@example.com',
        password: await bcrypt.hash('password123', 12),
        firstName: 'Mike',
        lastName: 'Wilson',
        bio: 'Guitar teacher and music producer. 10+ years of experience in music education.',
        rating: 4.7,
        totalRatings: 15,
      },
      {
        username: 'emma_davis',
        email: 'emma@example.com',
        password: await bcrypt.hash('password123', 12),
        firstName: 'Emma',
        lastName: 'Davis',
        bio: 'Language tutor specializing in Spanish and French. Native speaker with teaching certification.',
        rating: 4.6,
        totalRatings: 20,
      },
      {
        username: 'alex_chen',
        email: 'alex@example.com',
        password: await bcrypt.hash('password123', 12),
        firstName: 'Alex',
        lastName: 'Chen',
        bio: 'Fitness trainer and nutrition expert. Helping people achieve their health goals.',
        rating: 4.5,
        totalRatings: 18,
      },
      {
        username: 'lisa_brown',
        email: 'lisa@example.com',
        password: await bcrypt.hash('password123', 12),
        firstName: 'Lisa',
        lastName: 'Brown',
        bio: 'Cooking instructor and food blogger. Love sharing culinary skills and recipes.',
        rating: 4.4,
        totalRatings: 14,
      },
      {
        username: 'david_lee',
        email: 'david@example.com',
        password: await bcrypt.hash('password123', 12),
        firstName: 'David',
        lastName: 'Lee',
        bio: 'Photography enthusiast and professional photographer. Teaching camera techniques and editing.',
        rating: 4.3,
        totalRatings: 11,
      },
      {
        username: 'anna_garcia',
        email: 'anna@example.com',
        password: await bcrypt.hash('password123', 12),
        firstName: 'Anna',
        lastName: 'Garcia',
        bio: 'Yoga instructor and wellness coach. Certified in multiple yoga styles.',
        rating: 4.2,
        totalRatings: 16,
      }
    ]);

    console.log('👥 Created', users.length, 'users');

    // Create skills
    const skills = await Skill.bulkCreate([
      // Technology Skills
      {
        title: 'JavaScript Programming',
        description: 'Learn modern JavaScript including ES6+, async programming, and web development fundamentals. Perfect for beginners and intermediate developers.',
        category: 'Technology',
        type: 'offer',
        level: 'intermediate',
        duration: '2 hours per session',
        location: 'online',
        tags: ['javascript', 'programming', 'web-development'],
        userId: users[0].id,
      },
      {
        title: 'React Development',
        description: 'Looking to learn React.js for building modern web applications. Have basic JavaScript knowledge and want to expand my skills.',
        category: 'Technology',
        type: 'request',
        level: 'beginner',
        duration: '1-2 hours per session',
        location: 'online',
        tags: ['react', 'javascript', 'frontend'],
        userId: users[1].id,
      },
      {
        title: 'Python for Data Science',
        description: 'Teaching Python programming with focus on data analysis, pandas, numpy, and machine learning basics.',
        category: 'Technology',
        type: 'offer',
        level: 'advanced',
        duration: '3 hours per session',
        location: 'both',
        tags: ['python', 'data-science', 'machine-learning'],
        userId: users[0].id,
      },

      // Language Skills
      {
        title: 'Spanish Conversation',
        description: 'Native Spanish speaker offering conversational Spanish lessons. Focus on practical speaking skills and cultural context.',
        category: 'Language',
        type: 'offer',
        level: 'beginner',
        duration: '1 hour per session',
        location: 'online',
        tags: ['spanish', 'conversation', 'language'],
        userId: users[3].id,
      },
      {
        title: 'French Grammar and Writing',
        description: 'Want to improve my French writing skills and grammar. Have basic conversational French but need help with formal writing.',
        category: 'Language',
        type: 'request',
        level: 'intermediate',
        duration: '1.5 hours per session',
        location: 'online',
        tags: ['french', 'grammar', 'writing'],
        userId: users[2].id,
      },

      // Music Skills
      {
        title: 'Guitar Lessons for Beginners',
        description: 'Professional guitar teacher offering lessons for complete beginners. Learn chords, strumming patterns, and your favorite songs.',
        category: 'Music',
        type: 'offer',
        level: 'beginner',
        duration: '1 hour per session',
        location: 'both',
        tags: ['guitar', 'music', 'beginner'],
        userId: users[2].id,
      },
      {
        title: 'Piano Basics',
        description: 'Looking to learn piano from scratch. Complete beginner with no musical background but eager to learn.',
        category: 'Music',
        type: 'request',
        level: 'beginner',
        duration: '1 hour per session',
        location: 'in-person',
        tags: ['piano', 'music', 'beginner'],
        userId: users[4].id,
      },

      // Art Skills
      {
        title: 'Digital Art and Illustration',
        description: 'Graphic designer teaching digital art using Photoshop and Illustrator. Learn illustration techniques and digital painting.',
        category: 'Art',
        type: 'offer',
        level: 'intermediate',
        duration: '2 hours per session',
        location: 'online',
        tags: ['digital-art', 'illustration', 'photoshop'],
        userId: users[1].id,
      },
      {
        title: 'Watercolor Painting',
        description: 'Want to learn watercolor painting techniques. Complete beginner looking for patient teacher.',
        category: 'Art',
        type: 'request',
        level: 'beginner',
        duration: '2 hours per session',
        location: 'in-person',
        tags: ['watercolor', 'painting', 'art'],
        userId: users[5].id,
      },

      // Cooking Skills
      {
        title: 'Italian Cooking Basics',
        description: 'Home cook teaching authentic Italian recipes. Learn pasta making, sauces, and traditional Italian techniques.',
        category: 'Cooking',
        type: 'offer',
        level: 'beginner',
        duration: '3 hours per session',
        location: 'in-person',
        tags: ['italian', 'cooking', 'pasta'],
        userId: users[5].id,
      },
      {
        title: 'Baking and Pastry',
        description: 'Looking to learn baking skills, especially bread making and pastry. Have basic cooking knowledge.',
        category: 'Cooking',
        type: 'request',
        level: 'beginner',
        duration: '2-3 hours per session',
        location: 'both',
        tags: ['baking', 'pastry', 'bread'],
        userId: users[6].id,
      },

      // Fitness Skills
      {
        title: 'Personal Training',
        description: 'Certified personal trainer offering workout plans and fitness coaching. Specializing in strength training and weight loss.',
        category: 'Fitness',
        type: 'offer',
        level: 'intermediate',
        duration: '1 hour per session',
        location: 'both',
        tags: ['fitness', 'training', 'strength'],
        userId: users[4].id,
      },
      {
        title: 'Yoga for Beginners',
        description: 'Want to learn yoga for stress relief and flexibility. Complete beginner with no experience.',
        category: 'Fitness',
        type: 'request',
        level: 'beginner',
        duration: '1 hour per session',
        location: 'both',
        tags: ['yoga', 'flexibility', 'stress-relief'],
        userId: users[0].id,
      },

      // Photography Skills
      {
        title: 'Photography Fundamentals',
        description: 'Professional photographer teaching camera basics, composition, and editing techniques.',
        category: 'Education',
        type: 'offer',
        level: 'beginner',
        duration: '2 hours per session',
        location: 'both',
        tags: ['photography', 'camera', 'composition'],
        userId: users[6].id,
      },
      {
        title: 'Video Editing',
        description: 'Looking to learn video editing for YouTube content. Have basic computer skills but no editing experience.',
        category: 'Technology',
        type: 'request',
        level: 'beginner',
        duration: '2 hours per session',
        location: 'online',
        tags: ['video-editing', 'youtube', 'content-creation'],
        userId: users[7].id,
      },

      // Business Skills
      {
        title: 'Business Strategy',
        description: 'Business consultant offering strategy sessions for startups and small businesses.',
        category: 'Business',
        type: 'offer',
        level: 'advanced',
        duration: '2 hours per session',
        location: 'both',
        tags: ['business', 'strategy', 'consulting'],
        userId: users[0].id,
      },
      {
        title: 'Marketing Fundamentals',
        description: 'Want to learn digital marketing basics for my small business. Need help with social media and online presence.',
        category: 'Business',
        type: 'request',
        level: 'beginner',
        duration: '1.5 hours per session',
        location: 'online',
        tags: ['marketing', 'social-media', 'digital'],
        userId: users[1].id,
      }
    ]);

    console.log('🎯 Created', skills.length, 'skills');

    // Create some matches
    const matches = await Match.bulkCreate([
      {
        offerSkillId: skills[0].id, // JavaScript Programming
        requestSkillId: skills[1].id, // React Development
        requesterId: users[1].id,
        offererId: users[0].id,
        message: 'Hi John! I\'m really interested in learning React and saw you\'re offering JavaScript lessons. Would love to connect and learn from you!',
        status: 'pending',
      },
      {
        offerSkillId: skills[4].id, // French Grammar
        requestSkillId: skills[3].id, // Spanish Conversation
        requesterId: users[2].id,
        offererId: users[3].id,
        message: 'Hello Emma! I\'m learning French and would love to practice conversation. I can help you with Spanish in return!',
        status: 'accepted',
        acceptedAt: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000), // 7 days ago
      },
      {
        offerSkillId: skills[5].id, // Guitar Lessons
        requestSkillId: skills[6].id, // Piano Basics
        requesterId: users[4].id,
        offererId: users[2].id,
        message: 'Hi Mike! I\'ve always wanted to learn piano and I\'m a complete beginner. Would love to take lessons from you!',
        status: 'completed',
        acceptedAt: new Date(Date.now() - 14 * 24 * 60 * 60 * 1000), // 14 days ago
        completedAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000), // 2 days ago
      },
      {
        offerSkillId: skills[7].id, // Digital Art
        requestSkillId: skills[8].id, // Watercolor Painting
        requesterId: users[5].id,
        offererId: users[1].id,
        message: 'Hi Sarah! I love your digital art work and would love to learn some techniques. I can teach you watercolor in exchange!',
        status: 'pending',
      },
      {
        offerSkillId: skills[10].id, // Personal Training
        requestSkillId: skills[11].id, // Yoga for Beginners
        requesterId: users[0].id,
        offererId: users[4].id,
        message: 'Hi Alex! I\'m looking to get into yoga for stress relief. I can help you with strength training in return!',
        status: 'accepted',
        acceptedAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000), // 3 days ago
      }
    ]);

    console.log('🤝 Created', matches.length, 'matches');

    console.log('✅ Data seeding completed successfully!');
    console.log('\n📊 Summary:');
    console.log('- Users:', users.length);
    console.log('- Skills:', skills.length);
    console.log('- Matches:', matches.length);
    console.log('\n🔑 Test Accounts:');
    users.forEach(user => {
      console.log(`- ${user.email} (password: password123)`);
    });

  } catch (error) {
    console.error('❌ Error seeding data:', error);
  }
};

// Run the seeding
seedData().then(() => {
  console.log('🎉 Seeding finished!');
  process.exit(0);
}).catch(error => {
  console.error('💥 Seeding failed:', error);
  process.exit(1);
});
