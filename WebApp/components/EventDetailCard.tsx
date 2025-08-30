'use client';

import { useState, useEffect } from 'react';
import { Event } from '@/types/event';
import { formatDate, formatTime } from '@/lib/utils';
import { MapPin, Calendar, User } from 'lucide-react';
import Image from 'next/image';
import dynamic from 'next/dynamic';

// Dynamically import OnboardingModal to avoid Firebase initialization on page load
const OnboardingModal = dynamic(() => import('./OnboardingModal'), {
  ssr: false,
  loading: () => <div>Loading...</div>
});
import { checkAuthStatus } from '@/lib/auth';
import GuestListModal from './GuestListModal';
import RSVPSuccessModal from './RSVPSuccessModal';

interface EventDetailCardProps {
  event: Event;
}

export function EventDetailCard({ event }: EventDetailCardProps) {
  const [showOnboarding, setShowOnboarding] = useState(false);
  const [showGuestList, setShowGuestList] = useState(false);
  const [showSuccessModal, setShowSuccessModal] = useState(false);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [hasCompletedOnboarding, setHasCompletedOnboarding] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [rsvpStatus, setRsvpStatus] = useState(event.rsvpStatus);

  // Check authentication status on component mount
  useEffect(() => {
    const checkAuth = async () => {
      try {
        const { isAuthenticated, user } = await checkAuthStatus();
        setIsAuthenticated(isAuthenticated);
        // Check if user has completed onboarding (not null/undefined and not true means completed)
        setHasCompletedOnboarding(!!(isAuthenticated && user && !user.onboarding));
      } catch (error) {
        console.error('Auth check error:', error);
        setIsAuthenticated(false);
        setHasCompletedOnboarding(false);
      } finally {
        setIsLoading(false);
      }
    };

    checkAuth();
  }, []);

  const handleRSVP = async () => {
    // Check if user is authenticated and has completed onboarding
    if (!isAuthenticated || !hasCompletedOnboarding) {
      setShowOnboarding(true);
    } else {
      // User is authenticated and has completed onboarding, proceed with RSVP
      if (rsvpStatus === 'GOING') {
        await performRSVPRemoval();
      } else {
        await performRSVP();
      }
    }
  };

  // Check if user can see full event details (RSVP'd or host)
  const canSeeFullDetails = rsvpStatus === 'GOING' || event.isHost;

  // Check if user can see Venmo handle (authenticated and completed onboarding)
  const canSeeVenmoHandle = isAuthenticated && hasCompletedOnboarding && event.paymentHandle;

  const performRSVP = async () => {
    try {
      console.log('Attempting RSVP for event:', event.id);
      console.log('User authenticated:', isAuthenticated);
      
      const response = await fetch('/api/rsvp', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        credentials: 'include', // Include cookies for authentication
        body: JSON.stringify({
          eventId: event.id,
          status: 'PENDING',
        }),
      });

      console.log('RSVP response status:', response.status);

      if (response.ok) {
        // Update local RSVP status and show success modal
        setRsvpStatus('PENDING');
        setShowSuccessModal(true);
      } else {
        const data = await response.json();
        console.log('RSVP error response:', data);
        alert(data.message || 'Failed to RSVP');
      }
    } catch (error) {
      console.error('RSVP error:', error);
      alert('Failed to RSVP. Please try again.');
    }
  };

  const performRSVPRemoval = async () => {
    try {
      console.log('Removing RSVP for event:', event.id);
      
      const response = await fetch('/api/rsvp', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        credentials: 'include', // Include cookies for authentication
        body: JSON.stringify({
          eventId: event.id,
          status: 'NOT_GOING',
        }),
      });

      console.log('RSVP removal response status:', response.status);

      if (response.ok) {
        // Update local RSVP status
        setRsvpStatus(null);
      } else {
        const data = await response.json();
        console.log('RSVP removal error response:', data);
        alert(data.message || 'Failed to remove RSVP');
      }
    } catch (error) {
      console.error('RSVP removal error:', error);
      alert('Failed to remove RSVP. Please try again.');
    }
  };

  const handleOnboardingComplete = (userId: string) => {
    setIsAuthenticated(true);
    setHasCompletedOnboarding(true);
    setShowOnboarding(false);
    // Automatically perform the RSVP action
    performRSVP();
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

            {/* Location - Only show if user can see full details */}
            {canSeeFullDetails && event.location && (
              <div className="space-y-4 max-w-md">
                <div className="flex items-center space-x-2">
                  <MapPin size={16} className="text-[#8B8B8B]" />
                  <span className="font-libre-bodoni text-base text-[#2D2D2D]">
                    {event.location}
                  </span>
                </div>
              </div>
            )}

            {/* RSVP Status Info - Only show if authenticated but not RSVP'd */}
            {isAuthenticated && !canSeeFullDetails && (
              <div className="space-y-4 max-w-md">
                <div className="font-libre-bodoni text-base text-[#8B8B8B]">
                  RSVP to see location and guest list
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

          {/* Guest List Preview - Only show if user can see full details */}
          {canSeeFullDetails && event.rsvps && event.rsvps.length > 0 && (
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <h3 className="font-libre-bodoni text-lg text-[#2D2D2D]">guest list</h3>
                <button
                  onClick={() => setShowGuestList(true)}
                  className="text-[#5E1C1D] underline underline-offset-4 text-sm"
                >
                  view all
                </button>
              </div>
              
              {/* Guest preview avatars */}
              <div className="flex items-center space-x-3">
                <div className="flex -space-x-2">
                  {event.rsvps.slice(0, 6).map((rsvp, index) => (
                    <div
                      key={rsvp.id}
                      className="w-12 h-12 rounded-full overflow-hidden border-2 border-white bg-gray-200"
                    >
                      {rsvp.profilePhotoUrl ? (
                        <img
                          src={rsvp.profilePhotoUrl}
                          alt={rsvp.userName}
                          className="w-full h-full object-cover"
                        />
                      ) : (
                        <div className="w-full h-full bg-gray-300 flex items-center justify-center">
                          <User size={16} className="text-gray-500" />
                        </div>
                      )}
                    </div>
                  ))}
                </div>
                
                {event.goingCount && event.goingCount > 6 && (
                  <span className="font-libre-bodoni text-sm text-[#8B8B8B]">
                    +{event.goingCount - 6} others going
                  </span>
                )}
              </div>
            </div>
          )}

          {/* Venmo Handle - Only show if authenticated */}
          {canSeeVenmoHandle && (
            <div className="text-center">
              <p className="font-libre-bodoni text-sm text-[#2D2D2D]">
                venmo @{event.paymentHandle}
              </p>
            </div>
          )}

          {/* RSVP button */}
          <div className="flex justify-center">
            {rsvpStatus === 'PENDING' ? (
              <button
                disabled
                className="px-16 py-3 bg-gray-200 text-gray-500 rounded-full font-libre-bodoni text-lg border border-gray-300 cursor-not-allowed"
              >
                pending approval...
              </button>
            ) : rsvpStatus === 'GOING' ? (
              <button
                onClick={handleRSVP}
                className="px-16 py-3 bg-[#F5F5F5] text-[#2D2D2D] rounded-full font-libre-bodoni text-lg border border-[#E5E5E5] hover:bg-[#EEEEEE] transition-colors"
              >
                can't make it...
              </button>
            ) : (
              <button
                onClick={handleRSVP}
                className="px-16 py-3 bg-[#F5F5F5] text-[#2D2D2D] rounded-full font-libre-bodoni text-lg border border-[#E5E5E5] hover:bg-[#EEEEEE] transition-colors"
              >
                rsvp
              </button>
            )}
          </div>
        </div>
      </div>

      {/* Onboarding Modal */}
      <OnboardingModal
        isOpen={showOnboarding}
        onClose={() => setShowOnboarding(false)}
        onComplete={handleOnboardingComplete}
        originalAction="RSVP to this event"
      />

      {/* Guest List Modal */}
      <GuestListModal
        isOpen={showGuestList}
        onClose={() => setShowGuestList(false)}
        eventId={event.id}
      />

      {/* RSVP Success Modal */}
      <RSVPSuccessModal
        isOpen={showSuccessModal}
        onClose={() => setShowSuccessModal(false)}
        eventName={event.name}
      />
    </div>
  );
} 