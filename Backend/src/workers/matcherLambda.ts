//
// matcherLambda.ts
//
// Lambda handler for EventBridge scheduled batch matching
// Runs every 3 hours to find matches for users in the pool
//

import { PrismaClient } from '@prisma/client';
import { initializeDatabase } from '../config/database';
import { runBatchMatcher } from './batchMatcher';

// Advisory lock ID for preventing concurrent runs
const MATCHER_LOCK_ID = 911911;

export const handler = async (event: any) => {
  console.log('🚀 Batch matcher Lambda triggered');
  console.log('Event:', JSON.stringify(event, null, 2));
  
  const startTime = Date.now();
  let prisma: PrismaClient | null = null;
  
  try {
    // Initialize database connection with Secrets Manager
    prisma = await initializeDatabase();
    
    console.log('🔒 Attempting to acquire advisory lock...');
    const lockResult = await prisma.$queryRaw<Array<{ pg_try_advisory_lock: boolean }>>`
      SELECT pg_try_advisory_lock(${MATCHER_LOCK_ID})
    `;
    
    const acquired = lockResult[0]?.pg_try_advisory_lock;
    
    if (!acquired) {
      console.log('⏭️  Another matcher instance is running, skipping this execution');
      await prisma.$disconnect();
      return {
        statusCode: 200,
        body: JSON.stringify({
          message: 'Skipped - another instance is running',
          timestamp: new Date().toISOString()
        })
      };
    }
    
    console.log('✅ Advisory lock acquired, starting batch matcher...');
    
    try {
      // Run the batch matcher
      await runBatchMatcher();
      
      const duration = Date.now() - startTime;
      console.log(`✅ Batch matcher completed successfully in ${duration}ms`);
      
      return {
        statusCode: 200,
        body: JSON.stringify({
          message: 'Batch matching completed successfully',
          duration,
          timestamp: new Date().toISOString()
        })
      };
      
    } finally {
      // Always release the lock
      console.log('🔓 Releasing advisory lock...');
      await prisma.$queryRaw`SELECT pg_advisory_unlock(${MATCHER_LOCK_ID})`;
    }
    
  } catch (error) {
    const duration = Date.now() - startTime;
    console.error('❌ Batch matcher failed:', error);
    
    // Return error but don't throw (Lambda will retry otherwise)
    return {
      statusCode: 500,
      body: JSON.stringify({
        message: 'Batch matching failed',
        error: error instanceof Error ? error.message : 'Unknown error',
        duration,
        timestamp: new Date().toISOString()
      })
    };
  } finally {
    // Always disconnect Prisma
    if (prisma) {
      await prisma.$disconnect();
      console.log('👋 Prisma disconnected');
    }
  }
};

