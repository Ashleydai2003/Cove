import { NextRequest, NextResponse } from 'next/server';
import { clearSecureSession } from '@/lib/session';

export async function POST(request: NextRequest) {
  try {
    const response = NextResponse.json(
      { message: 'Logged out successfully' },
      { status: 200 }
    );

    // Clear the session token cookie securely
    clearSecureSession(response);

    return response;
  } catch (error) {
    console.error('Logout API error:', error);
    return NextResponse.json(
      { message: 'Internal server error' },
      { status: 500 }
    );
  }
} 