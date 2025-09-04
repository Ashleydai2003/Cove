import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { eventId, status } = body;

    if (!eventId || !status) {
      return NextResponse.json(
        { message: 'Event ID and status are required' },
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

    // Call the backend API to update RSVP
    const backendResponse = await fetch(`${process.env.BACKEND_API_URL}/update-event-rsvp`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${authToken}`,
      },
      body: JSON.stringify({ eventId, status }),
    });

    const data = await backendResponse.json().catch(() => ({ message: 'Invalid response from backend' }));

    if (backendResponse.ok) {
      return NextResponse.json(data);
    } else {
      return NextResponse.json(
        { message: data.message || 'Failed to update RSVP' },
        { status: backendResponse.status }
      );
    }
  } catch (error) {
    console.error('RSVP API error:', error);
    return NextResponse.json(
      { message: 'Internal server error' },
      { status: 500 }
    );
  }
} 