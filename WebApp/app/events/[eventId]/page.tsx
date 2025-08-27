'use client';

import { useState, useEffect } from 'react';
import { useParams } from 'next/navigation';
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
      {/* Cove Logo in top corner */}
      <div className="absolute top-6 left-6 z-10">
        <img
          src="/cove-logo.svg"
          alt="Cove"
          className="w-12 h-12"
        />
      </div>
      
      <div className="max-w-2xl mx-auto px-4 py-8">
        <EventDetailCard event={event} />
      </div>
    </div>
  );
} 