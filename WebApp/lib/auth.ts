// Authentication utilities for the web app

export interface User {
  id: string;
  name: string;
  phone: string;
  onboarding: boolean;
  verified: boolean;
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
    await fetch('/api/auth/logout', {
      method: 'POST',
      credentials: 'include',
    });
  } catch (error) {
    console.error('Logout error:', error);
  }
} 