import { useState } from 'react';
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

export function CreateObject(props: CreateObjectProps) {
  const { act } = useBackend();
  const [searchText, setSearchText] = useState('');
  const [tooltipIcon, setTooltipIcon] = useState(false);
  const [selectedObj, setSelectedObj] = useState(-1);
  const [searchBy, setSearchBy] = useState(true);
  const [sortBy, setSortBy] = useState(listTypes.Objects);
  const [hideMapping, setHideMapping] = useState(true);
  const { objList } = props;

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
                  onClick={() => setHideMapping(!hideMapping)}
                  color={hideMapping && 'good'}
                  checked={hideMapping}
                >
                  Hide mapping types
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
                  onClick={() => setSearchBy(!searchBy)}
                >
                  {searchBy ? 'Search by type' : 'Search by name'}
                </Button>
              </Stack.Item>
            </Stack>
            <Stack>
              <Stack.Item grow ml="-0.5em">
                <SearchBar
                  noIcon
                  placeholder={'Search here...'}
                  query=""
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
                      tooltipIcon && (
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
