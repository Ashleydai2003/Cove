// Configuration for environment variables
export const config = {
  apiUrl: (() => {
    if (typeof window !== 'undefined') {
      // Client-side: use NEXT_PUBLIC_ prefixed variable
      return process.env.NEXT_PUBLIC_API_URL || '';
    } else {
      // Server-side: can use regular env variables
      return process.env.BACKEND_API_URL || process.env.NEXT_PUBLIC_API_URL || '';
    }
  })(),
  
  isDevelopment: process.env.NODE_ENV === 'development',
  isProduction: process.env.NODE_ENV === 'production',
  isLocalDev: process.env.NEXT_PUBLIC_IS_DEV === 'true',
} as const;

// Validate required configuration
if (!config.apiUrl && typeof window === 'undefined') {
  console.warn('API URL not configured. Set BACKEND_API_URL or NEXT_PUBLIC_API_URL environment variable.');
}

// Development helpers
export const isLocalDevelopment = () => {
  return config.isDevelopment && config.isLocalDev;
};

export const getApiUrl = () => {
  if (isLocalDevelopment()) {
    console.log('🔧 Running in local development mode');
    console.log('🌐 API URL:', config.apiUrl);
  }
  return config.apiUrl;
}; 