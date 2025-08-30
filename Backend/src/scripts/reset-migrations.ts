import { execSync } from 'child_process';
import * as dotenv from 'dotenv';
import { initializeDatabase } from '../config/database';

dotenv.config();

async function resetMigrations() {
  try {
    console.log('🚀 Starting migration reset process...');
    
    // Initialize database connection using the shared configuration
    console.log('Initializing database connection...');
    await initializeDatabase();
    
    console.log('🔄 Resetting migration state...');
    
    // First, let's check what migrations exist
    try {
      const statusOutput = execSync('npx prisma migrate status', { 
        stdio: 'pipe', 
        encoding: 'utf8' 
      });
      console.log('Current migration status:', statusOutput);
    } catch (error) {
      console.log('Could not get migration status, proceeding with reset...');
    }
    
    // Mark all existing migrations as applied to create a clean baseline
    console.log('📋 Marking all migrations as applied...');
    
    const migrations = [
      '20250702043422_revamped_database',
      '20250702045124_initial_init',
      '20250702045602_baseline',
      '20250702052156_baseline_main',
      '20250702053809_baseline_main',
      '20250704102905_invites',
      '20250719183252_messaging',
      '20250727053141_add_grad_year',
      '20250730003345_cove_posts',
      '20250821061338_privacy_settings',
      '20250829183716_update_rsvp_system_approval_based',
      '20250829202434_add_payment_handle',
      '20250830001047_add_not_going_to_rsvp_enum'
    ];
    
    for (const migration of migrations) {
      try {
        console.log(`Marking ${migration} as applied...`);
        execSync(`npx prisma migrate resolve --applied ${migration}`, { 
          stdio: 'pipe' 
        });
        console.log(`✅ ${migration} marked as applied`);
      } catch (error) {
        console.log(`⚠️  ${migration} already applied or doesn't exist, continuing...`);
      }
    }
    
    console.log('✅ All migrations marked as applied');
    
    // Verify the final status
    try {
      const finalStatus = execSync('npx prisma migrate status', { 
        stdio: 'pipe', 
        encoding: 'utf8' 
      });
      console.log('Final migration status:', finalStatus);
    } catch (error) {
      console.log('Could not get final status, but reset should be complete');
    }
    
    console.log('🎉 Migration reset completed successfully!');
    console.log('📝 Next steps:');
    console.log('1. Create a new baseline migration: npx prisma migrate dev --name fresh_baseline');
    console.log('2. Commit and push the changes');
    console.log('3. Deploy to production');
    
  } catch (error: any) {
    console.error('❌ Migration reset failed:', error.message);
    console.error('Full error:', error);
    process.exit(1);
  }
}

// Run the reset
resetMigrations(); 