# Cove WebApp Development Guide

This guide will help you set up and run the Cove WebApp locally for development.

## 🚀 Quick Start

### 1. Setup Development Environment

```bash
# Run the development setup script
npm run dev:setup

# Or manually copy the environment template
cp env.local.example .env.local
```

### 2. Configure Environment Variables

Edit `.env.local` with your configuration:

```bash
# Backend API (for local development)
BACKEND_API_URL=http://localhost:3001
NEXT_PUBLIC_API_URL=http://localhost:3001

# Firebase Configuration (Development)
NEXT_PUBLIC_FIREBASE_API_KEY=your-dev-api-key
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN=your-dev-project.firebaseapp.com
NEXT_PUBLIC_FIREBASE_PROJECT_ID=your-dev-project-id
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET=your-dev-project.appspot.com
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID=123456789
NEXT_PUBLIC_FIREBASE_APP_ID=your-dev-app-id

# Development Settings
NODE_ENV=development
NEXT_PUBLIC_IS_DEV=true
```

### 3. Start Backend Server

Make sure your backend is running on localhost:3001:

```bash
cd ../Backend
npm run dev
```

### 4. Start WebApp Development Server

```bash
npm run dev
```

The app will be available at: http://localhost:3000

## 🔧 Development Commands

```bash
npm run dev          # Start development server
npm run dev:setup    # Setup development environment
npm run build        # Build for production
npm run start        # Start production server
npm run lint         # Run ESLint
npm run type-check   # Run TypeScript type checking
```

## 🌍 Environment Configuration

### Development vs Production

- **Development**: Uses `localhost:3001` for backend API
- **Production**: Uses AWS API Gateway URL
- **Environment Detection**: Automatically detects based on `NODE_ENV` and `NEXT_PUBLIC_IS_DEV`

### API URL Resolution

1. **Client-side**: Uses `NEXT_PUBLIC_API_URL`
2. **Server-side**: Uses `BACKEND_API_URL` (falls back to `NEXT_PUBLIC_API_URL`)
3. **Local Development**: Automatically uses `http://localhost:3001`

## 🔍 Troubleshooting

### Common Issues

1. **Backend Connection Failed**
   - Ensure backend is running on localhost:3001
   - Check `BACKEND_API_URL` in `.env.local`

2. **Firebase Authentication Issues**
   - Verify Firebase configuration in `.env.local`
   - Check Firebase console for project settings

3. **Port Already in Use**
   - Change port: `npm run dev -- -p 3001`
   - Kill existing process: `lsof -ti:3000 | xargs kill -9`

### Debug Mode

The app automatically logs development information when `NEXT_PUBLIC_IS_DEV=true`:

- 🔧 Development mode indicators
- 🌐 API URL being used
- 📡 Backend connection status

## 📁 Project Structure

```
WebApp/
├── app/                 # Next.js app directory
├── components/          # React components
├── lib/                 # Utility libraries
├── scripts/             # Development scripts
├── .env.local          # Local environment (create from env.local.example)
├── env.local.example   # Environment template
└── DEVELOPMENT.md      # This file
```

## 🔄 Hot Reload

The development server automatically reloads when you make changes to:
- React components
- API routes
- Configuration files
- Environment variables (requires restart)

## 📱 Testing

- **Browser**: Open http://localhost:3000
- **Mobile**: Use browser dev tools or ngrok for external access
- **API Testing**: Test endpoints at http://localhost:3000/api/*

## 🚀 Deployment

When ready to deploy:

1. Update environment variables for production
2. Run `npm run build`
3. Deploy to your hosting platform
4. Ensure `NEXT_PUBLIC_IS_DEV` is not set to `true`

---

Happy coding! 🎉 