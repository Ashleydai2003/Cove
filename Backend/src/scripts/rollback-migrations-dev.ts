import { execSync } from 'child_process';
import * as dotenv from 'dotenv';

dotenv.config();

async function rollbackMigrationsDev() {
  try {
    console.log('🔄 Starting development migration rollback...');
    
    // List of migrations to rollback (in reverse order)
    const migrationsToRollback = [
      '20250830002305_remove_notgoing',
      '20250830001047_add_not_going_to_rsvp_enum',
      '20250829202434_add_payment_handle',
      '20250829183716_update_rsvp_system_approval_based'
    ];
    
    console.log('📋 Rolling back problematic migrations...');
    
    for (const migration of migrationsToRollback) {
      try {
        console.log(`Rolling back ${migration}...`);
        
        // Check if this migration is applied
        const statusOutput = execSync('npx prisma migrate status', { 
          stdio: 'pipe', 
          encoding: 'utf8' 
        });
        
        if (statusOutput.includes(migration)) {
          // Mark as not applied (rollback)
          execSync(`npx prisma migrate resolve --rolled-back ${migration}`, { 
            stdio: 'inherit' 
          });
          console.log(`✅ ${migration} rolled back successfully`);
        } else {
          console.log(`⚠️  ${migration} not found in migration history`);
        }
        
      } catch (error: any) {
        console.log(`⚠️  Could not rollback ${migration}:`, error.message || error);
      }
    }
    
    console.log('✅ Development migration rollback completed!');
    
    // Check final status
    try {
      const finalStatus = execSync('npx prisma migrate status', { 
        stdio: 'pipe', 
        encoding: 'utf8' 
      });
      console.log('Final migration status:', finalStatus);
    } catch (error) {
      console.log('Could not get final status');
    }
    
    console.log('📝 Next steps:');
    console.log('1. Create a new clean migration: npx prisma migrate dev --name clean_rsvp_system');
    console.log('2. Commit and push the changes');
    
  } catch (error: any) {
    console.error('❌ Development migration rollback failed:', error.message);
    console.error('Full error:', error);
    process.exit(1);
  }
}

// Run the rollback
rollbackMigrationsDev(); 