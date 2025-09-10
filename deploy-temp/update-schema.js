const sequelize = require('./config/database');
const Match = require('./src/models/Match');

async function updateSchema() {
  try {
    console.log('Updating database schema...');
    
    // Sync the database with the new schema
    await sequelize.sync({ alter: true });
    
    console.log('Database schema updated successfully!');
    console.log('New compatibilityScore field added to Match table.');
    
    process.exit(0);
  } catch (error) {
    console.error('Error updating schema:', error);
    process.exit(1);
  }
}

updateSchema();
