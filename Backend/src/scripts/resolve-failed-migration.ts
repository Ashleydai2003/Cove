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
    const failedMigration = '20250830002305_remove_notgoing';
    
    console.log(`Resolving ${failedMigration}...`);
    execSync(`npx prisma migrate resolve --schema prisma/schema.prisma --rolled-back ${failedMigration}`, { 
      stdio: 'inherit' 
    });
    
    console.log(`✅ ${failedMigration} resolved successfully!`);
    
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
    
    console.log('📝 Next steps:');
    console.log('1. Create a new clean migration: npx prisma migrate dev --name clean_baseline');
    console.log('2. Commit and push the changes');
    
  } catch (error: any) {
    console.error('❌ Failed to resolve migration:', error.message);
    console.error('Full error:', error);
    process.exit(1);
  }
}

// Run the resolve
resolveFailedMigration(); 