// Authentication utilities for the web app
import { auth } from './firebase';
import { onAuthStateChanged, User as FirebaseUser } from 'firebase/auth';

export interface User {
  id: string;
  name: string;
  phone: string;
  onboarding: boolean;
  verified: boolean;
}

// Token refresh interval (check every 50 minutes since Firebase tokens expire after 1 hour)
const TOKEN_REFRESH_INTERVAL = 50 * 60 * 1000; // 50 minutes in milliseconds

let tokenRefreshTimer: NodeJS.Timeout | null = null;

// Function to refresh the Firebase token and update the session
async function refreshTokenAndSession(firebaseUser: FirebaseUser) {
  try {
    const newIdToken = await firebaseUser.getIdToken(true); // Force refresh
    
    // Update the session with the new token
    await fetch('/api/auth/refresh', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      credentials: 'include',
      body: JSON.stringify({ idToken: newIdToken }),
    });
    
    console.log('Token refreshed successfully');
  } catch (error) {
    console.error('Token refresh failed:', error);
    // If refresh fails, the user will need to log in again
    await logout();
  }
}

// Set up automatic token refresh
export function setupTokenRefresh() {
  if (typeof window === 'undefined') return; // Only run on client side
  
  onAuthStateChanged(auth, (firebaseUser) => {
    if (firebaseUser) {
      // Clear any existing timer
      if (tokenRefreshTimer) {
        clearInterval(tokenRefreshTimer);
      }
      
      // Set up periodic token refresh
      tokenRefreshTimer = setInterval(() => {
        refreshTokenAndSession(firebaseUser);
      }, TOKEN_REFRESH_INTERVAL);
      
      // Also refresh immediately if the token is close to expiring
      firebaseUser.getIdTokenResult().then((result) => {
        const expiresIn = result.expirationTime ? 
          new Date(result.expirationTime).getTime() - Date.now() : 
          0;
        
        if (expiresIn < 10 * 60 * 1000) { // Less than 10 minutes left
          refreshTokenAndSession(firebaseUser);
        }
      });
    } else {
      // User is not authenticated, clear the timer
      if (tokenRefreshTimer) {
        clearInterval(tokenRefreshTimer);
        tokenRefreshTimer = null;
      }
    }
  });
}

// Clean up token refresh on page unload
if (typeof window !== 'undefined') {
  window.addEventListener('beforeunload', () => {
    if (tokenRefreshTimer) {
      clearInterval(tokenRefreshTimer);
    }
  });
}

export async function checkAuthStatus(): Promise<{ isAuthenticated: boolean; user?: User }> {
  try {
    const response = await fetch('/api/auth/status', {
      method: 'GET',
      credentials: 'include', // Include cookies
    });

    if (response.ok) {
      const data = await response.json();
      return {
        isAuthenticated: true,
        user: data.user,
      };
    } else {
      return {
        isAuthenticated: false,
      };
    }
  } catch (error) {
    console.error('Auth check error:', error);
    return {
      isAuthenticated: false,
    };
  }
}

export async function logout(): Promise<void> {
  try {
    // Clear the token refresh timer
    if (tokenRefreshTimer) {
      clearInterval(tokenRefreshTimer);
      tokenRefreshTimer = null;
    }
    
    // Sign out from Firebase
    await auth.signOut();
    
    // Call the logout API to clear the session cookie
    await fetch('/api/auth/logout', {
      method: 'POST',
      credentials: 'include',
    });
  } catch (error) {
    console.error('Logout error:', error);
  }
} 