'use client';

import { useState, useEffect } from 'react';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import { Event } from '@/types/event';
import { apiClient } from '@/lib/api';
import { EventDetailCard } from '@/components/EventDetailCard';
import { LoadingSpinner } from '@/components/LoadingSpinner';
import { ErrorMessage } from '@/components/ErrorMessage';

export default function EventPage() {
  const params = useParams();
  const eventId = params?.eventId as string;
  
  const [event, setEvent] = useState<Event | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!eventId) return;

    const fetchEvent = async () => {
      try {
        setLoading(true);
        setError(null);
        const eventData = await apiClient.fetchEvent(eventId);
        setEvent(eventData);
      } catch (err) {
        console.error('Error fetching event:', err);
        setError(err instanceof Error ? err.message : 'Failed to load event');
      } finally {
        setLoading(false);
      }
    };

    fetchEvent();
  }, [eventId]);

  if (loading) {
    return <LoadingSpinner />;
  }

  if (error) {
    return <ErrorMessage message={error} />;
  }

  if (!event) {
    return <ErrorMessage message="Event not found" />;
  }

  return (
    <div className="min-h-screen bg-faf8f4">
      {/* Top Bar */}
      <div className="w-full max-w-5xl mx-auto px-6 pt-8 flex items-center justify-between">
        <span className="font-libre-bodoni text-3xl text-primary-dark">cove</span>
        <Link href="/" className="font-libre-bodoni text-primary-dark underline underline-offset-4">
          join the waitlist
        </Link>
      </div>

      <div className="max-w-5xl mx-auto px-6 py-8">
        <EventDetailCard event={event} />
      </div>
    </div>
  );
} 