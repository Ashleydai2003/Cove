'use client';

import { useEffect } from 'react';
import { setupTokenRefresh } from '@/lib/auth';
import { auth } from '@/lib/firebase';
import { onAuthStateChanged } from 'firebase/auth';
import { debugAuthState } from '@/lib/debug';

export function SessionProvider({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    // Debug auth state in development
    if (process.env.NODE_ENV === 'development') {
      debugAuthState();
    }
    
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
          const response = await fetch('/api/auth/refresh', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            credentials: 'include',
            body: JSON.stringify({ idToken }),
          });
          
          if (!response.ok) {
            console.warn('Session refresh failed with status:', response.status);
            // Try to re-establish session by calling login endpoint
            const loginResponse = await fetch('/api/auth/login', {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
              },
              credentials: 'include',
              body: JSON.stringify({ idToken }),
            });
            
            if (!loginResponse.ok) {
              console.error('Failed to re-establish session');
            }
          }
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