'use client';

import { useState, useEffect } from 'react';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import { Event } from '@/types/event';
import { apiClient } from '@/lib/api';
import { EventDetailCard } from '@/components/EventDetailCard';

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
    return (
      <div className="min-h-screen bg-faf8f4 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-dark mx-auto mb-4"></div>
          <p className="font-libre-bodoni text-primary-dark">Loading event...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-faf8f4 flex items-center justify-center">
        <div className="text-center max-w-md mx-auto px-6">
          <h2 className="font-libre-bodoni text-2xl font-semibold text-primary-dark mb-4">
            {error.includes('not found') ? 'Event not found' : 'Something went wrong'}
          </h2>
          <p className="font-libre-bodoni text-lg text-k6F6F73 mb-6">{error}</p>
          <Link href="/" className="font-libre-bodoni text-primary-dark underline underline-offset-4">
            Back to home
          </Link>
        </div>
      </div>
    );
  }

  if (!event) {
    return (
      <div className="min-h-screen bg-faf8f4 flex items-center justify-center">
        <div className="text-center max-w-md mx-auto px-6">
          <h2 className="font-libre-bodoni text-2xl font-semibold text-primary-dark mb-4">Event not found</h2>
          <p className="font-libre-bodoni text-lg text-k6F6F73 mb-6">This event may have been deleted or the link is incorrect.</p>
          <Link href="/" className="font-libre-bodoni text-primary-dark underline underline-offset-4">
            Back to home
          </Link>
        </div>
      </div>
    );
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