import { execSync } from 'child_process';
import * as dotenv from 'dotenv';
import { initializeDatabase } from '../config/database';

dotenv.config();

async function runMigrations() {
  try {
    // Initialize database connection using the shared configuration
    console.log('Initializing database connection...');
    await initializeDatabase();
    
    // Check if database has the _prisma_migrations table
    console.log('Checking migration status...');
    let needsBaseline = false;
    
    try {
      execSync('npx prisma migrate status', { stdio: 'pipe' });
      console.log('Database has migration history, proceeding with deploy...');
    } catch (statusError) {
      console.log('Database needs baseline setup...');
      needsBaseline = true;
    }
    
    if (needsBaseline) {
      // Baseline the database to the first migration
      console.log('🔄 Baselining database to initial migration state...');
      
      // Use the first migration as baseline (revamped_database)
      execSync('npx prisma migrate resolve --applied 20250702043422_revamped_database', { stdio: 'inherit' });
      console.log('✅ Database baselined successfully');
    }
    
    // Run remaining Prisma migrations
    console.log('Running Prisma migrations...');
    execSync('npx prisma migrate deploy', { stdio: 'inherit' });
    
    console.log('Migrations completed successfully!');
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
}

// Run the migration
runMigrations(); 