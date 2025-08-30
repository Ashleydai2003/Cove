import { Event, EventResponse, ApiError } from '@/types/event';
import { config } from '@/lib/config';

class ApiClient {
  private baseUrl: string;

  constructor(baseUrl: string = config.apiUrl) {
    this.baseUrl = baseUrl;
  }

  async fetchEvent(eventId: string): Promise<Event> {
    try {
      // Use the web app's API route instead of calling backend directly
      const url = `/api/event?eventId=${encodeURIComponent(eventId)}`;
      
      const response = await fetch(url, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
        credentials: 'include', // Include cookies for authentication
        // Don't cache authenticated requests
        cache: 'no-store',
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
      
      if (error instanceof Error) {
        throw error;
      }
      
      throw new Error('Failed to fetch event data');
    }
  }

  // Future: Add authentication and RSVP methods
  async updateRSVP(eventId: string, status: string, authToken?: string): Promise<void> {
    // This will be implemented when authentication is added
    throw new Error('RSVP functionality requires authentication - coming soon!');
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
      cache: 'force-cache',
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