import { execSync } from 'child_process';
import * as dotenv from 'dotenv';
import { initializeDatabase } from '../config/database';

dotenv.config();

async function regeneratePrismaClient() {
  try {
    console.log('🔄 Regenerating Prisma Client...');
    
    // Initialize database connection using the shared configuration
    console.log('Initializing database connection...');
    await initializeDatabase();
    
    // Force regenerate the Prisma Client
    try {
      console.log('Generating Prisma Client...');
      execSync('npx prisma generate', { stdio: 'inherit' });
      console.log('✅ Prisma Client regenerated successfully!');
    } catch (error: any) {
      console.log(`⚠️  Could not regenerate Prisma Client:`, error.message || error);
    }
    
    // Check the current schema status
    try {
      console.log('Checking schema status...');
      const status = execSync('npx prisma db pull', { 
        stdio: 'pipe', 
        encoding: 'utf8' 
      });
      console.log('Schema pulled successfully');
    } catch (error) {
      console.log('Could not pull schema');
    }
    
    console.log('🎉 Prisma Client regeneration completed!');
    
  } catch (error: any) {
    console.error('❌ Failed to regenerate Prisma Client:', error.message);
    console.error('Full error:', error);
    process.exit(1);
  }
}

// Run the regeneration
regeneratePrismaClient(); 