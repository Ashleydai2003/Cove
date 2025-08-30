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

  useEffect(() => {
    if (isOpen && eventId) {
      fetchGuests();
    }
  }, [isOpen, eventId]);

  const fetchGuests = async () => {
    setLoading(true);
    setError('');

    try {
      const response = await fetch(`/api/event-members?eventId=${eventId}`, {
        credentials: 'include',
      });

      if (response.ok) {
        const data = await response.json();
        setGuests(data.members || []);
      } else {
        const data = await response.json();
        setError(data.message || 'Failed to load guests');
      }
    } catch (err) {
      setError('Network error. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl w-full max-w-lg max-h-[90vh] overflow-hidden">
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
        <div className="px-6 pb-6 overflow-y-auto max-h-[calc(90vh-80px)]">
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
              {guests.map((guest) => (
                <div key={guest.id} className="flex items-center space-x-4">
                  <div className="w-16 h-16 rounded-full overflow-hidden bg-gray-200 flex-shrink-0 border-2 border-white shadow-sm">
                    {guest.profilePhotoUrl ? (
                      <img
                        src={guest.profilePhotoUrl}
                        alt={guest.userName}
                        className="w-full h-full object-cover"
                      />
                    ) : (
                      <div className="w-full h-full bg-gray-300 flex items-center justify-center">
                        <User size={24} className="text-gray-500" />
                      </div>
                    )}
                  </div>
                  <div className="flex-1">
                    <p className="font-libre-bodoni text-[#2D2D2D] font-medium">{guest.userName}</p>
                    {guest.school && guest.gradYear && (
                      <p className="font-libre-bodoni text-sm text-[#8B8B8B] mt-1">
                        {guest.school}'{guest.gradYear.slice(-2)}
                      </p>
                    )}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
} 