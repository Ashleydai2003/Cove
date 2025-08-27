import { ImageResponse } from 'next/og';
import { getEventData } from '@/lib/api';

export const runtime = 'edge';
export const alt = 'Cove Event';
export const size = {
  width: 1200,
  height: 630,
};

export const contentType = 'image/png';

export default async function Image({ params }: { params: { eventId: string } }) {
  const event = await getEventData(params.eventId);

  if (!event) {
    return new ImageResponse(
      (
        <div
          style={{
            fontSize: 60,
            background: '#FAF8F4',
            width: '100%',
            height: '100%',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            flexDirection: 'column',
            color: '#8B6914',
          }}
        >
          <div style={{ marginBottom: 20 }}>🏡</div>
          <div>Event Not Found</div>
          <div style={{ fontSize: 30, marginTop: 20 }}>Cove</div>
        </div>
      ),
      {
        ...size,
      }
    );
  }

  return new ImageResponse(
    (
      <div
        style={{
          fontSize: 48,
          background: '#FAF8F4',
          width: '100%',
          height: '100%',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          flexDirection: 'column',
          color: '#8B6914',
          padding: 60,
        }}
      >
        <div
          style={{
            fontSize: 72,
            fontWeight: 'bold',
            marginBottom: 30,
            textAlign: 'center',
            lineHeight: 1.2,
          }}
        >
          {event.name}
        </div>
        {event.description && (
          <div
            style={{
              fontSize: 32,
              marginBottom: 40,
              textAlign: 'center',
              color: '#292929',
              maxWidth: '80%',
            }}
          >
            {event.description.substring(0, 120)}
            {event.description.length > 120 ? '...' : ''}
          </div>
        )}
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            fontSize: 28,
            color: '#292929',
          }}
        >
          <span style={{ marginRight: 20 }}>📅</span>
          <span>{new Date(event.date).toLocaleDateString()}</span>
        </div>
        <div
          style={{
            position: 'absolute',
            bottom: 40,
            right: 60,
            fontSize: 36,
            fontWeight: 'bold',
          }}
        >
          Cove
        </div>
      </div>
    ),
    {
      ...size,
    }
  );
} 