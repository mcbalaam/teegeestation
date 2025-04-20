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

interface CreateObjectProps {
  objList: {
    Objects: Record<
      string,
      { icon: string; icon_state: string; name: string; mapping: boolean }
    >;
    Turfs: Record<
      string,
      { icon: string; icon_state: string; name: string; mapping: boolean }
    >;
    Mobs: Record<
      string,
      { icon: string; icon_state: string; name: string; mapping: boolean }
    >;
  };
}

interface GamePanelData {
  icon: string;
  iconState: string;
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
  const preferences = data.preferences || {
    hide_icons: false,
    hide_mappings: false,
    sort_by: 'Objects',
    search_text: '',
    search_by: 'name',
  };

  const [searchText, setSearchText] = useState(preferences.search_text);
  const [tooltipIcon, setTooltipIcon] = useState(false);
  const [selectedObj, setSelectedObj] = useState(-1);
  const [searchBy, setSearchBy] = useState(preferences.search_by === 'type');
  const [sortBy, setSortBy] = useState(
    listTypes[preferences.sort_by] || listTypes.Objects,
  );
  const [hideMapping, setHideMapping] = useState(preferences.hide_mappings);
  const [hideIcons, setHideIcons] = useState(preferences.hide_icons);
  const { objList } = props;

  useEffect(() => {
    setSearchText(preferences.search_text);
    setSearchBy(preferences.search_by === 'type');
    setSortBy(listTypes[preferences.sort_by] || listTypes.Objects);
    setHideMapping(preferences.hide_mappings);
    setHideIcons(preferences.hide_icons);
  }, [preferences]);

  const currentType =
    Object.entries(listTypes).find(([_, value]) => value === sortBy)?.[0] ||
    'Objects';

  const currentList = objList?.[currentType] || {};

  return (
    <Stack vertical fill>
      <Stack.Item>
        <Section>
          <CreateObjectSettings />
        </Section>
      </Stack.Item>

      <Stack.Item>
        <Section>
          <Stack vertical>
            <Stack>
              <Stack.Item>
                <Button.Checkbox
                  onClick={() => {
                    setHideMapping(!hideMapping);
                    act('toggle-hide-mappings');
                  }}
                  color={hideMapping && 'good'}
                  checked={hideMapping}
                >
                  Hide mapping
                </Button.Checkbox>
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon={sortBy}
                  onClick={() => {
                    const types = Object.values(listTypes);
                    const currentIndex = types.indexOf(sortBy);
                    const nextIndex = (currentIndex + 1) % types.length;
                    setSortBy(types[nextIndex]);

                    const nextType =
                      Object.keys(listTypes).find(
                        (key) => listTypes[key] === types[nextIndex],
                      ) || 'Objects';
                    act('set-sort-by', { new_sort_by: nextType });
                  }}
                  tooltip={
                    listNames[
                      Object.keys(listTypes).find(
                        (key) => listTypes[key] === sortBy,
                      ) || 'Objects'
                    ]
                  }
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
                    act('toggle-search-by', {
                      new_search_by: !searchBy ? 'type' : 'name',
                    });
                  }}
                >
                  {searchBy ? 'Search by type' : 'Search by name'}
                </Button>
              </Stack.Item>
              <Stack.Item>
                <Button.Checkbox
                  onClick={() => {
                    setHideIcons(!hideIcons);
                    act('toggle-hide-icons');
                  }}
                  color={hideIcons && 'good'}
                  checked={hideIcons}
                >
                  Icons
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
                    act('set-search-text', { new_search_text: query });
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
                  if (hideMapping && Boolean(currentList[obj].mapping)) {
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
                      (hideIcons || tooltipIcon) && (
                        <DmIcon
                          icon={currentList[obj].icon}
                          icon_state={currentList[obj].icon_state}
                        />
                      )
                    }
                    tooltipPosition="top-start"
                    fluid
                    selected={selectedObj === index}
                    style={{
                      backgroundColor:
                        selectedObj === index
                          ? 'rgba(255, 255, 255, 0.1)'
                          : undefined,
                      color: selectedObj === index ? '#fff' : undefined,
                    }}
                    onDoubleClick={() => {
                      if (selectedObj !== -1) {
                        const selectedObject =
                          Object.keys(currentList)[selectedObj];
                        act('create-object-action', {
                          object_list: selectedObject,
                        });
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
                      setSelectedObj(index);
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
