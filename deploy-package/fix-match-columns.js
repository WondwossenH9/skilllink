const sequelize = require('./config/database');

async function fixMatchColumns() {
  try {
    console.log('🔄 Fixing Match table column names to match Sequelize convention...');
    
    // Drop the existing camelCase columns
    await sequelize.query(`ALTER TABLE "Matches" DROP COLUMN "offerSkillId"`);
    await sequelize.query(`ALTER TABLE "Matches" DROP COLUMN "requestSkillId"`);
    await sequelize.query(`ALTER TABLE "Matches" DROP COLUMN "requesterId"`);
    await sequelize.query(`ALTER TABLE "Matches" DROP COLUMN "offererId"`);
    
    // Add the columns with snake_case names
    await sequelize.query(`ALTER TABLE "Matches" ADD COLUMN "offer_skill_id" UUID`);
    await sequelize.query(`ALTER TABLE "Matches" ADD COLUMN "request_skill_id" UUID`);
    await sequelize.query(`ALTER TABLE "Matches" ADD COLUMN "requester_id" UUID`);
    await sequelize.query(`ALTER TABLE "Matches" ADD COLUMN "offerer_id" UUID`);
    
    console.log('✅ Match table columns fixed successfully');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

fixMatchColumns();
