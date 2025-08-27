// CORS utility for Lambda responses
// Ensures consistent CORS headers across all API endpoints

export interface CorsHeaders {
  [header: string]: string | number | boolean;
  'Access-Control-Allow-Origin': string;
  'Access-Control-Allow-Methods': string;
  'Access-Control-Allow-Headers': string;
  'Access-Control-Allow-Credentials': string;
}

/**
 * Gets allowed origins from environment variable with secure defaults
 */
function getAllowedOrigins(): string[] {
  const allowedOrigins = process.env.ALLOWED_ORIGINS?.split(',').map(origin => origin.trim()) || [
    'https://coveapp.co',
    'https://www.coveapp.co',
    'https://api.coveapp.co',
    'capacitor://localhost', // iOS Capacitor
    'ionic://localhost' // Ionic
  ];

  // Add localhost for development/testing only in non-production
  if (process.env.NODE_ENV !== 'production') {
    allowedOrigins.push('http://localhost:3000', 'http://localhost:8080');
  }

  return allowedOrigins;
}

/**
 * Validates if the origin is allowed
 */
function isOriginAllowed(origin: string | undefined): boolean {
  if (!origin) return true; // Allow requests with no origin (mobile apps, server-to-server)
  
  const allowedOrigins = getAllowedOrigins();
  return allowedOrigins.includes(origin);
}

/**
 * Gets appropriate CORS headers for the request origin
 */
export function getCorsHeaders(requestOrigin?: string): CorsHeaders {
  const allowedOrigins = getAllowedOrigins();
  
  // Determine which origin to allow
  let allowOrigin = 'null';
  
  if (!requestOrigin) {
    // No origin provided (mobile apps, server-to-server)
    allowOrigin = '*';
  } else if (isOriginAllowed(requestOrigin)) {
    // Valid origin - echo it back for credentials support
    allowOrigin = requestOrigin;
  }
  // Invalid origins get 'null', effectively blocking the request

  return {
    'Access-Control-Allow-Origin': allowOrigin,
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS, PUT, DELETE',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With',
    'Access-Control-Allow-Credentials': 'true'
  };
}

/**
 * Handles CORS preflight OPTIONS requests
 */
export function handleCorsPreflightRequest(requestOrigin?: string): {
  statusCode: number;
  headers: CorsHeaders;
  body: string;
} {
  const corsHeaders = getCorsHeaders(requestOrigin);
  
  return {
    statusCode: 200,
    headers: corsHeaders,
    body: ''
  };
}

/**
 * Adds CORS headers to any API response
 */
export function addCorsHeaders(response: any, requestOrigin?: string): any {
  const corsHeaders = getCorsHeaders(requestOrigin);
  
  return {
    ...response,
    headers: {
      ...response.headers,
      ...corsHeaders
    }
  };
} 