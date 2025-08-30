import { execSync } from 'child_process';
import * as dotenv from 'dotenv';
import { initializeDatabase } from '../config/database';

dotenv.config();

async function createCleanMigration() {
  try {
    console.log('🚀 Creating clean migration...');
    
    // Initialize database connection using the shared configuration
    console.log('Initializing database connection...');
    await initializeDatabase();
    
    console.log('📋 Creating clean RSVP system migration...');
    
    // Create the migration
    execSync('npx prisma migrate dev --name clean_rsvp_system', { 
      stdio: 'inherit' 
    });
    
    console.log('✅ Clean migration created successfully!');
    
    // Check the migration status
    try {
      const status = execSync('npx prisma migrate status', { 
        stdio: 'pipe', 
        encoding: 'utf8' 
      });
      console.log('Migration status:', status);
    } catch (error) {
      console.log('Could not get migration status');
    }
    
    console.log('📝 Next steps:');
    console.log('1. Commit the new migration: git add . && git commit -m "Clean RSVP system migration"');
    console.log('2. Push to main: git push origin main');
    console.log('3. Deploy to production');
    
  } catch (error: any) {
    console.error('❌ Failed to create clean migration:', error.message);
    console.error('Full error:', error);
    process.exit(1);
  }
}

// Run the migration creation
createCleanMigration(); 