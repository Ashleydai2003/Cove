# Feed Ranking Architecture

This directory contains the feed ranking system for the Cove application.

## Architecture Overview

The feed system is designed with separation of concerns and future scalability in mind:

```
src/
├── routes/
│   └── feed.ts          # Thin route handler - validates input, calls service
├── services/
│   └── feedService.ts   # Data access layer - fetches from DB, calls ranker
├── ranking/
│   ├── feedRanker.ts    # Pure ranking algorithm
│   ├── feedRanker.test.ts # Unit tests
│   └── README.md        # This file
```

## Components

### 1. FeedRanker (`feedRanker.ts`)
**Pure function module** - no side effects, no database calls.

**Current Algorithm:**
- Simple time-based ranking (newest first)
- Exponential decay scoring for relevance
- Handles both events and posts uniformly

**Future Extensions:**
- Engagement-based scoring (likes, RSVPs, comments)
- User preference weighting
- Machine learning model integration
- Real-time feature incorporation

### 2. FeedService (`feedService.ts`)
**Data access layer** - handles database queries and data transformation.

**Responsibilities:**
- Fetches raw data from Prisma
- Converts to FeedItem format for ranking
- Applies pagination
- Converts back to API response format

### 3. Feed Route (`routes/feed.ts`)
**Thin route handler** - validates input, calls service, formats response.

**Responsibilities:**
- Request validation
- Authentication
- Service orchestration
- S3 URL generation
- Response formatting

## Current Ranking Algorithm

### Simple Time-Based Ranking
```typescript
// Events: ranked by event date (earliest first)
// Posts: ranked by creation date (newest first)
// Mixed: simple time-based ordering
```

### Scoring Function
```typescript
score = Math.exp(-hoursAgo / 24) // Exponential decay over 24 hours
```

## Future Enhancements

### Phase 1: Engagement Scoring
```typescript
score = α * freshness + β * engagement + γ * relevance
```

### Phase 2: User Context
```typescript
interface UserContext {
  userId: string
  followedCoves: string[]
  friends: string[]
  preferences: UserPreferences
}
```

### Phase 3: Machine Learning
```typescript
// Replace scoring function with ML model
score = mlModel.predict(item, userContext)
```

## Testing

Run tests with:
```bash
npm test                    # Run all tests
npm run test:watch         # Watch mode
npm test feedRanker.test.ts # Run specific test file
```

## Monitoring

Future monitoring points:
- Log top-N item IDs and scores per request
- Track ranking algorithm performance
- A/B test different algorithms
- Monitor user engagement with ranked items

## Migration Path

1. **Current**: Simple time-based ranking
2. **Next**: Add engagement metrics (likes, RSVPs)
3. **Future**: ML model integration
4. **Advanced**: Real-time features, personalization

The architecture is designed to make each transition seamless with minimal code changes. 