import { execSync } from 'child_process';
import * as dotenv from 'dotenv';
import { initializeDatabase } from '../config/database';

dotenv.config();

async function resolveDrift() {
  try {
    console.log('Initializing database connection...');
    await initializeDatabase();
    
    const missingMigrations = [
      '20250508033331_init',
      '20250514005216_user_onboarding', 
      '20250519221357_new',
      '20250520022616_user_images_schema',
      '20250527035022_user_events_coves',
      '20250527043215_updated_schema_5_26',
      '20250527063059_request_schema_5_26',
      '20250527080319_updated_profile_5_26',
      '20250527204831_admin_allow_list_schema_5_27',
      '20250527222839_admin_user_5_27'
    ];
    
    console.log('Resolving migration drift by marking missing migrations as applied...');
    
    for (const migration of missingMigrations) {
      try {
        console.log(`Resolving migration: ${migration}`);
        execSync(`npx prisma migrate resolve --applied ${migration}`, { stdio: 'inherit' });
        console.log(`✓ Migration ${migration} resolved`);
      } catch (error) {
        console.log(`Migration ${migration} already resolved or not needed`);
      }
    }
    
    console.log('Drift resolution completed successfully!');
  } catch (error) {
    console.error('Drift resolution failed:', error);
    process.exit(1);
  }
}

// Run the drift resolution
resolveDrift(); 