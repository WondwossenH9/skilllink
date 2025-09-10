const sequelize = require('./config/database');

async function addCompatibilityScore() {
  try {
    console.log('🔄 Adding compatibilityScore column to Matches table...');
    
    // Add the compatibilityScore column
    await sequelize.query(`
      ALTER TABLE "Matches" 
      ADD COLUMN "compatibilityScore" DECIMAL(3,2)
    `);
    
    console.log('✅ compatibilityScore column added successfully');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

addCompatibilityScore();
