import { Event, EventResponse, ApiError } from '@/types/event';
import { config } from '@/lib/config';

class ApiClient {
  private baseUrl: string;

  constructor(baseUrl: string = config.apiUrl) {
    this.baseUrl = baseUrl;
  }

  async fetchEvent(eventId: string): Promise<Event> {
    try {
      const url = `${this.baseUrl}/event?eventId=${encodeURIComponent(eventId)}`;
      
      const response = await fetch(url, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
        credentials: 'include', // Include cookies for authentication
        // Browser caching
        cache: 'force-cache',
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
    return await apiClient.fetchEvent(eventId);
  } catch (error) {
    console.error(`Failed to fetch event ${eventId}:`, error);
    return null;
  }
} 