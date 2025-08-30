import { execSync } from 'child_process';
import * as dotenv from 'dotenv';
import { initializeDatabase } from '../config/database';
import * as fs from 'fs';
import * as path from 'path';

dotenv.config();

async function markLatestMigrationAsApplied() {
  try {
    console.log('🔧 Marking latest migration as applied...');
    
    // Initialize database connection using the shared configuration
    console.log('Initializing database connection...');
    await initializeDatabase();
    
    // Get the migrations directory
    const migrationsDir = path.join(process.cwd(), 'prisma', 'migrations');
    
    // Read all migration directories
    const migrationDirs = fs.readdirSync(migrationsDir)
      .filter(item => {
        const itemPath = path.join(migrationsDir, item);
        return fs.statSync(itemPath).isDirectory() && item.match(/^\d{14}_/);
      })
      .sort();
    
    if (migrationDirs.length === 0) {
      console.log('❌ No migrations found');
      return;
    }
    
    // Get the latest migration
    const latestMigration = migrationDirs[migrationDirs.length - 1];
    console.log(`Latest migration: ${latestMigration}`);
    
    // Mark it as applied
    console.log(`Marking ${latestMigration} as applied...`);
    execSync(`npx prisma migrate resolve --schema prisma/schema.prisma --applied ${latestMigration}`, { 
      stdio: 'inherit' 
    });
    
    console.log(`✅ ${latestMigration} marked as applied successfully!`);
    
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
    
  } catch (error: any) {
    console.error('❌ Failed to mark latest migration as applied:', error.message);
    console.error('Full error:', error);
    process.exit(1);
  }
}

// Run the script
markLatestMigrationAsApplied(); 