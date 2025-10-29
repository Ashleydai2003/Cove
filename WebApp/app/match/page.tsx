'use client';

import { useState, useEffect } from 'react';
import { auth } from '@/lib/firebase';
import { onAuthStateChanged } from 'firebase/auth';
import { useRouter } from 'next/navigation';
import OnboardingModal from '@/components/OnboardingModal';
import MatchingFlow from '@/components/MatchingFlow';

export default function MatchPage() {
  const router = useRouter();
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [hasCompletedOnboarding, setHasCompletedOnboarding] = useState(false);
  const [isLoading, setIsLoading] = useState(true);
  const [showOnboarding, setShowOnboarding] = useState(false);
  const [showOptIn, setShowOptIn] = useState(true); // Show opt-in by default
  const [userId, setUserId] = useState<string | null>(null);

  useEffect(() => {
    console.log('🔐 [MatchPage] Checking authentication...');
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      if (user) {
        // User is signed in with Firebase
        console.log('✅ [MatchPage] Firebase user found:', user.uid);
        try {
          const response = await fetch('/api/auth/refresh', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            credentials: 'include',
            body: JSON.stringify({ idToken: await user.getIdToken() })
          });

          if (response.ok) {
            const data = await response.json();
            const uid = data.user?.uid || user.uid;
            setUserId(uid);
            
            // Check if user has completed onboarding
            const needsOnboarding = data.user?.onboarding === true;
            
            console.log('📊 [MatchPage] Auth status:', {
              uid,
              needsOnboarding,
              hasSessionToken: !!response.headers.get('set-cookie')
            });
            
            if (needsOnboarding) {
              // User needs to complete onboarding
              console.log('⚠️ [MatchPage] User needs onboarding');
              setShowOnboarding(true);
              setShowOptIn(false);
              setIsAuthenticated(false);
              setHasCompletedOnboarding(false);
            } else {
              // User is fully authenticated and onboarded
              console.log('✅ [MatchPage] User fully authenticated');
              setIsAuthenticated(true);
              setHasCompletedOnboarding(true);
              setShowOnboarding(false);
              setShowOptIn(false); // Hide opt-in, show matching flow
            }
          } else {
            console.error('❌ [MatchPage] Auth refresh failed:', response.status);
            setShowOnboarding(true);
            setShowOptIn(false);
            setIsAuthenticated(false);
            setHasCompletedOnboarding(false);
          }
        } catch (error) {
          console.error('❌ [MatchPage] Auth error:', error);
          setShowOnboarding(true);
          setShowOptIn(false);
          setIsAuthenticated(false);
          setHasCompletedOnboarding(false);
        }
      } else {
        // User is not signed in - show opt-in screen
        console.log('❌ [MatchPage] No Firebase user, showing opt-in');
        setShowOptIn(true);
        setShowOnboarding(false);
        setIsAuthenticated(false);
        setHasCompletedOnboarding(false);
      }
      setIsLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const handleOnboardingComplete = async (completedUserId: string) => {
    console.log('✅ [MatchPage] Onboarding completed for user:', completedUserId);
    setUserId(completedUserId);
    setShowOnboarding(false);
    setIsAuthenticated(true);
    setHasCompletedOnboarding(true);
  };

  const handleOptInClick = () => {
    console.log('🎯 [MatchPage] User clicked get started, triggering auth flow');
    setShowOptIn(false);
    setShowOnboarding(true);
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-[#F5F0E6] flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-6xl font-libre-bodoni text-[#5E1C1D] mb-4 font-bold">cove</h1>
          <p className="font-libre-bodoni text-[#2D2D2D]">loading...</p>
        </div>
      </div>
    );
  }

  // Show opt-in screen for unauthenticated users
  if (showOptIn) {
    return (
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
              onClick={handleOptInClick}
              className="w-full bg-[#5E1C1D] text-white font-libre-bodoni text-lg font-medium py-4 rounded-2xl hover:bg-opacity-90 transition-all"
            >
              get started
            </button>
          </div>
        </div>
      </div>
    );
  }

  // Show onboarding modal if needed
  if (showOnboarding) {
    return (
      <OnboardingModal
        isOpen={showOnboarding}
        onClose={() => router.push('/')}
        onComplete={handleOnboardingComplete}
        originalAction="match with compatible people"
      />
    );
  }

  // User is authenticated and onboarded - show matching flow
  return (
    <>
      {userId && (
        <MatchingFlow userId={userId} />
      )}
    </>
  );
}

