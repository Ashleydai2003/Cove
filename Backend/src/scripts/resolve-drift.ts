import { execSync } from 'child_process';
import * as dotenv from 'dotenv';
import { initializeDatabase } from '../config/database';

dotenv.config();

async function resolveDrift() {
  try {
    console.log('Initializing database connection...');
    await initializeDatabase();
    
    console.log('One-time reset to fix migration drift permanently');
    console.log('Using force-reset to sync database with current schema and clear migration history');
    
    // Use force-reset to clear drift and sync database with schema
    console.log('Running prisma db push --force-reset...');
    execSync('npx prisma db push --force-reset', { stdio: 'inherit' });
    
    console.log('Database reset and synced with current schema');
    console.log('Migration drift has been resolved - database is now clean');
    
  } catch (error) {
    console.error('Database reset failed:', error);
    process.exit(1);
  }
}

// Run the drift resolution
resolveDrift(); 