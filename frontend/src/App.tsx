import { useState } from 'react';
import AppLayout from '@cloudscape-design/components/app-layout';
import TopNavigation from '@cloudscape-design/components/top-navigation';
import SideNavigation from '@cloudscape-design/components/side-navigation';
import EventsView from './components/EventsView';
import UsersView from './components/UsersView';
import RegistrationsView from './components/RegistrationsView';

type View = 'events' | 'users' | 'registrations';

function App() {
  const [activeView, setActiveView] = useState<View>('events');
  const [navigationOpen, setNavigationOpen] = useState(true);

  const renderContent = () => {
    switch (activeView) {
      case 'events':
        return <EventsView />;
      case 'users':
        return <UsersView />;
      case 'registrations':
        return <RegistrationsView />;
      default:
        return <EventsView />;
    }
  };

  return (
    <>
      <TopNavigation
        identity={{
          href: '#',
          title: 'Events Management',
        }}
        utilities={[
          {
            type: 'button',
            text: 'Documentation',
            href: '#',
            external: true,
            externalIconAriaLabel: ' (opens in a new tab)',
          },
        ]}
      />
      <AppLayout
        navigation={
          <SideNavigation
            activeHref={`#/${activeView}`}
            header={{ text: 'Navigation', href: '#' }}
            onFollow={(event) => {
              if (!event.detail.external) {
                event.preventDefault();
                const view = event.detail.href.replace('#/', '') as View;
                setActiveView(view);
              }
            }}
            items={[
              { type: 'link', text: 'Events', href: '#/events' },
              { type: 'link', text: 'Users', href: '#/users' },
              { type: 'link', text: 'Registrations', href: '#/registrations' },
            ]}
          />
        }
        navigationOpen={navigationOpen}
        onNavigationChange={({ detail }) => setNavigationOpen(detail.open)}
        content={renderContent()}
        toolsHide
      />
    </>
  );
}

export default App;
