'use client';

import { useState, useEffect } from 'react';
import Image from 'next/image';

interface PoolStatusViewProps {
  onMatchFound: () => void;
}

export default function PoolStatusView({ onMatchFound }: PoolStatusViewProps) {
  const [userName, setUserName] = useState('');
  const [intention, setIntention] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadStatus();
    // Poll for match every 30 seconds
    const interval = setInterval(checkForMatch, 30000);
    return () => clearInterval(interval);
  }, []);

  const loadStatus = async () => {
    try {
      const response = await fetch('/api/match/status', {
        credentials: 'include'
      });

      if (response.ok) {
        const data = await response.json();
        setUserName(data.userName || '');
        setIntention(data.intention);
      }
    } catch (err) {
      console.error('failed to load status:', err);
    } finally {
      setLoading(false);
    }
  };

  const checkForMatch = async () => {
    try {
      const response = await fetch('/api/match/current', {
        credentials: 'include'
      });

      if (response.ok) {
        const data = await response.json();
        if (data.hasMatch && data.match) {
          onMatchFound();
        }
      }
    } catch (err) {
      console.error('failed to check for match:', err);
    }
  };

  const parseIntention = () => {
    if (!intention?.parsedJson) return { activity: '', timeAndLocation: '' };
    
    try {
      const chips = typeof intention.parsedJson === 'string' 
        ? JSON.parse(intention.parsedJson) 
        : intention.parsedJson;

      let activities: string[] = [];
      let availability: string[] = [];
      let location = '';

      // Current format: { who: {}, what: { intention, activities }, when: [], where: "" }
      if (chips.what?.activities) {
        activities = chips.what.activities;
        availability = chips.when || [];
        location = chips.where || '';
      } 
      // Legacy format: { who: {}, what: { notes, activities }, when: [], location: "" }
      else if (chips.what?.notes && chips.what?.activities) {
        activities = chips.what.activities;
        availability = chips.when || [];
        location = chips.location || '';
      }

      if (activities.length > 0 || availability.length > 0) {
        const activity = activities.join(' or ');
        const formattedTime = availability.map((t: string) => t.toLowerCase()).join(', ');
        const timeAndLocation = `${formattedTime}${location ? ` near ${location}` : ''}`;
        return { activity, timeAndLocation };
      }
    } catch (e) {
      console.error('Failed to parse parsedJson:', e);
    }

    return { activity: '', timeAndLocation: '' };
  };

  const { activity, timeAndLocation } = parseIntention();

  if (loading) {
    return (
      <div className="min-h-screen bg-[#F5F0E6] flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-4 border-[#5E1C1D] border-t-transparent" />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#F5F0E6] flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        {/* Cove logo */}
        <h1 className="text-6xl font-libre-bodoni text-[#5E1C1D] text-center font-bold mb-8">
          cove
        </h1>

        {/* Status card */}
        <div className="bg-white rounded-3xl p-8 shadow-sm">
          {/* Sparkle icon */}
          <div className="flex justify-center mb-8">
            <div className="text-6xl">✨</div>
          </div>

          {/* Message */}
          <div className="text-center mb-8">
            <p className="font-libre-bodoni text-xl text-[#5E1C1D] mb-2">
              {userName
                ? `${userName.split(' ')[0]}, we are finding your match. we will notify you if we find a good one!`
                : 'we are finding your match. we will notify you if we find a good one!'}
            </p>
          </div>

          {/* Divider */}
          <div className="border-t border-gray-200 my-8" />

          {/* Intention details */}
          <div>
            <h3 className="font-libre-bodoni text-lg text-[#5E1C1D] font-semibold mb-4">
              chosen intention & activities
            </h3>

            {activity && (
              <div className="mb-4">
                <div className="font-libre-bodoni text-xl text-[#5E1C1D] font-medium mb-2">
                  <ul className="list-disc list-inside space-y-1">
                    {activity.split(' or ').map((part: string, index: number) => (
                      <li key={index} className="ml-2">
                        {part}
                      </li>
                    ))}
                  </ul>
                </div>
                <p className="font-libre-bodoni text-base text-[#5E1C1D] opacity-70">
                  {timeAndLocation}
                </p>
              </div>
            )}
          </div>
        </div>

        {/* Helper text */}
        <p className="text-center font-libre-bodoni text-sm text-[#5E1C1D] opacity-60 mt-6">
          check back soon or wait for a notification
        </p>
      </div>
    </div>
  );
}

