// feedRanker.test.ts - Unit tests for feed ranking algorithm

import { rankFeedItems, rankFeedItemsWithScores, computeItemScore, FeedItem, UserContext } from './feedRanker'

describe('FeedRanker', () => {
  const mockUserContext: UserContext = {
    userId: 'test-user-123'
  }

  const createMockEvent = (id: string, date: Date): FeedItem => ({
    kind: 'event',
    id,
    ts: date
  })

  const createMockPost = (id: string, date: Date): FeedItem => ({
    kind: 'post',
    id,
    ts: date
  })

  describe('rankFeedItems', () => {
    it('should rank items by timestamp (newest first)', () => {
      const now = new Date()
      const oneHourAgo = new Date(now.getTime() - 60 * 60 * 1000)
      const twoHoursAgo = new Date(now.getTime() - 2 * 60 * 60 * 1000)

      const items: FeedItem[] = [
        createMockEvent('event-1', twoHoursAgo),
        createMockPost('post-1', now),
        createMockEvent('event-2', oneHourAgo)
      ]

      const ranked = rankFeedItems(items)

      expect(ranked[0].id).toBe('post-1') // Newest
      expect(ranked[1].id).toBe('event-2') // Middle
      expect(ranked[2].id).toBe('event-1') // Oldest
    })

    it('should handle empty array', () => {
      const ranked = rankFeedItems([])
      expect(ranked).toEqual([])
    })

    it('should handle single item', () => {
      const item = createMockPost('post-1', new Date())
      const ranked = rankFeedItems([item])
      expect(ranked).toEqual([item])
    })
  })

  describe('computeItemScore', () => {
    it('should give higher scores to newer items', () => {
      const now = new Date()
      const oneHourAgo = new Date(now.getTime() - 60 * 60 * 1000)
      const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000)

      const recentItem = createMockPost('recent', oneHourAgo)
      const oldItem = createMockPost('old', oneDayAgo)

      const recentScore = computeItemScore(recentItem)
      const oldScore = computeItemScore(oldItem)

      expect(recentScore).toBeGreaterThan(oldScore)
    })

    it('should handle items from the future', () => {
      const future = new Date(Date.now() + 24 * 60 * 60 * 1000) // 1 day in future
      const futureItem = createMockEvent('future', future)
      
      const score = computeItemScore(futureItem)
      expect(score).toBeGreaterThan(0)
    })
  })

  describe('rankFeedItemsWithScores', () => {
    it('should rank items by computed scores', () => {
      const now = new Date()
      const oneHourAgo = new Date(now.getTime() - 60 * 60 * 1000)
      const oneDayAgo = new Date(now.getTime() - 24 * 60 * 60 * 1000)

      const items: FeedItem[] = [
        createMockPost('old', oneDayAgo),
        createMockEvent('recent', oneHourAgo),
        createMockPost('newest', now)
      ]

      const ranked = rankFeedItemsWithScores(items, mockUserContext)

      // Should be ranked by score (newest first)
      expect(ranked[0].id).toBe('newest')
      expect(ranked[1].id).toBe('recent')
      expect(ranked[2].id).toBe('old')

      // Should have computed ranks
      expect(ranked[0].rank).toBeDefined()
      expect(ranked[1].rank).toBeDefined()
      expect(ranked[2].rank).toBeDefined()

      // Ranks should be in descending order
      expect(ranked[0].rank).toBeGreaterThan(ranked[1].rank!)
      expect(ranked[1].rank).toBeGreaterThan(ranked[2].rank!)
    })

    it('should handle mixed event and post types', () => {
      const now = new Date()
      const oneHourAgo = new Date(now.getTime() - 60 * 60 * 1000)

      const items: FeedItem[] = [
        createMockEvent('event', oneHourAgo),
        createMockPost('post', now)
      ]

      const ranked = rankFeedItemsWithScores(items, mockUserContext)

      // Should rank by score regardless of type
      expect(ranked[0].id).toBe('post') // Newer
      expect(ranked[1].id).toBe('event') // Older
    })
  })

  describe('Edge cases', () => {
    it('should handle items with same timestamp', () => {
      const sameTime = new Date()
      const items: FeedItem[] = [
        createMockEvent('event', sameTime),
        createMockPost('post', sameTime)
      ]

      const ranked = rankFeedItemsWithScores(items, mockUserContext)
      
      // Should maintain stable ordering
      expect(ranked).toHaveLength(2)
      expect(ranked[0].rank).toBe(ranked[1].rank)
    })

    it('should handle very old items', () => {
      const veryOld = new Date(0) // Unix epoch
      const item = createMockPost('ancient', veryOld)
      
      const ranked = rankFeedItemsWithScores([item], mockUserContext)
      
      expect(ranked[0].rank).toBeLessThan(0.1) // Should have very low score
    })
  })
}) 