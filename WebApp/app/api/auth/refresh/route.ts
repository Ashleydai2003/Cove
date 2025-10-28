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
    const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3001';
    const backendResponse = await fetch(`${BACKEND_URL}/profile`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${idToken}`,
      },
    });

    if (backendResponse.ok) {
      // Get user profile data
      const userData = await backendResponse.json();
      
      // Token is valid, update the session
      const response = NextResponse.json({ 
        message: 'Token refreshed successfully',
        user: {
          uid: userData.uid || userData.id,
          onboarding: userData.onboarding || false
        }
      });
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