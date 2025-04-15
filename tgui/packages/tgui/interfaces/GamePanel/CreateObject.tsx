import { useState } from 'react';
import {
  Box,
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
    [key: string]: {
      icon: string;
      icon_state: string;
      name: string;
      mapping: boolean;
    };
  };
}

export function CreateObject(props: CreateObjectProps) {
  const { act } = useBackend();
  const [searchText, setSearchText] = useState('');
  const [tooltipIcon, setTooltipIcon] = useState(false);
  const [selectedObj, setSelectedObj] = useState(-1);
  const [searchBy, setSearchBy] = useState(true);
  const [sortBy, setSortBy] = useState(listTypes.Objects);
  const [hideMapping, setHideMapping] = useState(false);
  const { objList } = props;

  const currentList = objList;

  return (
    <Box>
      <Section>
        <CreateObjectSettings />
      </Section>

      <Box height="100%">
        <Section>
          <Stack vertical fill ml="-0.5em">
            <Stack>
              <Stack.Item grow>
                <SearchBar
                  noIcon
                  placeholder={'Search here...'}
                  query=""
                  onSearch={(query) => {
                    setSearchText(query);
                  }}
                />
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon={hideMapping ? 'toggle-on' : 'toggle-off'}
                  onClick={() => setHideMapping(!hideMapping)}
                  tooltip={
                    hideMapping
                      ? 'Hide mapping objects'
                      : 'Show mapping objects'
                  }
                  color={hideMapping && 'good'}
                />
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
                />
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon={searchBy ? 'code' : 'font'}
                  onClick={() => setSearchBy(!searchBy)}
                  tooltip={searchBy ? 'Search by type' : 'Search by name'}
                />
              </Stack.Item>
            </Stack>
            <Stack.Item
              ml="0.5em"
              style={{
                visibility:
                  Object.keys(currentList).length === 0 ? 'hidden' : 'visible',
              }}
            >
              <VirtualList>
                {Object.keys(currentList)
                  .filter((obj: string) => {
                    if (searchText === '') return false;
                    if (hideMapping && currentList[obj].mapping) return false;
                    if (searchBy) {
                      return obj
                        .toLowerCase()
                        .includes(searchText.toLowerCase());
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
                      onDoubleClick={(e) => act('create-object-action')}
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
            </Stack.Item>
          </Stack>
        </Section>
      </Box>
    </Box>
  );
}
