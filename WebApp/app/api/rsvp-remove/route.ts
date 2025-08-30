import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    console.log('=== RSVP REMOVAL API START ===');
    console.log('Request headers:', Object.fromEntries(request.headers.entries()));
    console.log('Request cookies:', request.cookies.getAll());
    
    const body = await request.json();
    console.log('Request body:', body);
    
    const { eventId } = body;
    console.log('Extracted data:', { eventId });
    
    if (!eventId) {
      console.log('Missing required fields:', { eventId });
      return NextResponse.json(
        { message: 'Event ID is required' },
        { status: 400 }
      );
    }

    // Get auth token from cookie
    const authToken = request.cookies.get('session-token')?.value;
    console.log('Auth token present:', !!authToken);

    if (!authToken) {
      console.log('No auth token found in cookies');
      return NextResponse.json(
        { message: 'Authentication required' },
        { status: 401 }
      );
    }

    // Call the backend API to remove RSVP
    console.log('Calling backend RSVP removal endpoint...');
    const rsvpRequestBody = {
      eventId,
    };
    console.log('RSVP removal request body:', rsvpRequestBody);
    
    const backendResponse = await fetch(`${process.env.BACKEND_API_URL}/remove-event-rsvp`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${authToken}`,
      },
      body: JSON.stringify(rsvpRequestBody),
    });

    console.log('Backend RSVP removal response status:', backendResponse.status);
    console.log('Backend RSVP removal response headers:', Object.fromEntries(backendResponse.headers.entries()));
    
    const responseText = await backendResponse.text();
    console.log('Backend RSVP removal response text:', responseText);

    let data;
    try {
      data = JSON.parse(responseText);
      console.log('Backend RSVP removal response data:', data);
    } catch (parseError) {
      console.log('Failed to parse backend response as JSON:', parseError);
      data = { message: 'Invalid response from backend' };
    }
    
    if (backendResponse.ok) {
      console.log('RSVP removal successful, returning data');
      return NextResponse.json(data);
    } else {
      console.log('RSVP removal failed, returning error');
      return NextResponse.json(
        { message: data.message || 'Failed to remove RSVP' },
        { status: backendResponse.status }
      );
    }
  } catch (error) {
    console.error('=== RSVP REMOVAL API ERROR ===');
    console.error('Error type:', typeof error);
    console.error('Error message:', error instanceof Error ? error.message : error);
    console.error('Error stack:', error instanceof Error ? error.stack : 'No stack trace');
    console.error('Full error object:', error);
    
    // Return more detailed error information
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    const errorStack = error instanceof Error ? error.stack : 'No stack trace';
    
    return NextResponse.json(
      { 
        message: 'Internal server error',
        error: errorMessage,
        stack: process.env.NODE_ENV === 'development' ? errorStack : undefined
      },
      { status: 500 }
    );
  }
} 