# spr25-team-23
[Visit the Wiki](https://github.com/StanfordCS194/spr25-team-23/wiki/Cove-Wiki-Page)



# Cove Feed Architecture

## Goals
- Avoid redundant network requests for cove and event data
- Preload cove details for instant navigation
- Cache per-cove data for smooth UX and smart refresh
- Cleanly separate summary (list) and detail (feed) models

## Key Patterns

### 1. Per-Cove ViewModel Storage
- `CoveFeed` holds a dictionary of `CoveModel` objects, keyed by coveId.
- Use `getOrCreateCoveModel(for:)` to access or create a model for a cove.

### 2. Lazy Preloading
- When a `CoveCardView` appears, call `preloadCoveDetails(for:)` to fetch details in the background.

### 3. Smart Fetching
- Each `CoveModel` tracks its own `lastFetchTime`.
- Use `fetchCoveDetailsIfStale(coveId:)` to only fetch if data is missing or stale (older than 5 minutes).

### 4. Clean Model Separation
- Use `Cove` for summary data in the feed.
- Use `FeedCoveDetails` for full details in the feed view.

### 5. Centralized Event Fetching
- Event fetching logic is centralized in `CoveModel` to avoid duplication.

## Example Usage

```swift
// In CoveFeed
@Published var coveModels: [String: CoveModel] = [:]
func getOrCreateCoveModel(for id: String) -> CoveModel { ... }
func preloadCoveDetails(for id: String) { ... }

// In CoveCardView
.onAppear {
    appController.coveFeed.preloadCoveDetails(for: cove.id)
}

// In FeedView
@ObservedObject var viewModel: CoveModel
.onAppear {
    viewModel.fetchCoveDetailsIfStale(coveId: coveId)
}
```

## Benefits
- No redundant network requests
- Instant transitions between feed and detail
- Per-cove caching and refresh
- Clean, maintainable code

