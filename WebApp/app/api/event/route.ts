import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  console.log('🚨🚨🚨 /api/event/route.ts - GET function called! 🚨🚨🚨');
  try {
    // Get event ID from query parameters
    const { searchParams } = new URL(request.url);
    const eventId = searchParams.get('eventId');

    if (!eventId) {
      return NextResponse.json(
        { message: 'Event ID is required' },
        { status: 400 }
      );
    }

    // Get auth token from cookie
    const authToken = request.cookies.get('session-token')?.value;
    
    // Debug logging
    console.log('Event API - Auth token found:', !!authToken);
    console.log('Event API - Token length:', authToken?.length || 0);
    console.log('Event API - All cookies:', request.cookies.getAll().map(c => c.name));
    console.log('Event API - All cookies with values:', request.cookies.getAll().map(c => ({ name: c.name, value: c.value.substring(0, 20) + '...' })));

    // Prepare headers for backend request
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
    };

    // Add authorization header if token exists
    if (authToken) {
      headers['Authorization'] = `Bearer ${authToken}`;
      console.log('Event API - Authorization header set');
    } else {
      console.log('Event API - No auth token, making unauthenticated request');
    }

    // Call the backend API to get event data
    console.log('Event API - Calling backend with headers:', headers);
    const backendResponse = await fetch(`${process.env.BACKEND_API_URL}/event?eventId=${encodeURIComponent(eventId)}`, {
      method: 'GET',
      headers,
    });
    
    console.log('Event API - Backend response status:', backendResponse.status);

    if (backendResponse.ok) {
      const data = await backendResponse.json();
      
      // Return the event data with appropriate caching headers
      const response = NextResponse.json(data);
      
      // Set caching headers based on authentication status
      if (authToken) {
        response.headers.set('Cache-Control', 'private, no-store');
        response.headers.set('Vary', 'Authorization, Cookie');
      } else {
        response.headers.set('Cache-Control', 'public, max-age=60');
      }
      
      return response;
    } else {
      // Handle different error cases
      if (backendResponse.status === 401) {
        return NextResponse.json(
          { message: 'Authentication required' },
          { status: 401 }
        );
      } else if (backendResponse.status === 404) {
        return NextResponse.json(
          { message: 'Event not found' },
          { status: 404 }
        );
      } else {
        const errorData = await backendResponse.json().catch(() => ({ message: 'Failed to fetch event' }));
        return NextResponse.json(
          { message: errorData.message },
          { status: backendResponse.status }
        );
      }
    }
  } catch (error) {
    console.error('Event API error:', error);
    return NextResponse.json(
      { message: 'Error processing event request' },
      { status: 500 }
    );
  }
} 