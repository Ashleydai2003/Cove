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
    // Try to parse from parsedJson first
    if (intention?.parsedJson) {
      const chips = typeof intention.parsedJson === 'string' 
        ? JSON.parse(intention.parsedJson) 
        : intention.parsedJson;

      // Get the first activity
      const activities = chips.what?.activities || [];
      const activity = activities[0] || '';

      // Format time windows
      const timeWindows = chips.when || [];
      const formattedTime = timeWindows.join(', ');

      // Get location
      const location = chips.where || chips.location || '';

      const timeAndLocation = `${formattedTime}${location ? ` near ${location}` : ''}`;

      return { activity, timeAndLocation };
    }

    // Fallback: parse from text field
    if (intention?.text) {
      const parts = intention.text.split(', ').map((p: string) => p.trim());
      
      // Find activities (look for common activity keywords)
      const activityKeywords = [
        'sports', 'recreation', 'outdoors', 'music', 'performances', 
        'cocktails', 'bars', 'food', 'fashion', 'arts', 'crafts'
      ];
      
      const activities = parts.filter(part => 
        activityKeywords.some(keyword => part.toLowerCase().includes(keyword))
      );
      
      // Find time windows
      const timeKeywords = ['friday', 'saturday', 'sunday', 'daytime', 'evening'];
      const timeWindows = parts.filter(part => 
        timeKeywords.some(keyword => part.toLowerCase().includes(keyword))
      );
      
      // Find location (usually the last part that's not an activity or time)
      const location = parts[parts.length - 1] || '';
      
      const activity = activities[0] || '';
      const formattedTime = timeWindows.join(', ');
      const timeAndLocation = `${formattedTime}${location ? ` near ${location}` : ''}`;

      return { activity, timeAndLocation };
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
                ? `${userName}, we are finding your match. we will notify you when we have one!`
                : 'we are finding your match. we will notify you when we have one!'}
            </p>
          </div>

          {/* Divider */}
          <div className="border-t border-gray-200 my-8" />

          {/* Intention details */}
          <div>
            <h3 className="font-libre-bodoni text-lg text-[#5E1C1D] font-semibold mb-4">
              chosen intention & activity
            </h3>

            {activity && (
              <div className="mb-4">
                <p className="font-libre-bodoni text-2xl text-[#5E1C1D] font-bold mb-2">
                  {activity}
                </p>
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

