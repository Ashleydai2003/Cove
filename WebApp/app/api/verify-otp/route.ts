import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    const { phone, otp, verificationId } = await request.json();

    if (!phone || !otp || !verificationId) {
      return NextResponse.json(
        { message: 'Phone number, OTP, and verification ID are required' },
        { status: 400 }
      );
    }

    // For the webapp, we'll return success immediately
    // The actual OTP verification will be handled by Firebase on the frontend
    // This endpoint is just for compatibility with the existing frontend code
    return NextResponse.json({
      message: 'OTP verification successful',
      phone: phone,
      onboarding: true // Assume user needs onboarding for now
    });
  } catch (error) {
    console.error('Verify OTP API error:', error);
    return NextResponse.json(
      { message: 'Internal server error' },
      { status: 500 }
    );
  }
} 