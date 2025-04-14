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
import { CreateObjectSettings } from './CreateObjectSettings';
import { CreateObjectProps } from './types';

export function CreateObject(props: CreateObjectProps) {
  const { act } = useBackend();
  const [searchText, setSearchText] = useState('');
  const [tooltipIcon, setTooltipIcon] = useState(false);
  const [selectedObj, setSelectedObj] = useState(-1);
  const [searchBy, setSearchBy] = useState(true);
  const [sortBy, setSortBy] = useState(true);
  const { objList, tabName } = props;

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
                  icon="toggle-off"
                  onClick={() => setSearchBy(!searchBy)}
                  tooltip={searchBy ? 'Search by type' : 'Search by name'}
                  tooltipPosition="top"
                />
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon="cat"
                  onClick={() => setSearchBy(!searchBy)}
                  tooltip={searchBy ? 'Search by type' : 'Search by name'}
                  tooltipPosition="top"
                />
              </Stack.Item>
              <Stack.Item>
                <Button
                  icon={searchBy ? 'code' : 'font'}
                  onClick={() => setSearchBy(!searchBy)}
                  tooltip={searchBy ? 'Search by type' : 'Search by name'}
                  tooltipPosition="top"
                />
              </Stack.Item>
            </Stack>
            <Stack.Item ml="0.5em">
              <VirtualList>
                {Object.keys(objList)
                  .filter((obj: string) => {
                    if (searchText === '') return false;
                    if (searchBy) {
                      return obj
                        .toLowerCase()
                        .includes(searchText.toLowerCase());
                    }
                    return objList[obj].name
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
                            icon={objList[obj].icon}
                            icon_state={objList[obj].icon_state}
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
                          {objList[obj].name}
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
