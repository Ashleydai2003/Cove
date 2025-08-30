import { NextRequest, NextResponse } from 'next/server';
import { setSecureSession, validateToken, checkRateLimit } from '@/lib/session';

export async function POST(request: NextRequest) {
  try {
    // Rate limiting
    const clientIP = request.headers.get('x-forwarded-for') || 
                    request.headers.get('x-real-ip') || 
                    'unknown';
    const rateLimit = checkRateLimit(`refresh:${clientIP}`);
    
    if (!rateLimit.allowed) {
      return NextResponse.json(
        { message: 'Too many refresh attempts. Please try again later.' },
        { status: 429 }
      );
    }

    const { idToken } = await request.json();

    if (!idToken) {
      return NextResponse.json(
        { message: 'Firebase ID token is required' },
        { status: 400 }
      );
    }

    // Validate token format
    if (!validateToken(idToken)) {
      return NextResponse.json(
        { message: 'Invalid token format' },
        { status: 400 }
      );
    }

    // Call the backend API to validate the new token
    const backendResponse = await fetch(`${process.env.BACKEND_API_URL}/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${idToken}`,
      },
    });

    if (backendResponse.ok) {
      // Update the session cookie with the new token
      const response = NextResponse.json({ success: true });
      
      setSecureSession(response, idToken);

      return response;
    } else {
      return NextResponse.json(
        { message: 'Token validation failed' },
        { status: 401 }
      );
    }
  } catch (error) {
    console.error('Token refresh error:', error);
    return NextResponse.json(
      { message: 'Internal server error' },
      { status: 500 }
    );
  }
} 