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
// Auth is now handled automatically by cookies in API calls
import { apiClient } from '@/lib/api';
import GuestListModal from './GuestListModal';
import RSVPSuccessModal from './RSVPSuccessModal';
import VenmoConfirmModal from './VenmoConfirmModal';

interface EventDetailCardProps {
  event: Event;
  onEventUpdate?: (event: Event) => void;
}

/**
 * API Call Strategy - Only 3 instances:
 * 1. Initial page load (handled in EventDetailCard useEffect)
 * 2. After user login (handleOnboardingComplete)
 * 3. After user RSVP/RSVP removal (handleRSVP/handleRemoveRSVP)
 */

export function EventDetailCard({ event, onEventUpdate }: EventDetailCardProps) {
  const [showOnboarding, setShowOnboarding] = useState(false);
  const [showGuestList, setShowGuestList] = useState(false);
  const [showSuccessModal, setShowSuccessModal] = useState(false);
  const [showVenmoConfirm, setShowVenmoConfirm] = useState(false);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [hasCompletedOnboarding, setHasCompletedOnboarding] = useState(false);
  const [rsvpStatus, setRsvpStatus] = useState<string | null>(event.rsvpStatus ?? null);
  const [isRsvpLoading, setIsRsvpLoading] = useState(false);

  // Fetch fresh event data on mount to get current auth state and complete event details
  useEffect(() => {
    const fetchFreshData = async () => {
      try {
        const eventData = await apiClient.fetchEvent(event.id, true); // Force fresh data
        console.log('Fresh event data:', eventData);

        // Update the entire event object with authenticated data
        if (onEventUpdate) {
          onEventUpdate(eventData);
        }
        setRsvpStatus(eventData.rsvpStatus ?? null);

        // Update authentication state based on the fresh data
        const isUserAuthenticated = eventData.rsvpStatus !== null || !!eventData.isHost;
        setIsAuthenticated(isUserAuthenticated);
        setHasCompletedOnboarding(isUserAuthenticated);
      } catch (error) {
        console.error('Error fetching fresh event data:', error);
        setIsAuthenticated(false);
        setHasCompletedOnboarding(false);
      }
    };

    fetchFreshData();
  }, [event.id]);

  const handleRSVP = async () => {
    // Check if user is authenticated and has completed onboarding
    if (!isAuthenticated || !hasCompletedOnboarding) {
      setShowOnboarding(true);
    } else {
      // User is authenticated and has completed onboarding, proceed with RSVP
      if (rsvpStatus === 'GOING' || rsvpStatus === 'PENDING') {
        // User is already going or pending, no action needed (button should be disabled)
        return;
      } else {
        // Check if event has a ticket price - if so, show Venmo confirmation
        if (event.ticketPrice && event.ticketPrice > 0 && event.paymentHandle) {
          setShowVenmoConfirm(true);
        } else {
          // No payment required, proceed directly with RSVP
          await performRSVP();
        }
      }
    }
  };

  // Check if user can see full event details (RSVP'd, pending, or host)
  const canSeeFullDetails = rsvpStatus === 'GOING' || rsvpStatus === 'PENDING' || event.isHost;

  // Check if user can see Venmo handle (authenticated and completed onboarding)
  const canSeeVenmoHandle = isAuthenticated && hasCompletedOnboarding && event.paymentHandle;



  const performRSVP = async () => {
    setIsRsvpLoading(true);
    try {
      const response = await fetch('/api/rsvp', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        credentials: 'include',
        body: JSON.stringify({
          eventId: event.id,
          status: 'PENDING',
        }),
      });

      if (response.ok) {
        setRsvpStatus('PENDING');
        setShowSuccessModal(true);
        
        // API Call #3: After user RSVP - fetch fresh event data
        console.log('Fetching fresh event data after RSVP...');
        try {
          const eventData = await apiClient.fetchEvent(event.id, true); // Force fresh data
          setRsvpStatus(eventData.rsvpStatus ?? null);
        } catch (refreshError) {
          console.error('Error refreshing event data after RSVP:', refreshError);
        }
      } else {
        const data = await response.json();
        alert(data.message || 'Failed to RSVP');
      }
    } catch (error) {
      console.error('RSVP error:', error);
      alert('Failed to RSVP. Please try again.');
    } finally {
      setIsRsvpLoading(false);
    }
  };

  const performRSVPRemoval = async () => {
    try {
      const response = await fetch('/api/rsvp-remove', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        credentials: 'include',
        body: JSON.stringify({
          eventId: event.id,
        }),
      });

      if (response.ok) {
        setRsvpStatus(null);
        
        // API Call #3: After user RSVP removal - fetch fresh event data
        console.log('Fetching fresh event data after RSVP removal...');
        try {
          const eventData = await apiClient.fetchEvent(event.id, true); // Force fresh data
          setRsvpStatus(eventData.rsvpStatus ?? null);
        } catch (refreshError) {
          console.error('Error refreshing event data after RSVP removal:', refreshError);
        }
      } else {
        const data = await response.json();
        alert(data.message || 'Failed to remove RSVP');
      }
    } catch (error) {
      console.error('RSVP removal error:', error);
      alert('Failed to remove RSVP. Please try again.');
    }
  };

  const handleOnboardingComplete = async (userId: string) => {
    try {
      // Fetch fresh event data to get updated auth state
      const eventData = await apiClient.fetchEvent(event.id, true); // Force fresh data
      setRsvpStatus(eventData.rsvpStatus ?? null);
      setIsAuthenticated(eventData.rsvpStatus !== null || !!eventData.isHost);
      setHasCompletedOnboarding(true);
    } catch (error) {
      console.error('Error refreshing after login:', error);
      // Fallback: update basic auth state
      setIsAuthenticated(true);
      setHasCompletedOnboarding(true);
    }
    
    setShowOnboarding(false);
  };

  const title = event.name || 'Untitled Event';
  const hostName = event.host?.name || '';
  const dateStr = formatDate(event.date);
  const timeStr = formatTime(event.date);
  const coveName = event.cove?.name || '';
  const displayGoingCount = (event.goingCount ?? 0) + 24;

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
        <div className="space-y-8 pr-4">
          <div>
            <h1 className="font-libre-bodoni text-4xl lg:text-5xl text-[#5E1C1D] leading-[0.9] mb-4">
              {title}
            </h1>
            <p className="font-libre-bodoni text-sm text-[#5E1C1D] opacity-50">{hostedByText}</p>
          </div>

          <div className="space-y-6">
            {/* Location or RSVP prompt */}
            {canSeeFullDetails && event.location ? (
              <div className="flex items-center space-x-2">
                <MapPin size={16} className="text-[#8B8B8B]" />
                <span className="font-libre-bodoni text-base text-[#2D2D2D]">
                  {event.location}
                </span>
              </div>
            ) : isAuthenticated && !canSeeFullDetails ? (
              <div className="font-libre-bodoni text-sm text-[#8B8B8B]">
                RSVP to see location
              </div>
            ) : null}

            <div>
              <p className="font-libre-bodoni text-lg font-semibold text-[#2D2D2D]">{dateStr}</p>
              <p className="font-libre-bodoni text-sm text-[#8B8B8B]">{timeStr.replace('AM','am').replace('PM','pm')}</p>
            </div>

            {/* Divider */}
            <div className="h-px w-full bg-[#E5E5E5]"></div>

            {/* Price and spots - only show if data exists */}
            {(event.ticketPrice !== null && event.ticketPrice !== undefined) || 
             (event.memberCap !== null && event.memberCap !== undefined) ? (
              <div className="space-y-4">
                {event.ticketPrice !== null && event.ticketPrice !== undefined && (
                  <div className="flex items-center gap-4">
                    <img src="/ticket.svg" alt="Ticket" className="w-8 h-8" />
                    <span className="font-libre-bodoni text-lg font-semibold text-[#5E1C1D]">
                      ${event.ticketPrice.toFixed(2)} per person
                    </span>
                  </div>
                )}
                {event.memberCap !== null && event.memberCap !== undefined && (
                  <div className="flex items-center gap-4">
                    <img src="/capacity.svg" alt="Capacity" className="w-8 h-8" />
                    <span className="font-libre-bodoni text-lg font-semibold text-[#5E1C1D]">
                      {/* {displayGoingCount !== undefined && displayGoingCount !== null 
                        ? `${Math.max(0, event.memberCap - displayGoingCount)}/${event.memberCap} spots left`
                        : `${event.memberCap} spots available`
                      } */}
                      {displayGoingCount} people going
                    </span>
                  </div>
                )}
                
                {/* Venmo Handle - Only show if authenticated and below price info */}
                {canSeeVenmoHandle && (
                  <div>
                    <p className="font-libre-bodoni text-sm text-[#2D2D2D]">
                      venmo @{event.paymentHandle}
                    </p>
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
          <div className="relative w-full aspect-[4/3] rounded-2xl overflow-hidden">
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

          {/* Guest List Preview */}
          {canSeeFullDetails && event.rsvps && event.rsvps.length > 0 ? (
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <h3 className="font-libre-bodoni text-base text-[#2D2D2D]">guest list</h3>
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
                  {event.rsvps.slice(0, 5).map((rsvp, index) => (
                    <div
                      key={rsvp.id}
                      className="w-10 h-10 rounded-full overflow-hidden border-2 border-white bg-gray-200"
                    >
                      {rsvp.profilePhotoUrl ? (
                        <img
                          src={rsvp.profilePhotoUrl}
                          alt={rsvp.userName}
                          className="w-full h-full object-cover"
                        />
                      ) : (
                        <div className="w-full h-full bg-gray-300 flex items-center justify-center">
                          <User size={14} className="text-gray-500" />
                        </div>
                      )}
                    </div>
                  ))}
                </div>
                
                {displayGoingCount > 5 && (
                  <span className="font-libre-bodoni text-sm text-[#2D2D2D]">
                    +{displayGoingCount - 5} others going
                  </span>
                )}
              </div>
            </div>
          ) : displayGoingCount > 0 ? (
            <div className="text-center">
              <span className="font-libre-bodoni text-sm text-[#2D2D2D]">
                {displayGoingCount} people going
              </span>
              <p className="font-libre-bodoni text-xs text-[#8B8B8B] mt-1">
                RSVP to view guest list!
              </p>
            </div>
          ) : null}



          {/* RSVP button */}
          <div className="flex justify-center">
            {rsvpStatus === 'PENDING' ? (
              <button
                disabled
                className="px-16 py-3 bg-gray-200 text-gray-500 rounded-lg font-libre-bodoni text-lg border border-gray-300 cursor-not-allowed"
              >
                pending approval...
              </button>
            ) : rsvpStatus === 'GOING' ? (
              <button
                disabled
                className="px-16 py-3 bg-[#F5F5F5] text-[#2D2D2D] rounded-lg font-libre-bodoni text-lg border border-[#E5E5E5] cursor-not-allowed"
              >
                you're on the list!
              </button>
            ) : (
              <button
                onClick={handleRSVP}
                disabled={isRsvpLoading}
                className="px-24 py-3 bg-[#5E1C1D] text-white rounded-lg font-libre-bodoni text-xl font-medium hover:bg-[#4A1718] transition-colors shadow-lg disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isRsvpLoading ? 'rsvping...' : 'rsvp'}
              </button>
            )}
          </div>

          {/* Login button - only show when not authenticated */}
          {!isAuthenticated && (
            <div className="flex justify-center mt-4">
              <button
                onClick={() => setShowOnboarding(true)}
                className="font-libre-bodoni text-[#5E1C1D] underline underline-offset-4 hover:text-[#4A1718] transition-colors"
              >
                login
              </button>
            </div>
          )}
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

      {/* Venmo Confirmation Modal */}
      <VenmoConfirmModal
        isOpen={showVenmoConfirm}
        onClose={() => setShowVenmoConfirm(false)}
        onConfirm={async () => {
          setShowVenmoConfirm(false);
          await performRSVP();
        }}
        paymentHandle={event.paymentHandle || ''}
        ticketPrice={event.ticketPrice || 0}
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