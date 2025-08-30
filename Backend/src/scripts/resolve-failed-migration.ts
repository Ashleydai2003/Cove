import { execSync } from 'child_process';
import * as dotenv from 'dotenv';
import { initializeDatabase } from '../config/database';

dotenv.config();

async function resolveFailedMigration() {
  try {
    console.log('🔧 Resolving failed migration...');
    
    // Initialize database connection using the shared configuration
    console.log('Initializing database connection...');
    await initializeDatabase();
    
    // Resolve the specific failed migration
    const failedMigration = '20250830021337_update_rsvp_enum';
    
    try {
      console.log(`Resolving ${failedMigration}...`);
      execSync(`npx prisma migrate resolve --applied ${failedMigration}`, { 
        stdio: 'inherit' 
      });
      console.log(`✅ ${failedMigration} resolved successfully!`);
    } catch (error: any) {
      console.log(`⚠️  Could not resolve ${failedMigration}:`, error.message || error);
    }
    
    // Now try to apply migrations
    try {
      console.log('📋 Applying migrations...');
      execSync('npx prisma migrate deploy', { stdio: 'inherit' });
      console.log('✅ Migrations applied successfully!');
    } catch (error: any) {
      console.log(`⚠️  Could not apply migrations:`, error.message || error);
    }
    
    // Check final status
    try {
      const status = execSync('npx prisma migrate status', { 
        stdio: 'pipe', 
        encoding: 'utf8' 
      });
      console.log('Final migration status:', status);
    } catch (error) {
      console.log('Could not get final status');
    }
    
    console.log('🎉 Migration resolution process completed!');
    
  } catch (error: any) {
    console.error('❌ Failed to resolve migration:', error.message);
    console.error('Full error:', error);
    process.exit(1);
  }
}

// Run the resolve
resolveFailedMigration(); 