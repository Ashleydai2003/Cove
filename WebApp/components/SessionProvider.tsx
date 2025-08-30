'use client';

import { useEffect } from 'react';
import { setupTokenRefresh } from '@/lib/auth';
import { auth } from '@/lib/firebase';
import { onAuthStateChanged } from 'firebase/auth';

export function SessionProvider({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    // Set up automatic token refresh when the app loads
    setupTokenRefresh();
    
    // Also listen for auth state changes to handle page refreshes
    const unsubscribe = onAuthStateChanged(auth, (user) => {
      if (user) {
        console.log('User authenticated, setting up token refresh');
        // The setupTokenRefresh function will handle the rest
      } else {
        console.log('User not authenticated');
      }
    });

    return () => {
      unsubscribe();
    };
  }, []);

  return <>{children}</>;
} 