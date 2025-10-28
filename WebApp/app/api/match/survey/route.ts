import { NextRequest, NextResponse } from 'next/server';

const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3001';

// GET /api/match/survey - Get user's survey responses
export async function GET(request: NextRequest) {
  try {
    const authToken = request.cookies.get('session-token')?.value;

    if (!authToken) {
      return NextResponse.json(
        { message: 'authentication required' },
        { status: 401 }
      );
    }

    // Call backend API to get survey responses
    const backendResponse = await fetch(`${BACKEND_URL}/survey`, {
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
        { message: data.message || 'failed to load survey' },
        { status: backendResponse.status }
      );
    }
  } catch (error) {
    console.error('Survey API error:', error);
    return NextResponse.json(
      { message: 'internal server error' },
      { status: 500 }
    );
  }
}

// POST /api/match/survey - Submit survey responses
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
    const { responses } = body;

    if (!responses || !Array.isArray(responses)) {
      return NextResponse.json(
        { message: 'invalid request: responses array required' },
        { status: 400 }
      );
    }

    // Call backend API to submit survey
    const backendResponse = await fetch(`${BACKEND_URL}/survey/submit`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${authToken}`,
      },
      body: JSON.stringify({ responses }),
    });

    const data = await backendResponse.json();

    if (backendResponse.ok) {
      return NextResponse.json(data);
    } else {
      return NextResponse.json(
        { message: data.message || 'failed to submit survey' },
        { status: backendResponse.status }
      );
    }
  } catch (error) {
    console.error('Survey submit API error:', error);
    return NextResponse.json(
      { message: 'internal server error' },
      { status: 500 }
    );
  }
}

