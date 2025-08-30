import { execSync } from 'child_process';
import * as dotenv from 'dotenv';
import { initializeDatabase } from '../config/database';

dotenv.config();

async function resolveFailedMigration() {
  try {
    // Initialize database connection using the shared configuration
    console.log('Initializing database connection...');
    await initializeDatabase();
    
    // Resolve the failed migration
    console.log('🔧 Resolving failed migration...');
    execSync('npx prisma migrate resolve --applied 20250830021337_update_rsvp_enum', { stdio: 'inherit' });
    console.log('✅ Failed migration resolved successfully!');
    
    // Now try to apply migrations again
    console.log('📋 Applying migrations...');
    execSync('npx prisma migrate deploy', { stdio: 'inherit' });
    console.log('✅ Migrations applied successfully!');
    
    console.log('🎉 Migration resolution process completed successfully!');
    
  } catch (error: any) {
    console.error('❌ Migration resolution failed:', error.message);
    console.error('Full error:', error);
    process.exit(1);
  }
}

// Run the migration resolution
resolveFailedMigration(); 