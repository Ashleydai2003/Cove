import { NextResponse } from 'next/server';

// Secure session configuration
const SESSION_CONFIG = {
  name: 'session-token',
  maxAge: 60 * 60 * 24 * 7, // 7 days
  httpOnly: true,
  secure: process.env.NODE_ENV === 'production',
  sameSite: 'lax' as const, // Changed from 'strict' to 'lax' for better compatibility
  path: '/',
  // Don't set domain in production - let it default to the current domain
  // This allows cookies to work on any deployment domain (Vercel, custom domains, etc.)
  domain: undefined,
};

// Rate limiting configuration
const RATE_LIMIT = {
  windowMs: 15 * 60 * 1000, // 15 minutes
  maxRequests: 100, // Max 100 requests per window
};

// Store for rate limiting (in production, use Redis or similar)
const rateLimitStore = new Map<string, { count: number; resetTime: number }>();

export function setSecureSession(response: NextResponse, token: string): NextResponse {
  response.cookies.set(SESSION_CONFIG.name, token, {
    httpOnly: SESSION_CONFIG.httpOnly,
    secure: SESSION_CONFIG.secure,
    sameSite: SESSION_CONFIG.sameSite,
    maxAge: SESSION_CONFIG.maxAge,
    path: SESSION_CONFIG.path,
    domain: SESSION_CONFIG.domain,
  });
  return response;
}

export function clearSecureSession(response: NextResponse): NextResponse {
  response.cookies.set(SESSION_CONFIG.name, '', {
    httpOnly: SESSION_CONFIG.httpOnly,
    secure: SESSION_CONFIG.secure,
    sameSite: SESSION_CONFIG.sameSite,
    maxAge: 0, // Expire immediately
    path: SESSION_CONFIG.path,
    domain: SESSION_CONFIG.domain,
  });
  return response;
}

export function validateToken(token: string): boolean {
  // Basic token validation
  if (!token || typeof token !== 'string') {
    return false;
  }
  
  // Firebase ID tokens are JWTs with 3 parts separated by dots
  const parts = token.split('.');
  if (parts.length !== 3) {
    return false;
  }
  
  // Check if token is not too short (basic sanity check)
  if (token.length < 100) {
    return false;
  }
  
  return true;
}

export function checkRateLimit(identifier: string): { allowed: boolean; remaining: number } {
  const now = Date.now();
  const windowStart = now - RATE_LIMIT.windowMs;
  
  const current = rateLimitStore.get(identifier);
  
  if (!current || current.resetTime < windowStart) {
    // Reset or create new entry
    rateLimitStore.set(identifier, {
      count: 1,
      resetTime: now,
    });
    return { allowed: true, remaining: RATE_LIMIT.maxRequests - 1 };
  }
  
  if (current.count >= RATE_LIMIT.maxRequests) {
    return { allowed: false, remaining: 0 };
  }
  
  // Increment count
  current.count++;
  rateLimitStore.set(identifier, current);
  
  return { allowed: true, remaining: RATE_LIMIT.maxRequests - current.count };
}

// Clean up old rate limit entries periodically
setInterval(() => {
  const now = Date.now();
  const windowStart = now - RATE_LIMIT.windowMs;
  
  rateLimitStore.forEach((value, key) => {
    if (value.resetTime < windowStart) {
      rateLimitStore.delete(key);
    }
  });
}, RATE_LIMIT.windowMs);

export { SESSION_CONFIG, RATE_LIMIT }; 