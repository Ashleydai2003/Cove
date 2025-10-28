import { NextRequest, NextResponse } from 'next/server';

const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3001';

// POST /api/match/intention - Submit intention
export async function POST(request: NextRequest) {
  try {
    const authToken = request.cookies.get('session-token')?.value;

    if (!authToken) {
      return NextResponse.json(
        { message: 'authentication required' },
        { status: 401 }
      );
    }

    const body = await request.json();
    const { activities, timeWindows, vibe, notes } = body;

    if (!activities || !Array.isArray(activities) || activities.length === 0) {
      return NextResponse.json(
        { message: 'invalid request: activities required' },
        { status: 400 }
      );
    }

    if (!timeWindows || !Array.isArray(timeWindows) || timeWindows.length === 0) {
      return NextResponse.json(
        { message: 'invalid request: time windows required' },
        { status: 400 }
      );
    }

    // Call backend API to submit intention
    const backendResponse = await fetch(`${process.env.BACKEND_API_URL}/intention/submit`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${authToken}`,
      },
      body: JSON.stringify({
        activities,
        timeWindows,
        vibe: vibe || [],
        notes: notes || ''
      }),
    });

    const data = await backendResponse.json();

    if (backendResponse.ok) {
      return NextResponse.json(data);
    } else {
      return NextResponse.json(
        { message: data.message || 'failed to submit intention' },
        { status: backendResponse.status }
      );
    }
  } catch (error) {
    console.error('Intention submit API error:', error);
    return NextResponse.json(
      { message: 'internal server error' },
      { status: 500 }
    );
  }
}

