import { NextRequest, NextResponse } from 'next/server';
import { cookies } from 'next/headers';

const BACKEND_URL = process.env.BACKEND_API_URL || process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3001';

export async function POST(request: NextRequest) {
  try {
    const cookieStore = cookies();
    const sessionToken = cookieStore.get('session-token');

    if (!sessionToken) {
      return NextResponse.json(
        { message: 'unauthorized' },
        { status: 401 }
      );
    }

    // Forward request to backend
    const response = await fetch(`${BACKEND_URL}/match/accept`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${sessionToken.value}`,
        'Content-Type': 'application/json'
      }
    });

    const data = await response.json();

    if (!response.ok) {
      return NextResponse.json(
        { message: data.message || 'failed to accept match' },
        { status: response.status }
      );
    }

    return NextResponse.json(data);
  } catch (error) {
    console.error('Error accepting match:', error);
    return NextResponse.json(
      { message: 'internal server error' },
      { status: 500 }
    );
  }
}

