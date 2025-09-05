'use client';

import { useEffect } from 'react';
import { setupTokenRefresh } from '@/lib/auth';
import { auth } from '@/lib/firebase';
import { onAuthStateChanged } from 'firebase/auth';

export function SessionProvider({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    // Set up automatic token refresh when the app loads
    setupTokenRefresh();
    
    // No need to check session status - cookies handle it automatically
    
    // Also listen for auth state changes to handle page refreshes
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      if (user) {
        console.log('User authenticated, setting up token refresh');
        // The setupTokenRefresh function will handle the rest
        
        // Also refresh the session to ensure it's up to date
        try {
          const idToken = await user.getIdToken();
          await fetch('/api/auth/refresh', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            credentials: 'include',
            body: JSON.stringify({ idToken }),
          });
        } catch (error) {
          console.error('Session refresh failed:', error);
        }
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