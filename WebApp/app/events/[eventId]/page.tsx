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
      <div className="min-h-screen bg-[#F5F0E6] flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#5E1C1D] mx-auto mb-6"></div>
          <p className="font-libre-bodoni text-xl text-[#5E1C1D] mb-2">Loading event...</p>
          <p className="font-libre-bodoni text-sm text-[#8B8B8B]">Getting everything ready for you</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-[#F5F0E6] flex items-center justify-center">
        <div className="text-center max-w-md mx-auto px-6">
          <h2 className="font-libre-bodoni text-2xl font-semibold text-[#5E1C1D] mb-4">
            {error.includes('not found') ? 'Event not found' : 'Something went wrong'}
          </h2>
          <p className="font-libre-bodoni text-lg text-[#8B8B8B] mb-6">{error}</p>
          <Link href="/" className="font-libre-bodoni text-[#5E1C1D] underline underline-offset-4">
            Back to home
          </Link>
        </div>
      </div>
    );
  }

  if (!event) {
    return (
      <div className="min-h-screen bg-[#F5F0E6] flex items-center justify-center">
        <div className="text-center max-w-md mx-auto px-6">
          <h2 className="font-libre-bodoni text-2xl font-semibold text-[#5E1C1D] mb-4">Event not found</h2>
          <p className="font-libre-bodoni text-lg text-[#8B8B8B] mb-6">This event may have been deleted or the link is incorrect.</p>
          <Link href="/" className="font-libre-bodoni text-[#5E1C1D] underline underline-offset-4">
            Back to home
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#F5F0E6]">
      {/* Top Bar */}
      <div className="w-full px-8 pt-8 pb-12">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <span className="font-libre-bodoni text-3xl text-[#5E1C1D]">cove</span>
          <Link href="/" className="font-libre-bodoni text-[#5E1C1D] underline underline-offset-4 text-lg">
            join the waitlist
          </Link>
        </div>
      </div>

      {/* Event Content */}
      <div className="max-w-7xl mx-auto px-8 pb-16">
        <EventDetailCard 
          event={event} 
          onEventUpdate={(updatedEvent) => setEvent(updatedEvent)}
        />
      </div>
    </div>
  );
} 