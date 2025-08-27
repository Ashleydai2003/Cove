'use client';

import { Event } from '@/types/event';
import { formatDate, formatTime } from '@/lib/utils';
import { MapPin, Calendar, User, Users } from 'lucide-react';
import Image from 'next/image';

interface EventDetailCardProps {
  event: Event;
}

export function EventDetailCard({ event }: EventDetailCardProps) {
  const handleRSVP = () => {
    // TODO: Implement authentication flow and RSVP
    alert('RSVP functionality coming soon! Sign up for the mobile app at coveapp.co');
  };

  const isAuthenticated = false; // TODO: Check authentication status
  const userRSVPStatus = event.rsvpStatus;
  const isGoing = userRSVPStatus === 'GOING';
  
  // Filter RSVPs to only show "GOING" status
  const goingRsvps = event.rsvps?.filter(rsvp => rsvp.status === 'GOING') || [];

  return (
    <div className="card max-w-2xl mx-auto">
      {/* Header with cove image */}
      <div className="flex justify-center mb-6">
        {event.cove?.coverPhoto?.url ? (
          <div className="relative w-24 h-24 rounded-full overflow-hidden">
            <Image
              src={event.cove.coverPhoto.url}
              alt={`${event.cove.name || 'Cove'} cover`}
              fill
              className="object-cover"
              sizes="96px"
            />
          </div>
        ) : (
          <div className="w-24 h-24 rounded-full bg-gray-200 flex items-center justify-center">
            <Users className="w-8 h-8 text-gray-400" />
          </div>
        )}
      </div>

      {/* Event title */}
      <h1 className="text-headline font-libre-bodoni font-bold text-center text-primary-dark mb-6">
        {event.name || 'Untitled Event'}
      </h1>

      {/* Event cover photo */}
      {event.coverPhoto?.url ? (
        <div className="relative w-full h-80 rounded-xl overflow-hidden mb-6">
          <Image
            src={event.coverPhoto.url}
            alt={event.name}
            fill
            className="object-cover"
            sizes="(max-width: 768px) 100vw, 768px"
            priority
          />
        </div>
      ) : (
        <div className="w-full h-80 rounded-xl bg-gray-200 flex items-center justify-center mb-6">
          <Calendar className="w-12 h-12 text-gray-400" />
        </div>
      )}

      {/* Event details */}
      <div className="space-y-4 mb-6">
        {/* Date and Time */}
        <div className="flex justify-between items-center">
          <div className="flex items-center space-x-2">
            <Calendar className="w-5 h-5 text-primary-dark" />
            <span className="font-libre-bodoni text-lg">
              {formatDate(event.date)}
            </span>
          </div>
          <span className="font-libre-bodoni text-lg text-primary-dark">
            {formatTime(event.date)}
          </span>
        </div>

        {/* Location */}
        <div className="flex items-start space-x-2">
          <MapPin className="w-5 h-5 text-primary-dark mt-0.5 flex-shrink-0" />
          <span className="font-libre-bodoni font-semibold text-primary-dark">
            {event.location || (isAuthenticated ? 'TBD' : 'RSVP to see location')}
          </span>
        </div>

        {/* Host */}
        <div className="flex items-center space-x-2">
          <User className="w-5 h-5 text-primary-dark" />
          <span className="font-libre-bodoni text-lg">
            hosted by{' '}
            <span className="text-primary-dark font-semibold">
              {event.host.name}
            </span>
          </span>
        </div>
      </div>

      {/* Description */}
      {event.description && (
        <div className="mb-6">
          <p className="font-libre-bodoni text-lg text-k292929 leading-relaxed">
            {event.description}
          </p>
        </div>
      )}

      {/* Guest List */}
      <div className="mb-8">
        <h3 className="font-libre-bodoni text-lg text-primary-dark mb-3">
          guest list
        </h3>
        
        {isAuthenticated && event.rsvps ? (
          goingRsvps.length === 0 ? (
            <p className="font-libre-bodoni text-sm text-primary-dark">
              no guests yet! send your invites!
            </p>
          ) : (
            <div className="flex space-x-2">
              {/* Show up to 4 profile photos */}
              {goingRsvps.slice(0, 4).map((rsvp) => (
                <div
                  key={rsvp.id}
                  className="relative w-16 h-16 rounded-full overflow-hidden bg-gray-200"
                >
                  {rsvp.profilePhotoUrl ? (
                    <Image
                      src={rsvp.profilePhotoUrl}
                      alt={rsvp.userName}
                      fill
                      className="object-cover"
                      sizes="64px"
                    />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center">
                      <User className="w-6 h-6 text-gray-400" />
                    </div>
                  )}
                </div>
              ))}
              
              {/* Show "+X" if there are more than 4 people */}
              {goingRsvps.length > 4 && (
                <div className="w-16 h-16 rounded-full border border-primary-dark flex items-center justify-center">
                  <span className="font-libre-bodoni font-bold text-xs text-primary-dark">
                    +{goingRsvps.length - 4}
                  </span>
                </div>
              )}
            </div>
          )
        ) : (
          <p className="font-libre-bodoni text-sm text-primary-dark">
            RSVP to see guest list
          </p>
        )}
      </div>

      {/* RSVP Button */}
      <button
        onClick={handleRSVP}
        className={`w-full py-4 rounded-xl font-libre-bodoni text-xl font-medium transition-all duration-200 ${
          isGoing
            ? 'bg-white text-primary-dark border border-primary-dark shadow-cove hover:shadow-cove-hover'
            : 'bg-primary-dark text-white shadow-cove hover:shadow-cove-hover'
        }`}
      >
        {isGoing ? "can't make it..." : 'rsvp'}
      </button>
    </div>
  );
} 