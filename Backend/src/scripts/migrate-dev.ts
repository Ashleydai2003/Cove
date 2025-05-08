import { execSync } from 'child_process';
import * as dotenv from 'dotenv';
import { initializeDatabase } from '../config/database';

dotenv.config();

async function runMigrations() {
  try {
    // Get migration name from command line arguments
    const migrationName = process.argv[2];
    if (!migrationName) {
      console.error('Please provide a migration name as an argument');
      console.error('Usage: npm run prisma:migrate:dev <migration_name>');
      process.exit(1);
    }

    // Initialize database connection using the shared configuration
    console.log('Initializing database connection...');
    await initializeDatabase();
    
    // Run Prisma migrations
    console.log('Running Prisma migrations...');
    execSync(`npx prisma migrate dev --name ${migrationName}`, { stdio: 'inherit' });
    
    console.log('Migrations completed successfully!');
  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
}

// Run the migration
runMigrations(); 