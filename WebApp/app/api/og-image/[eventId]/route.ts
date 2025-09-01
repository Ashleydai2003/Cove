import { NextRequest, NextResponse } from 'next/server';

export const revalidate = 60; // cache for 1 minute at the edge

export async function GET(
  _req: NextRequest,
  { params }: { params: { eventId: string } }
) {
  try {
    const backendUrl = `${process.env.BACKEND_API_URL}/event?eventId=${encodeURIComponent(params.eventId)}`;
    const res = await fetch(backendUrl, { next: { revalidate: 60 } });
    if (!res.ok) {
      return NextResponse.redirect(new URL('/cove-logo.png', 'https://www.coveapp.co'));
    }

    const data = await res.json();
    const coverUrl: string | undefined = data?.event?.coverPhoto?.url;

    if (!coverUrl) {
      return NextResponse.redirect(new URL('/cove-logo.png', 'https://www.coveapp.co'));
    }

    const imageRes = await fetch(coverUrl);
    if (!imageRes.ok) {
      return NextResponse.redirect(new URL('/cove-logo.png', 'https://www.coveapp.co'));
    }

    // Stream the image bytes through our domain
    const contentType = imageRes.headers.get('content-type') || 'image/jpeg';
    const arrayBuffer = await imageRes.arrayBuffer();
    return new NextResponse(arrayBuffer, {
      status: 200,
      headers: {
        'Content-Type': contentType,
        'Cache-Control': 'public, max-age=60, s-maxage=300',
      },
    });
  } catch (e) {
    return NextResponse.redirect(new URL('/cove-logo.png', 'https://www.coveapp.co'));
  }
}


