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
              setIsAuthenticated(false);
              setHasCompletedOnboarding(false);
            } else {
              // User is fully authenticated and onboarded
              console.log('✅ [MatchPage] User fully authenticated');
              setIsAuthenticated(true);
              setHasCompletedOnboarding(true);
              setShowOnboarding(false);
            }
          } else {
            console.error('❌ [MatchPage] Auth refresh failed:', response.status);
            setShowOnboarding(true);
            setIsAuthenticated(false);
            setHasCompletedOnboarding(false);
          }
        } catch (error) {
          console.error('❌ [MatchPage] Auth error:', error);
          setShowOnboarding(true);
          setIsAuthenticated(false);
          setHasCompletedOnboarding(false);
        }
      } else {
        // User is not signed in
        console.log('❌ [MatchPage] No Firebase user, showing onboarding');
        setShowOnboarding(true);
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

  // Only show matching flow if fully authenticated and onboarded
  if (!isAuthenticated || !hasCompletedOnboarding) {
    return (
      <>
        {showOnboarding && (
          <OnboardingModal
            isOpen={showOnboarding}
            onClose={() => router.push('/')}
            onComplete={handleOnboardingComplete}
            originalAction="match with compatible people"
          />
        )}
      </>
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

