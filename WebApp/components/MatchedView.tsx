'use client';

import { useState, useEffect } from 'react';

interface MatchedViewProps {
  matchData?: any;
}

export default function MatchedView({ matchData }: MatchedViewProps) {
  const [match, setMatch] = useState<any>(null);
  const [loading, setLoading] = useState(!matchData);

  useEffect(() => {
    if (matchData) {
      setMatch(matchData);
    } else {
      loadMatch();
    }
  }, [matchData]);

  const loadMatch = async () => {
    try {
      const response = await fetch('/api/match/current', {
        credentials: 'include'
      });

      if (response.ok) {
        const data = await response.json();
        if (data.hasMatch) {
          setMatch(data.match);
        }
      }
    } catch (err) {
      console.error('failed to load match:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleConnect = async () => {
    try {
      const response = await fetch('/api/match/accept', {
        method: 'POST',
        credentials: 'include'
      });

      if (response.ok) {
        const data = await response.json();
        // Redirect to thread or show success
        window.location.href = `/messages/${data.threadId}`;
      }
    } catch (err) {
      console.error('failed to accept match:', err);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-[#F5F0E6] flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-4 border-[#5E1C1D] border-t-transparent" />
      </div>
    );
  }

  if (!match) {
    return (
      <div className="min-h-screen bg-[#F5F0E6] flex items-center justify-center">
        <p className="font-libre-bodoni text-xl text-[#5E1C1D]">no match found</p>
      </div>
    );
  }

  const groupSize = match.groupSize || 2;
  const otherCount = groupSize - 1;

  return (
    <div className="min-h-screen bg-[#F5F0E6] flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        {/* Cove logo */}
        <h1 className="text-6xl font-libre-bodoni text-[#5E1C1D] text-center font-bold mb-8">
          cove
        </h1>

        {/* Match card */}
        <div className="bg-white rounded-3xl p-8 shadow-sm">
          {/* Match icon */}
          <div className="flex justify-center mb-6">
            <div className="w-16 h-16 bg-[#5E1C1D] rounded-full flex items-center justify-center">
              <span className="text-3xl">🌍</span>
            </div>
          </div>

          {/* Match title */}
          <h2 className="font-libre-bodoni text-3xl text-[#5E1C1D] font-bold text-center mb-2">
            your match
          </h2>

          {/* Match description */}
          <p className="font-libre-bodoni text-base text-[#5E1C1D] text-center mb-6 opacity-70">
            you look so good together! now dont be shy... make it happen!
          </p>

          {/* Divider */}
          <div className="border-t border-gray-200 my-6" />

          {/* Group card label */}
          <div className="mb-6">
            <p className="font-libre-bodoni text-sm text-[#5E1C1D] uppercase tracking-wide opacity-50 mb-4">
              group card
            </p>

            {/* Group info */}
            <div className="flex items-center gap-2 mb-4">
              <span className="text-xl">😊</span>
              <p className="font-libre-bodoni text-lg text-[#5E1C1D]">
                you & {otherCount} other{otherCount !== 1 ? 's' : ''}
              </p>
            </div>

            {/* Matched user details */}
            {match.user && (
              <div className="bg-gray-50 rounded-2xl p-4 mb-4">
                <p className="font-libre-bodoni text-xl text-[#5E1C1D] font-semibold mb-2">
                  {match.user.name || 'your match'}
                </p>
                {match.user.age && (
                  <p className="font-libre-bodoni text-base text-[#5E1C1D] opacity-70">
                    {match.user.age} years old
                  </p>
                )}
                {match.user.almaMater && (
                  <p className="font-libre-bodoni text-base text-[#5E1C1D] opacity-70">
                    {match.user.almaMater}
                  </p>
                )}
                {match.user.bio && (
                  <p className="font-libre-bodoni text-base text-[#5E1C1D] mt-2">
                    {match.user.bio}
                  </p>
                )}
              </div>
            )}

            {/* Match score */}
            {match.score && (
              <p className="font-libre-bodoni text-sm text-[#5E1C1D] opacity-50">
                {Math.round(match.score * 100)}% compatibility
              </p>
            )}
          </div>

          {/* Connect button */}
          <button
            onClick={handleConnect}
            className="w-full bg-[#5E1C1D] text-white font-libre-bodoni text-lg font-medium py-4 rounded-2xl hover:bg-opacity-90 transition-all"
          >
            connect me
          </button>
        </div>
      </div>
    </div>
  );
}

