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
import { apiClient } from '@/lib/api';
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
        console.log('Checking authentication status...');
        const { isAuthenticated, user } = await checkAuthStatus();
        console.log('Auth check result:', { isAuthenticated, user: user ? 'user found' : 'no user' });
        
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

    // Check auth immediately
    checkAuth();
    
    // Also check auth again after a short delay to handle any timing issues
    const timeoutId = setTimeout(checkAuth, 1000);
    
    return () => clearTimeout(timeoutId);
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
      
      const response = await fetch('/api/rsvp-remove', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        credentials: 'include', // Include cookies for authentication
        body: JSON.stringify({
          eventId: event.id,
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

  const handleOnboardingComplete = async (userId: string) => {
    // Refresh authentication status and event data
    try {
      console.log('Onboarding completed, refreshing authentication status...');
      
      // Check authentication status again
      const { isAuthenticated, user } = await checkAuthStatus();
      setIsAuthenticated(isAuthenticated);
      setHasCompletedOnboarding(!!(isAuthenticated && user && !user.onboarding));
      
      // Refresh event data to get updated RSVP status and other details
      const eventData = await apiClient.fetchEvent(event.id);
      setRsvpStatus(eventData.rsvpStatus);
      
      console.log('Page refreshed after login');
    } catch (error) {
      console.error('Error refreshing after login:', error);
      // Fallback: just update the basic auth state
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
                      {event.goingCount !== undefined && event.goingCount !== null 
                        ? `${Math.max(0, event.memberCap - event.goingCount)}/${event.memberCap} spots left`
                        : `${event.memberCap} spots available`
                      }
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
                
                {event.goingCount && event.goingCount > 5 && (
                  <span className="font-libre-bodoni text-sm text-[#2D2D2D]">
                    +{event.goingCount - 5} others going
                  </span>
                )}
              </div>
            </div>
          ) : event.goingCount && event.goingCount > 0 ? (
            <div className="text-center">
              <span className="font-libre-bodoni text-sm text-[#2D2D2D]">
                {event.goingCount} people going
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
                className="px-16 py-4 bg-[#5E1C1D] text-white rounded-lg font-libre-bodoni text-xl font-medium hover:bg-[#4A1718] transition-colors shadow-lg"
              >
                rsvp
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

      {/* RSVP Success Modal */}
      <RSVPSuccessModal
        isOpen={showSuccessModal}
        onClose={() => setShowSuccessModal(false)}
        eventName={event.name}
      />
    </div>
  );
} 