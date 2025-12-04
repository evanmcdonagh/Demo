export interface Event {
  eventId: string;
  title: string;
  description: string;
  date: string;
  location: string;
  capacity: number;
  organizer: string;
  status: 'scheduled' | 'ongoing' | 'completed' | 'cancelled' | 'active';
  currentRegistrations: number;
  waitlistEnabled: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface EventCreate {
  title: string;
  description: string;
  date: string;
  location: string;
  capacity: number;
  organizer: string;
  status: string;
  eventId?: string;
  waitlistEnabled?: boolean;
}

export interface User {
  userId: string;
  name: string;
  createdAt?: string;
}

export interface Registration {
  userId: string;
  eventId: string;
  registrationStatus: string;
  registeredAt: string;
}
