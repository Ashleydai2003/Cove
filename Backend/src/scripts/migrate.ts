import { execSync } from 'child_process';
import * as dotenv from 'dotenv';
import { initializeDatabase } from '../config/database';

dotenv.config();

async function runMigrations() {
  try {
    // Initialize database connection using the shared configuration
    console.log('Initializing database connection...');
    await initializeDatabase();
    
    // Check migration status and handle accordingly
    console.log('Checking migration status...');
    
    try {
      // Try to get migration status
      const statusOutput = execSync('npx prisma migrate status', { 
        stdio: 'pipe', 
        encoding: 'utf8' 
      });
      
      console.log('Migration status output:', statusOutput);
      
      // Check if there are pending migrations
      if (statusOutput.includes('Following migration have not yet been applied')) {
        console.log('📋 Found pending migrations, applying them...');
        execSync('npx prisma migrate deploy', { stdio: 'inherit' });
        console.log('✅ Migrations applied successfully!');
      } else if (statusOutput.includes('Database schema is up to date')) {
        console.log('✅ Database is already up to date, no migrations needed');
      } else {
        console.log('🔄 Running migrate deploy to ensure consistency...');
        execSync('npx prisma migrate deploy', { stdio: 'inherit' });
        console.log('✅ Migration deploy completed!');
      }
      
    } catch (statusError: any) {
      const errorOutput = statusError.stdout?.toString() || statusError.stderr?.toString() || statusError.message;
      console.log('Migration status check failed:', errorOutput);
      
      // Check if it's a "database is not empty" error (P3005)
      if (errorOutput.includes('P3005') || errorOutput.includes('database schema is not empty')) {
        console.log('🔄 Database exists but has no migration history, attempting baseline...');
        
        try {
          // Try to baseline to the first migration
          console.log('Attempting to baseline to first migration...');
          execSync('npx prisma migrate resolve --applied 20250702043422_revamped_database', { 
            stdio: 'inherit' 
          });
          console.log('✅ Database baselined successfully');
          
          // Now try to apply any remaining migrations
          execSync('npx prisma migrate deploy', { stdio: 'inherit' });
          console.log('✅ Remaining migrations applied!');
          
        } catch (baselineError: any) {
          console.log('Baseline failed, trying direct migrate deploy...');
          console.log('Baseline error:', baselineError.message);
          
          // If baseline fails, try direct migrate deploy
          try {
            execSync('npx prisma migrate deploy', { stdio: 'inherit' });
            console.log('✅ Direct migration deploy succeeded!');
          } catch (deployError) {
            console.error('❌ All migration attempts failed');
            throw deployError;
          }
        }
        
      } else {
        // For other errors, try direct migrate deploy
        console.log('🔄 Status check failed, attempting direct migration deploy...');
        execSync('npx prisma migrate deploy', { stdio: 'inherit' });
        console.log('✅ Migration deploy completed!');
      }
    }
    
    console.log('🎉 Migration process completed successfully!');
    
  } catch (error: any) {
    console.error('❌ Migration failed:', error.message);
    console.error('Full error:', error);
    process.exit(1);
  }
}

// Run the migration
runMigrations(); 