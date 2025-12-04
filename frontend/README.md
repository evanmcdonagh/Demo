# Events Management Frontend

A React TypeScript application built with Vite and AWS CloudScape Design System for managing events, users, and registrations.

## Features

- **Events Management**: Create, view, edit, and delete events
- **User Management**: Create users and view their registered events
- **Registration Management**: Register/unregister users for events with waitlist support
- **Modern UI**: Built with AWS CloudScape Design System components
- **Type-Safe**: Full TypeScript support
- **Fast Development**: Powered by Vite

## Prerequisites

- Node.js 18+ and npm
- Backend API running (either locally or deployed to AWS)

## Setup Instructions

### 1. Install Dependencies

```bash
cd frontend
npm install
```

### 2. Configure API Endpoint

The application needs to know where your backend API is running.

#### Option A: Using Environment Variables (Recommended)

1. Copy the example environment file:
```bash
cp .env.example .env
```

2. Edit `.env` and set your API URL:

For local development:
```
VITE_API_BASE_URL=http://localhost:8000
```

For deployed AWS API:
```
VITE_API_BASE_URL=https://your-api-id.execute-api.region.amazonaws.com/prod
```

#### Option B: Direct Configuration

Edit `src/config.ts` and update the `API_BASE_URL`:

```typescript
export const API_BASE_URL = 'https://your-api-url.com';
```

### 3. Run the Development Server

```bash
npm run dev
```

The application will start at `http://localhost:3000`

## Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build locally
- `npm run lint` - Run ESLint

## Connecting to Your Backend

### Local Backend

1. Start your backend server:
```bash
cd backend
uvicorn main:app --reload
```

2. The frontend is already configured to connect to `http://localhost:8000` by default

### AWS Deployed Backend

1. Deploy your backend to AWS using CDK:
```bash
cd infrastructure
npm run deploy
```

2. Copy the API Gateway URL from the deployment output

3. Update your `.env` file:
```
VITE_API_BASE_URL=https://abc123.execute-api.us-east-1.amazonaws.com/prod
```

4. Restart the development server

## Application Structure

```
frontend/
├── src/
│   ├── components/          # React components
│   │   ├── EventsView.tsx   # Events management
│   │   ├── UsersView.tsx    # User management
│   │   └── RegistrationsView.tsx  # Registration management
│   ├── App.tsx              # Main application component
│   ├── api.ts               # API client functions
│   ├── config.ts            # Configuration
│   ├── types.ts             # TypeScript type definitions
│   └── main.tsx             # Application entry point
├── index.html               # HTML template
├── package.json             # Dependencies
├── tsconfig.json            # TypeScript configuration
└── vite.config.ts           # Vite configuration
```

## Usage Guide

### Managing Events

1. Navigate to the **Events** tab
2. Click **Create Event** to add a new event
3. Fill in event details (title, description, date, location, capacity, etc.)
4. Select an event and click **Edit** to modify it
5. Select an event and click **Delete** to remove it

### Managing Users

1. Navigate to the **Users** tab
2. Click **Create User** to add a new user
3. Enter a user ID and name
4. Use the "View User Events" section to see events a user is registered for

### Managing Registrations

1. Navigate to the **Registrations** tab
2. Click **Register User** to register a user for an event
3. Enter the user ID and select an event
4. Click **Unregister User** to remove a registration
5. The table shows current event capacity and waitlist status

## API Integration

The application integrates with all backend API endpoints:

- `GET /events` - List all events
- `POST /events` - Create event
- `GET /events/{id}` - Get event details
- `PUT /events/{id}` - Update event
- `DELETE /events/{id}` - Delete event
- `POST /users` - Create user
- `GET /users/{id}` - Get user details
- `GET /users/{id}/events` - Get user's events
- `POST /registrations` - Register user for event
- `DELETE /registrations/{userId}/{eventId}` - Unregister user

## Troubleshooting

### CORS Errors

If you see CORS errors in the browser console:

1. Ensure your backend has CORS enabled (it should be by default)
2. Check that the API URL in your configuration is correct
3. Verify the backend is running and accessible

### API Connection Failed

1. Check that the backend server is running
2. Verify the API URL in `.env` or `config.ts` is correct
3. Test the API directly: `curl http://localhost:8000/health`
4. Check browser console for detailed error messages

### Build Errors

1. Delete `node_modules` and reinstall:
```bash
rm -rf node_modules package-lock.json
npm install
```

2. Clear Vite cache:
```bash
rm -rf node_modules/.vite
```

## Production Build

To create a production build:

```bash
npm run build
```

The built files will be in the `dist/` directory. You can deploy these to:
- AWS S3 + CloudFront
- Netlify
- Vercel
- Any static hosting service

To test the production build locally:

```bash
npm run preview
```

## Technology Stack

- **React 18** - UI framework
- **TypeScript** - Type safety
- **Vite** - Build tool and dev server
- **AWS CloudScape** - Design system and UI components
- **Fetch API** - HTTP client

## License

MIT
