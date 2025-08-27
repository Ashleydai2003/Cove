# Cove Web App

A modern web application for sharing and viewing Cove events. Built with Next.js 14, TypeScript, and Tailwind CSS.

## 🌟 Features

- **Event Detail Pages**: Beautiful, responsive event detail pages matching the iOS app design
- **Server-Side Rendering**: Fast loading with SEO optimization
- **Caching Strategy**: Intelligent caching for optimal performance
- **Mobile-First Design**: Responsive design that works on all devices
- **Future RSVP Integration**: Placeholder for web-based authentication and RSVP functionality

## 🚀 Tech Stack

- **Framework**: Next.js 14 with App Router
- **Language**: TypeScript
- **Styling**: Tailwind CSS with custom Cove design system
- **Icons**: Lucide React
- **Date Handling**: date-fns
- **Image Optimization**: Next.js Image component with Sharp
- **Deployment**: Vercel

## 📁 Project Structure

```
WebApp/
├── app/                    # Next.js App Router
│   ├── events/[eventId]/   # Dynamic event pages
│   ├── layout.tsx          # Root layout
│   └── globals.css         # Global styles
├── components/             # Reusable UI components
│   ├── EventDetailCard.tsx # Main event display component
│   ├── LoadingSpinner.tsx  # Loading states
│   └── ErrorMessage.tsx    # Error handling
├── lib/                    # Utilities and configurations
│   ├── api.ts             # API client for backend integration
│   ├── config.ts          # Environment configuration
│   └── utils.ts           # Utility functions
├── types/                  # TypeScript type definitions
│   └── event.ts           # Event-related types
└── public/                # Static assets
```

## 🛠️ Setup Instructions

### 1. Install Dependencies

```bash
cd WebApp
npm install
```

### 2. Environment Configuration

Copy the example environment file and configure your API URL:

```bash
cp env.example .env.local
```

Edit `.env.local`:
```bash
# Production API
BACKEND_API_URL=https://your-api-gateway-url.amazonaws.com/dev
NEXT_PUBLIC_API_URL=https://your-api-gateway-url.amazonaws.com/dev

# Or for local development
# BACKEND_API_URL=http://localhost:3001
# NEXT_PUBLIC_API_URL=http://localhost:3001
```

### 3. Development

```bash
npm run dev
```

Visit `http://localhost:3000/events/[eventId]` to view event pages.

### 4. Build for Production

```bash
npm run build
npm start
```

## 🌐 URL Structure

The web app follows this URL pattern:
- `coveapp.co/events/{eventId}` - Individual event detail pages

## 📱 Design System

The web app maintains visual consistency with the iOS app:

### Colors
- **Primary**: `#B8860B` (Cove brand gold)
- **Primary Dark**: `#8B6914` 
- **Background**: `#FAF8F4` (Warm off-white)
- **Text**: `#292929` (Dark gray)

### Typography
- **Primary Font**: Libre Bodoni (serif)
- **Secondary Font**: League Spartan (sans-serif)

### Components
- **Cards**: Rounded corners with subtle shadows
- **Buttons**: Consistent with iOS app styling
- **Images**: Optimized with Next.js Image component

## 🚀 Deployment (Vercel)

### 1. Connect Repository

1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Click "New Project"
3. Import your repository
4. Set root directory to `WebApp`

### 2. Configure Environment Variables

In Vercel dashboard, add these environment variables:
- `BACKEND_API_URL`: Your production API URL
- `NEXT_PUBLIC_API_URL`: Your production API URL (for client-side requests)

### 3. Configure Build Settings

- **Framework Preset**: Next.js
- **Root Directory**: `WebApp`
- **Build Command**: `npm run build`
- **Output Directory**: `.next` (default)

### 4. Custom Domain

Configure your domain to point to:
- Main domain: `coveapp.co` (your main site)
- Events: `coveapp.co/events/*` (this web app)

## 📈 Performance Optimizations

### Caching Strategy

1. **Static Assets**: Cached by CDN
2. **Event Pages**: 
   - Server-side caching with 60-second revalidation
   - Browser caching for images and static content
3. **API Responses**: Cached based on backend headers

### Image Optimization

- Automatic WebP/AVIF conversion
- Responsive image serving
- Lazy loading for better performance

## 🔮 Future Enhancements

### Authentication & RSVP
- User registration and login
- Web-based RSVP functionality
- Profile management
- Social features

### Additional Features
- Event search and discovery
- Cove browsing
- Event creation (for authenticated users)
- Social sharing improvements

## 🔧 API Integration

The web app integrates with your existing backend using the `/event` endpoint:

```typescript
// Fetches event data for display
GET /event?eventId={eventId}

// Returns either:
// - Limited data (unauthenticated users)
// - Full data (authenticated users with RSVP/host privileges)
```

## 🐛 Troubleshooting

### Common Issues

1. **API Connection Issues**
   - Verify `BACKEND_API_URL` is correct
   - Check CORS settings on backend
   - Ensure API Gateway is accessible

2. **Build Errors**
   - Run `npm run type-check` to identify TypeScript issues
   - Clear `.next` folder and rebuild

3. **Styling Issues**
   - Verify Tailwind CSS is configured correctly
   - Check for conflicting CSS classes

## 📄 License

This project is part of the Cove application suite. 