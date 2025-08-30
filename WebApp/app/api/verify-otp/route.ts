import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    const { phone, otp } = await request.json();

    if (!phone || !otp) {
      return NextResponse.json(
        { message: 'Phone number and OTP are required' },
        { status: 400 }
      );
    }

    // Call the backend API to verify OTP
    const backendResponse = await fetch(`${process.env.API_BASE_URL}/verify-otp`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ phone, otp }),
    });

    const data = await backendResponse.json();

    if (backendResponse.ok) {
      // Set authentication cookie
      const response = NextResponse.json(data);
      
      // Set the auth token as an HTTP-only cookie
      if (data.token) {
        response.cookies.set('auth-token', data.token, {
          httpOnly: true,
          secure: process.env.NODE_ENV === 'production',
          sameSite: 'lax',
          maxAge: 60 * 60 * 24 * 7, // 7 days
        });
      }

      return response;
    } else {
      return NextResponse.json(
        { message: data.message || 'Invalid OTP' },
        { status: backendResponse.status }
      );
    }
  } catch (error) {
    console.error('Verify OTP API error:', error);
    return NextResponse.json(
      { message: 'Internal server error' },
      { status: 500 }
    );
  }
} 