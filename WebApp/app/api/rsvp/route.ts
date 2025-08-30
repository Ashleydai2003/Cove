import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    console.log('=== RSVP API START ===');
    console.log('Request headers:', Object.fromEntries(request.headers.entries()));
    console.log('Request cookies:', request.cookies.getAll());
    
    const body = await request.json();
    console.log('Request body:', body);
    
    const { eventId, status } = body;
    console.log('Extracted data:', { eventId, status });

    if (!eventId || !status) {
      console.log('Missing required fields:', { eventId, status });
      return NextResponse.json(
        { message: 'Event ID and status are required' },
        { status: 400 }
      );
    }

    // Get auth token from cookie
    const authToken = request.cookies.get('firebase-token')?.value;
    console.log('Auth token present:', !!authToken);
    console.log('Auth token length:', authToken?.length || 0);

    if (!authToken) {
      console.log('No auth token found in cookies');
      return NextResponse.json(
        { message: 'Authentication required' },
        { status: 401 }
      );
    }

    // Verify authentication and check onboarding status
    console.log('Calling backend profile endpoint...');
    console.log('Backend URL:', process.env.BACKEND_API_URL);
    
    const authResponse = await fetch(`${process.env.BACKEND_API_URL}/profile`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${authToken}`,
      },
    });

    console.log('Auth response status:', authResponse.status);
    console.log('Auth response headers:', Object.fromEntries(authResponse.headers.entries()));

    if (!authResponse.ok) {
      const authErrorText = await authResponse.text();
      console.log('Auth error response:', authErrorText);
      return NextResponse.json(
        { message: 'Authentication required' },
        { status: 401 }
      );
    }

    const authData = await authResponse.json();
    console.log('Auth data received:', authData);
    const user = authData.user;

    // Check if user has completed onboarding
    console.log('User onboarding status:', user.onboarding);
    if (user.onboarding) {
      console.log('User has not completed onboarding');
      return NextResponse.json(
        { message: 'You must complete your profile before RSVPing to events' },
        { status: 403 }
      );
    }

    // Call the backend API to update RSVP
    console.log('Calling backend RSVP update endpoint...');
    const rsvpRequestBody = {
      eventId,
      status,
    };
    console.log('RSVP request body:', rsvpRequestBody);
    
    const backendResponse = await fetch(`${process.env.BACKEND_API_URL}/update-event-rsvp`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${authToken}`,
      },
      body: JSON.stringify(rsvpRequestBody),
    });

    console.log('Backend RSVP response status:', backendResponse.status);
    console.log('Backend RSVP response headers:', Object.fromEntries(backendResponse.headers.entries()));

    const responseText = await backendResponse.text();
    console.log('Backend RSVP response text:', responseText);

    let data;
    try {
      data = JSON.parse(responseText);
      console.log('Backend RSVP response data:', data);
    } catch (parseError) {
      console.log('Failed to parse backend response as JSON:', parseError);
      data = { message: 'Invalid response from backend' };
    }

    if (backendResponse.ok) {
      console.log('RSVP successful, returning data');
      return NextResponse.json(data);
    } else {
      console.log('RSVP failed, returning error');
      return NextResponse.json(
        { message: data.message || 'Failed to update RSVP' },
        { status: backendResponse.status }
      );
    }
  } catch (error) {
    console.error('=== RSVP API ERROR ===');
    console.error('Error type:', typeof error);
    console.error('Error message:', error instanceof Error ? error.message : error);
    console.error('Error stack:', error instanceof Error ? error.stack : 'No stack trace');
    console.error('Full error object:', error);
    return NextResponse.json(
      { message: 'Internal server error' },
      { status: 500 }
    );
  }
} 