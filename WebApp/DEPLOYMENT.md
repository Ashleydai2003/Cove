# Cove Web App Deployment Guide

This guide walks you through deploying the Cove web app to Vercel for the URL structure `coveapp.co/events/<event_id>`.

## Prerequisites

- Vercel account
- Access to your domain DNS settings
- Backend API deployed and accessible

## Step 1: Prepare for Deployment

### 1.1 Install Dependencies
```bash
cd WebApp
npm install
```

### 1.2 Test Locally
```bash
# Copy environment file
cp env.example .env.local

# Edit .env.local with your API URL
# BACKEND_API_URL=https://your-api-gateway-url.amazonaws.com/dev
# NEXT_PUBLIC_API_URL=https://your-api-gateway-url.amazonaws.com/dev

# Test the app
npm run dev
```

### 1.3 Verify Backend Integration

Make sure your backend `/event` endpoint:
- Accepts unauthenticated requests
- Returns proper CORS headers
- Handles the event ID parameter correctly

Test with: `https://your-api-gateway-url.amazonaws.com/dev/event?eventId=your-test-event-id`

## Step 2: Deploy to Vercel

### 2.1 Connect Repository

1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Click "New Project"
3. Import your GitHub repository
4. **Important**: Set root directory to `WebApp`

### 2.2 Configure Build Settings

- **Framework Preset**: Next.js
- **Root Directory**: `WebApp`
- **Build Command**: `npm run build`
- **Output Directory**: `.next` (default)
- **Install Command**: `npm install`

### 2.3 Add Environment Variables

In the Vercel project settings, add:
- `BACKEND_API_URL`: `https://your-api-gateway-url.amazonaws.com/dev`
- `NEXT_PUBLIC_API_URL`: `https://your-api-gateway-url.amazonaws.com/dev`

### 2.4 Deploy

Click "Deploy" and wait for the build to complete.

## Step 3: Configure Custom Domain

### 3.1 Add Domain to Vercel

1. In Vercel project settings, go to "Domains"
2. Add your domain: `coveapp.co`
3. Vercel will provide DNS configuration instructions

### 3.2 Configure DNS

In your domain registrar's DNS settings:

**Option A: Use Vercel's nameservers (Recommended)**
- Point your domain's nameservers to Vercel's
- Vercel will handle all DNS automatically

**Option B: CNAME/A Records**
- Add CNAME record: `coveapp.co` → `cname.vercel-dns.com`
- Add A record: `coveapp.co` → Vercel's IP addresses

### 3.3 Verify Domain

- Wait for DNS propagation (can take up to 48 hours)
- Test: `https://coveapp.co/events/your-test-event-id`

## Step 4: Performance and SEO Optimization

### 4.1 Caching Configuration

The app includes automatic caching:
- **Static assets**: 1 year cache
- **Event pages**: 60-second cache with stale-while-revalidate
- **API responses**: Respects backend cache headers

### 4.2 Meta Tags and SEO

Each event page automatically generates:
- Dynamic page titles
- Meta descriptions
- Open Graph tags for social sharing
- Twitter Card metadata

### 4.3 Performance Monitoring

Monitor your app performance in:
- Vercel Analytics (built-in)
- Vercel Speed Insights
- Google PageSpeed Insights

## Step 5: Testing and Verification

### 5.1 Test Event URLs

Verify these work:
- `https://coveapp.co/events/valid-event-id` (should show event)
- `https://coveapp.co/events/invalid-id` (should show error)

### 5.2 Test Social Sharing

Share an event URL on:
- Twitter/X
- Facebook  
- LinkedIn
- Discord/Slack

Verify the preview cards show properly.

### 5.3 Test Performance

- Run Lighthouse audit
- Test on mobile devices
- Verify loading times < 3 seconds

## Step 6: Monitoring and Maintenance

### 6.1 Set Up Monitoring

- Enable Vercel Analytics
- Set up error tracking (Sentry recommended)
- Monitor API performance

### 6.2 Update Process

Future updates:
```bash
# Make changes
git add .
git commit -m "Update web app"
git push origin main

# Vercel auto-deploys from main branch
```

### 6.3 Rollback Process

If issues occur:
1. Go to Vercel Dashboard
2. Select your project
3. Go to "Deployments" 
4. Click "..." on a previous deployment
5. Select "Promote to Production"

## Troubleshooting

### Common Issues

**Build Fails**
- Check TypeScript errors: `npm run type-check`
- Verify all dependencies are installed
- Check environment variables are set

**404 Errors**
- Verify DNS configuration
- Check domain settings in Vercel
- Ensure root directory is set to `WebApp`

**API Connection Issues**
- Test API endpoint directly
- Check CORS settings
- Verify environment variables

**Slow Loading**
- Check API response times
- Verify caching headers
- Monitor Vercel Analytics

### Support

For deployment issues:
- Check Vercel documentation
- Contact Vercel support
- Review Vercel deployment logs

For app-specific issues:
- Check browser console for errors
- Review network tab for API calls
- Test with different event IDs 