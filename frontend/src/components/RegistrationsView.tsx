import { useState, useEffect } from 'react';
import Container from '@cloudscape-design/components/container';
import Header from '@cloudscape-design/components/header';
import SpaceBetween from '@cloudscape-design/components/space-between';
import Button from '@cloudscape-design/components/button';
import Box from '@cloudscape-design/components/box';
import Modal from '@cloudscape-design/components/modal';
import FormField from '@cloudscape-design/components/form-field';
import Input from '@cloudscape-design/components/input';
import Flashbar from '@cloudscape-design/components/flashbar';
import Table from '@cloudscape-design/components/table';
import Select from '@cloudscape-design/components/select';
import { Event } from '../types';
import { eventApi, registrationApi } from '../api';

export default function RegistrationsView() {
  const [events, setEvents] = useState<Event[]>([]);
  const [showRegisterModal, setShowRegisterModal] = useState(false);
  const [showUnregisterModal, setShowUnregisterModal] = useState(false);
  const [notifications, setNotifications] = useState<any[]>([]);
  const [userId, setUserId] = useState('');
  const [selectedEvent, setSelectedEvent] = useState<{ label: string; value: string } | null>(null);
  const [unregisterUserId, setUnregisterUserId] = useState('');
  const [unregisterEventId, setUnregisterEventId] = useState('');

  useEffect(() => {
    loadEvents();
  }, []);

  const loadEvents = async () => {
    try {
      const data = await eventApi.list();
      setEvents(data);
    } catch (error) {
      addNotification('error', 'Failed to load events', String(error));
    }
  };

  const addNotification = (type: string, header: string, content: string) => {
    setNotifications([
      ...notifications,
      {
        type,
        header,
        content,
        dismissible: true,
        onDismiss: () => setNotifications([]),
        id: Date.now().toString(),
      },
    ]);
  };

  const handleRegister = async () => {
    if (!userId || !selectedEvent) {
      addNotification('error', 'Missing information', 'Please provide both user ID and event');
      return;
    }

    try {
      const result = await registrationApi.register(userId, selectedEvent.value);
      addNotification(
        'success',
        'Registration successful',
        `User ${userId} registered for event. Status: ${result.registrationStatus}`
      );
      setShowRegisterModal(false);
      setUserId('');
      setSelectedEvent(null);
    } catch (error) {
      addNotification('error', 'Registration failed', String(error));
    }
  };

  const handleUnregister = async () => {
    if (!unregisterUserId || !unregisterEventId) {
      addNotification('error', 'Missing information', 'Please provide both user ID and event ID');
      return;
    }

    try {
      await registrationApi.unregister(unregisterUserId, unregisterEventId);
      addNotification(
        'success',
        'Unregistration successful',
        `User ${unregisterUserId} unregistered from event`
      );
      setShowUnregisterModal(false);
      setUnregisterUserId('');
      setUnregisterEventId('');
    } catch (error) {
      addNotification('error', 'Unregistration failed', String(error));
    }
  };

  const eventOptions = events.map((event) => ({
    label: `${event.title} (${event.date})`,
    value: event.eventId,
  }));

  return (
    <SpaceBetween size="l">
      <Flashbar items={notifications} />
      
      <Container
        header={
          <Header
            variant="h1"
            actions={
              <SpaceBetween direction="horizontal" size="xs">
                <Button onClick={() => setShowUnregisterModal(true)}>
                  Unregister User
                </Button>
                <Button
                  variant="primary"
                  onClick={() => setShowRegisterModal(true)}
                >
                  Register User
                </Button>
              </SpaceBetween>
            }
          >
            Registrations
          </Header>
        }
      >
        <SpaceBetween size="m">
          <Box variant="p">
            Register users for events or unregister them. Users can be registered
            for events if capacity allows, or added to a waitlist if enabled.
          </Box>
          
          <Table
            columnDefinitions={[
              {
                id: 'title',
                header: 'Event',
                cell: (item) => item.title,
              },
              {
                id: 'date',
                header: 'Date',
                cell: (item) => item.date,
              },
              {
                id: 'capacity',
                header: 'Capacity',
                cell: (item) => `${item.currentRegistrations}/${item.capacity}`,
              },
              {
                id: 'waitlist',
                header: 'Waitlist',
                cell: (item) => item.waitlistEnabled ? 'Enabled' : 'Disabled',
              },
              {
                id: 'status',
                header: 'Status',
                cell: (item) => item.status,
              },
            ]}
            items={events}
            empty={
              <Box textAlign="center" color="inherit">
                <b>No events</b>
                <Box padding={{ bottom: 's' }} variant="p" color="inherit">
                  No events available for registration.
                </Box>
              </Box>
            }
          />
        </SpaceBetween>
      </Container>

      <Modal
        onDismiss={() => {
          setShowRegisterModal(false);
          setUserId('');
          setSelectedEvent(null);
        }}
        visible={showRegisterModal}
        header="Register User for Event"
        footer={
          <Box float="right">
            <SpaceBetween direction="horizontal" size="xs">
              <Button
                variant="link"
                onClick={() => {
                  setShowRegisterModal(false);
                  setUserId('');
                  setSelectedEvent(null);
                }}
              >
                Cancel
              </Button>
              <Button variant="primary" onClick={handleRegister}>
                Register
              </Button>
            </SpaceBetween>
          </Box>
        }
      >
        <SpaceBetween size="m">
          <FormField label="User ID">
            <Input
              value={userId}
              onChange={({ detail }) => setUserId(detail.value)}
              placeholder="user123"
            />
          </FormField>
          <FormField label="Event">
            <Select
              selectedOption={selectedEvent}
              onChange={({ detail }) => setSelectedEvent(detail.selectedOption)}
              options={eventOptions}
              placeholder="Select an event"
              empty="No events available"
            />
          </FormField>
        </SpaceBetween>
      </Modal>

      <Modal
        onDismiss={() => {
          setShowUnregisterModal(false);
          setUnregisterUserId('');
          setUnregisterEventId('');
        }}
        visible={showUnregisterModal}
        header="Unregister User from Event"
        footer={
          <Box float="right">
            <SpaceBetween direction="horizontal" size="xs">
              <Button
                variant="link"
                onClick={() => {
                  setShowUnregisterModal(false);
                  setUnregisterUserId('');
                  setUnregisterEventId('');
                }}
              >
                Cancel
              </Button>
              <Button variant="primary" onClick={handleUnregister}>
                Unregister
              </Button>
            </SpaceBetween>
          </Box>
        }
      >
        <SpaceBetween size="m">
          <FormField label="User ID">
            <Input
              value={unregisterUserId}
              onChange={({ detail }) => setUnregisterUserId(detail.value)}
              placeholder="user123"
            />
          </FormField>
          <FormField label="Event ID">
            <Input
              value={unregisterEventId}
              onChange={({ detail }) => setUnregisterEventId(detail.value)}
              placeholder="event-id"
            />
          </FormField>
        </SpaceBetween>
      </Modal>
    </SpaceBetween>
  );
}
