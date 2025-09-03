import { NextRequest, NextResponse } from 'next/server';
import { setSecureSession, validateToken } from '@/lib/session';

export async function POST(request: NextRequest) {
  try {
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

    // Verify the token with the backend
    const backendResponse = await fetch(`${process.env.BACKEND_API_URL}/profile`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${idToken}`,
      },
    });

    if (backendResponse.ok) {
      // Token is valid, update the session
      const response = NextResponse.json({ message: 'Token refreshed successfully' });
      setSecureSession(response, idToken);
      return response;
    } else {
      return NextResponse.json(
        { message: 'Invalid token' },
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