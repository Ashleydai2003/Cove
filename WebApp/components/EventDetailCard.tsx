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
  const hostName = event.host?.name || '';
  const dateStr = formatDate(event.date);
  const timeStr = formatTime(event.date);
  const coveName = event.cove?.name || '';

  // Create the hosted by text in the format "hosted by [host] @ [cove]"
  const hostedByText = hostName && coveName 
    ? `hosted by ${hostName} @ ${coveName}`
    : hostName 
    ? `hosted by ${hostName}`
    : coveName 
    ? `hosted by ${coveName}`
    : 'hosted by cove';

  return (
    <div className="w-full">
      {/* Two-column layout */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-20 items-start">
        {/* Left column: text */}
        <div className="space-y-8">
          <div>
            <h1 className="font-libre-bodoni text-5xl lg:text-6xl text-[#5E1C1D] leading-[0.9] mb-4">
              {title}
            </h1>
            <p className="font-libre-bodoni text-base text-[#A8A8A8]">{hostedByText}</p>
          </div>

          <div className="space-y-6">
            <div>
              <p className="font-libre-bodoni text-lg text-[#2D2D2D] font-medium">{dateStr}</p>
              <p className="font-libre-bodoni text-base text-[#8B8B8B]">{timeStr.replace('AM','am').replace('PM','pm')}</p>
            </div>

            {/* Divider */}
            <div className="h-px w-full bg-[#E5E5E5]"></div>

            {/* Price and spots - only show if data exists */}
            {(event.ticketPrice !== null && event.ticketPrice !== undefined) || 
             (event.memberCap !== null && event.memberCap !== undefined) ? (
              <div className="flex items-center gap-8">
                {event.ticketPrice !== null && event.ticketPrice !== undefined && (
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-6 bg-[#E8E8E8] rounded-sm"></div>
                    <span className="font-libre-bodoni text-base text-[#2D2D2D]">
                      ${event.ticketPrice.toFixed(2)} per person
                    </span>
                  </div>
                )}
                {event.memberCap !== null && event.memberCap !== undefined && (
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-6 bg-[#E8E8E8] rounded-sm"></div>
                    <span className="font-libre-bodoni text-base text-[#2D2D2D]">
                      {event.goingCount !== undefined && event.goingCount !== null 
                        ? `${Math.max(0, event.memberCap - event.goingCount)}/${event.memberCap} spots left`
                        : `${event.memberCap} spots available`
                      }
                    </span>
                  </div>
                )}
              </div>
            ) : null}

            {/* Description */}
            {event.description && (
              <div className="space-y-4 max-w-md">
                <div className="font-libre-bodoni text-base text-[#2D2D2D] leading-relaxed whitespace-pre-wrap">
                  {event.description}
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Right column: image + button */}
        <div className="space-y-6">
          {/* Image */}
          <div className="relative w-full aspect-square rounded-2xl overflow-hidden">
            {event.coverPhoto?.url ? (
              <Image
                src={event.coverPhoto.url}
                alt={title}
                fill
                className="object-cover"
                sizes="(max-width: 768px) 100vw, 50vw"
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
              className="px-16 py-3 bg-[#F5F5F5] text-[#2D2D2D] rounded-full font-libre-bodoni text-lg border border-[#E5E5E5] hover:bg-[#EEEEEE] transition-colors"
            >
              rsvp
            </button>
          </div>
        </div>
      </div>
    </div>
  );
} 