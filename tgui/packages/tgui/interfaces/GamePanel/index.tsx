import { useEffect, useState } from 'react';
import { Button, Stack, Tabs } from 'tgui-core/components';
import { fetchRetry } from 'tgui-core/http';

import { resolveAsset } from '../../assets';
import { useBackend } from '../../backend';
import { Window } from '../../layouts';
import { logger } from '../../logging';
import { GamePanelTabs } from './constants';
import { CreateObject } from './CreateObject';
import { Data, GamePanelTabName } from './types';

export function GamePanel(props) {
  const { act } = useBackend();
  const [selectedTab, setSelectedTab] = useState<
    GamePanelTabName | undefined
  >();
  const [data, setData] = useState<Data | undefined>();

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

  const selectedTabData = data && selectedTab && data[selectedTab];

  return (
    <Window
      height={selectedTab ? 500 : 80}
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
          <Stack vertical={false}>
            <Stack.Item shrink={3} width="100%">
              <Tabs fluid>
                {GamePanelTabs.map((tab) => (
                  <Tabs.Tab
                    key={tab.name}
                    onClick={() => setSelectedTab(tab.name)}
                    selected={selectedTab === tab.name}
                    icon={tab.icon}
                  >
                    {tab.content}
                  </Tabs.Tab>
                ))}
              </Tabs>
            </Stack.Item>
          </Stack>
          <Stack.Item grow>
            {selectedTabData && (
              <CreateObject
                objList={selectedTabData}
                tabName={selectedTab || ''}
              />
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
}
