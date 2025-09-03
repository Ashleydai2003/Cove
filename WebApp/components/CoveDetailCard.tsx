'use client';

import { useState, useEffect } from 'react';
import Image from 'next/image';

interface Cove {
  id: string;
  name: string;
  description: string;
  location: string;
  createdAt: string;
  creator: {
    id: string;
    name: string;
  };
  coverPhoto: {
    id: string;
    url: string;
  } | null;
  stats: {
    memberCount: number;
    eventCount: number;
  };
}

interface CoveDetailCardProps {
  cove: Cove;
  isAuthenticated: boolean | null;
}

export default function CoveDetailCard({ cove, isAuthenticated }: CoveDetailCardProps) {
  const [showJoinModal, setShowJoinModal] = useState(false);
  const [events, setEvents] = useState<{
    id: string;
    name: string;
    description: string;
    date: string;
    coveCoverPhoto: { id: string; url: string } | null;
    hostName: string;
    coverPhoto: { id: string; url: string } | null;
  }[]>([]);
  const [loadingEvents, setLoadingEvents] = useState(false);

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    });
  };

  const formatEventDate = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric'
    });
  };

  const formatEventTime = (dateString: string) => {
    const date = new Date(dateString);
    return date.toLocaleTimeString('en-US', {
      hour: 'numeric',
      minute: '2-digit',
      hour12: true
    });
  };

  // Fetch events for this cove
  useEffect(() => {
    const fetchEvents = async () => {
      try {
        setLoadingEvents(true);
        const response = await fetch(`/api/coves/${cove.id}/events`);
        if (response.ok) {
          const data = await response.json();
          setEvents(data.events || []);
        }
      } catch (error) {
        console.error('Error fetching events:', error);
      } finally {
        setLoadingEvents(false);
      }
    };

    fetchEvents();
  }, [cove.id]);

  const handleJoinCove = () => {
    if (!isAuthenticated) {
      // Redirect to login or show login modal
      window.location.href = '/login';
      return;
    }
    setShowJoinModal(true);
  };

  const handleShare = async () => {
    const shareUrl = `${window.location.origin}/coves/${cove.id}`;
    
    if (navigator.share) {
      try {
        await navigator.share({
          title: `Join ${cove.name} on Cove`,
          text: `Check out this cove: ${cove.name}`,
          url: shareUrl,
        });
      } catch (error) {
        console.log('Error sharing:', error);
      }
    } else {
      // Fallback: copy to clipboard
      try {
        await navigator.clipboard.writeText(shareUrl);
        alert('Link copied to clipboard!');
      } catch (error) {
        console.error('Failed to copy:', error);
        // Fallback: show the URL
        prompt('Copy this link:', shareUrl);
      }
    }
  };

  return (
    <div>
      {/* Cove Header - Instagram-style */}
      <div className="mb-12">
        {/* Cover Photo */}
        <div className="flex justify-center mb-8">
          <div className="relative w-32 h-32 md:w-40 md:h-40 rounded-2xl overflow-hidden">
            {cove.coverPhoto ? (
              <Image
                src={cove.coverPhoto.url}
                alt={cove.name}
                fill
                className="object-cover"
                sizes="(max-width: 768px) 128px, 160px"
                priority
              />
            ) : (
              <div className="w-full h-full bg-gradient-to-br from-blue-400 to-purple-600 flex items-center justify-center">
                <div className="text-center">
                  <div className="text-4xl md:text-5xl mb-2">🏠</div>
                  <h2 className="font-libre-bodoni text-sm md:text-base text-white font-bold leading-tight">
                    {cove.name}
                  </h2>
                </div>
              </div>
            )}
          </div>
        </div>

        {/* Cove Info Section - Clean & Balanced */}
        <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8">
          {/* Main Info */}
          <div className="text-center mb-8 sm:mb-12">
            <h1 className="font-libre-bodoni text-3xl sm:text-4xl lg:text-5xl text-[#5E1C1D] leading-[0.9] mb-3 sm:mb-4">
              {cove.name}
            </h1>
            <p className="font-libre-bodoni text-base sm:text-lg text-[#8B8B8B] mb-4 sm:mb-6">
              created by {cove.creator.name}
              {cove.location && (
                <span className="block sm:inline sm:ml-4 mt-1 sm:mt-0">
                  • {cove.location}
                </span>
              )}
            </p>
            
            {/* Stats Row */}
            <div className="flex flex-col sm:flex-row justify-center items-center gap-8 sm:gap-16 mb-6 sm:mb-8">
              <div className="text-center">
                <div className="font-libre-bodoni text-3xl sm:text-4xl font-bold text-[#5E1C1D]">
                  {cove.stats.memberCount}
                </div>
                <div className="font-libre-bodoni text-xs sm:text-sm text-[#8B8B8B] uppercase tracking-wide">
                  Members
                </div>
              </div>
              <div className="hidden sm:block w-px h-16 bg-[#E5E5E5]"></div>
              <div className="text-center">
                <div className="font-libre-bodoni text-3xl sm:text-4xl font-bold text-[#5E1C1D]">
                  {cove.stats.eventCount}
                </div>
                <div className="font-libre-bodoni text-xs sm:text-sm text-[#8B8B8B] uppercase tracking-wide">
                  Events
                </div>
              </div>
            </div>

            {/* Description */}
            {cove.description && (
              <div className="max-w-3xl mx-auto mb-6 sm:mb-8 px-4">
                <p className="font-libre-bodoni text-base sm:text-lg text-[#2D2D2D] leading-relaxed text-center">
                  {cove.description}
                </p>
              </div>
            )}

            {/* Action Buttons */}
            <div className="flex flex-col sm:flex-row gap-3 sm:gap-4 justify-center">
              <button
                onClick={handleJoinCove}
                className="bg-[#5E1C1D] text-white py-3 sm:py-4 px-6 sm:px-8 rounded-xl font-libre-bodoni font-semibold text-base sm:text-lg hover:bg-[#4A1617] transition-colors shadow-lg hover:shadow-xl w-full sm:w-auto sm:min-w-[160px]"
              >
                {isAuthenticated ? 'Join Waitlist' : 'Sign in to Join'}
              </button>
              
              <button
                onClick={handleShare}
                className="bg-white text-[#5E1C1D] py-3 sm:py-4 px-6 sm:px-8 rounded-xl font-libre-bodoni font-semibold text-base sm:text-lg hover:bg-gray-50 transition-colors border border-[#5E1C1D] shadow-sm hover:shadow-md w-full sm:w-auto sm:min-w-[160px]"
              >
                Share Cove
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Events Feed Section */}
      <div className="mt-12 sm:mt-16 lg:mt-20">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <h2 className="font-libre-bodoni text-2xl sm:text-3xl text-[#5E1C1D] mb-6 sm:mb-8">Upcoming Events</h2>
          
          {loadingEvents ? (
            <div className="text-center py-12">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-[#5E1C1D] mx-auto mb-4"></div>
              <p className="font-libre-bodoni text-[#8B8B8B]">Loading events...</p>
            </div>
          ) : events.length > 0 ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {events.slice(0, 6).map((event) => (
                <div 
                  key={event.id} 
                  className="bg-white rounded-2xl overflow-hidden shadow-lg hover:shadow-xl transition-shadow cursor-pointer transform hover:scale-105 transition-transform duration-200"
                  onClick={() => window.location.href = `/events/${event.id}`}
                >
                  {/* Event Image */}
                  <div className="relative w-full aspect-[4/3]">
                    {event.coverPhoto?.url ? (
                      <Image
                        src={event.coverPhoto.url}
                        alt={event.name}
                        fill
                        className="object-cover"
                        sizes="(max-width: 768px) 100vw, (max-width: 1024px) 50vw, 33vw"
                      />
                    ) : (
                      <div className="w-full h-full bg-gray-200 flex items-center justify-center">
                        <div className="text-6xl">🎉</div>
                      </div>
                    )}
                  </div>
                  
                  {/* Event Info */}
                  <div className="p-6">
                    <h3 className="font-libre-bodoni text-xl font-semibold text-[#2D2D2D] mb-2 line-clamp-2">
                      {event.name}
                    </h3>
                    <div className="space-y-2 mb-4">
                      <p className="font-libre-bodoni text-sm text-[#8B8B8B]">
                        {formatEventDate(event.date)} • {formatEventTime(event.date)}
                      </p>
                      <p className="font-libre-bodoni text-sm text-[#2D2D2D]">
                        👤 {event.hostName}
                      </p>
                    </div>
                    {event.description && (
                      <p className="font-libre-bodoni text-sm text-[#8B8B8B] line-clamp-2">
                        {event.description}
                      </p>
                    )}
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="text-center py-12">
              <div className="text-6xl mb-4">📅</div>
              <p className="font-libre-bodoni text-lg text-[#8B8B8B]">No events scheduled yet</p>
            </div>
          )}

          {/* Join to See More CTA */}
          {events.length > 0 && (
            <div className="text-center mt-12">
              <div className="bg-white rounded-2xl p-8 shadow-lg max-w-md mx-auto">
                <h3 className="font-libre-bodoni text-xl font-semibold text-[#5E1C1D] mb-3">
                  Want to see more?
                </h3>
                <p className="font-libre-bodoni text-sm text-[#8B8B8B] mb-6">
                  Join this cove to discover all upcoming events and connect with members.
                </p>
                <button
                  onClick={handleJoinCove}
                  className="bg-[#5E1C1D] text-white py-3 px-6 rounded-xl font-libre-bodoni font-semibold hover:bg-[#4A1617] transition-colors"
                >
                  Join Waitlist
                </button>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Join Modal */}
      {showJoinModal && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="bg-white rounded-2xl p-8 max-w-md mx-4">
            <div className="text-center mb-6">
              <div className="text-4xl mb-4">🏠</div>
              <h3 className="font-libre-bodoni text-2xl font-semibold text-[#5E1C1D] mb-2">
                Join {cove.name}
              </h3>
              <p className="font-libre-bodoni text-sm text-[#8B8B8B]">
                You'll need to be invited by a member of this cove to join.
              </p>
            </div>
            
            <div className="space-y-4">
              <button
                onClick={() => setShowJoinModal(false)}
                className="w-full bg-gray-100 text-[#2D2D2D] py-3 px-6 rounded-xl font-libre-bodoni font-semibold hover:bg-gray-200 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={() => {
                  setShowJoinModal(false);
                  // Here you could implement invite request logic
                  alert('Invite request feature coming soon!');
                }}
                className="w-full bg-[#5E1C1D] text-white py-3 px-6 rounded-xl font-libre-bodoni font-semibold hover:bg-[#4A1617] transition-colors"
              >
                Request Invite
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
} 