// Debug utilities for authentication issues

export function debugAuthState() {
  if (typeof window === 'undefined') return;
  
  console.log('=== AUTH DEBUG INFO ===');
  
  // Check cookies
  const cookies = document.cookie.split(';').reduce((acc, cookie) => {
    const [name, value] = cookie.trim().split('=');
    acc[name] = value;
    return acc;
  }, {} as Record<string, string>);
  
  console.log('Cookies:', cookies);
  console.log('Session token cookie:', cookies['session-token'] ? 'Present' : 'Missing');
  
  // Check localStorage
  const localStorage = window.localStorage;
  console.log('LocalStorage keys:', Object.keys(localStorage));
  
  // Check sessionStorage
  const sessionStorage = window.sessionStorage;
  console.log('SessionStorage keys:', Object.keys(sessionStorage));
  
  // Check if we're in incognito mode
  const isIncognito = !window.indexedDB;
  console.log('Incognito mode:', isIncognito);
  
  console.log('=== END AUTH DEBUG ===');
}

// Call this function in browser console to debug auth issues
if (typeof window !== 'undefined') {
  (window as any).debugAuth = debugAuthState;
}
