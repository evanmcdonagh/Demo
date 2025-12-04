import { config } from './config';
import { Event, EventCreate, User, Registration } from './types';

const API_URL = config.apiBaseUrl;

async function handleResponse<T>(response: Response): Promise<T> {
  if (!response.ok) {
    const error = await response.json().catch(() => ({ detail: 'An error occurred' }));
    throw new Error(error.detail || `HTTP error! status: ${response.status}`);
  }
  
  if (response.status === 204) {
    return null as T;
  }
  
  return response.json();
}

// Event API
export const eventApi = {
  list: async (status?: string): Promise<Event[]> => {
    const url = status ? `${API_URL}/events?status=${status}` : `${API_URL}/events`;
    const response = await fetch(url);
    return handleResponse<Event[]>(response);
  },

  get: async (eventId: string): Promise<Event> => {
    const response = await fetch(`${API_URL}/events/${eventId}`);
    return handleResponse<Event>(response);
  },

  create: async (event: EventCreate): Promise<Event> => {
    const response = await fetch(`${API_URL}/events`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(event),
    });
    return handleResponse<Event>(response);
  },

  update: async (eventId: string, updates: Partial<EventCreate>): Promise<Event> => {
    const response = await fetch(`${API_URL}/events/${eventId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(updates),
    });
    return handleResponse<Event>(response);
  },

  delete: async (eventId: string): Promise<void> => {
    const response = await fetch(`${API_URL}/events/${eventId}`, {
      method: 'DELETE',
    });
    return handleResponse<void>(response);
  },

  getRegistrations: async (eventId: string): Promise<Registration[]> => {
    const response = await fetch(`${API_URL}/events/${eventId}/registrations`);
    return handleResponse<Registration[]>(response);
  },
};

// User API
export const userApi = {
  create: async (user: { userId: string; name: string }): Promise<User> => {
    const response = await fetch(`${API_URL}/users`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(user),
    });
    return handleResponse<User>(response);
  },

  get: async (userId: string): Promise<User> => {
    const response = await fetch(`${API_URL}/users/${userId}`);
    return handleResponse<User>(response);
  },

  getEvents: async (userId: string): Promise<Event[]> => {
    const response = await fetch(`${API_URL}/users/${userId}/events`);
    return handleResponse<Event[]>(response);
  },

  getRegistrations: async (userId: string): Promise<Registration[]> => {
    const response = await fetch(`${API_URL}/users/${userId}/registrations`);
    return handleResponse<Registration[]>(response);
  },
};

// Registration API
export const registrationApi = {
  register: async (userId: string, eventId: string): Promise<Registration> => {
    const response = await fetch(`${API_URL}/registrations`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ userId, eventId }),
    });
    return handleResponse<Registration>(response);
  },

  unregister: async (userId: string, eventId: string): Promise<void> => {
    const response = await fetch(`${API_URL}/registrations/${userId}/${eventId}`, {
      method: 'DELETE',
    });
    return handleResponse<void>(response);
  },
};
