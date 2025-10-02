import { NextRequest, NextResponse } from 'next/server';

export async function GET(
  request: NextRequest,
  { params }: { params: { params: string[] } }
) {
  try {
    // Parse dimensions from URL params
    // Expected format: /api/placeholder/400/300
    const [width, height] = params.params;
    
    const w = parseInt(width) || 400;
    const h = parseInt(height) || 300;
    
    // Validate dimensions
    if (w < 1 || w > 2000 || h < 1 || h > 2000) {
      return new NextResponse('Invalid dimensions', { status: 400 });
    }
    
    // Create a simple SVG placeholder
    const svg = `
      <svg width="${w}" height="${h}" xmlns="http://www.w3.org/2000/svg">
        <rect width="100%" height="100%" fill="#f3f4f6"/>
        <rect x="10" y="10" width="${w-20}" height="${h-20}" fill="#e5e7eb" stroke="#d1d5db" stroke-width="2"/>
        <text x="50%" y="50%" text-anchor="middle" dy=".3em" font-family="Arial, sans-serif" font-size="16" fill="#6b7280">
          ${w} × ${h}
        </text>
        <text x="50%" y="60%" text-anchor="middle" dy=".3em" font-family="Arial, sans-serif" font-size="12" fill="#9ca3af">
          Cove Temporary Image
        </text>
      </svg>
    `.trim();
    
    return new NextResponse(svg, {
      headers: {
        'Content-Type': 'image/svg+xml',
        'Cache-Control': 'public, max-age=3600',
      },
    });
    
  } catch (error) {
    console.error('Error generating placeholder:', error);
    return new NextResponse('Error generating image', { status: 500 });
  }
}
