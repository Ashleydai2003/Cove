import { NextRequest, NextResponse } from 'next/server';

const BACKEND_URL = process.env.BACKEND_API_URL || process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3001';

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
    const { parsedJson } = body;

    console.log('[Intention API] Request body:', { parsedJson });

    if (!parsedJson) {
      return NextResponse.json(
        { message: 'invalid request: parsedJson required' },
        { status: 400 }
      );
    }

    // Call backend API to submit intention (backend expects "chips" field)
    const backendResponse = await fetch(`${BACKEND_URL}/intention`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${authToken}`,
      },
      body: JSON.stringify({
        chips: parsedJson  // Backend expects "chips" field
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

