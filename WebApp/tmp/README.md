# Temporary Endpoint

This folder contains temporary testing endpoints for the Cove web app.

## Available Endpoints

- **`/tmp`** - Main temporary page with image display
- **`/api/placeholder/[width]/[height]`** - Dynamic placeholder image generator

## Usage

1. **Visit the page**: `https://coveapp.co/tmp`
2. **Test placeholder API**: 
   - `https://coveapp.co/api/placeholder/400/300`
   - `https://coveapp.co/api/placeholder/800/600`

## Features

- ✅ Responsive image display
- ✅ Dynamic placeholder image generation
- ✅ URL input for custom images
- ✅ Branded styling matching Cove design

## Files

- `app/tmp/page.tsx` - Main temporary page component
- `app/api/placeholder/[...params]/route.ts` - Placeholder image API
- `tmp/sample-image.svg` - Static sample image
- `tmp/README.md` - This documentation

## Cleanup

This is a temporary endpoint and should be removed when no longer needed.
