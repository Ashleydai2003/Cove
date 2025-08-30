export interface CoverPhoto {
  id: string;
  url: string;
}

export interface Host {
  id?: string;
  name: string;
}

export interface Cove {
  id?: string;
  name?: string;
  coverPhoto?: CoverPhoto | null;
}

export interface EventRSVP {
  id: string;
  status: 'GOING' | 'MAYBE' | 'NOT_GOING';
  userId: string;
  userName: string;
  profilePhotoUrl?: string | null;
  createdAt: string;
}

export interface Event {
  id: string;
  name: string;
  description?: string;
  date: string;
  location: string;
  memberCap?: number | null;
  ticketPrice?: number | null;
  paymentHandle?: string | null;
  coveId: string;
  host: Host;
  cove: Cove;
  rsvpStatus?: 'GOING' | 'MAYBE' | 'NOT_GOING' | 'PENDING' | null;
  goingCount?: number;
  rsvps?: EventRSVP[];
  coverPhoto?: CoverPhoto;
  isHost?: boolean;
}

export interface EventResponse {
  event: Event;
}

export interface ApiError {
  message: string;
  error?: string;
} 