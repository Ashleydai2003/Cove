import { Event, EventResponse, ApiError } from '@/types/event';
import { config } from '@/lib/config';

class ApiClient {
  private baseUrl: string;

  constructor(baseUrl: string = config.apiUrl) {
    this.baseUrl = baseUrl;
  }

  async fetchEvent(eventId: string, forceFresh: boolean = false): Promise<Event> {
    try {
      const url = `/api/event?eventId=${encodeURIComponent(eventId)}${forceFresh ? `&_t=${Date.now()}` : ''}`;

      const response = await fetch(url, {
        method: 'GET',
        credentials: 'include', // Browser automatically includes auth cookies
        cache: forceFresh ? 'no-store' : 'default', // Force fresh data when needed
      });

      if (!response.ok) {
        const errorData: ApiError = await response.json().catch(() => ({
          message: `HTTP ${response.status}: ${response.statusText}`,
        }));
        
        throw new Error(errorData.message || `Failed to fetch event: ${response.statusText}`);
      }

      const data: EventResponse = await response.json();
      return data.event;
    } catch (error) {
      console.error('Error fetching event:', error);
      throw error instanceof Error ? error : new Error('Failed to fetch event data');
    }
  }

  async updateRSVP(eventId: string, status: string): Promise<void> {
    try {
      const response = await fetch('/api/rsvp', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        credentials: 'include', // Browser automatically includes auth cookies
        body: JSON.stringify({ eventId, status }),
      });

      if (!response.ok) {
        const errorData: ApiError = await response.json().catch(() => ({
          message: `HTTP ${response.status}: ${response.statusText}`,
        }));
        
        throw new Error(errorData.message || `Failed to update RSVP: ${response.statusText}`);
      }
    } catch (error) {
      console.error('Error updating RSVP:', error);
      throw error instanceof Error ? error : new Error('Failed to update RSVP');
    }
  }
}

export const apiClient = new ApiClient();

// Utility function for server-side data fetching
export async function getEventData(eventId: string): Promise<Event | null> {
  try {
    // For server-side rendering, we need to call the backend directly
    // since we don't have access to cookies in SSR context
    const url = `${process.env.BACKEND_API_URL}/event?eventId=${encodeURIComponent(eventId)}`;
    
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
      // Server-side requests don't include cookies, so we get unauthenticated response
      cache: 'force-cache', // Cache for SSR performance
    });

    if (!response.ok) {
      console.error(`Failed to fetch event ${eventId}: ${response.status}`);
      return null;
    }

    const data: EventResponse = await response.json();
    return data.event;
  } catch (error) {
    console.error(`Failed to fetch event ${eventId}:`, error);
    return null;
  }
} 