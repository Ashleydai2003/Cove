'use client';

import { useState, useEffect } from 'react';
import SurveyView from './SurveyView';
import IntentionComposer from './IntentionComposer';
import PoolStatusView from './PoolStatusView';
import MatchedView from './MatchedView';

interface MatchingFlowProps {
  userId: string;
}

type FlowState = 'loading' | 'optin' | 'survey' | 'intention' | 'pool' | 'matched';

export default function MatchingFlow({ userId }: MatchingFlowProps) {
  const [flowState, setFlowState] = useState<FlowState>('loading');
  const [hasLoadedInitialState, setHasLoadedInitialState] = useState(false);
  const [currentMatch, setCurrentMatch] = useState<any>(null);
  const [userCity, setUserCity] = useState('palo alto');
  const [surveyComplete, setSurveyComplete] = useState(false);
  const [hasIntention, setHasIntention] = useState(false);

  useEffect(() => {
    if (!hasLoadedInitialState) {
      setHasLoadedInitialState(true);
      loadInitialState();
    }
  }, [userId]);

  const loadInitialState = async () => {
    console.log('🔄 [MatchingFlow] Loading initial state...');
    
    try {
      // Load all data in parallel
      const [surveyResponse, statusResponse, matchResponse] = await Promise.all([
        fetch('/api/match/survey', { credentials: 'include' }),
        fetch('/api/match/status', { credentials: 'include' }),
        fetch('/api/match/current', { credentials: 'include' })
      ]);

      // Check survey completion
      let isSurveyComplete = false;
      if (surveyResponse.ok) {
        const surveyData = await surveyResponse.json();
        isSurveyComplete = surveyData.responses && surveyData.responses.length > 0;
      }
      setSurveyComplete(isSurveyComplete);

      // Check intention status
      let hasActiveIntention = false;
      if (statusResponse.ok) {
        const statusData = await statusResponse.json();
        hasActiveIntention = statusData.hasIntention;
        if (statusData.userCity) {
          setUserCity(statusData.userCity);
        }
      }
      setHasIntention(hasActiveIntention);

      // Check for current match
      let hasCurrentMatch = false;
      if (matchResponse.ok) {
        const matchData = await matchResponse.json();
        if (matchData.hasMatch && matchData.match) {
          setCurrentMatch(matchData.match);
          hasCurrentMatch = true;
        }
      }

      // Determine which view to show (matching iOS logic exactly)
      let nextState: FlowState = 'survey';
      
      if (hasCurrentMatch) {
        nextState = 'matched';
      } else if (!isSurveyComplete) {
        // Show opt-in only if no survey completed AND no intention exists
        nextState = hasActiveIntention ? 'pool' : 'optin';
      } else if (hasActiveIntention) {
        nextState = 'pool';
      } else {
        nextState = 'intention';
      }

      console.log('📊 [MatchingFlow] State check:');
      console.log('   - Survey complete:', isSurveyComplete);
      console.log('   - Has intention:', hasActiveIntention);
      console.log('   - Has match:', hasCurrentMatch);
      console.log('   - Next state:', nextState);

      // Small delay to match iOS behavior
      setTimeout(() => {
        setFlowState(nextState);
      }, 500);

    } catch (error) {
      console.error('❌ [MatchingFlow] Error loading initial state:', error);
      setFlowState('survey');
    }
  };

  const handleSurveyComplete = () => {
    console.log('📋 [MatchingFlow] Survey completed, reloading intentions');
    setSurveyComplete(true);
    // Reload intention after survey complete
    loadInitialState();
  };

  const handleIntentionComplete = () => {
    console.log('🎯 [MatchingFlow] Intention created! Transitioning to pool status view...');
    setHasIntention(true);
    setFlowState('pool');
  };

  const handleMatchFound = () => {
    console.log('🎉 [MatchingFlow] Match found! Transitioning to matched view...');
    // Reload to get the match data
    loadInitialState();
  };

  const handleOptInComplete = () => {
    console.log('✅ [MatchingFlow] Opt-in completed, showing survey');
    setFlowState('survey');
  };

  if (flowState === 'loading') {
    return (
      <div className="min-h-screen bg-[#F5F0E6] flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-6xl font-libre-bodoni text-[#5E1C1D] mb-4 font-bold">cove</h1>
          <div className="animate-spin rounded-full h-12 w-12 border-4 border-[#5E1C1D] border-t-transparent mx-auto"></div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#F5F0E6]">
      {flowState === 'optin' && (
        <div className="min-h-screen bg-[#F5F0E6] flex items-center justify-center p-4">
          <div className="w-full max-w-md">
            <h1 className="text-6xl font-libre-bodoni text-[#5E1C1D] text-center font-bold mb-8">
              cove
            </h1>
            <div className="bg-white rounded-3xl p-8 shadow-sm">
              <h2 className="font-libre-bodoni text-2xl text-[#5E1C1D] font-semibold mb-4 text-center">
                welcome to matching
              </h2>
              <p className="font-libre-bodoni text-base text-[#5E1C1D] mb-6 text-center">
                let's find your perfect match! we'll ask you a few questions to understand your preferences and then match you with like-minded people.
              </p>
              <button
                onClick={handleOptInComplete}
                className="w-full bg-[#5E1C1D] text-white font-libre-bodoni text-lg font-medium py-4 rounded-2xl hover:bg-opacity-90 transition-all"
              >
                get started
              </button>
            </div>
          </div>
        </div>
      )}
      
      {flowState === 'survey' && (
        <SurveyView onComplete={handleSurveyComplete} />
      )}
      
      {flowState === 'intention' && (
        <IntentionComposer userCity={userCity} onComplete={handleIntentionComplete} />
      )}
      
      {flowState === 'pool' && (
        <PoolStatusView onMatchFound={handleMatchFound} />
      )}
      
      {flowState === 'matched' && currentMatch && (
        <MatchedView matchData={currentMatch} />
      )}
    </div>
  );
}

