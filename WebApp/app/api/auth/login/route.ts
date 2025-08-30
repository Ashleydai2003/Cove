import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    const { idToken } = await request.json();

    if (!idToken) {
      return NextResponse.json(
        { message: 'Firebase ID token is required' },
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
      
      // Set the Firebase ID token as an HTTP-only cookie for future requests
      response.cookies.set('firebase-token', idToken, {
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'lax',
        maxAge: 60 * 60 * 24 * 7, // 7 days
      });

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