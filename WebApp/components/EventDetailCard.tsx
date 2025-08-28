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

  // Create the hosted by text - show both cove and host if they're different
  const hostedByText = coveName && hostName && coveName !== hostName 
    ? `hosted by ${coveName} & ${hostName}`
    : `hosted by ${coveName || hostName}`;

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

            {/* Price and spots */}
            <div className="flex items-center gap-8">
              {event.ticketPrice !== null && event.ticketPrice !== undefined && (
                <div className="flex items-center gap-3">
                  <div className="w-10 h-6 bg-[#E8E8E8] rounded-sm"></div>
                  <span className="font-libre-bodoni text-base text-[#2D2D2D]">
                    ${event.ticketPrice} per person
                  </span>
                </div>
              )}
              {event.memberCap !== null && event.memberCap !== undefined && (
                <div className="flex items-center gap-3">
                  <div className="w-10 h-6 bg-[#E8E8E8] rounded-sm"></div>
                  <span className="font-libre-bodoni text-base text-[#2D2D2D]">
                    {event.goingCount !== undefined && event.goingCount !== null 
                      ? `${Math.max(0, event.memberCap - event.goingCount)}/${event.memberCap} spots left`
                      : `x/${event.memberCap} spots left`
                    }
                  </span>
                </div>
              )}
              {/* Fallback to placeholders if neither field is set */}
              {(event.ticketPrice === null || event.ticketPrice === undefined) && 
               (event.memberCap === null || event.memberCap === undefined) && (
                <>
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-6 bg-[#E8E8E8] rounded-sm"></div>
                    <span className="font-libre-bodoni text-base text-[#2D2D2D]">$6 per person</span>
                  </div>
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-6 bg-[#E8E8E8] rounded-sm"></div>
                    <span className="font-libre-bodoni text-base text-[#2D2D2D]">x/150 spots left</span>
                  </div>
                </>
              )}
            </div>

            {/* Description */}
            <div className="space-y-4 max-w-md">
              {event.description ? (
                <div className="font-libre-bodoni text-base text-[#2D2D2D] leading-relaxed whitespace-pre-wrap">
                  {event.description}
                </div>
              ) : (
                <>
                  <p className="font-libre-bodoni text-base text-[#2D2D2D]">hey san francisco,</p>
                  <p className="font-libre-bodoni text-base text-[#2D2D2D] leading-relaxed">
                    you're invited to the city's first ever cafe dj set. we've invited the city's hottest djs to spin a set you won't want to miss.
                  </p>
                </>
              )}
              
              {/* Random string from mock */}
              <p className="font-libre-bodoni text-sm text-[#8B8B8B] break-all pt-4">
                xkjnfkjnjknkjsdnfkjsdnfkjsdnfskjdfnks jnf
              </p>
            </div>
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