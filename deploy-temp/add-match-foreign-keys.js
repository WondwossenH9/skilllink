const sequelize = require('./config/database');

async function addMatchForeignKeys() {
  try {
    console.log('🔄 Adding foreign key columns to Matches table...');
    
    // Add the foreign key columns
    await sequelize.query(`
      ALTER TABLE "Matches" 
      ADD COLUMN "requesterId" UUID
    `);
    
    await sequelize.query(`
      ALTER TABLE "Matches" 
      ADD COLUMN "offererId" UUID
    `);
    
    await sequelize.query(`
      ALTER TABLE "Matches" 
      ADD COLUMN "offerSkillId" UUID
    `);
    
    await sequelize.query(`
      ALTER TABLE "Matches" 
      ADD COLUMN "requestSkillId" UUID
    `);
    
    console.log('✅ Foreign key columns added successfully');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

addMatchForeignKeys();
