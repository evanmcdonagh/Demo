import { useState } from 'react';
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
import { Event } from '../types';
import { userApi } from '../api';

export default function UsersView() {
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showEventsModal, setShowEventsModal] = useState(false);
  const [userEvents, setUserEvents] = useState<Event[]>([]);
  const [notifications, setNotifications] = useState<any[]>([]);
  const [userId, setUserId] = useState('');
  const [userName, setUserName] = useState('');
  const [searchUserId, setSearchUserId] = useState('');

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

  const handleCreateUser = async () => {
    try {
      await userApi.create({ userId, name: userName });
      addNotification('success', 'User created', `User ${userId} created successfully`);
      setShowCreateModal(false);
      setUserId('');
      setUserName('');
    } catch (error) {
      addNotification('error', 'Failed to create user', String(error));
    }
  };

  const handleViewUserEvents = async () => {
    if (!searchUserId) {
      addNotification('error', 'User ID required', 'Please enter a user ID');
      return;
    }
    
    try {
      const events = await userApi.getEvents(searchUserId);
      setUserEvents(events);
      setShowEventsModal(true);
    } catch (error) {
      addNotification('error', 'Failed to load user events', String(error));
    }
  };

  return (
    <SpaceBetween size="l">
      <Flashbar items={notifications} />
      
      <Container
        header={
          <Header
            variant="h1"
            actions={
              <Button
                variant="primary"
                onClick={() => setShowCreateModal(true)}
              >
                Create User
              </Button>
            }
          >
            Users
          </Header>
        }
      >
        <SpaceBetween size="m">
          <Box variant="p">
            Create new users and view their registered events.
          </Box>
          
          <FormField
            label="View User Events"
            description="Enter a user ID to see their registered events"
          >
            <SpaceBetween direction="horizontal" size="xs">
              <Input
                value={searchUserId}
                onChange={({ detail }) => setSearchUserId(detail.value)}
                placeholder="Enter user ID"
              />
              <Button onClick={handleViewUserEvents}>
                View Events
              </Button>
            </SpaceBetween>
          </FormField>
        </SpaceBetween>
      </Container>

      <Modal
        onDismiss={() => {
          setShowCreateModal(false);
          setUserId('');
          setUserName('');
        }}
        visible={showCreateModal}
        header="Create User"
        footer={
          <Box float="right">
            <SpaceBetween direction="horizontal" size="xs">
              <Button
                variant="link"
                onClick={() => {
                  setShowCreateModal(false);
                  setUserId('');
                  setUserName('');
                }}
              >
                Cancel
              </Button>
              <Button variant="primary" onClick={handleCreateUser}>
                Create
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
          <FormField label="Name">
            <Input
              value={userName}
              onChange={({ detail }) => setUserName(detail.value)}
              placeholder="John Doe"
            />
          </FormField>
        </SpaceBetween>
      </Modal>

      <Modal
        onDismiss={() => setShowEventsModal(false)}
        visible={showEventsModal}
        header={`Events for User: ${searchUserId}`}
        size="large"
      >
        <Table
          columnDefinitions={[
            {
              id: 'title',
              header: 'Title',
              cell: (item) => item.title,
            },
            {
              id: 'date',
              header: 'Date',
              cell: (item) => item.date,
            },
            {
              id: 'location',
              header: 'Location',
              cell: (item) => item.location,
            },
            {
              id: 'status',
              header: 'Status',
              cell: (item) => item.status,
            },
          ]}
          items={userEvents}
          empty={
            <Box textAlign="center" color="inherit">
              <b>No events</b>
              <Box padding={{ bottom: 's' }} variant="p" color="inherit">
                This user is not registered for any events.
              </Box>
            </Box>
          }
        />
      </Modal>
    </SpaceBetween>
  );
}
