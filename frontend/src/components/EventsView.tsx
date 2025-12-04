import { useState, useEffect } from 'react';
import Container from '@cloudscape-design/components/container';
import Header from '@cloudscape-design/components/header';
import SpaceBetween from '@cloudscape-design/components/space-between';
import Button from '@cloudscape-design/components/button';
import Table from '@cloudscape-design/components/table';
import Box from '@cloudscape-design/components/box';
import Modal from '@cloudscape-design/components/modal';
import FormField from '@cloudscape-design/components/form-field';
import Input from '@cloudscape-design/components/input';
import Textarea from '@cloudscape-design/components/textarea';
import Select from '@cloudscape-design/components/select';
import Toggle from '@cloudscape-design/components/toggle';
import Flashbar from '@cloudscape-design/components/flashbar';
import { Event, EventCreate } from '../types';
import { eventApi } from '../api';

export default function EventsView() {
  const [events, setEvents] = useState<Event[]>([]);
  const [loading, setLoading] = useState(false);
  const [selectedItems, setSelectedItems] = useState<Event[]>([]);
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [notifications, setNotifications] = useState<any[]>([]);

  const [formData, setFormData] = useState<EventCreate>({
    title: '',
    description: '',
    date: '',
    location: '',
    capacity: 50,
    organizer: '',
    status: 'scheduled',
    waitlistEnabled: false,
  });

  useEffect(() => {
    loadEvents();
  }, []);

  const loadEvents = async () => {
    setLoading(true);
    try {
      const data = await eventApi.list();
      setEvents(data);
    } catch (error) {
      addNotification('error', 'Failed to load events', String(error));
    } finally {
      setLoading(false);
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

  const handleCreate = async () => {
    try {
      await eventApi.create(formData);
      addNotification('success', 'Event created', 'Event created successfully');
      setShowCreateModal(false);
      resetForm();
      loadEvents();
    } catch (error) {
      addNotification('error', 'Failed to create event', String(error));
    }
  };

  const handleUpdate = async () => {
    if (selectedItems.length === 0) return;
    try {
      await eventApi.update(selectedItems[0].eventId, formData);
      addNotification('success', 'Event updated', 'Event updated successfully');
      setShowEditModal(false);
      resetForm();
      loadEvents();
    } catch (error) {
      addNotification('error', 'Failed to update event', String(error));
    }
  };

  const handleDelete = async () => {
    if (selectedItems.length === 0) return;
    try {
      await eventApi.delete(selectedItems[0].eventId);
      addNotification('success', 'Event deleted', 'Event deleted successfully');
      setSelectedItems([]);
      loadEvents();
    } catch (error) {
      addNotification('error', 'Failed to delete event', String(error));
    }
  };

  const openEditModal = () => {
    if (selectedItems.length === 0) return;
    const event = selectedItems[0];
    setFormData({
      title: event.title,
      description: event.description,
      date: event.date,
      location: event.location,
      capacity: event.capacity,
      organizer: event.organizer,
      status: event.status,
      waitlistEnabled: event.waitlistEnabled,
    });
    setShowEditModal(true);
  };

  const resetForm = () => {
    setFormData({
      title: '',
      description: '',
      date: '',
      location: '',
      capacity: 50,
      organizer: '',
      status: 'scheduled',
      waitlistEnabled: false,
    });
  };

  return (
    <SpaceBetween size="l">
      <Flashbar items={notifications} />
      
      <Container
        header={
          <Header
            variant="h1"
            actions={
              <SpaceBetween direction="horizontal" size="xs">
                <Button onClick={loadEvents} iconName="refresh">
                  Refresh
                </Button>
                <Button
                  onClick={openEditModal}
                  disabled={selectedItems.length !== 1}
                >
                  Edit
                </Button>
                <Button
                  onClick={handleDelete}
                  disabled={selectedItems.length !== 1}
                >
                  Delete
                </Button>
                <Button
                  variant="primary"
                  onClick={() => setShowCreateModal(true)}
                >
                  Create Event
                </Button>
              </SpaceBetween>
            }
          >
            Events
          </Header>
        }
      >
        <Table
          columnDefinitions={[
            {
              id: 'title',
              header: 'Title',
              cell: (item) => item.title,
              sortingField: 'title',
            },
            {
              id: 'date',
              header: 'Date',
              cell: (item) => item.date,
              sortingField: 'date',
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
            {
              id: 'capacity',
              header: 'Capacity',
              cell: (item) => `${item.currentRegistrations}/${item.capacity}`,
            },
            {
              id: 'organizer',
              header: 'Organizer',
              cell: (item) => item.organizer,
            },
          ]}
          items={events}
          loading={loading}
          loadingText="Loading events"
          selectionType="single"
          selectedItems={selectedItems}
          onSelectionChange={({ detail }) =>
            setSelectedItems(detail.selectedItems)
          }
          empty={
            <Box textAlign="center" color="inherit">
              <b>No events</b>
              <Box padding={{ bottom: 's' }} variant="p" color="inherit">
                No events to display.
              </Box>
              <Button onClick={() => setShowCreateModal(true)}>
                Create event
              </Button>
            </Box>
          }
        />
      </Container>

      <Modal
        onDismiss={() => {
          setShowCreateModal(false);
          resetForm();
        }}
        visible={showCreateModal}
        header="Create Event"
        footer={
          <Box float="right">
            <SpaceBetween direction="horizontal" size="xs">
              <Button
                variant="link"
                onClick={() => {
                  setShowCreateModal(false);
                  resetForm();
                }}
              >
                Cancel
              </Button>
              <Button variant="primary" onClick={handleCreate}>
                Create
              </Button>
            </SpaceBetween>
          </Box>
        }
      >
        <SpaceBetween size="m">
          <FormField label="Title">
            <Input
              value={formData.title}
              onChange={({ detail }) =>
                setFormData({ ...formData, title: detail.value })
              }
            />
          </FormField>
          <FormField label="Description">
            <Textarea
              value={formData.description}
              onChange={({ detail }) =>
                setFormData({ ...formData, description: detail.value })
              }
            />
          </FormField>
          <FormField label="Date (YYYY-MM-DD)">
            <Input
              value={formData.date}
              onChange={({ detail }) =>
                setFormData({ ...formData, date: detail.value })
              }
              placeholder="2024-12-31"
            />
          </FormField>
          <FormField label="Location">
            <Input
              value={formData.location}
              onChange={({ detail }) =>
                setFormData({ ...formData, location: detail.value })
              }
            />
          </FormField>
          <FormField label="Capacity">
            <Input
              type="number"
              value={String(formData.capacity)}
              onChange={({ detail }) =>
                setFormData({ ...formData, capacity: parseInt(detail.value) || 0 })
              }
            />
          </FormField>
          <FormField label="Organizer">
            <Input
              value={formData.organizer}
              onChange={({ detail }) =>
                setFormData({ ...formData, organizer: detail.value })
              }
            />
          </FormField>
          <FormField label="Status">
            <Select
              selectedOption={{ label: formData.status, value: formData.status }}
              onChange={({ detail }) =>
                setFormData({ ...formData, status: detail.selectedOption.value || 'scheduled' })
              }
              options={[
                { label: 'scheduled', value: 'scheduled' },
                { label: 'ongoing', value: 'ongoing' },
                { label: 'completed', value: 'completed' },
                { label: 'cancelled', value: 'cancelled' },
                { label: 'active', value: 'active' },
              ]}
            />
          </FormField>
          <FormField label="Waitlist Enabled">
            <Toggle
              checked={formData.waitlistEnabled || false}
              onChange={({ detail }) =>
                setFormData({ ...formData, waitlistEnabled: detail.checked })
              }
            >
              Enable waitlist
            </Toggle>
          </FormField>
        </SpaceBetween>
      </Modal>

      <Modal
        onDismiss={() => {
          setShowEditModal(false);
          resetForm();
        }}
        visible={showEditModal}
        header="Edit Event"
        footer={
          <Box float="right">
            <SpaceBetween direction="horizontal" size="xs">
              <Button
                variant="link"
                onClick={() => {
                  setShowEditModal(false);
                  resetForm();
                }}
              >
                Cancel
              </Button>
              <Button variant="primary" onClick={handleUpdate}>
                Update
              </Button>
            </SpaceBetween>
          </Box>
        }
      >
        <SpaceBetween size="m">
          <FormField label="Title">
            <Input
              value={formData.title}
              onChange={({ detail }) =>
                setFormData({ ...formData, title: detail.value })
              }
            />
          </FormField>
          <FormField label="Description">
            <Textarea
              value={formData.description}
              onChange={({ detail }) =>
                setFormData({ ...formData, description: detail.value })
              }
            />
          </FormField>
          <FormField label="Date (YYYY-MM-DD)">
            <Input
              value={formData.date}
              onChange={({ detail }) =>
                setFormData({ ...formData, date: detail.value })
              }
              placeholder="2024-12-31"
            />
          </FormField>
          <FormField label="Location">
            <Input
              value={formData.location}
              onChange={({ detail }) =>
                setFormData({ ...formData, location: detail.value })
              }
            />
          </FormField>
          <FormField label="Capacity">
            <Input
              type="number"
              value={String(formData.capacity)}
              onChange={({ detail }) =>
                setFormData({ ...formData, capacity: parseInt(detail.value) || 0 })
              }
            />
          </FormField>
          <FormField label="Organizer">
            <Input
              value={formData.organizer}
              onChange={({ detail }) =>
                setFormData({ ...formData, organizer: detail.value })
              }
            />
          </FormField>
          <FormField label="Status">
            <Select
              selectedOption={{ label: formData.status, value: formData.status }}
              onChange={({ detail }) =>
                setFormData({ ...formData, status: detail.selectedOption.value || 'scheduled' })
              }
              options={[
                { label: 'scheduled', value: 'scheduled' },
                { label: 'ongoing', value: 'ongoing' },
                { label: 'completed', value: 'completed' },
                { label: 'cancelled', value: 'cancelled' },
                { label: 'active', value: 'active' },
              ]}
            />
          </FormField>
          <FormField label="Waitlist Enabled">
            <Toggle
              checked={formData.waitlistEnabled || false}
              onChange={({ detail }) =>
                setFormData({ ...formData, waitlistEnabled: detail.checked })
              }
            >
              Enable waitlist
            </Toggle>
          </FormField>
        </SpaceBetween>
      </Modal>
    </SpaceBetween>
  );
}
