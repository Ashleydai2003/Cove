'use client';

import { Event } from '@/types/event';
import { formatDate, formatTime } from '@/lib/utils';
import { MapPin, Calendar, User } from 'lucide-react';
import Image from 'next/image';

interface EventDetailCardProps {
  event: Event;
}

export function EventDetailCard({ event }: EventDetailCardProps) {
  const handleRSVP = () => {
    alert('RSVP functionality coming soon!');
  };

  const title = event.name || 'Untitled Event';
  const hostName = event.host?.name || 'cove';
  const dateStr = formatDate(event.date);
  const timeStr = formatTime(event.date);

  return (
    <div className="bg-white rounded-2xl shadow-cove p-6 md:p-10">
      {/* Two-column layout */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-10 items-start">
        {/* Left column: text */}
        <div>
          <h1 className="font-libre-bodoni text-4xl md:text-5xl text-primary-dark leading-tight">
            {title}
          </h1>

          <p className="mt-3 font-libre-bodoni text-k6F6F73">hosted by cove &amp; cheminé</p>

          <div className="mt-8 space-y-3">
            <div>
              <p className="font-libre-bodoni text-k171719">saturday, september 6th</p>
              <p className="font-libre-bodoni text-k6F6F73">{timeStr.replace('AM','am').replace('PM','pm')}</p>
            </div>

            {/* Divider */}
            <div className="h-px w-full bg-k262627/30 my-4"></div>

            {/* Price and spots placeholders */}
            <div className="flex items-center gap-6">
              <div className="flex items-center gap-3">
                <div className="w-10 h-6 bg-f3f3f3 rounded"></div>
                <span className="font-libre-bodoni text-primary-dark">$6 per person</span>
              </div>
              <div className="flex items-center gap-3">
                <div className="w-10 h-6 bg-f3f3f3 rounded"></div>
                <span className="font-libre-bodoni text-primary-dark">x/150 spots left</span>
              </div>
            </div>

            {/* Description */}
            <div className="mt-6 space-y-3 max-w-md">
              <p className="font-libre-bodoni text-k171719">hey san francisco,</p>
              <p className="font-libre-bodoni text-k171719">
                you’re invited to the city’s first ever cafe dj set. we’ve invited the city’s hottest djs to spin a set you won’t want to miss.
              </p>
            </div>
          </div>
        </div>

        {/* Right column: image + button */}
        <div>
          {/* Image */}
          <div className="relative w-full h-80 rounded-xl overflow-hidden">
            {event.coverPhoto?.url ? (
              <Image
                src={event.coverPhoto.url}
                alt={title}
                fill
                className="object-cover"
                sizes="(max-width: 768px) 100vw, 640px"
                priority
              />
            ) : (
              <div className="w-full h-full bg-gray-200" />
            )}
          </div>

          {/* RSVP button */}
          <div className="mt-6 flex justify-center">
            <button
              onClick={handleRSVP}
              className="px-16 py-4 bg-white text-primary-dark rounded-xl shadow-cove font-libre-bodoni text-2xl"
            >
              rsvp
            </button>
          </div>
        </div>
      </div>
    </div>
  );
} 