import { useBackend } from '../../backend';
import { Window } from '../../layouts';
import { AnnouncementRecorderModal } from './AnnouncementRecorderModal';

export const AnnouncementRecorder = () => {
  return (
    <Window title="Announcement Recorder" width={520} height={480}>
      <Window.Content>
        <AnnouncementRecorderModal />
      </Window.Content>
    </Window>
  );
};
