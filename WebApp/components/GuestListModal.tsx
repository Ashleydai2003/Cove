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
  name: string;
  profilePhoto?: {
    url: string;
  };
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
      <div className="bg-white rounded-2xl max-w-md w-full max-h-[80vh] overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b">
          <h2 className="text-xl font-semibold text-gray-900">guest list</h2>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 transition-colors"
          >
            <X size={24} />
          </button>
        </div>

        {/* Content */}
        <div className="p-6 overflow-y-auto max-h-[60vh]">
          {loading && (
            <div className="text-center py-8">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-4"></div>
              <p className="text-gray-600">Loading guests...</p>
            </div>
          )}

          {error && (
            <div className="text-center py-8">
              <p className="text-red-600">{error}</p>
            </div>
          )}

          {!loading && !error && guests.length === 0 && (
            <div className="text-center py-8">
              <p className="text-gray-600">No guests yet</p>
            </div>
          )}

          {!loading && !error && guests.length > 0 && (
            <div className="space-y-4">
              {guests.map((guest) => (
                <div key={guest.id} className="flex items-center space-x-4">
                  <div className="w-12 h-12 rounded-full overflow-hidden bg-gray-200 flex-shrink-0">
                    {guest.profilePhoto?.url ? (
                      <img
                        src={guest.profilePhoto.url}
                        alt={guest.name}
                        className="w-full h-full object-cover"
                      />
                    ) : (
                      <div className="w-full h-full bg-gray-300 flex items-center justify-center">
                        <User size={20} className="text-gray-500" />
                      </div>
                    )}
                  </div>
                  <div className="flex-1">
                    <p className="text-gray-900 font-medium">{guest.name}</p>
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