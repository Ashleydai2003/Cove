import { NextRequest, NextResponse } from 'next/server';
import { setSecureSession, validateToken, checkRateLimit } from '@/lib/session';

export async function POST(request: NextRequest) {
  try {
    // Rate limiting
    const clientIP = request.headers.get('x-forwarded-for') || 
                    request.headers.get('x-real-ip') || 
                    'unknown';
    const rateLimit = checkRateLimit(`login:${clientIP}`);
    
    if (!rateLimit.allowed) {
      return NextResponse.json(
        { message: 'Too many login attempts. Please try again later.' },
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

    // Call the backend API with the Firebase ID token
    const backendResponse = await fetch(`${process.env.BACKEND_API_URL}/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${idToken}`,
      },
    });

    const data = await backendResponse.json();

    if (backendResponse.ok) {
      // Set authentication cookie
      const response = NextResponse.json(data);
      
      // Set secure session cookie
      setSecureSession(response, idToken);

      return response;
    } else {
      return NextResponse.json(
        { message: data.message || 'Backend authentication failed' },
        { status: backendResponse.status }
      );
    }
  } catch (error) {
    console.error('Backend login API error:', error);
    return NextResponse.json(
      { message: 'Internal server error' },
      { status: 500 }
    );
  }
} 