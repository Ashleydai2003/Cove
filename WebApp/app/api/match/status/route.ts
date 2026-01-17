import { NextRequest, NextResponse } from 'next/server';

// GET /api/match/status - Get intention and pool status
export async function GET(request: NextRequest) {
  try {
    const authToken = request.cookies.get('session-token')?.value;

    if (!authToken) {
      return NextResponse.json(
        { message: 'authentication required' },
        { status: 401 }
      );
    }

    // Call backend API to get intention status
    const backendResponse = await fetch(`${process.env.BACKEND_API_URL}/intention/status`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${authToken}`,
      },
    });

    const data = await backendResponse.json();

    if (backendResponse.ok) {
      return NextResponse.json(data);
    } else {
      return NextResponse.json(
        { message: data.message || 'failed to load status' },
        { status: backendResponse.status }
      );
    }
  } catch (error) {
    console.error('Status API error:', error);
    return NextResponse.json(
      { message: 'internal server error' },
      { status: 500 }
    );
  }
}

