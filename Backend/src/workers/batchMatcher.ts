//
// batchMatcher.ts
// 
// Batch matching worker that runs every 3 hours
// Implements the tiered relaxation system for smart matching
//

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// MARK: - Types
interface Candidate {
  userId: string;
  intentionId: string;
  tier: number;
  score: number;
}

interface MatchPair {
  userAId: string;
  userBId: string;
  intentionAId: string;
  intentionBId: string;
  score: number;
  tier: number;
}

// MARK: - Main Batch Matcher
export async function runBatchMatcher() {
  console.log('🔄 Starting batch matcher...');
  const startTime = Date.now();
  
  try {
    // Process each tier in order: 0 → 1 → 2
    for (const tier of [0, 1, 2]) {
      console.log(`\n📊 Processing tier ${tier}...`);
      await processTier(tier);
    }
    
    // Promote unmatched users to next tier
    await promoteUnmatchedUsers();
    
    const duration = Date.now() - startTime;
    console.log(`\n✅ Batch matching complete in ${duration}ms`);
    
  } catch (error) {
    console.error('❌ Batch matching failed:', error);
    throw error;
  }
}

// MARK: - Process Single Tier
async function processTier(tier: number) {
  // Get all active pool entries for this tier
  const poolEntries = await prisma.poolEntry.findMany({
    where: { tier },
    include: {
      intention: {
        include: {
          user: {
            include: {
              profile: true,
              surveyResponses: true
            }
          }
        }
      }
    }
  });
  
  console.log(`  Found ${poolEntries.length} active entries in tier ${tier}`);
  
  if (poolEntries.length < 2) {
    console.log(`  Skipping - need at least 2 users to match`);
    return;
  }
  
  // Build match pairs
  const matchPairs: MatchPair[] = [];
  
  for (let i = 0; i < poolEntries.length; i++) {
    const entryA = poolEntries[i];
    const intentionA = entryA.intention;
    const userA = intentionA.user;
    
    // Skip if already has active match
    const existingMatch = await prisma.match.findFirst({
      where: {
        OR: [
          { userAId: userA.id },
          { userBId: userA.id }
        ],
        status: 'active'
      }
    });
    
    if (existingMatch) {
      continue;
    }
    
    // Find candidates for this user
    const candidates = await findCandidates(userA.id, intentionA, tier);
    
    // Score each candidate
    for (const candidate of candidates) {
      const entryB = poolEntries.find(e => e.intention.userId === candidate.userId);
      if (!entryB) continue;
      
      const userB = entryB.intention.user;
      const intentionB = entryB.intention;
      
      // Skip if already matched
      const existingMatchB = await prisma.match.findFirst({
        where: {
          OR: [
            { userAId: userB.id },
            { userBId: userB.id }
          ],
          status: 'active'
        }
      });
      
      if (existingMatchB) continue;
      
      // Calculate compatibility score
      const score = await calculateCompatibility(
        userA,
        intentionA,
        userB,
        intentionB,
        tier
      );
      
      if (score > 0.3) { // Minimum threshold
        matchPairs.push({
          userAId: userA.id < userB.id ? userA.id : userB.id,
          userBId: userA.id < userB.id ? userB.id : userA.id,
          intentionAId: userA.id < userB.id ? intentionA.id : intentionB.id,
          intentionBId: userA.id < userB.id ? intentionB.id : intentionA.id,
          score,
          tier
        });
      }
    }
  }
  
  // Sort by score (highest first)
  matchPairs.sort((a, b) => b.score - a.score);
  
  console.log(`  Found ${matchPairs.length} potential match pairs`);
  
  // Greedy matching: take best pairs without overlap
  const matched = new Set<string>();
  const finalMatches: MatchPair[] = [];
  
  for (const pair of matchPairs) {
    if (!matched.has(pair.userAId) && !matched.has(pair.userBId)) {
      finalMatches.push(pair);
      matched.add(pair.userAId);
      matched.add(pair.userBId);
    }
  }
  
  console.log(`  Creating ${finalMatches.length} matches`);
  
  // Create matches in database
  for (const match of finalMatches) {
    await createMatch(match);
  }
  
  // Update pool entries' lastBatchAt timestamp
  await prisma.poolEntry.updateMany({
    where: { tier },
    data: { lastBatchAt: new Date() }
  });
}

