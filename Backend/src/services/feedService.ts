// feedService.ts - Data access and processing for feed items

import { PrismaClient } from '@prisma/client'
import { rankFeedItemsWithScores, FeedItem, UserContext } from '../ranking/feedRanker'

export interface FeedServiceOptions {
  limit: number
  cursor?: string
  types: string[]
  userId: string
}

export interface FeedResponse {
  items: any[]
  pagination: {
    hasMore: boolean
    nextCursor: string | null
  }
}

export class FeedService {
  constructor(private prisma: PrismaClient) {}

  /**
   * Fetches and ranks feed items for a user.
   */
  async getFeedItems(options: FeedServiceOptions): Promise<FeedResponse> {
    const { limit, cursor, types, userId } = options
    
    // Fetch raw data from database
    const rawItems = await this.fetchRawItems(types, userId)
    
    // Convert to FeedItem format for ranking
    const feedItems: FeedItem[] = rawItems.map(item => ({
      kind: item.type,
      id: item.id,
      ts: item.type === 'event' ? new Date(item.data.date) : new Date(item.data.createdAt),
      rank: item.rank
    }))
    
    // Apply ranking algorithm
    const userContext: UserContext = { userId }
    const rankedItems = rankFeedItemsWithScores(feedItems, userContext)
    
    // Apply pagination
    const paginatedItems = this.applyPagination(rankedItems, limit, cursor)
    
    // Convert back to API response format
    const responseItems = this.convertToResponseFormat(rankedItems, rawItems)
    
    return {
      items: responseItems,
      pagination: {
        hasMore: rankedItems.length > limit,
        nextCursor: rankedItems.length > limit ? rankedItems[limit - 1].id : null
      }
    }
  }

  /**
   * Fetches raw items from database based on requested types.
   */
  private async fetchRawItems(types: string[], userId: string): Promise<any[]> {
    const items: any[] = []
    
    // Fetch events if requested
    if (types.includes('event')) {
      const events = await this.prisma.event.findMany({
        where: {
          cove: {
            members: {
              some: { userId }
            }
          }
        },
        include: {
          rsvps: { where: { userId } },
          hostedBy: { select: { id: true, name: true } },
          cove: { select: { id: true, name: true, coverPhotoID: true } },
          coverPhoto: { select: { id: true } }
        },
        orderBy: { date: 'asc' }
      })
      
      items.push(...events.map(event => ({
        type: 'event',
        id: event.id,
        data: event,
        rank: 0.987 // Placeholder rank
      })))
    }
    
    // Fetch posts if requested
    if (types.includes('post')) {
      const posts = await this.prisma.post.findMany({
        where: {
          cove: {
            members: {
              some: { userId }
            }
          }
        },
        include: {
          likes: { where: { userId } },
          author: { select: { id: true, name: true, profilePhotoID: true } },
          cove: { select: { id: true, name: true } }
        },
        orderBy: { createdAt: 'desc' }
      })
      
      items.push(...posts.map(post => ({
        type: 'post',
        id: post.id,
        data: post,
        rank: 0.945 // Placeholder rank
      })))
    }
    
    return items
  }

  /**
   * Applies pagination to ranked items.
   */
  private applyPagination(items: FeedItem[], limit: number, cursor?: string): FeedItem[] {
    let startIndex = 0
    
    if (cursor) {
      const cursorIndex = items.findIndex(item => item.id === cursor)
      if (cursorIndex !== -1 && cursorIndex < items.length - 1) {
        startIndex = cursorIndex + 1
      }
    }
    
    return items.slice(startIndex, startIndex + limit)
  }

  /**
   * Converts ranked items back to API response format.
   */
  private convertToResponseFormat(rankedItems: FeedItem[], rawItems: any[]): any[] {
    return rankedItems.map(rankedItem => {
      const rawItem = rawItems.find(item => item.id === rankedItem.id)
      if (!rawItem) return null
      
      return {
        kind: rawItem.type,
        id: rawItem.id,
        rank: rankedItem.rank,
        [rawItem.type]: rawItem.data
      }
    }).filter(Boolean)
  }
} 