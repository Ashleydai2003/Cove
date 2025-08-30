import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    const { phone } = await request.json();

    if (!phone) {
      return NextResponse.json(
        { message: 'Phone number is required' },
        { status: 400 }
      );
    }

    // For the webapp, we'll return success immediately
    // The actual OTP sending will be handled by Firebase on the frontend
    // This endpoint is just for compatibility with the existing frontend code
    return NextResponse.json({
      message: 'Phone number received. Please check your phone for the verification code.',
      phone: phone
    });
  } catch (error) {
    console.error('Login API error:', error);
    return NextResponse.json(
      { message: 'Internal server error' },
      { status: 500 }
    );
  }
} 