// MARK: - Find Candidates
async function findCandidates(
  userId: string,
  intention: any,
  tier: number
): Promise<Candidate[]> {
  // Parse intention chips
  const chips = typeof intention.parsedJson === 'string' 
    ? JSON.parse(intention.parsedJson) 
    : intention.parsedJson;
  
  // Get user's profile and survey responses
  const user = await prisma.user.findUnique({
    where: { id: userId },
    include: { profile: true }
  });
  
  if (!user || !user.profile) {
    console.log(`User ${userId} not found or no profile`);
    return [];
  }
  
  const surveyResponses = await prisma.surveyResponse.findMany({
    where: { userId }
  });
  
  // Build must-have constraints from survey responses
  const mustHaves: any = {};
  for (const response of surveyResponses) {
    if (response.isMustHave) {
      mustHaves[response.questionId] = response.value;
    }
  }
  
  // Add profile-based must-haves
  if (user.profile.city) {
    mustHaves.city = user.profile.city;
  }
  if (user.profile.almaMater) {
    mustHaves.alumni_network = user.profile.almaMater;
  }
  if (user.profile.age) {
    // Convert age to age band
    if (user.profile.age >= 21 && user.profile.age <= 24) {
      mustHaves.age_band = '21-24';
    } else if (user.profile.age >= 25 && user.profile.age <= 28) {
      mustHaves.age_band = '25-28';
    } else if (user.profile.age >= 29 && user.profile.age <= 32) {
      mustHaves.age_band = '29-32';
    } else if (user.profile.age >= 33) {
      mustHaves.age_band = '33+';
    }
  }
  
  // Build where clause based on tier
  const where: any = {
    NOT: { id: userId },
    intentions: {
      some: {
        status: 'active',
        validUntil: { gt: new Date() }
      }
    }
  };
  
  // Apply must-have filters (relaxed based on tier)
  if (tier === 0) {
    // Tier 0: Strict filters
    const profileWhere: any = {};
    
    if (mustHaves.city) {
      profileWhere.city = mustHaves.city;
    }
    if (mustHaves.alumni_network) {
      profileWhere.almaMater = mustHaves.alumni_network;
    }
    if (mustHaves.age_band) {
      const ageRange = parseAgeBand(mustHaves.age_band);
      profileWhere.age = {
        gte: ageRange.min,
        lte: ageRange.max
      };
    }
    
    if (Object.keys(profileWhere).length > 0) {
      where.profile = profileWhere;
    }
  } else if (tier === 1) {
    // Tier 1: Relax some constraints (e.g., adjacent age bands)
    if (mustHaves.city) {
      where.profile = { city: mustHaves.city }; // Still enforce city
    }
  }
  // Tier 2: Very relaxed (minimal constraints)
  
  // Find candidates
  const candidateUsers = await prisma.user.findMany({
    where,
    include: {
      profile: true,
      intentions: {
        where: {
          status: 'active',
          validUntil: { gt: new Date() }
        }
      },
      surveyResponses: true
    },
    take: 200 // Limit to top 200 candidates
  });
  
  return candidateUsers.map(user => ({
    userId: user.id,
    intentionId: user.intentions[0]?.id || '',
    tier,
    score: 0 // Will be calculated later
  }));
}

// MARK: - Calculate Compatibility Score
async function calculateCompatibility(
  userA: any,
  intentionA: any,
  userB: any,
  intentionB: any,
  tier: number
): Promise<number> {
  // Parse chips
  const chipsA = typeof intentionA.parsedJson === 'string' 
    ? JSON.parse(intentionA.parsedJson) 
    : intentionA.parsedJson;
  const chipsB = typeof intentionB.parsedJson === 'string' 
    ? JSON.parse(intentionB.parsedJson) 
    : intentionB.parsedJson;
  
  // Get survey responses
  const surveyA = userA.surveyResponses || [];
  const surveyB = userB.surveyResponses || [];
  
  // Calculate survey similarity (based on common answers)
  const surveySim = calculateSurveySimilarity(surveyA, surveyB);
  
  // Calculate intention overlap
  const intentionSim = calculateIntentionSimilarity(chipsA, chipsB);
  
  // Time window overlap
  const timeOverlap = calculateTimeOverlap(chipsA.when || [], chipsB.when || []);
  
  // Location match
  const locationMatch = chipsA.where === chipsB.where ? 1.0 : 0.0;
  
  // Activity overlap
  const activityOverlap = calculateArrayOverlap(
    chipsA.what?.activities || [],
    chipsB.what?.activities || []
  );
  
  // Vibe overlap
  const vibeOverlap = calculateArrayOverlap(
    chipsA.vibe || [],
    chipsB.vibe || []
  );
  
  // Weighted score
  let score = 
    0.25 * surveySim +
    0.25 * intentionSim +
    0.20 * timeOverlap +
    0.15 * locationMatch +
    0.10 * activityOverlap +
    0.05 * vibeOverlap;
  
  // Tier adjustment (lower tiers are more strict)
  if (tier === 0 && timeOverlap < 0.5) {
    score *= 0.5; // Heavily penalize poor time overlap in tier 0
  }
  
  return score;
}

// MARK: - Helper: Survey Similarity
function calculateSurveySimilarity(surveyA: any[], surveyB: any[]): number {
  const questionsA = new Map(surveyA.map(r => [r.questionId, r.value]));
  const questionsB = new Map(surveyB.map(r => [r.questionId, r.value]));
  
  let matches = 0;
  let total = 0;
  
  for (const [qId, valueA] of Array.from(questionsA)) {
    const valueB = questionsB.get(qId);
    if (!valueB) continue;
    
    total++;
    
    // Handle both string and array values
    if (typeof valueA === 'string' && typeof valueB === 'string') {
      if (valueA === valueB) matches++;
    } else if (Array.isArray(valueA) && Array.isArray(valueB)) {
      const overlap = calculateArrayOverlap(valueA, valueB);
      matches += overlap;
    }
  }
  
  return total > 0 ? matches / total : 0;
}

