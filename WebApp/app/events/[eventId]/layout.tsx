import React from 'react';
import type { Metadata } from 'next';
import { getEventData } from '@/lib/api';

type Params = { params: { eventId: string } };

export async function generateMetadata({ params }: Params): Promise<Metadata> {
  const url = `https://www.coveapp.co/events/${params.eventId}`;

  const event = await getEventData(params.eventId);
  const eventName = event?.name || 'event';
  // Use same-origin proxy for OG images to avoid hotlink/protection issues
  const coverUrl = `https://www.coveapp.co/api/og-image/${params.eventId}`;

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
      images: [{ url: coverUrl, secureUrl: coverUrl, width: 1200, height: 630, alt: eventName }]
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
