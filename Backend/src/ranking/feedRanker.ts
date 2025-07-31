// feedRanker.ts - Pure ranking algorithm for feed items

export interface FeedItem {
  kind: 'event' | 'post'
  id: string
  ts: Date // eventDate or createdAt
  rank?: number // Optional pre-computed rank for future ML models
}

export interface UserContext {
  userId: string
  // Future: followed coves, friends, preferences, etc.
}

/**
 * Ranks feed items by relevance.
 * Currently uses simple time-based ordering, but designed for future ML integration.
 */
export function rankFeedItems(items: FeedItem[], userContext?: UserContext): FeedItem[] {
  // For now, simple time-based ranking (newest first)
  // Future: This will incorporate engagement, relevance, ML models, etc.
  return items.sort((a, b) => {
    // Events and posts are ranked by their timestamp
    return b.ts.getTime() - a.ts.getTime()
  })
}

/**
 * Computes a relevance score for a feed item.
 * Currently uses time-based scoring, but designed for future ML integration.
 */
export function computeItemScore(item: FeedItem, userContext?: UserContext): number {
  const now = new Date()
  const timeDiff = now.getTime() - item.ts.getTime()
  const hoursAgo = timeDiff / (1000 * 60 * 60)
  
  // Simple exponential decay: newer items get higher scores
  // Future: This will incorporate engagement, user preferences, ML models, etc.
  return Math.exp(-hoursAgo / 24) // Decay over 24 hours
}

/**
 * Ranks feed items with computed scores.
 * This is the main entry point for feed ranking.
 */
export function rankFeedItemsWithScores(items: FeedItem[], userContext?: UserContext): FeedItem[] {
  // Compute scores for all items
  const itemsWithScores = items.map(item => ({
    ...item,
    rank: computeItemScore(item, userContext)
  }))
  
  // Sort by computed score (highest first)
  return itemsWithScores.sort((a, b) => (b.rank || 0) - (a.rank || 0))
}

// Future: Add more sophisticated ranking algorithms
// export function rankWithEngagement(items: FeedItem[], userContext: UserContext): FeedItem[]
// export function rankWithMLModel(items: FeedItem[], userContext: UserContext): FeedItem[] 