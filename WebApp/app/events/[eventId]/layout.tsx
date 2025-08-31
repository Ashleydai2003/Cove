import React from 'react';
import type { Metadata } from 'next';
import { getEventData } from '@/lib/api';

type Params = { params: { eventId: string } };

export async function generateMetadata({ params }: Params): Promise<Metadata> {
  const url = `https://www.coveapp.co/events/${params.eventId}`;

  const event = await getEventData(params.eventId);
  const eventName = event?.name || 'event';
  const rawCoverUrl = event?.coverPhoto?.url || '/cove-logo.png';
  const coverUrl = rawCoverUrl.startsWith('http')
    ? rawCoverUrl
    : `https://www.coveapp.co${rawCoverUrl}`;

  const title = `RSVP to ${eventName}`;
  const description = 'cove - events for young alumni';

  return {
    alternates: { canonical: url },
    title,
    description,
    openGraph: {
      url,
      siteName: 'Cove',
      title,
      description,
      images: [{ url: coverUrl, alt: eventName }]
    },
    twitter: {
      card: 'summary_large_image',
      title,
      description,
      images: [coverUrl]
    }
  };
}

export default function EventLayout({ children }: { children: React.ReactNode }) {
  return <>{children}</>;
}
import { getEventData } from '@/lib/api';

type Params = { params: { eventId: string } };

export async function generateMetadata({ params }: Params): Promise<Metadata> {
  const url = `https://www.coveapp.co/events/${params.eventId}`;

  // Fetch event server-side to build rich metadata
  const event = await getEventData(params.eventId);
  const eventName = event?.name || 'event';
  const coverUrl = event?.coverPhoto?.url || '/cove-logo.png';
  const title = `RSVP to ${eventName}`;
  const description = 'cove - events for young alumni';

  return {
    alternates: { canonical: url },
    title,
    description,
    openGraph: {
      url,
      siteName: 'Cove',
      title,
      description,
      images: [
        {
          url: coverUrl,
          alt: eventName
        }
      ]
    },
    twitter: {
      card: 'summary_large_image',
      title,
      description,
      images: [coverUrl]
    }
  };
}

export default function EventLayout({ children }: { children: React.ReactNode }) {
  return <>{children}</>;
}


