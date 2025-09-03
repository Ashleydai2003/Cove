import { NextRequest, NextResponse } from 'next/server';

export async function GET(
  request: NextRequest,
  { params }: { params: { coveId: string } }
) {
  try {
    const { coveId } = params;

    if (!coveId) {
      return NextResponse.json(
        { message: 'Cove ID is required' },
        { status: 400 }
      );
    }

    // Call the backend API to get cove events
    const backendResponse = await fetch(`${process.env.BACKEND_API_URL}/cove-events?coveId=${encodeURIComponent(coveId)}&limit=6`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    });

    if (!backendResponse.ok) {
      if (backendResponse.status === 404) {
        return NextResponse.json(
          { message: 'Cove not found' },
          { status: 404 }
        );
      }
      
      console.error('Backend error:', backendResponse.status, backendResponse.statusText);
      return NextResponse.json(
        { message: 'Failed to fetch cove events' },
        { status: backendResponse.status }
      );
    }

    const data = await backendResponse.json();
    return NextResponse.json(data);
  } catch (error) {
    console.error('Error fetching cove events:', error);
    return NextResponse.json(
      { message: 'Internal server error' },
      { status: 500 }
    );
  }
} 