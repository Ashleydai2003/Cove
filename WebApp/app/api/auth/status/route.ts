import { NextRequest, NextResponse } from 'next/server';
import { clearSecureSession, validateToken } from '@/lib/session';

export async function GET(request: NextRequest) {
  try {
    console.log('Auth status check - BACKEND_API_URL:', process.env.BACKEND_API_URL);
    
    // Get auth token from cookie
    const authToken = request.cookies.get('session-token')?.value;

    if (!authToken) {
      console.log('No session token found in cookies');
      return NextResponse.json(
        { isAuthenticated: false },
        { status: 401 }
      );
    }

    console.log('Session token found, length:', authToken.length);

    // Validate token format
    if (!validateToken(authToken)) {
      console.log('Invalid token format');
      const response = NextResponse.json(
        { isAuthenticated: false },
        { status: 401 }
      );
      clearSecureSession(response);
      return response;
    }

    console.log('Token format is valid, calling backend...');

    // Call the backend API to verify the token
    const backendResponse = await fetch(`${process.env.BACKEND_API_URL}/profile`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${authToken}`,
      },
    });

    console.log('Backend response status:', backendResponse.status);

    if (backendResponse.ok) {
      const data = await backendResponse.json();
      console.log('Session validated successfully, user data:', data.profile);
      return NextResponse.json({
        isAuthenticated: true,
        user: data.profile,
      });
    } else if (backendResponse.status === 401) {
      // Token is expired or invalid, clear the cookie
      console.log('Backend validation failed (401), clearing session');
      const response = NextResponse.json(
        { isAuthenticated: false },
        { status: 401 }
      );
      clearSecureSession(response);
      return response;
    } else {
      // Other backend errors
      console.log('Backend validation failed with status:', backendResponse.status);
      return NextResponse.json(
        { isAuthenticated: false },
        { status: backendResponse.status }
      );
    }
  } catch (error) {
    console.error('Auth status API error:', error);
    return NextResponse.json(
      { isAuthenticated: false },
      { status: 500 }
    );
  }
} 