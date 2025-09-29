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

export interface EventPricingTier {
  id: string;
  tierType: string;
  price: number;
  maxSpots?: number | null;
  currentSpots: number;
  sortOrder: number;
  spotsLeft?: number;
  isSoldOut?: boolean;
}

export interface EventRSVP {
  id: string;
  status: 'GOING' | 'NOT_GOING' | 'PENDING';
  userId: string;
  userName: string;
  profilePhotoUrl?: string | null;
  createdAt: string;
  pricingTierId?: string | null;
  pricePaid?: number | null;
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
  useTieredPricing?: boolean;
  pricingTiers?: EventPricingTier[];
  coveId: string;
  host: Host;
  cove: Cove;
  rsvpStatus?: 'GOING' | 'NOT_GOING' | 'PENDING' | null;
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