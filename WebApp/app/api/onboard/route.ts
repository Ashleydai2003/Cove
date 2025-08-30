import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { name, birthdate, almaMater, gradYear, hobbies, bio, city } = body;

    // Validate required fields
    const requiredFields = [];
    if (!name || name.trim() === '') requiredFields.push('name');
    if (!birthdate) requiredFields.push('birthdate');
    if (!almaMater || almaMater.trim() === '') requiredFields.push('almaMater');
    if (!gradYear || gradYear.trim() === '') requiredFields.push('gradYear');

    if (requiredFields.length > 0) {
      return NextResponse.json(
        { message: `Missing required fields: ${requiredFields.join(', ')}` },
        { status: 400 }
      );
    }

    // Get auth token from cookie
    const authToken = request.cookies.get('auth-token')?.value;

    if (!authToken) {
      return NextResponse.json(
        { message: 'Authentication required' },
        { status: 401 }
      );
    }

    // Call the backend API to complete onboarding
    const backendResponse = await fetch(`${process.env.API_BASE_URL}/onboard`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${authToken}`,
      },
      body: JSON.stringify({
        name: name.trim(),
        birthdate,
        almaMater: almaMater.trim(),
        gradYear: gradYear.trim(),
        hobbies: hobbies || [],
        bio: bio || '',
        city: city || '',
      }),
    });

    const data = await backendResponse.json();

    if (backendResponse.ok) {
      return NextResponse.json(data);
    } else {
      return NextResponse.json(
        { message: data.message || 'Failed to complete onboarding' },
        { status: backendResponse.status }
      );
    }
  } catch (error) {
    console.error('Onboard API error:', error);
    return NextResponse.json(
      { message: 'Internal server error' },
      { status: 500 }
    );
  }
} 