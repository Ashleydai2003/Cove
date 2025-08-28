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
  const coveName = event.cove?.name || 'cove';

  return (
    <div className="max-w-5xl mx-auto">
      {/* Two-column layout */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-16 items-start">
        {/* Left column: text */}
        <div>
          <h1 className="font-libre-bodoni text-5xl md:text-6xl text-primary-dark leading-tight mb-6">
            {title}
          </h1>

          <p className="mb-8 font-libre-bodoni text-lg text-k6F6F73">hosted by {coveName}</p>

          <div className="space-y-6">
            <div>
              <p className="font-libre-bodoni text-xl text-k171719 mb-1">{dateStr}</p>
              <p className="font-libre-bodoni text-lg text-k6F6F73">{timeStr.replace('AM','am').replace('PM','pm')}</p>
            </div>

            {/* Divider */}
            <div className="h-px w-full bg-k262627/20 my-8"></div>

            {/* Price and spots placeholders */}
            <div className="flex items-center gap-8">
              <div className="flex items-center gap-3">
                <div className="w-12 h-8 bg-f3f3f3 rounded"></div>
                <span className="font-libre-bodoni text-lg text-primary-dark">$6 per person</span>
              </div>
              <div className="flex items-center gap-3">
                <div className="w-12 h-8 bg-f3f3f3 rounded"></div>
                <span className="font-libre-bodoni text-lg text-primary-dark">x/150 spots left</span>
              </div>
            </div>

            {/* Description */}
            <div className="mt-8 space-y-4 max-w-lg">
              {event.description ? (
                <div className="font-libre-bodoni text-lg text-k171719 leading-relaxed whitespace-pre-wrap">
                  {event.description}
                </div>
              ) : (
                <>
                  <p className="font-libre-bodoni text-lg text-k171719">hey san francisco,</p>
                  <p className="font-libre-bodoni text-lg text-k171719 leading-relaxed">
                    you're invited to the city's first ever cafe dj set. we've invited the city's hottest djs to spin a set you won't want to miss.
                  </p>
                </>
              )}
              
              {/* Random string from mock - keeping as placeholder */}
              <p className="font-libre-bodoni text-sm text-k6F6F73 mt-6 break-all">
                xkjnfkjnjknkjsdnfkjsdnfkjsdnfskjdfnks jnf
              </p>
            </div>
          </div>
        </div>

        {/* Right column: image + button */}
        <div>
          {/* Image */}
          <div className="relative w-full h-96 rounded-2xl overflow-hidden mb-8">
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
          <div className="flex justify-center">
            <button
              onClick={handleRSVP}
              className="px-20 py-4 bg-white text-primary-dark rounded-2xl border border-gray-200 font-libre-bodoni text-xl hover:shadow-sm transition-shadow"
            >
              rsvp
            </button>
          </div>
        </div>
      </div>
    </div>
  );
} 