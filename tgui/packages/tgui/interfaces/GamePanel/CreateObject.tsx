import { useLocalStorage } from '@uidotdev/usehooks';
import { useEffect, useState } from 'react';
import {
  Button,
  DmIcon,
  Section,
  Stack,
  VirtualList,
} from 'tgui-core/components';

import { useBackend } from '../../backend';
import { SearchBar } from '../common/SearchBar';
import { listNames, listTypes } from './constants';
import { CreateObjectSettings } from './CreateObjectSettings';
import { CreateObjectProps } from './types';

interface GamePanelData {
  icon: string;
  iconState: string;
  selected_object?: string;
  preferences?: {
    hide_icons: boolean;
    hide_mappings: boolean;
    sort_by: string;
    search_text: string;
    search_by: string;
  };
}

export function CreateObject(props: CreateObjectProps) {
  const { act, data } = useBackend<GamePanelData>();
  const { objList } = props;

  const [tooltipIcon, setTooltipIcon] = useState(false);
  const [selectedObj, setSelectedObj] = useState<string | null>(null);

  const [searchText, setSearchText] = useLocalStorage(
    'gamepanel-searchText',
    '',
  );
  const [searchBy, setSearchBy] = useLocalStorage('gamepanel-searchBy', false);
  const [sortBy, setSortBy] = useLocalStorage(
    'gamepanel-sortBy',
    listTypes.Objects,
  );
  const [hideMapping, setHideMapping] = useLocalStorage(
    'gamepanel-hideMapping',
    false,
  );
  const [showIcons, setshowIcons] = useLocalStorage(
    'gamepanel-showIcons',
    false,
  );
  const [showPreview, setshowPreview] = useLocalStorage(
    'gamepanel-showPreview',
    false,
  );
  const currentType =
    Object.entries(listTypes).find(([_, value]) => value === sortBy)?.[0] ||
    'Objects';

  const currentList = objList?.[currentType] || {};

  useEffect(() => {
    if (data.selected_object) {
      setSelectedObj(data.selected_object);
      setSearchText(data.selected_object);
      setSearchBy(true);
    }
  }, [data.selected_object]);

  const sendPreferences = (settings) => {
    const prefsToSend = {
      hide_icons: showIcons,
      hide_mappings: hideMapping,
      sort_by:
        Object.keys(listTypes).find((key) => listTypes[key] === sortBy) ||
        'Objects',
      search_text: searchText,
      search_by: searchBy ? 'type' : 'name',
      ...settings,
    };

    act('create-object-action', prefsToSend);
  };

  return (
    <Stack vertical fill>
      <Stack.Item>
        <Section>
          <CreateObjectSettings onCreateObject={sendPreferences} />
        </Section>
      </Stack.Item>

      {showPreview && selectedObj && currentList[selectedObj] && (
        <Stack.Item>
          <Section
            style={{
              height: '6em',
            }}
          >
            <Stack>
              <Stack.Item>
                <Button
                  width="5em"
                  height="4.8em"
                  mb="-3px"
                  color="transparent"
                  ml="1px"
                  style={{
                    alignContent: 'center',
                  }}
                >
                  <DmIcon
                    width="4em"
                    mt="2px"
                    icon={currentList[selectedObj].icon}
                    icon_state={currentList[selectedObj].icon_state}
                  />
                </Button>
              </Stack.Item>
              <Stack.Item
                grow
                style={{
                  maxHeight: '4.8em',
                  overflowY: 'auto',
                }}
              >
                <Stack vertical>
                  <Stack.Item>
                    <b>{currentList[selectedObj].name}</b>
                  </Stack.Item>
                  <Stack.Item grow>
                    <i style={{ color: 'rgba(200, 200, 200, 0.7)' }}>
                      {currentList[selectedObj].description || 'no description'}
                    </i>
                  </Stack.Item>
                </Stack>
              </Stack.Item>
            </Stack>
          </Section>
        </Stack.Item>
      )}

      <Stack.Item>
        <Section>
          <Stack vertical>
            <Stack>
              <Stack.Item>
                <Button
                  icon={sortBy}
                  onClick={() => {
                    const types = Object.values(listTypes);
                    const currentIndex = types.indexOf(sortBy);
                    const nextIndex = (currentIndex + 1) % types.length;
                    setSortBy(types[nextIndex]);
                  }}
                >
                  {
                    listNames[
                      Object.keys(listTypes).find(
                        (key) => listTypes[key] === sortBy,
                      ) || 'Objects'
                    ]
                  }
                </Button>
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon={searchBy ? 'code' : 'font'}
                  onClick={() => {
                    setSearchBy(!searchBy);
                  }}
                >
                  {searchBy ? 'By type' : 'By name'}
                </Button>
              </Stack.Item>
              <Stack.Item>
                <Button.Checkbox
                  onClick={() => {
                    setHideMapping(!hideMapping);
                  }}
                  color={!hideMapping && 'good'}
                  checked={!hideMapping}
                >
                  Mapping
                </Button.Checkbox>
              </Stack.Item>
              <Stack.Item>
                <Button.Checkbox
                  onClick={() => {
                    setshowIcons(!showIcons);
                  }}
                  color={showIcons && 'good'}
                  checked={showIcons}
                >
                  Icons
                </Button.Checkbox>
              </Stack.Item>
              <Stack.Item>
                <Button.Checkbox
                  onClick={() => {
                    setshowPreview(!showPreview);
                  }}
                  color={showPreview && 'good'}
                  checked={showPreview}
                >
                  Preview
                </Button.Checkbox>
              </Stack.Item>
            </Stack>
            <Stack>
              <Stack.Item grow ml="-0.5em">
                <SearchBar
                  noIcon
                  placeholder={'Search here...'}
                  query={searchText}
                  onSearch={(query) => {
                    setSearchText(query);
                  }}
                />
              </Stack.Item>
            </Stack>
          </Stack>
        </Section>
      </Stack.Item>

      <Stack.Item grow>
        <Section fill scrollable>
          {searchText !== '' && (
            <VirtualList>
              {Object.keys(currentList)
                .filter((obj: string) => {
                  if (!hideMapping && Boolean(currentList[obj].mapping)) {
                    return false;
                  }
                  if (searchBy) {
                    return obj.toLowerCase().includes(searchText.toLowerCase());
                  }
                  return currentList[obj].name
                    ?.toLowerCase()
                    .includes(searchText.toLowerCase());
                })
                .map((obj, index) => (
                  <Button
                    key={index}
                    color="transparent"
                    tooltip={
                      (showIcons || tooltipIcon) && (
                        <DmIcon
                          icon={currentList[obj].icon}
                          icon_state={currentList[obj].icon_state}
                        />
                      )
                    }
                    tooltipPosition="top-start"
                    fluid
                    selected={selectedObj === obj}
                    style={{
                      backgroundColor:
                        selectedObj === obj
                          ? 'rgba(255, 255, 255, 0.1)'
                          : undefined,
                      color: selectedObj === obj ? '#fff' : undefined,
                    }}
                    onDoubleClick={() => {
                      if (selectedObj) {
                        sendPreferences({ object_list: selectedObj });
                      }
                    }}
                    onMouseDown={(e) => {
                      if (e.button === 0 && e.shiftKey) {
                        setTooltipIcon(true);
                      }
                    }}
                    onMouseUp={(e) => {
                      if (e.button === 0) {
                        setTooltipIcon(false);
                      }
                    }}
                    onClick={() => {
                      setSelectedObj(obj);
                      act('selected-object-changed', {
                        newObj: obj,
                      });
                    }}
                  >
                    {searchBy ? (
                      obj
                    ) : (
                      <>
                        {currentList[obj].name}
                        <span
                          className="label label-info"
                          style={{
                            marginLeft: '0.5em',
                            color: 'rgba(200, 200, 200, 0.5)',
                            fontSize: '10px',
                          }}
                        >
                          {obj}
                        </span>
                      </>
                    )}
                  </Button>
                ))}
            </VirtualList>
          )}
        </Section>
      </Stack.Item>
    </Stack>
  );
}
