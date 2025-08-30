import { NextRequest, NextResponse } from 'next/server';
import { clearSecureSession, validateToken } from '@/lib/session';

export async function GET(request: NextRequest) {
  try {
    // Get auth token from cookie
    const authToken = request.cookies.get('session-token')?.value;

    if (!authToken) {
      return NextResponse.json(
        { isAuthenticated: false },
        { status: 401 }
      );
    }

    // Validate token format
    if (!validateToken(authToken)) {
      const response = NextResponse.json(
        { isAuthenticated: false },
        { status: 401 }
      );
      clearSecureSession(response);
      return response;
    }

    // Call the backend API to verify the token and get user info
    const backendResponse = await fetch(`${process.env.BACKEND_API_URL}/profile`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${authToken}`,
      },
    });

    if (backendResponse.ok) {
      const data = await backendResponse.json();
      return NextResponse.json({
        isAuthenticated: true,
        user: data.user,
      });
    } else {
      // Token is invalid, clear the cookie
      const response = NextResponse.json(
        { isAuthenticated: false },
        { status: 401 }
      );
      clearSecureSession(response);
      return response;
    }
  } catch (error) {
    console.error('Auth status API error:', error);
    return NextResponse.json(
      { isAuthenticated: false },
      { status: 500 }
    );
  }
} 