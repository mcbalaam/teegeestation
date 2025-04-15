import { useEffect, useState } from 'react';
import { Button, Stack } from 'tgui-core/components';
import { fetchRetry } from 'tgui-core/http';

import { resolveAsset } from '../../assets';
import { useBackend } from '../../backend';
import { Window } from '../../layouts';
import { logger } from '../../logging';
import { CreateObject } from './CreateObject';

interface CreateObjectData {
  [key: string]: {
    [key: string]: {
      icon: string;
      icon_state: string;
      name: string;
      mapping: boolean;
    };
  };
}

export function GamePanel(props) {
  const { act } = useBackend();
  const [data, setData] = useState<CreateObjectData | undefined>();

  useEffect(() => {
    fetchRetry(resolveAsset('gamepanel.json'))
      .then((response) => response.json())
      .then((data) => {
        setData(data);
      })
      .catch((error) => {
        logger.log('Failed to fetch gamepanel.json', error);
      });
  }, []);

  return (
    <Window
      height={500}
      title="Spawn Panel"
      width={500}
      theme="admin"
      buttons={
        <Button
          height="100%"
          align="center"
          verticalAlignContent="middle"
          fluid
          onClick={() => act('game-mode-panel')}
          icon="gamepad"
        >
          Game Mode Panel
        </Button>
      }
    >
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item grow>
            {data && <CreateObject objList={data.Objects} />}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
}
