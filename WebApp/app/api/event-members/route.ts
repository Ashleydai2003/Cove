import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const eventId = searchParams.get('eventId');
    const cursor = searchParams.get('cursor');
    const limit = searchParams.get('limit') || '20';

    if (!eventId) {
      return NextResponse.json(
        { message: 'Event ID is required' },
        { status: 400 }
      );
    }

    // Get auth token from cookie
    const authToken = request.cookies.get('session-token')?.value;

    if (!authToken) {
      return NextResponse.json(
        { message: 'Authentication required' },
        { status: 401 }
      );
    }

    // Build query parameters for backend
    const backendParams = new URLSearchParams({
      eventId,
      limit
    });
    if (cursor) {
      backendParams.append('cursor', cursor);
    }

    // Call the backend API to get event members with pagination
    const backendResponse = await fetch(`${process.env.BACKEND_API_URL}/event-members?${backendParams.toString()}`, {
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
        { message: data.message || 'Failed to load event members' },
        { status: backendResponse.status }
      );
    }
  } catch (error) {
    console.error('Event members API error:', error);
    return NextResponse.json(
      { message: 'Internal server error' },
      { status: 500 }
    );
  }
} 