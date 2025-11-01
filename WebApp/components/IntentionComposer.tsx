'use client';

import { useState, useEffect } from 'react';

interface IntentionComposerProps {
  userCity: string;
  onComplete: () => void;
}

export default function IntentionComposer({ userCity, onComplete }: IntentionComposerProps) {
  const [showFirstMessage, setShowFirstMessage] = useState(false);
  const [showSecondMessage, setShowSecondMessage] = useState(false);
  const [showFirstQuestion, setShowFirstQuestion] = useState(false);
  const [connectionType, setConnectionType] = useState<string | null>(null);
  const [showConnectionResponse, setShowConnectionResponse] = useState(false);
  const [showActivitiesPrompt, setShowActivitiesPrompt] = useState(false);
  const [selectedActivities, setSelectedActivities] = useState<string[]>([]);
  const [showActivitiesResponse, setShowActivitiesResponse] = useState(false);
  const [showTimeQuestion, setShowTimeQuestion] = useState(false);
  const [selectedTimeWindows, setSelectedTimeWindows] = useState<string[]>([]);
  const [showTimeResponse, setShowTimeResponse] = useState(false);
  const [showFinalMessage, setShowFinalMessage] = useState(false);
  const [error, setError] = useState('');

  const activityOptions = [
    'sports, recreation & the outdoors',
    'music & live performances',
    'nights out—cocktails & bars',
    'food & good company',
    'fashion, arts & crafts'
  ];

  const timeWindowOptions = [
    'friday evening',
    'saturday daytime',
    'saturday evening',
    'sunday daytime'
  ];

  // Start the conversation
  useEffect(() => {
    // Show first message immediately
    setTimeout(() => {
      setShowFirstMessage(true);
    }, 100);

    // Show second message after 2 seconds
    setTimeout(() => {
      setShowSecondMessage(true);
      
      // Show response options after a short delay
      setTimeout(() => {
        setShowFirstQuestion(true);
      }, 500);
    }, 2000);
  }, []);

  const handleFirstResponse = (connection: string) => {
    setConnectionType(connection);
    
    // Hide question options and show user's response
    setShowFirstQuestion(false);
    setShowConnectionResponse(true);
    
    // Show activities prompt after a delay
    setTimeout(() => {
      setShowActivitiesPrompt(true);
    }, 800);
  };

  const toggleActivity = (activity: string) => {
    setSelectedActivities(prev => {
      if (prev.includes(activity)) {
        return prev.filter(a => a !== activity);
      } else {
        return [...prev, activity];
      }
    });
  };

  const showActivitiesAfterSelection = () => {
    // Show user's activity selections as sent messages
    setShowActivitiesResponse(true);
    
    // Show time question
    setTimeout(() => {
      setShowTimeQuestion(true);
    }, 800);
  };

  const toggleTimeWindow = (timeWindow: string) => {
    setSelectedTimeWindows(prev => {
      if (prev.includes(timeWindow)) {
        return prev.filter(t => t !== timeWindow);
      } else {
        return [...prev, timeWindow];
      }
    });
  };

  const submitIntention = async () => {
    // Show user's time window selections as sent messages
    setShowTimeResponse(true);
    
    // Show final message
    setTimeout(() => {
      setShowFinalMessage(true);
      
      // Submit to backend after final message shows
      setTimeout(() => {
        performIntentionSubmission();
      }, 1500);
    }, 500);
  };

  const performIntentionSubmission = async () => {
    try {
      // Build the current parsed JSON structure
      const parsedJson = {
        who: {},
        what: {
          intention: connectionType === 'friends' ? 'friends' : 'romantic',
          activities: selectedActivities
        },
        when: selectedTimeWindows,
        where: userCity,
        mustHaves: ['location', 'when']
      };

      const response = await fetch('/api/match/intention', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({ parsedJson })
      });

      if (response.ok) {
        setTimeout(() => {
          onComplete();
        }, 2000);
      } else {
        const data = await response.json();
        setError(data.message || 'failed to submit intention');
      }
    } catch (err) {
      setError('network error. please try again.');
    }
  };

  return (
    <div className="min-h-screen bg-[#F5F0E6] flex items-center justify-center p-4">
      <div className="w-full max-w-2xl">
        {/* Cove logo */}
        <h1 className="text-6xl font-libre-bodoni text-[#5E1C1D] text-center font-bold mb-8">
          cove
        </h1>

        {/* Chat container */}
        <div className="bg-white rounded-3xl p-6 min-h-[600px] max-h-[700px] flex flex-col">
          {/* Messages */}
          <div className="flex-1 overflow-y-auto mb-6 space-y-4">
            {/* First message from Cove */}
            {showFirstMessage && (
              <div className="flex justify-start animate-fade-in">
                <div className="max-w-[75%] px-6 py-4 rounded-2xl bg-[#5E1C1D] text-white shadow-sm">
                  <p className="font-libre-bodoni text-base">
                    set your intention... now that we know a bit about you.
                  </p>
                </div>
              </div>
            )}

            {/* Second message from Cove */}
            {showSecondMessage && (
              <div className="flex justify-start animate-fade-in">
                <div className="max-w-[75%] px-6 py-4 rounded-2xl bg-[#5E1C1D] text-white shadow-sm">
                  <p className="font-libre-bodoni text-base">
                    first things first, what are you looking for?
                  </p>
                </div>
              </div>
            )}

            {/* User response options (connection type) */}
            {showFirstQuestion && (
              <div className="flex justify-end animate-fade-in">
                <div className="max-w-[75%] space-y-3">
                  <button
                    onClick={() => handleFirstResponse('friends')}
                    className="w-full px-6 py-4 rounded-2xl font-libre-bodoni text-base bg-[#5E1C1D] text-white hover:bg-opacity-90 transition-all duration-200"
                  >
                    new friends & connections
                  </button>
                  <button
                    onClick={() => handleFirstResponse('romantic')}
                    className="w-full px-6 py-4 rounded-2xl font-libre-bodoni text-base bg-[#5E1C1D] text-white hover:bg-opacity-90 transition-all duration-200"
                  >
                    romantic connection
                  </button>
                </div>
              </div>
            )}

            {/* User's selected connection type (stays on screen) */}
            {showConnectionResponse && connectionType && (
              <div className="flex justify-end animate-fade-in">
                <div className="max-w-[75%] px-6 py-4 rounded-2xl bg-gray-100 text-[#5E1C1D] shadow-sm">
                  <p className="font-libre-bodoni text-base">
                    {connectionType === 'friends' ? 'new friends & connections' : 'romantic connection'}
                  </p>
                </div>
              </div>
            )}

            {/* Activities prompt */}
            {showActivitiesPrompt && (
              <div className="flex justify-start animate-fade-in">
                <div className="max-w-[75%] px-6 py-4 rounded-2xl bg-[#5E1C1D] text-white shadow-sm">
                  <p className="font-libre-bodoni text-base">
                    fantastic. now select the activities that excite you, and we will match you with people who are on the same wavelength.
                  </p>
                </div>
              </div>
            )}

            {/* Activity options */}
            {showActivitiesPrompt && !showActivitiesResponse && (
              <div className="flex justify-end animate-fade-in">
                <div className="max-w-[75%] space-y-3">
                  {activityOptions.map(activity => (
                    <button
                      key={activity}
                      onClick={() => toggleActivity(activity)}
                      className={`w-full px-6 py-4 rounded-2xl font-libre-bodoni text-base transition-all duration-200 ${
                        selectedActivities.includes(activity)
                          ? 'bg-[#5E1C1D] text-white'
                          : 'bg-gray-100 text-[#5E1C1D] hover:bg-gray-200'
                      }`}
                    >
                      {activity}
                    </button>
                  ))}
                  
                  {/* Continue button (only show if at least one activity selected) */}
                  {selectedActivities.length > 0 && (
                    <button
                      onClick={showActivitiesAfterSelection}
                      className="w-full px-6 py-4 rounded-2xl font-libre-bodoni text-lg font-semibold bg-[#5E1C1D] text-white hover:bg-opacity-90 transition-all duration-200 mt-2"
                    >
                      continue
                    </button>
                  )}
                </div>
              </div>
            )}

            {/* User's selected activities (stays on screen) */}
            {showActivitiesResponse && (
              <div className="flex justify-end animate-fade-in">
                <div className="max-w-[75%] space-y-2">
                  {selectedActivities.map(activity => (
                    <div key={activity} className="px-6 py-4 rounded-2xl bg-gray-100 text-[#5E1C1D] shadow-sm">
                      <p className="font-libre-bodoni text-base">{activity}</p>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Time window question */}
            {showTimeQuestion && (
              <div className="flex justify-start animate-fade-in">
                <div className="max-w-[75%] px-6 py-4 rounded-2xl bg-[#5E1C1D] text-white shadow-sm">
                  <p className="font-libre-bodoni text-base">
                    great! when are you free to meet up?
                  </p>
                </div>
              </div>
            )}

            {/* Time window options */}
            {showTimeQuestion && !showTimeResponse && (
              <div className="flex justify-end animate-fade-in">
                <div className="max-w-[75%] space-y-3">
                  {timeWindowOptions.map(timeWindow => (
                    <button
                      key={timeWindow}
                      onClick={() => toggleTimeWindow(timeWindow)}
                      className={`w-full px-6 py-4 rounded-2xl font-libre-bodoni text-base transition-all duration-200 ${
                        selectedTimeWindows.includes(timeWindow)
                          ? 'bg-[#5E1C1D] text-white'
                          : 'bg-gray-100 text-[#5E1C1D] hover:bg-gray-200'
                      }`}
                    >
                      {timeWindow}
                    </button>
                  ))}
                  
                  {/* Continue button (only show if at least one time selected) */}
                  {selectedTimeWindows.length > 0 && (
                    <button
                      onClick={submitIntention}
                      className="w-full px-6 py-4 rounded-2xl font-libre-bodoni text-base bg-[#5E1C1D] text-white hover:bg-opacity-90 transition-all duration-200 mt-4"
                    >
                      continue
                    </button>
                  )}
                </div>
              </div>
            )}

            {/* User's selected time windows (stays on screen) */}
            {showTimeResponse && (
              <div className="flex justify-end animate-fade-in">
                <div className="max-w-[75%] space-y-2">
                  {selectedTimeWindows.map(timeWindow => (
                    <div key={timeWindow} className="px-6 py-4 rounded-2xl bg-gray-100 text-[#5E1C1D] shadow-sm">
                      <p className="font-libre-bodoni text-base">{timeWindow}</p>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Final message */}
            {showFinalMessage && (
              <div className="flex justify-start animate-fade-in">
                <div className="max-w-[75%] px-6 py-4 rounded-2xl bg-[#5E1C1D] text-white shadow-sm">
                  <p className="font-libre-bodoni text-base">
                    setting you up with your perfect match!
                  </p>
                </div>
              </div>
            )}
          </div>

          {/* Error message */}
          {error && (
            <p className="mt-4 text-red-600 font-libre-bodoni text-sm text-center">
              {error}
            </p>
          )}
        </div>
      </div>
    </div>
  );
}

