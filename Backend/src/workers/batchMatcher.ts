import { PrismaClient } from '@prisma/client';
import { initializeDatabase } from '../config/database';

console.log('🚀 Script starting...');

// Initialize Prisma client
let prisma: PrismaClient;

// MARK: - Types
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
    // Initialize database connection
    console.log('🔌 Initializing database connection...');
    prisma = await initializeDatabase();
    console.log('✅ Database connected successfully');
    
    // Simple weighted matching (like dating apps)
    console.log(`\n📊 Processing simple weighted matching...`);
    await processSimpleMatching();
    
    // Promote unmatched users to next tier
    console.log(`\n📈 Promoting unmatched users...`);
    await promoteUnmatchedUsers();
    
    const duration = Date.now() - startTime;
    console.log(`\n✅ Batch matching complete in ${duration}ms`);
    
  } catch (error) {
    console.error('❌ Batch matching failed:', error);
    throw error;
  }
}

// MARK: - Separate Pool Matching (Romantic vs Friendship)
async function processSimpleMatching() {
  // Get all available users
  const availableUsers = await getAvailableUsers();
  
  console.log(`  Found ${availableUsers.length} available users`);
  
  if (availableUsers.length < 2) {
    console.log(`  Skipping - need at least 2 users to match`);
    return;
  }
  
  // Separate users by intention type
  const romanticUsers = availableUsers.filter(user => {
    const chips = typeof user.intention.parsedJson === 'string' 
      ? JSON.parse(user.intention.parsedJson) 
      : user.intention.parsedJson;
    // Check if this is a romantic intention (has romantic keywords or specific structure)
    return chips.what?.connection === 'romantic' || 
           chips.what?.notes?.toLowerCase().includes('romantic') ||
           chips.what?.notes?.toLowerCase().includes('date') ||
           chips.what?.notes?.toLowerCase().includes('relationship');
  });
  
  const friendshipUsers = availableUsers.filter(user => {
    const chips = typeof user.intention.parsedJson === 'string' 
      ? JSON.parse(user.intention.parsedJson) 
      : user.intention.parsedJson;
    // Default to friendship if not explicitly romantic
    return !romanticUsers.includes(user);
  });
  
  console.log(`📊 [POOL SEPARATION] Romantic: ${romanticUsers.length}, Friendship: ${friendshipUsers.length}`);
  
  // Process romantic matches (1-on-1)
  if (romanticUsers.length >= 2) {
    console.log(`💕 Processing romantic matches...`);
    await processRomanticMatching(romanticUsers);
  }
  
  // Process friendship matches (groups of 2-6)
  if (friendshipUsers.length >= 2) {
    console.log(`👥 Processing friendship matches...`);
    await processFriendshipMatching(friendshipUsers);
  }
}

// MARK: - Romantic Matching (1-on-1)
async function processRomanticMatching(romanticUsers: any[]) {
  // Log waiting time distribution for romantic users
  const now = new Date();
  const waitingTimes = romanticUsers.map(user => {
    const daysWaiting = Math.floor((now.getTime() - user.joinedAt.getTime()) / (24 * 60 * 60 * 1000));
    return daysWaiting;
  });
  
  const day1Users = waitingTimes.filter(d => d <= 1).length;
  const day3Users = waitingTimes.filter(d => d <= 3).length;
  const day7Users = waitingTimes.filter(d => d <= 7).length;
  const maxWaiting = Math.max(...waitingTimes);
  
  console.log(`📈 [ROMANTIC WAITING] Day 1: ${day1Users}, Day 3: ${day3Users}, Day 7: ${day7Users}, Max: ${maxWaiting}d`);
  
  // Build compatibility matrix for romantic matching
  const compatibilityMatrix = await buildRomanticCompatibilityMatrix(romanticUsers);
  
  // Use greedy algorithm for optimal 1-on-1 matching
  const matches = findOptimalMatches(compatibilityMatrix, romanticUsers);
  
  console.log(`  Creating ${matches.length} romantic matches`);
  
  // Log algorithm performance metrics
  const totalPossiblePairs = (romanticUsers.length * (romanticUsers.length - 1)) / 2;
  const matchRate = matches.length / totalPossiblePairs;
  console.log(`📊 [ROMANTIC METRICS] Total users: ${romanticUsers.length}, Possible pairs: ${totalPossiblePairs}, Matches: ${matches.length}, Match rate: ${(matchRate * 100).toFixed(1)}%`);
  
  // Create matches in database
  for (const match of matches) {
    await createMatch(match);
    console.log(`  ✅ Created romantic match: ${match.userAId} ↔ ${match.userBId} (score: ${match.score.toFixed(2)})`);
  }
}

// MARK: - Friendship Matching (Groups of 2-6)
async function processFriendshipMatching(friendshipUsers: any[]) {
  // Log waiting time distribution for friendship users
  const now = new Date();
  const waitingTimes = friendshipUsers.map(user => {
    const daysWaiting = Math.floor((now.getTime() - user.joinedAt.getTime()) / (24 * 60 * 60 * 1000));
    return daysWaiting;
  });
  
  const day1Users = waitingTimes.filter(d => d <= 1).length;
  const day3Users = waitingTimes.filter(d => d <= 3).length;
  const day7Users = waitingTimes.filter(d => d <= 7).length;
  const maxWaiting = Math.max(...waitingTimes);
  
  console.log(`📈 [FRIENDSHIP WAITING] Day 1: ${day1Users}, Day 3: ${day3Users}, Day 7: ${day7Users}, Max: ${maxWaiting}d`);
  
  // Group users by preferred group size
  const groupSizePreferences = await getGroupSizePreferences(friendshipUsers);
  
  // Create friendship groups based on preferences
  const groups = await createFriendshipGroups(friendshipUsers, groupSizePreferences);
  
  console.log(`  Creating ${groups.length} friendship groups`);
  
  // Log algorithm performance metrics
  const totalUsers = friendshipUsers.length;
  const matchedUsers = groups.reduce((sum, group) => sum + group.users.length, 0);
  const matchRate = matchedUsers / totalUsers;
  console.log(`📊 [FRIENDSHIP METRICS] Total users: ${totalUsers}, Matched users: ${matchedUsers}, Match rate: ${(matchRate * 100).toFixed(1)}%`);
  
  // Create group matches in database
  for (const group of groups) {
    await createFriendshipGroup(group);
    console.log(`  ✅ Created friendship group: ${group.users.map((u: any) => u.id).join(', ')} (size: ${group.users.length})`);
  }
}