// MARK: - Helper: Intention Similarity
function calculateIntentionSimilarity(chipsA: any, chipsB: any): number {
  let score = 0;
  let count = 0;
  
  // Activities
  if (chipsA.what?.activities && chipsB.what?.activities) {
    score += calculateArrayOverlap(chipsA.what.activities, chipsB.what.activities);
    count++;
  }
  
  // Vibe
  if (chipsA.vibe && chipsB.vibe) {
    score += calculateArrayOverlap(chipsA.vibe, chipsB.vibe);
    count++;
  }
  
  // Time windows
  if (chipsA.when && chipsB.when) {
    score += calculateTimeOverlap(chipsA.when, chipsB.when);
    count++;
  }
  
  return count > 0 ? score / count : 0;
}

// MARK: - Helper: Array Overlap
function calculateArrayOverlap(arr1: string[], arr2: string[]): number {
  if (!arr1 || !arr2 || arr1.length === 0 || arr2.length === 0) {
    return 0;
  }
  
  const set1 = new Set(arr1);
  const set2 = new Set(arr2);
  const intersection = Array.from(set1).filter(x => set2.has(x));
  const union = new Set(arr1.concat(arr2));
  
  return intersection.length / union.size; // Jaccard similarity
}

// MARK: - Helper: Time Overlap
function calculateTimeOverlap(times1: string[], times2: string[]): number {
  return calculateArrayOverlap(times1, times2);
}

// MARK: - Helper: Parse Age Band
function parseAgeBand(ageBand: string | any): { min: number, max: number } {
  // Handle both string and JSON object
  if (typeof ageBand === 'object' && !Array.isArray(ageBand)) {
    ageBand = ageBand.value || ageBand;
  }
  
  if (typeof ageBand !== 'string') {
    return { min: 21, max: 99 };
  }
  
  if (ageBand.includes('21-24')) return { min: 21, max: 24 };
  if (ageBand.includes('25-28')) return { min: 25, max: 28 };
  if (ageBand.includes('29-32')) return { min: 29, max: 32 };
  if (ageBand.includes('33+')) return { min: 33, max: 99 };
  
  return { min: 21, max: 99 };
}

// MARK: - Create Match
async function createMatch(matchPair: MatchPair) {
  try {
    // Determine matched criteria and relaxed constraints
    const match = await prisma.match.create({
      data: {
        userAId: matchPair.userAId,
        userBId: matchPair.userBId,
        intentionAId: matchPair.intentionAId,
        intentionBId: matchPair.intentionBId,
        score: matchPair.score,
        tierUsed: matchPair.tier,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
        status: 'active'
      }
    });
    
    // Update intentions to "matched" status
    await prisma.intention.updateMany({
      where: {
        id: { in: [matchPair.intentionAId, matchPair.intentionBId] }
      },
      data: { status: 'matched' }
    });
    
    // Remove from pool
    await prisma.poolEntry.deleteMany({
      where: {
        intentionId: { in: [matchPair.intentionAId, matchPair.intentionBId] }
      }
    });
    
    console.log(`  ✅ Created match: ${matchPair.userAId.substring(0, 8)} ↔ ${matchPair.userBId.substring(0, 8)} (score: ${matchPair.score.toFixed(2)})`);
    
    // TODO: Send push notifications to both users
    
  } catch (error) {
    console.error(`  ❌ Failed to create match:`, error);
  }
}

// MARK: - Promote Unmatched Users
async function promoteUnmatchedUsers() {
  console.log('\n📈 Promoting unmatched users to next tier...');
  
  const now = new Date();
  const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000);
  const twoDaysAgo = new Date(now.getTime() - 48 * 60 * 60 * 1000);
  
  // Promote tier 0 → 1 (after 24 hours)
  const tier0Promoted = await prisma.poolEntry.updateMany({
    where: {
      tier: 0,
      joinedAt: { lt: oneDayAgo }
    },
    data: { tier: 1 }
  });
  
  console.log(`  Promoted ${tier0Promoted.count} users from tier 0 → 1`);
  
  // Promote tier 1 → 2 (after 48 hours total)
  const tier1Promoted = await prisma.poolEntry.updateMany({
    where: {
      tier: 1,
      joinedAt: { lt: twoDaysAgo }
    },
    data: { tier: 2 }
  });
  
  console.log(`  Promoted ${tier1Promoted.count} users from tier 1 → 2`);
  
  // Expire intentions that are past their valid until time
  const expiredIntentions = await prisma.intention.updateMany({
    where: {
      status: 'active',
      validUntil: { lt: now }
    },
    data: { status: 'expired' }
  });
  
  console.log(`  Expired ${expiredIntentions.count} intentions`);
  
  // Clean up pool entries for expired intentions
  await prisma.poolEntry.deleteMany({
    where: {
      intention: {
        status: 'expired'
      }
    }
  });
}

// MARK: - Standalone CLI Execution
if (require.main === module) {
  runBatchMatcher()
    .then(() => {
      console.log('\n✅ Batch matcher completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ Batch matcher failed:', error);
      process.exit(1);
    });
}

