'use client';

import { useState, useEffect } from 'react';
import { X, User } from 'lucide-react';
import { Event } from '@/types/event';

interface GuestListModalProps {
  isOpen: boolean;
  onClose: () => void;
  eventId: string;
}

interface Guest {
  id: string;
  userId: string;
  userName: string;
  profilePhotoUrl: string | null;
  joinedAt: string;
  school: string | null;
  gradYear: string | null;
}

export default function GuestListModal({ isOpen, onClose, eventId }: GuestListModalProps) {
  const [guests, setGuests] = useState<Guest[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [hasMore, setHasMore] = useState(false);
  const [nextCursor, setNextCursor] = useState<string | null>(null);
  const [loadingMore, setLoadingMore] = useState(false);

  useEffect(() => {
    if (isOpen && eventId) {
      fetchGuests(true); // Refresh on open
    }
  }, [isOpen, eventId]);

  const fetchGuests = async (refresh: boolean = false) => {
    if (refresh) {
      setLoading(true);
      setGuests([]);
      setNextCursor(null);
    } else {
      setLoadingMore(true);
    }
    setError('');

    try {
      const params = new URLSearchParams({
        eventId,
        limit: '20'
      });
      
      if (!refresh && nextCursor) {
        params.append('cursor', nextCursor);
      }

      const response = await fetch(`/api/event-members?${params.toString()}`, {
        credentials: 'include',
      });

      if (response.ok) {
        const data = await response.json();
        
        if (refresh) {
          setGuests(data.members || []);
        } else {
          setGuests(prev => [...prev, ...(data.members || [])]);
        }
        
        setHasMore(data.hasMore || false);
        setNextCursor(data.nextCursor || null);
      } else {
        const data = await response.json();
        setError(data.message || 'Failed to load guests');
      }
    } catch (err) {
      setError('Network error. Please try again.');
    } finally {
      setLoading(false);
      setLoadingMore(false);
    }
  };

  const loadMore = () => {
    if (hasMore && !loadingMore && !loading) {
      fetchGuests(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl w-full max-w-lg h-[400px] sm:h-[450px] md:h-[500px] lg:h-[550px] overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between p-6">
          <div className="flex-1"></div>
          <h2 className="font-libre-bodoni text-xl text-[#5E1C1D] text-center flex-1">guest list</h2>
          <div className="flex-1 flex justify-end">
            <button
              onClick={onClose}
              className="w-8 h-8 rounded-full bg-[#5E1C1D] text-white flex items-center justify-center hover:bg-[#4A1718] transition-colors"
            >
              <X size={16} />
            </button>
          </div>
        </div>

        {/* Content */}
        <div className="px-6 pb-6 overflow-y-auto h-[280px] sm:h-[330px] md:h-[380px] lg:h-[430px]">
          {loading && (
            <div className="text-center py-8">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-[#5E1C1D] mx-auto mb-4"></div>
              <p className="font-libre-bodoni text-[#8B8B8B]">Loading guests...</p>
            </div>
          )}

          {error && (
            <div className="text-center py-8">
              <p className="font-libre-bodoni text-red-600">{error}</p>
            </div>
          )}

          {!loading && !error && guests.length === 0 && (
            <div className="text-center py-8">
              <p className="font-libre-bodoni text-[#8B8B8B]">No guests yet</p>
            </div>
          )}

          {!loading && !error && guests.length > 0 && (
            <div className="space-y-4">
              {guests.map((guest, index) => (
                <div 
                  key={guest.id} 
                  className="flex items-center space-x-4"
                  onMouseEnter={() => {
                    // Load more when reaching the last few items
                    if (index >= guests.length - 3 && hasMore && !loadingMore) {
                      loadMore();
                    }
                  }}
                >
                  <div className="w-16 h-16 rounded-full overflow-hidden bg-gray-200 flex-shrink-0 border-2 border-white shadow-sm">
                    {guest.profilePhotoUrl ? (
                      <img
                        src={guest.profilePhotoUrl}
                        alt={guest.userName}
                        className="w-full h-full object-cover"
                      />
                    ) : (
                      <img
                        src="/default_user_pfp.svg"
                        alt="Default profile"
                        className="w-full h-full object-cover"
                      />
                    )}
                  </div>
                  <div className="flex-1">
                    <p className="font-libre-bodoni text-[#2D2D2D] font-medium">{guest.userName}</p>
                    {guest.school && guest.gradYear && guest.school.toLowerCase() !== 'other' && (
                      <p className="font-libre-bodoni text-sm text-[#8B8B8B] mt-1">
                        {guest.school}'{(() => {
                          // Clean and format the graduation year
                          const cleanYear = guest.gradYear.replace(/[^0-9]/g, '');
                          return cleanYear.length >= 2 ? cleanYear.slice(-2) : cleanYear;
                        })()}
                      </p>
                    )}
                  </div>
                </div>
              ))}
              
              {/* Loading more indicator */}
              {loadingMore && (
                <div className="text-center py-4">
                  <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-[#5E1C1D] mx-auto mb-2"></div>
                  <p className="font-libre-bodoni text-sm text-[#8B8B8B]">Loading more guests...</p>
                </div>
              )}
              
              {/* Load more button (fallback) */}
              {hasMore && !loadingMore && (
                <div className="text-center py-4">
                  <button
                    onClick={loadMore}
                    className="font-libre-bodoni text-[#5E1C1D] underline underline-offset-4 text-sm hover:text-[#4A1718]"
                  >
                    Load more guests
                  </button>
                </div>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
} 