// MARK: - Get Available Users
async function getAvailableUsers() {
  console.log('🔍 Querying database for pool entries...');
  
  const users = await prisma.poolEntry.findMany({
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
  
  console.log(`📊 Found ${users.length} pool entries in database`);
  
  if (users.length > 0) {
    console.log('👥 Pool entries:');
    users.forEach((entry, index) => {
      const user = entry.intention.user;
      let intention = 'unknown';
      try {
        console.log(`   ${index + 1}. Raw parsedJson:`, entry.intention.parsedJson);
        const chips = typeof entry.intention.parsedJson === 'string' 
          ? JSON.parse(entry.intention.parsedJson) 
          : entry.intention.parsedJson;
        console.log(`   ${index + 1}. Parsed chips:`, chips);
        // Determine intention type based on data structure
        if (chips.what?.connection === 'romantic' || 
            chips.what?.notes?.toLowerCase().includes('romantic') ||
            chips.what?.notes?.toLowerCase().includes('date') ||
            chips.what?.notes?.toLowerCase().includes('relationship')) {
          intention = 'romantic';
        } else {
          intention = 'friends';
        }
      } catch (error) {
        console.log(`   ${index + 1}. User: ${user.id}, Intention: ERROR parsing JSON - ${error instanceof Error ? error.message : String(error)}, Tier: ${entry.tier}, Joined: ${entry.joinedAt.toISOString()}`);
        return;
      }
      console.log(`   ${index + 1}. User: ${user.id}, Intention: ${intention}, Tier: ${entry.tier}, Joined: ${entry.joinedAt.toISOString()}`);
    });
  }
  
  return users;
}

// MARK: - Build Romantic Compatibility Matrix (1-on-1)
async function buildRomanticCompatibilityMatrix(users: any[]) {
  const matrix: number[][] = [];
  
  for (let i = 0; i < users.length; i++) {
    matrix[i] = [];
    for (let j = 0; j < users.length; j++) {
      if (i === j) {
        matrix[i][j] = 0; // Can't match with self
      } else {
        const score = await calculateRomanticCompatibility(users[i], users[j]);
        matrix[i][j] = score;
      }
    }
  }
  
  return matrix;
}

// MARK: - Get Group Size Preferences
async function getGroupSizePreferences(users: any[]) {
  const preferences = new Map<string, string[]>();
  
  for (const user of users) {
    const surveyResponses = user.intention.user.surveyResponses || [];
    const groupSizeResponse = surveyResponses.find((r: any) => r.questionId === 'group_size');
    
    if (groupSizeResponse) {
      const preferredSizes = Array.isArray(groupSizeResponse.value) 
        ? groupSizeResponse.value 
        : [groupSizeResponse.value];
      preferences.set(user.intention.user.id, preferredSizes);
    } else {
      // Default to small groups if no preference
      preferences.set(user.intention.user.id, ['small_group']);
    }
  }
  
  return preferences;
}

// MARK: - Create Friendship Groups (Hierarchical Clustering)
async function createFriendshipGroups(users: any[], groupSizePreferences: Map<string, string[]>) {
  console.log(`🔍 [HIERARCHICAL CLUSTERING] Starting with ${users.length} users`);
  
  // Step 1: Filter by non-negotiables
  const viableUsers = await filterByNonNegotiables(users);
  console.log(`🔍 [FILTERING] ${viableUsers.length}/${users.length} users pass non-negotiable filters`);
  
  if (viableUsers.length < 2) {
    console.log(`🔍 [FILTERING] Not enough viable users for matching`);
    return [];
  }
  
  // Step 2: Create initial pairs (highest compatibility)
  const initialPairs = await createInitialPairs(viableUsers);
  console.log(`🔍 [INITIAL PAIRS] Created ${initialPairs.length} initial pairs`);
  
  // Step 3: Hierarchical merging until no beneficial merges
  const finalGroups = await hierarchicalMerging(initialPairs, groupSizePreferences, users);
  console.log(`🔍 [FINAL GROUPS] Created ${finalGroups.length} final groups`);
  
  return finalGroups;
}

// MARK: - Filter by Non-Negotiables
async function filterByNonNegotiables(users: any[]) {
  const viableUsers: any[] = [];
  
  for (const user of users) {
    const chips = typeof user.intention.parsedJson === 'string' 
      ? JSON.parse(user.intention.parsedJson) 
      : user.intention.parsedJson;
    
    console.log(`   🔍 Checking user ${user.intention.user.id}:`, {
      where: chips.where,
      when: chips.when,
      activities: chips.what?.activities,
      location: chips.location
    });
    
    // Check non-negotiable requirements (more flexible)
    const hasLocation = (chips.where && chips.where.trim() !== '') || 
                       (chips.location && chips.location.trim() !== '');
    const hasTime = chips.when && Array.isArray(chips.when) && chips.when.length > 0;
    const hasActivities = chips.what?.activities && 
                         Array.isArray(chips.what.activities) && 
                         chips.what.activities.length > 0;
    
    if (hasLocation && hasTime && hasActivities) {
      viableUsers.push(user);
      console.log(`   ✅ User ${user.intention.user.id} passed filters`);
    } else {
      console.log(`   ❌ User ${user.intention.user.id} filtered out:`, {
        hasLocation,
        hasTime, 
        hasActivities
      });
    }
  }
  
  return viableUsers;
}

// MARK: - Create Initial Pairs
async function createInitialPairs(users: any[]) {
  const pairs: any[] = [];
  const used = new Set<string>();
  
  // Calculate all pairwise compatibilities
  const compatibilityMatrix: number[][] = [];
  for (let i = 0; i < users.length; i++) {
    compatibilityMatrix[i] = [];
    for (let j = 0; j < users.length; j++) {
      if (i === j) {
        compatibilityMatrix[i][j] = 0;
      } else {
        const compatibility = await calculateFriendshipCompatibility(users[i], users[j]);
        compatibilityMatrix[i][j] = compatibility;
      }
    }
  }
  
  // Create sorted list of all possible pairs
  const allPairs: {i: number, j: number, score: number}[] = [];
  for (let i = 0; i < users.length; i++) {
    for (let j = i + 1; j < users.length; j++) {
      allPairs.push({
        i, j, 
        score: compatibilityMatrix[i][j]
      });
    }
  }
  
  // Sort by compatibility (highest first)
  allPairs.sort((a, b) => b.score - a.score);
  
  // Select non-overlapping pairs
  for (const pair of allPairs) {
    if (used.has(users[pair.i].intention.user.id) || used.has(users[pair.j].intention.user.id)) {
      continue;
    }
    
    if (pair.score > 0.3) { // Minimum compatibility threshold
      console.log(`   🔍 Creating pair: ${users[pair.i].intention.user.id} + ${users[pair.j].intention.user.id} (score: ${pair.score.toFixed(3)})`);
      pairs.push({
        users: [users[pair.i], users[pair.j]],
        size: 2,
        avgCompatibility: pair.score,
        score: pair.score * 2 // Initial score for pair
      });
      
      used.add(users[pair.i].intention.user.id);
      used.add(users[pair.j].intention.user.id);
    }
  }
  
  console.log(`   🔍 Remaining unmatched users: ${users.filter(u => !used.has(u.intention.user.id)).map(u => u.intention.user.id).join(', ')}`);
  
  return pairs;
}

// MARK: - Hierarchical Merging
async function hierarchicalMerging(initialGroups: any[], groupSizePreferences: Map<string, string[]>, allUsers: any[]) {
  let currentGroups = [...initialGroups];
  let improved = true;
  let iteration = 0;
  
  // Track which users are already in groups
  const usedUserIds = new Set<string>();
  currentGroups.forEach(group => {
    group.users.forEach((user: any) => {
      usedUserIds.add(user.intention.user.id);
    });
  });
  
  // Get remaining unmatched users
  const unmatchedUsers = allUsers.filter(user => !usedUserIds.has(user.intention.user.id));
  console.log(`🔍 [UNMATCHED USERS] ${unmatchedUsers.length} users not in groups: ${unmatchedUsers.map(u => u.intention.user.id).join(', ')}`);
  
  while (improved && iteration < 10) { // Prevent infinite loops
    iteration++;
    improved = false;
    
    console.log(`🔍 [MERGE ITERATION ${iteration}] Starting with ${currentGroups.length} groups, ${unmatchedUsers.length} unmatched users`);
    
    // Calculate current global score
    const currentScore = currentGroups.reduce((sum, group) => sum + group.score, 0);
    console.log(`🔍 [MERGE ITERATION ${iteration}] Current global score: ${currentScore.toFixed(3)}`);
    
    // Try all possible merges
    let bestMerge: {group1: any, group2: any, newScore: number, type: 'group-group' | 'group-user'} | null = null;
    
    // 1. Try merging existing groups with each other
    for (let i = 0; i < currentGroups.length; i++) {
      for (let j = i + 1; j < currentGroups.length; j++) {
        const group1 = currentGroups[i];
        const group2 = currentGroups[j];
        
        console.log(`   🔍 Trying to merge groups: ${group1.users.map((u: any) => u.intention.user.id).join(',')} + ${group2.users.map((u: any) => u.intention.user.id).join(',')}`);
        
        // Check if merge is possible (no user overlap)
        const group1UserIds = group1.users.map((u: any) => u.intention.user.id);
        const group2UserIds = group2.users.map((u: any) => u.intention.user.id);
        const hasOverlap = group1UserIds.some((id: string) => group2UserIds.includes(id));
        
        if (hasOverlap) {
          console.log(`   ❌ Overlap detected, skipping merge`);
          continue;
        }
        
        // Check if merged group would be viable
        const mergedUsers = [...group1.users, ...group2.users];
        const isViable = await isGroupViable(mergedUsers);
        
        if (!isViable) {
          console.log(`   ❌ Merged group not viable, skipping merge`);
          continue;
        }
        
        // Calculate new group score
        const newCompatibility = await calculateGroupCompatibility(mergedUsers);
        const newPriority = calculateGroupPriority(mergedUsers, groupSizePreferences);
        const newScore = newCompatibility * newPriority * mergedUsers.length;
        
        // Check if this merge improves global score
        const mergeBenefit = newScore - (group1.score + group2.score);
        
        console.log(`   🔍 Merge analysis: newScore=${newScore.toFixed(3)}, group1Score=${group1.score.toFixed(3)}, group2Score=${group2.score.toFixed(3)}, benefit=${mergeBenefit.toFixed(3)}`);
        
        if (mergeBenefit > 0 && (!bestMerge || mergeBenefit > (bestMerge.newScore - (bestMerge.group1.score + bestMerge.group2.score)))) {
          bestMerge = { group1, group2, newScore, type: 'group-group' };
          console.log(`   ✅ New best group-group merge found with benefit: ${mergeBenefit.toFixed(3)}`);
        }
      }
    }
    
    // 2. Try merging existing groups with unmatched users
    for (let i = 0; i < currentGroups.length; i++) {
      for (let j = 0; j < unmatchedUsers.length; j++) {
        const group = currentGroups[i];
        const user = unmatchedUsers[j];
        
        console.log(`   🔍 Trying to merge group with unmatched user: ${group.users.map((u: any) => u.intention.user.id).join(',')} + ${user.intention.user.id}`);
        
        // Check if merge is possible (no user overlap)
        const groupUserIds = group.users.map((u: any) => u.intention.user.id);
        const hasOverlap = groupUserIds.includes(user.intention.user.id);
        
        if (hasOverlap) {
          console.log(`   ❌ Overlap detected, skipping merge`);
          continue;
        }
        
        // Check if merged group would be viable
        const mergedUsers = [...group.users, user];
        const isViable = await isGroupViable(mergedUsers);
        
        if (!isViable) {
          console.log(`   ❌ Merged group not viable, skipping merge`);
          continue;
        }
        
        // Calculate new group score
        const newCompatibility = await calculateGroupCompatibility(mergedUsers);
        const newPriority = calculateGroupPriority(mergedUsers, groupSizePreferences);
        const newScore = newCompatibility * newPriority * mergedUsers.length;
        
        // Check if this merge improves global score
        const mergeBenefit = newScore - group.score;
        
        console.log(`   🔍 Merge analysis: newScore=${newScore.toFixed(3)}, groupScore=${group.score.toFixed(3)}, benefit=${mergeBenefit.toFixed(3)}`);
        
        if (mergeBenefit > 0 && (!bestMerge || mergeBenefit > (bestMerge.newScore - (bestMerge.group1.score + (bestMerge.group2?.score || 0))))) {
          bestMerge = { group1: group, group2: { users: [user], score: 0 }, newScore, type: 'group-user' };
          console.log(`   ✅ New best group-user merge found with benefit: ${mergeBenefit.toFixed(3)}`);
        }
      }
    }
    
    // Apply best merge if it improves global score
    if (bestMerge) {
      const { group1, group2, newScore, type } = bestMerge;
      
      if (type === 'group-group') {
        // Remove original groups
        const newGroups = currentGroups.filter(g => g !== group1 && g !== group2);
        
        // Add merged group
        const mergedUsers = [...group1.users, ...group2.users];
        newGroups.push({
          users: mergedUsers,
          size: mergedUsers.length,
          avgCompatibility: await calculateGroupCompatibility(mergedUsers),
          score: newScore
        });
        
        currentGroups = newGroups;
        improved = true;
        
        console.log(`🔍 [MERGE ITERATION ${iteration}] Merged groups: ${group1.users.length} + ${group2.users.length} = ${mergedUsers.length} users`);
      } else if (type === 'group-user') {
        // Remove original group
        const newGroups = currentGroups.filter(g => g !== group1);
        
        // Add merged group with the unmatched user
        const mergedUsers = [...group1.users, ...group2.users];
        newGroups.push({
          users: mergedUsers,
          size: mergedUsers.length,
          avgCompatibility: await calculateGroupCompatibility(mergedUsers),
          score: newScore
        });
        
        currentGroups = newGroups;
        improved = true;
        
        // Remove the user from unmatched users
        const userToRemove = group2.users[0];
        const userIndex = unmatchedUsers.findIndex(u => u.intention.user.id === userToRemove.intention.user.id);
        if (userIndex !== -1) {
          unmatchedUsers.splice(userIndex, 1);
        }
        
        console.log(`🔍 [MERGE ITERATION ${iteration}] Merged group with user: ${group1.users.length} + 1 = ${mergedUsers.length} users`);
      }
      
      console.log(`🔍 [MERGE ITERATION ${iteration}] New global score: ${newScore.toFixed(3)}`);
    }
  }
  
  console.log(`🔍 [HIERARCHICAL MERGING] Completed after ${iteration} iterations`);
  return currentGroups;
}


// MARK: - Optimized Algorithm (≤15 users)
async function createFriendshipGroupsOptimized(users: any[], groupSizePreferences: Map<string, string[]>) {
  console.log(`🔍 [OPTIMIZED] Using full optimization for ${users.length} users`);
  
  const allPossibleGroups = await generateAllPossibleGroups(users, groupSizePreferences);
  console.log(`🔍 [OPTIMIZED] Generated ${allPossibleGroups.length} possible groups`);
  
  const optimalGroups = findOptimalGrouping(allPossibleGroups, users.length);
  console.log(`🔍 [OPTIMIZED] Selected ${optimalGroups.length} optimal groups`);
  
  return optimalGroups;
}

// MARK: - Scalable Algorithm (>15 users)
async function createFriendshipGroupsScalable(users: any[], groupSizePreferences: Map<string, string[]>) {
  console.log(`🔍 [SCALABLE] Using heuristic algorithm for ${users.length} users`);
  
  const groups: any[] = [];
  const used = new Set<string>();
  
  // Sort users by priority (waiting time + preferences)
  users.sort((a, b) => {
    const waitingA = Date.now() - a.joinedAt.getTime();
    const waitingB = Date.now() - b.joinedAt.getTime();
    return waitingB - waitingA; // Longest waiting first
  });
  
  // Process users in batches to find optimal local groups
  for (const user of users) {
    if (used.has(user.intention.user.id)) continue;
    
    const preferredSizes = groupSizePreferences.get(user.intention.user.id) || ['small_group'];
    const targetSize = getTargetGroupSize(preferredSizes);
    
    // Find best local group for this user
    const bestGroup = await findBestLocalGroup(user, users, used, targetSize, groupSizePreferences);
    
    if (bestGroup.length >= 2) {
      const compatibility = await calculateGroupCompatibility(bestGroup);
      groups.push({
        users: bestGroup,
        size: bestGroup.length,
        avgCompatibility: compatibility
      });
      
      // Mark all users as used
      bestGroup.forEach((u: any) => used.add(u.intention.user.id));
    }
  }
  
  console.log(`🔍 [SCALABLE] Created ${groups.length} groups, matched ${used.size}/${users.length} users`);
  return groups;
}

// MARK: - Find Best Local Group (Heuristic)
async function findBestLocalGroup(
  seedUser: any, 
  allUsers: any[], 
  used: Set<string>, 
  targetSize: number,
  groupSizePreferences: Map<string, string[]>
) {
  const candidates = allUsers.filter(u => 
    !used.has(u.intention.user.id) && 
    u.intention.user.id !== seedUser.intention.user.id
  );
  
  // Calculate compatibility with seed user
  const compatibilityScores = new Map<string, number>();
  for (const candidate of candidates) {
    const score = await calculateFriendshipCompatibility(seedUser, candidate);
    compatibilityScores.set(candidate.intention.user.id, score);
  }
  
  // Sort by compatibility
  candidates.sort((a, b) => {
    const scoreA = compatibilityScores.get(a.intention.user.id) || 0;
    const scoreB = compatibilityScores.get(b.intention.user.id) || 0;
    return scoreB - scoreA;
  });
  
  // Try different group sizes (prefer larger groups)
  const maxSize = Math.min(targetSize + 2, candidates.length + 1);
  let bestGroup = [seedUser];
  let bestScore = 0;
  
  for (let size = 2; size <= maxSize; size++) {
    const group = [seedUser];
    
    // Add best candidates up to target size
    for (let i = 0; i < size - 1 && i < candidates.length; i++) {
      const candidate = candidates[i];
      const compatibility = compatibilityScores.get(candidate.intention.user.id) || 0;
      
      if (compatibility > 0.3) { // Minimum threshold
        group.push(candidate);
      }
    }
    
    if (group.length >= 2) {
      // Check if this group is viable (all pairs compatible)
      const isViable = await isGroupViable(group);
      if (isViable) {
        const groupScore = await calculateGroupCompatibility(group);
        const priority = calculateGroupPriority(group, groupSizePreferences);
        const totalScore = groupScore * priority * group.length; // Favor larger groups
        
        if (totalScore > bestScore) {
          bestScore = totalScore;
          bestGroup = [...group];
        }
      }
    }
  }
  
  return bestGroup;
}

// MARK: - Generate All Possible Groups
async function generateAllPossibleGroups(users: any[], groupSizePreferences: Map<string, string[]>) {
  const possibleGroups: any[] = [];
  
  // Generate all combinations of 2-6 users
  for (let size = 2; size <= Math.min(6, users.length); size++) {
    const combinations = getCombinations(users, size);
    
    for (const combination of combinations) {
      // Check if this combination is viable
      const isViable = await isGroupViable(combination);
      if (isViable) {
        const compatibility = await calculateGroupCompatibility(combination);
        const priority = calculateGroupPriority(combination, groupSizePreferences);
        
        possibleGroups.push({
          users: combination,
          size: combination.length,
          avgCompatibility: compatibility,
          priority: priority,
          score: compatibility * priority // Combined score
        });
      }
    }
  }
  
  // Sort by score (highest first)
  possibleGroups.sort((a, b) => b.score - a.score);
  
  return possibleGroups;
}

// MARK: - Check if Group is Viable
async function isGroupViable(users: any[]): Promise<boolean> {
  if (users.length < 2) return false;
  
  // Check that all users are compatible with each other
  for (let i = 0; i < users.length; i++) {
    for (let j = i + 1; j < users.length; j++) {
      const compatibility = await calculateFriendshipCompatibility(users[i], users[j]);
      if (compatibility < 0.3) { // Minimum compatibility threshold
        return false;
      }
    }
  }
  
  return true;
}

// MARK: - Calculate Group Priority
function calculateGroupPriority(users: any[], groupSizePreferences: Map<string, string[]>) {
  let priority = 1.0;
  
  // Boost priority for users who prefer this group size
  for (const user of users) {
    const preferredSizes = groupSizePreferences.get(user.intention.user.id) || ['small_group'];
    const targetSize = getTargetGroupSize(preferredSizes);
    
    if (users.length === targetSize) {
      priority += 0.5; // Boost for preferred size
    } else if (users.length > targetSize) {
      priority += 0.2; // Slight boost for larger groups
    }
  }
  
  // Boost priority for larger groups (more people matched)
  priority += (users.length - 2) * 0.1;
  
  return priority;
}

// MARK: - Find Optimal Grouping (Maximum Weight Matching)
function findOptimalGrouping(possibleGroups: any[], totalUsers: number) {
  const selectedGroups: any[] = [];
  const usedUsers = new Set<string>();
  
  // Greedy selection of non-overlapping groups
  for (const group of possibleGroups) {
    // Check if any users in this group are already used
    const groupUserIds = group.users.map((u: any) => u.intention.user.id);
    const hasOverlap = groupUserIds.some((id: string) => usedUsers.has(id));
    
    if (!hasOverlap) {
      selectedGroups.push(group);
      groupUserIds.forEach((id: string) => usedUsers.add(id));
    }
  }
  
  console.log(`🔍 [OPTIMAL GROUPING] Selected ${selectedGroups.length} groups, matched ${usedUsers.size}/${totalUsers} users`);
  
  return selectedGroups;
}

// MARK: - Get Combinations (Helper)
function getCombinations<T>(arr: T[], size: number): T[][] {
  if (size === 1) return arr.map(item => [item]);
  if (size === arr.length) return [arr];
  if (size > arr.length) return [];
  
  const combinations: T[][] = [];
  
  function backtrack(start: number, current: T[]) {
    if (current.length === size) {
      combinations.push([...current]);
      return;
    }
    
    for (let i = start; i < arr.length; i++) {
      current.push(arr[i]);
      backtrack(i + 1, current);
      current.pop();
    }
  }
  
  backtrack(0, []);
  return combinations;
}

// MARK: - Get Target Group Size
function getTargetGroupSize(preferredSizes: string[]): number {
  if (preferredSizes.includes('large_group')) return 6;
  if (preferredSizes.includes('medium_group')) return 4;
  return 2; // Default to small group
}

// MARK: - Calculate Group Compatibility (Improved)
async function calculateGroupCompatibility(members: any[]): Promise<number> {
  if (members.length < 2) return 0;
  
  let totalCompatibility = 0;
  let pairCount = 0;
  
  // Calculate compatibility between all pairs in the group
  for (let i = 0; i < members.length; i++) {
    for (let j = i + 1; j < members.length; j++) {
      const compatibility = await calculateFriendshipCompatibility(members[i], members[j]);
      totalCompatibility += compatibility;
      pairCount++;
    }
  }
  
  // Return average compatibility
  const avgCompatibility = pairCount > 0 ? totalCompatibility / pairCount : 0;
  
  // Apply group size bonus (larger groups get slight bonus)
  const sizeBonus = Math.min(0.1, (members.length - 2) * 0.02);
  
  return Math.min(1.0, avgCompatibility + sizeBonus);
}

// MARK: - Dynamic Compatibility Score (Relaxes Over Time)
async function calculateSimpleCompatibility(userA: any, userB: any): Promise<number> {
  const intentionA = userA.intention;
  const intentionB = userB.intention;
  
  // Parse intention data
  const chipsA = typeof intentionA.parsedJson === 'string' 
    ? JSON.parse(intentionA.parsedJson) 
    : intentionA.parsedJson;
  const chipsB = typeof intentionB.parsedJson === 'string' 
    ? JSON.parse(intentionB.parsedJson) 
    : intentionB.parsedJson;
  
  // Calculate waiting time for dynamic relaxation
  const now = new Date();
  const daysWaitingA = Math.floor((now.getTime() - userA.joinedAt.getTime()) / (24 * 60 * 60 * 1000));
  const daysWaitingB = Math.floor((now.getTime() - userB.joinedAt.getTime()) / (24 * 60 * 60 * 1000));
  const maxWaitingDays = Math.max(daysWaitingA, daysWaitingB);
  
  // DYNAMIC REQUIREMENTS (relax over time)
  const locationMatch = calculateLocationCompatibility(chipsA.where, chipsB.where, maxWaitingDays);
  const timeMatch = calculateTimeCompatibility(chipsA.when || [], chipsB.when || [], maxWaitingDays);
  
  // If basic requirements not met, no match possible
  if (locationMatch === 0 || timeMatch === 0) {
    console.log(`🔍 [MATCHING DEBUG] ${userA.intention.user.id} ↔ ${userB.intention.user.id}: FAILED - Location: ${locationMatch}, Time: ${timeMatch}`);
    return 0;
  }
  
  // Dynamic scoring weights (relax over time)
  const weights = getDynamicWeights(maxWaitingDays);
  
  // Compatibility scoring with dynamic weights
  let score = 0;
  
  // 1. Intention alignment (relaxes over time)
  const intentionMatch = calculateIntentionCompatibility(chipsA, chipsB, maxWaitingDays);
  const intentionScore = weights.intention * intentionMatch;
  score += intentionScore;
  
  // 2. Activity overlap (becomes more important over time)
  const activityOverlap = calculateArrayOverlap(
    chipsA.what?.activities || [],
    chipsB.what?.activities || []
  );
  const activityScore = weights.activity * activityOverlap;
  score += activityScore;
  
  // 3. Age compatibility (relaxes significantly over time)
  const ageCompatibility = calculateAgeCompatibility(
    userA.intention.user.profile?.age,
    userB.intention.user.profile?.age,
    maxWaitingDays
  );
  const ageScore = weights.age * ageCompatibility;
  score += ageScore;
  
  // 4. Survey compatibility (becomes more important over time)
  const surveyCompatibility = calculateSurveyCompatibility(
    userA.intention.user.surveyResponses || [],
    userB.intention.user.surveyResponses || []
  );
  const surveyScore = weights.survey * surveyCompatibility;
  score += surveyScore;
  
  // 5. Location and time compatibility
  const locationScore = weights.location * locationMatch;
  const timeScore = weights.time * timeMatch;
  score += locationScore + timeScore;
  
  // Priority boost for long waiters (exponential)
  const priorityBoost = Math.pow(1.2, maxWaitingDays); // 20% boost per day
  const finalScore = Math.min(score * priorityBoost, 1.0); // Cap at 1.0
  
  // COMPREHENSIVE LOGGING FOR DEVELOPERS
  console.log(`🔍 [MATCHING DEBUG] ${userA.intention.user.id} ↔ ${userB.intention.user.id}:`);
  console.log(`   📊 Waiting: A=${daysWaitingA}d, B=${daysWaitingB}d, Max=${maxWaitingDays}d`);
  console.log(`   🎯 Weights: Intention=${weights.intention}, Activity=${weights.activity}, Age=${weights.age}, Survey=${weights.survey}`);
  console.log(`   ✅ Matched on: Location=${locationMatch}, Time=${timeMatch}`);
  console.log(`   📈 Scores: Intention=${intentionScore.toFixed(3)}, Activity=${activityScore.toFixed(3)}, Age=${ageScore.toFixed(3)}, Survey=${surveyScore.toFixed(3)}`);
  console.log(`   🚀 Priority Boost: ${priorityBoost.toFixed(2)}x, Final Score: ${finalScore.toFixed(3)}`);
  
  // Log relaxation details
  const relaxationLog = [];
  if (maxWaitingDays > 1) relaxationLog.push(`Age range expanded to ${maxWaitingDays <= 3 ? '5' : '8'} years`);
  if (maxWaitingDays > 3) relaxationLog.push(`Intention matching relaxed`);
  if (maxWaitingDays > 1) relaxationLog.push(`Survey compatibility prioritized`);
  
  if (relaxationLog.length > 0) {
    console.log(`   🔄 Relaxed: ${relaxationLog.join(', ')}`);
  }
  
  return finalScore;
}

// MARK: - Romantic Compatibility (1-on-1 with Gender/Sexual Orientation)
async function calculateRomanticCompatibility(userA: any, userB: any): Promise<number> {
  const intentionA = userA.intention;
  const intentionB = userB.intention;
  
  // Parse intention data
  const chipsA = typeof intentionA.parsedJson === 'string' 
    ? JSON.parse(intentionA.parsedJson) 
    : intentionA.parsedJson;
  const chipsB = typeof intentionB.parsedJson === 'string' 
    ? JSON.parse(intentionB.parsedJson) 
    : intentionB.parsedJson;
  
  // Calculate waiting time for dynamic relaxation
  const now = new Date();
  const daysWaitingA = Math.floor((now.getTime() - userA.joinedAt.getTime()) / (24 * 60 * 60 * 1000));
  const daysWaitingB = Math.floor((now.getTime() - userB.joinedAt.getTime()) / (24 * 60 * 60 * 1000));
  const maxWaitingDays = Math.max(daysWaitingA, daysWaitingB);
  
  // ABSOLUTE REQUIREMENTS for romantic matching
  const locationMatch = calculateLocationCompatibility(chipsA.where, chipsB.where, maxWaitingDays);
  const timeMatch = calculateTimeCompatibility(chipsA.when || [], chipsB.when || [], maxWaitingDays);
  
  if (locationMatch === 0 || timeMatch === 0) {
    console.log(`🔍 [ROMANTIC DEBUG] ${userA.intention.user.id} ↔ ${userB.intention.user.id}: FAILED - Location: ${locationMatch}, Time: ${timeMatch}`);
    return 0;
  }
  
  // ABSOLUTE REQUIREMENT: Check gender and sexual orientation compatibility
  const genderCompatibility = checkGenderCompatibility(userA, userB);
  if (genderCompatibility === 0) {
    console.log(`🔍 [ROMANTIC DEBUG] ${userA.intention.user.id} ↔ ${userB.intention.user.id}: FAILED - Gender/Sexual orientation mismatch (NON-NEGOTIABLE)`);
    return 0;
  }
  
  // Dynamic scoring weights for romantic matching
  const weights = getRomanticWeights(maxWaitingDays);
  
  let score = 0;
  
  // 1. Intention alignment (must be romantic)
  const intentionMatch = chipsA.what?.connection === 'romantic' && chipsB.what?.connection === 'romantic' ? 1.0 : 0.0;
  score += weights.intention * intentionMatch;
  
  // 2. Activity overlap
  const activityOverlap = calculateArrayOverlap(
    chipsA.what?.activities || [],
    chipsB.what?.activities || []
  );
  score += weights.activity * activityOverlap;
  
  // 3. Age compatibility (more important for romantic)
  const ageCompatibility = calculateAgeCompatibility(
    userA.intention.user.profile?.age,
    userB.intention.user.profile?.age,
    maxWaitingDays
  );
  score += weights.age * ageCompatibility;
  
  // 4. Survey compatibility (personality matters more for romantic)
  const surveyCompatibility = calculateSurveyCompatibility(
    userA.intention.user.surveyResponses || [],
    userB.intention.user.surveyResponses || []
  );
  score += weights.survey * surveyCompatibility;
  
  // 5. Location and time compatibility
  score += weights.location * locationMatch;
  score += weights.time * timeMatch;
  
  // Priority boost for long waiters
  const priorityBoost = Math.pow(1.2, maxWaitingDays);
  const finalScore = Math.min(score * priorityBoost, 1.0);
  
  // Log comprehensive romantic matching details
  console.log(`🔍 [ROMANTIC DEBUG] ${userA.intention.user.id} ↔ ${userB.intention.user.id}:`);
  console.log(`   📊 Waiting: A=${daysWaitingA}d, B=${daysWaitingB}d, Max=${maxWaitingDays}d`);
  console.log(`   🎯 Weights: Intention=${weights.intention}, Activity=${weights.activity}, Age=${weights.age}, Survey=${weights.survey}`);
  console.log(`   ✅ Matched on: Location=${locationMatch}, Time=${timeMatch}, Gender/Orientation=${genderCompatibility}`);
  console.log(`   📈 Scores: Intention=${(weights.intention * intentionMatch).toFixed(3)}, Activity=${(weights.activity * activityOverlap).toFixed(3)}, Age=${(weights.age * ageCompatibility).toFixed(3)}, Survey=${(weights.survey * surveyCompatibility).toFixed(3)}`);
  console.log(`   🚀 Priority Boost: ${priorityBoost.toFixed(2)}x, Final Score: ${finalScore.toFixed(3)}`);
  
  return finalScore;
}

// MARK: - Friendship Compatibility (Groups)
async function calculateFriendshipCompatibility(userA: any, userB: any): Promise<number> {
  const intentionA = userA.intention;
  const intentionB = userB.intention;
  
  // Parse intention data
  const chipsA = typeof intentionA.parsedJson === 'string' 
    ? JSON.parse(intentionA.parsedJson) 
    : intentionA.parsedJson;
  const chipsB = typeof intentionB.parsedJson === 'string' 
    ? JSON.parse(intentionB.parsedJson) 
    : intentionB.parsedJson;
  
  // Calculate waiting time for dynamic relaxation
  const now = new Date();
  const daysWaitingA = Math.floor((now.getTime() - userA.joinedAt.getTime()) / (24 * 60 * 60 * 1000));
  const daysWaitingB = Math.floor((now.getTime() - userB.joinedAt.getTime()) / (24 * 60 * 60 * 1000));
  const maxWaitingDays = Math.max(daysWaitingA, daysWaitingB);
  
  // ABSOLUTE REQUIREMENTS for friendship matching
  const locationMatch = calculateLocationCompatibility(chipsA.where, chipsB.where, maxWaitingDays);
  const timeMatch = calculateTimeCompatibility(chipsA.when || [], chipsB.when || [], maxWaitingDays);
  
  if (locationMatch === 0 || timeMatch === 0) {
    return 0;
  }
  
  // Dynamic scoring weights for friendship matching
  const weights = getFriendshipWeights(maxWaitingDays);
  
  let score = 0;
  
  // 1. Intention alignment (must be friends)
  const intentionMatch = chipsA.what?.connection === 'friends' && chipsB.what?.connection === 'friends' ? 1.0 : 0.0;
  score += weights.intention * intentionMatch;
  
  // 2. Activity overlap (most important for friendship)
  const activityOverlap = calculateArrayOverlap(
    chipsA.what?.activities || [],
    chipsB.what?.activities || []
  );
  score += weights.activity * activityOverlap;
  
  // 3. Age compatibility (less strict for friendship)
  const ageCompatibility = calculateAgeCompatibility(
    userA.intention.user.profile?.age,
    userB.intention.user.profile?.age,
    maxWaitingDays
  );
  score += weights.age * ageCompatibility;
  
  // 4. Survey compatibility (personality matters for friendship)
  const surveyCompatibility = calculateSurveyCompatibility(
    userA.intention.user.surveyResponses || [],
    userB.intention.user.surveyResponses || []
  );
  score += weights.survey * surveyCompatibility;
  
  // 5. Location and time compatibility
  score += weights.location * locationMatch;
  score += weights.time * timeMatch;
  
  // Priority boost for long waiters
  const priorityBoost = Math.pow(1.2, maxWaitingDays);
  const finalScore = Math.min(score * priorityBoost, 1.0);
  
  return finalScore;
}

// MARK: - Check Gender and Sexual Orientation Compatibility (NON-NEGOTIABLE)
function checkGenderCompatibility(userA: any, userB: any): number {
  const profileA = userA.intention.user.profile;
  const profileB = userB.intention.user.profile;
  
  // Get gender and sexual orientation from profiles and surveys
  const genderA = profileA?.gender;
  const genderB = profileB?.gender;
  
  const surveyA = userA.intention.user.surveyResponses || [];
  const surveyB = userB.intention.user.surveyResponses || [];
  
  const orientationA = surveyA.find((r: any) => r.questionId === 'sexual_orientation')?.value;
  const orientationB = surveyB.find((r: any) => r.questionId === 'sexual_orientation')?.value;
  
  // If gender or orientation is missing, cannot match
  if (!genderA || !genderB || !orientationA || !orientationB) {
    console.log(`🔍 [GENDER CHECK] Missing gender/orientation data: A(${genderA}, ${orientationA}) B(${genderB}, ${orientationB})`);
    return 0;
  }
  
  // Check if orientations are compatible
  const isCompatible = checkOrientationCompatibility(genderA, orientationA, genderB, orientationB);
  
  if (!isCompatible) {
    console.log(`🔍 [GENDER CHECK] Incompatible orientations: ${genderA}(${orientationA}) ↔ ${genderB}(${orientationB})`);
    return 0;
  }
  
  console.log(`🔍 [GENDER CHECK] Compatible orientations: ${genderA}(${orientationA}) ↔ ${genderB}(${orientationB})`);
  return 1.0;
}

// MARK: - Check Orientation Compatibility
function checkOrientationCompatibility(genderA: string, orientationA: string, genderB: string, orientationB: string): boolean {
  // Handle different orientation formats
  const normalizeOrientation = (orientation: string) => {
    const lower = orientation.toLowerCase();
    if (lower.includes('straight') || lower.includes('heterosexual')) return 'straight';
    if (lower.includes('gay') || lower.includes('homosexual')) return 'gay';
    if (lower.includes('bisexual') || lower.includes('bi')) return 'bisexual';
    if (lower.includes('pansexual') || lower.includes('pan')) return 'pansexual';
    return lower;
  };
  
  const normOrientationA = normalizeOrientation(orientationA);
  const normOrientationB = normalizeOrientation(orientationB);
  
  // Check compatibility based on orientations
  if (normOrientationA === 'straight' && normOrientationB === 'straight') {
    // Both straight - must be opposite genders
    return genderA !== genderB;
  }
  
  if (normOrientationA === 'gay' && normOrientationB === 'gay') {
    // Both gay - must be same gender
    return genderA === genderB;
  }
  
  if (normOrientationA === 'bisexual' || normOrientationB === 'bisexual') {
    // At least one is bisexual - compatible with any gender
    return true;
  }
  
  if (normOrientationA === 'pansexual' || normOrientationB === 'pansexual') {
    // At least one is pansexual - compatible with any gender
    return true;
  }
  
  // Default: no compatibility
  return false;
}

// MARK: - Romantic Weights (More Strict)
function getRomanticWeights(waitingDays: number) {
  if (waitingDays <= 1) {
    return {
      intention: 0.3,    // Must be romantic
      activity: 0.25,    // Important
      age: 0.25,         // Very important for romantic
      survey: 0.15,      // Personality matters
      location: 0.05,    // Must be exact
      time: 0.0          // Must be exact
    };
  } else if (waitingDays <= 3) {
    return {
      intention: 0.25,    // Still must be romantic
      activity: 0.3,     // More important
      age: 0.2,          // Still important
      survey: 0.2,       // More important
      location: 0.05,    // Still exact
      time: 0.0          // Still exact
    };
  } else {
    return {
      intention: 0.2,     // Still must be romantic
      activity: 0.35,    // Most important
      age: 0.15,         // Less strict
      survey: 0.25,      // Very important
      location: 0.05,    // Still exact
      time: 0.0          // Still exact
    };
  }
}

// MARK: - Friendship Weights (More Flexible)
function getFriendshipWeights(waitingDays: number) {
  if (waitingDays <= 1) {
    return {
      intention: 0.2,     // Must be friends
      activity: 0.4,     // Most important
      age: 0.15,         // Less important
      survey: 0.2,       // Important
      location: 0.05,    // Must be exact
      time: 0.0          // Must be exact
    };
  } else if (waitingDays <= 3) {
    return {
      intention: 0.15,    // Still must be friends
      activity: 0.45,    // Most important
      age: 0.1,          // Less important
      survey: 0.25,      // More important
      location: 0.05,    // Still exact
      time: 0.0          // Still exact
    };
  } else {
    return {
      intention: 0.1,     // Still must be friends
      activity: 0.5,     // Most important
      age: 0.05,         // Least important
      survey: 0.3,       // Very important
      location: 0.05,    // Still exact
      time: 0.0          // Still exact
    };
  }
}

// MARK: - Dynamic Weights (Relax Over Time - Max 7 Days)
function getDynamicWeights(waitingDays: number) {
  if (waitingDays <= 1) {
    // Day 1: Strict matching
    return {
      intention: 0.4,    // High importance
      activity: 0.25,     // High importance
      age: 0.2,          // High importance
      survey: 0.1,       // Medium importance
      location: 0.05,    // Must be exact
      time: 0.0          // Must be exact (handled separately)
    };
  } else if (waitingDays <= 3) {
    // Days 2-3: Moderate relaxation
    return {
      intention: 0.3,    // Still important
      activity: 0.3,     // More important
      age: 0.15,         // Less strict
      survey: 0.15,      // More important
      location: 0.05,    // Still exact
      time: 0.05         // Still exact
    };
  } else {
    // Days 4-7: Maximum relaxation (cap at 7 days)
    return {
      intention: 0.15,   // Less important
      activity: 0.4,     // Most important
      age: 0.1,          // Very relaxed
      survey: 0.25,      // Very important
      location: 0.05,    // Still exact
      time: 0.05         // Still exact
    };
  }
}

// MARK: - Location Compatibility (ALWAYS REQUIRED)
function calculateLocationCompatibility(locationA: string, locationB: string, waitingDays: number): number {
  // Location must ALWAYS match exactly - this is an absolute requirement
  return locationA === locationB ? 1.0 : 0.0;
}

// MARK: - Time Compatibility (ALWAYS REQUIRED)
function calculateTimeCompatibility(timesA: string[], timesB: string[], waitingDays: number): number {
  // Time overlap must ALWAYS exist - this is an absolute requirement
  const overlap = calculateTimeOverlap(timesA, timesB);
  return overlap > 0 ? 1.0 : 0.0;
}

// MARK: - Dynamic Intention Compatibility (Max 7 Days)
function calculateIntentionCompatibility(chipsA: any, chipsB: any, waitingDays: number): number {
  const connectionMatch = chipsA.what?.connection === chipsB.what?.connection ? 1.0 : 0.0;
  
  if (waitingDays <= 1) {
    return connectionMatch; // Must match exactly
  } else if (waitingDays <= 3) {
    return connectionMatch; // Still prefer exact match
  } else {
    // Days 4-7: Allow some flexibility in connection type (cap at 7 days)
    return connectionMatch * 0.8 + 0.2; // Partial credit for different intentions
  }
}

// MARK: - Dynamic Age Compatibility (Max 7 Days)
function calculateAgeCompatibility(ageA?: number, ageB?: number, waitingDays: number = 0): number {
  if (!ageA || !ageB) return 0.5; // Default if age unknown
  
  const ageDiff = Math.abs(ageA - ageB);
  
  if (waitingDays <= 1) {
    // Day 1: Strict age matching
    if (ageDiff <= 3) return 1.0;
    if (ageDiff <= 5) return 0.7;
    return 0;
  } else if (waitingDays <= 3) {
    // Days 2-3: Moderate age flexibility
    if (ageDiff <= 5) return 1.0;
    if (ageDiff <= 8) return 0.8;
    if (ageDiff <= 12) return 0.5;
    return 0.2;
  } else {
    // Days 4-7: Maximum age flexibility (cap at 7 days)
    if (ageDiff <= 8) return 1.0;
    if (ageDiff <= 15) return 0.8;
    if (ageDiff <= 20) return 0.6;
    return 0.3;
  }
}

// MARK: - Survey Compatibility (Jaccard Similarity)
function calculateSurveyCompatibility(surveyA: any[], surveyB: any[]): number {
  const responsesA = new Map(surveyA.map(r => [r.questionId, r.value]));
  const responsesB = new Map(surveyB.map(r => [r.questionId, r.value]));
  
  let matches = 0;
  let total = 0;
  
  for (const [questionId, valueA] of responsesA) {
    const valueB = responsesB.get(questionId);
    if (!valueB) continue;
    
    total++;
    if (valueA === valueB) matches++;
  }
  
  return total > 0 ? matches / total : 0;
}

// MARK: - Find Optimal Matches (Greedy Algorithm)
function findOptimalMatches(matrix: number[][], users: any[]): MatchPair[] {
  const matches: MatchPair[] = [];
  const used = new Set<number>();
  
  // Create list of all possible pairs with scores
  const pairs: { i: number, j: number, score: number }[] = [];
  
  for (let i = 0; i < matrix.length; i++) {
    for (let j = i + 1; j < matrix.length; j++) {
      if (matrix[i][j] > 0) {
        pairs.push({ i, j, score: matrix[i][j] });
      }
    }
  }
  
  // Sort by score (highest first)
  pairs.sort((a, b) => b.score - a.score);
  
  // Greedy selection
  for (const pair of pairs) {
    if (!used.has(pair.i) && !used.has(pair.j)) {
      matches.push({
        userAId: users[pair.i].intention.user.id,
        userBId: users[pair.j].intention.user.id,
        intentionAId: users[pair.i].intention.id,
        intentionBId: users[pair.j].intention.id,
        score: pair.score,
        tier: Math.min(users[pair.i].tier, users[pair.j].tier)
      });
      
      used.add(pair.i);
      used.add(pair.j);
    }
  }
  
  return matches;
}

// MARK: - Create Match (1-on-1)
async function createMatch(match: MatchPair) {
  const newMatch = await prisma.match.create({
    data: {
      groupSize: 2,
      score: match.score,
      tierUsed: match.tier,
      status: 'active',
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      members: {
        create: [
          {
            userId: match.userAId,
            intentionId: match.intentionAId
          },
          {
            userId: match.userBId,
            intentionId: match.intentionBId
          }
        ]
      }
    }
  });
  
  // Remove from pool
  await prisma.poolEntry.deleteMany({
    where: {
      OR: [
        { intention: { userId: match.userAId } },
        { intention: { userId: match.userBId } }
      ]
    }
  });
  
  return newMatch;
}

// MARK: - Create Friendship Group
async function createFriendshipGroup(group: any) {
  const userIds = group.users.map((u: any) => u.intention.user.id);
  
  // Create a single group match with all members
  const newMatch = await prisma.match.create({
    data: {
      groupSize: group.users.length,
      score: group.avgCompatibility,
      tierUsed: Math.min(...group.users.map((u: any) => u.tier)),
      status: 'active',
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      members: {
        create: group.users.map((user: any) => ({
          userId: user.intention.user.id,
          intentionId: user.intention.id
        }))
      }
    }
  });
  
  // Remove all users from pool
  await prisma.poolEntry.deleteMany({
    where: {
      intention: {
        userId: {
          in: userIds
        }
      }
    }
  });
  
  return newMatch;
}

// MARK: - Promote Unmatched Users (Max 7 Days)
async function promoteUnmatchedUsers() {
  const now = new Date();
  
  // Promote from tier 0 to 1 (after 24 hours)
  const tier0Entries = await prisma.poolEntry.findMany({
    where: {
      tier: 0,
      joinedAt: { lt: new Date(now.getTime() - 24 * 60 * 60 * 1000) }
    }
  });
  
  for (const entry of tier0Entries) {
    await prisma.poolEntry.update({
      where: { id: entry.id },
      data: { tier: 1 }
    });
  }
  
  console.log(`  Promoted ${tier0Entries.length} users from tier 0 → 1`);
  
  // Promote from tier 1 to 2 (after 48 hours)
  const tier1Entries = await prisma.poolEntry.findMany({
    where: {
      tier: 1,
      joinedAt: { lt: new Date(now.getTime() - 48 * 60 * 60 * 1000) }
    }
  });
  
  for (const entry of tier1Entries) {
    await prisma.poolEntry.update({
      where: { id: entry.id },
      data: { tier: 2 }
    });
  }
  
  console.log(`  Promoted ${tier1Entries.length} users from tier 1 → 2`);
  
  // CRITICAL: Expire intentions after 7 days (not 72 hours)
  const expiredEntries = await prisma.poolEntry.findMany({
    where: {
      joinedAt: { lt: new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000) }
    }
  });
  
  for (const entry of expiredEntries) {
    await prisma.poolEntry.delete({ where: { id: entry.id } });
  }
  
  console.log(`  Expired ${expiredEntries.length} intentions after 7 days`);
}

// MARK: - Simple Helper Functions
function calculateTimeOverlap(timesA: string[], timesB: string[]): number {
  if (timesA.length === 0 || timesB.length === 0) return 0;
  
  const setA = new Set(timesA);
  const setB = new Set(timesB);
  
  const intersection = new Set([...setA].filter(x => setB.has(x)));
  const union = new Set([...setA, ...setB]);
  
  return intersection.size / union.size; // Jaccard similarity
}

// Old simple version removed - using dynamic version above

function calculateArrayOverlap(arrA: string[], arrB: string[]): number {
  if (arrA.length === 0 && arrB.length === 0) return 1.0;
  if (arrA.length === 0 || arrB.length === 0) return 0.0;
  
  const setA = new Set(arrA);
  const setB = new Set(arrB);
  
  const intersection = new Set([...setA].filter(x => setB.has(x)));
  const union = new Set([...setA, ...setB]);
  
  return intersection.size / union.size;
}

// MARK: - Lambda Handler
export const handler = async (event: any) => {
  try {
    await runBatchMatcher();
    return { statusCode: 200, body: 'Batch matching completed successfully' };
  } catch (error) {
    console.error('Lambda error:', error);
    return { statusCode: 500, body: 'Batch matching failed' };
  }
};

// MARK: - Main Execution (for local testing)
if (require.main === module) {
  console.log('🎯 Running batch matcher locally...');
  runBatchMatcher()
    .then(() => {
      console.log('✅ Batch matcher completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Batch matcher failed:', error);
      process.exit(1);
    });
}