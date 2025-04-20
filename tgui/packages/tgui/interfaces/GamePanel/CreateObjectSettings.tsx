import { useEffect, useState } from 'react';
import {
  Button,
  Dropdown,
  Input,
  NumberInput,
  Slider,
  Stack,
  Table,
} from 'tgui-core/components';

import { useBackend } from '../../backend';
import {
  directionIcons,
  directionNames,
  spawnLocationIcons,
  spawnLocationOptions,
} from './constants';

interface GamePanelData {
  icon: string;
  iconState: string;
  preferences?: {
    hide_icons: boolean;
    hide_mappings: boolean;
    sort_by: string;
    search_text: string;
    search_by: string;
    where_dropdown_value: string;
    offset_type: string;
    offset: string;
    object_count: number;
    dir: number;
    object_name: string;
  };
}
export function CreateObjectSettings(props) {
  const { act, data } = useBackend<GamePanelData>();
  const preferences = data.preferences || {
    object_count: 1,
    offset_type: 'relative',
    where_dropdown_value: 'Current location',
    dir: 1,
    offset: '',
    object_name: '',
  };

  const initialSpawnLocation = () => {
    const savedValue = data.preferences?.where_dropdown_value;
    if (savedValue && spawnLocationOptions.includes(savedValue)) {
      return savedValue;
    }
    return 'Current location';
  };

  const [amount, setAmount] = useState(preferences.object_count || 1);
  const [cordsType, setCordsType] = useState(
    preferences.offset_type === 'absolute' ? 1 : 0,
  );
  const [spawnLocation, setSpawnLocation] = useState(initialSpawnLocation());
  const [direction, setDirection] = useState(() => {
    if (preferences.dir) {
      return [1, 2, 4, 8].indexOf(preferences.dir);
    }
    return 0;
  });
  const [objectName, setObjectName] = useState(preferences.object_name || '');
  const [offset, setOffset] = useState(preferences.offset || '');

  useEffect(() => {
    if (data.preferences?.object_count) {
      setAmount(data.preferences.object_count);
    }
    if (data.preferences?.offset_type) {
      setCordsType(data.preferences.offset_type === 'absolute' ? 1 : 0);
    }
    if (data.preferences?.object_name) {
      setObjectName(data.preferences.object_name);
    }
    if (data.preferences?.dir) {
      setDirection([1, 2, 4, 8].indexOf(data.preferences.dir));
    }
    if (data.preferences?.offset) {
      setOffset(data.preferences.offset);
    }
    if (data.preferences?.where_dropdown_value) {
      const savedValue = data.preferences.where_dropdown_value;
      if (spawnLocationOptions.includes(savedValue)) {
        setSpawnLocation(savedValue);
      }
    }
  }, [data.preferences]);

  return (
    <Stack fill vertical>
      <Stack>
        <Stack.Item grow>
          <Table
            style={{
              paddingLeft: '5px',
            }}
          >
            <Table.Row className="candystripe" lineHeight="25px">
              <Table.Cell pl={1} width="80px">
                Amount:
              </Table.Cell>
              <Table.Cell>
                <NumberInput
                  minValue={1}
                  maxValue={150}
                  step={1}
                  value={amount}
                  onChange={(value) => {
                    setAmount(value);
                    act('number-changed', { newNumber: value });
                  }}
                  width="100%"
                />
              </Table.Cell>
            </Table.Row>
            <Table.Row className="candystripe" lineHeight="25px">
              <Table.Cell pl={1} width="80px">
                Direction:
              </Table.Cell>
              <Table.Cell>
                <Stack>
                  <Stack.Item>
                    <Button
                      icon={directionIcons[[1, 2, 4, 8][direction]]}
                      tooltip={directionNames[[1, 2, 4, 8][direction]]}
                      tooltipPosition="top"
                      fontSize="14"
                      onClick={() => {
                        const values = [1, 2, 4, 8];
                        const currentIndex = values.indexOf(
                          [1, 2, 4, 8][direction],
                        );
                        const nextIndex = (currentIndex + 1) % 4;
                        setDirection(nextIndex);
                        act('cycle_dir');
                      }}
                    />
                  </Stack.Item>
                  <Stack.Item grow>
                    <Slider
                      minValue={0}
                      maxValue={3}
                      step={1}
                      stepPixelSize={25}
                      value={direction}
                      format={(value) => {
                        const values = [1, 2, 4, 8];
                        return values[value].toString();
                      }}
                      onChange={(e, value) => {
                        const values = [1, 2, 4, 8];
                        setDirection(value);
                        act('dir-changed', { newDir: values[value] });
                      }}
                    />
                  </Stack.Item>
                </Stack>
              </Table.Cell>
            </Table.Row>
            <Table.Row className="candystripe" lineHeight="25px">
              <Table.Cell pl={1} width="80px">
                Offset:
              </Table.Cell>
              <Table.Cell>
                <Stack>
                  <Stack.Item>
                    <Button
                      icon={preferences.offset_type === 'absolute' ? 'r' : 'a'}
                      height="19px"
                      fontSize="14"
                      onClick={() => {
                        setCordsType(
                          preferences.offset_type === 'absolute' ? 1 : 0,
                        );
                        act('cycle-offset-type');
                      }}
                      tooltip={
                        preferences.offset_type === 'absolute'
                          ? 'Absolute'
                          : 'Relative'
                      }
                      tooltipPosition="top"
                    />
                  </Stack.Item>
                  <Stack.Item grow>
                    <Input
                      placeholder="x, y, z"
                      value={offset}
                      onChange={(e, value) => {
                        setOffset(value);
                        value
                          ? act('offset-changed', { newOffset: value })
                          : undefined;
                      }}
                      width="100%"
                    />
                  </Stack.Item>
                </Stack>
              </Table.Cell>
            </Table.Row>
            <Table.Row className="candystripe" lineHeight="25px">
              <Table.Cell pl={1} width="80px">
                Name:
              </Table.Cell>
              <Table.Cell>
                <Input
                  onChange={(e, value) => {
                    setObjectName(value);
                    act('name-changed', { newName: value });
                  }}
                  value={objectName}
                  width="100%"
                  placeholder="leave empty for initial"
                />
              </Table.Cell>
            </Table.Row>
          </Table>
        </Stack.Item>
        <Stack.Item>
          <Stack vertical fill>
            <Stack.Item grow>
              <Button
                onClick={() => act('create-object-action')}
                style={{
                  width: '100%',
                  height: '100%',
                  textAlign: 'center',
                  fontSize: '20px',
                  alignContent: 'center',
                }}
                icon={spawnLocationIcons[spawnLocation]}
              >
                SPAWN
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Dropdown
                width="18em"
                options={spawnLocationOptions}
                onSelected={(value) => {
                  setSpawnLocation(value);
                  act('where-dropdown-changed', {
                    newWhere: value,
                  });
                }}
                selected={spawnLocation}
              />
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </Stack>
    </Stack>
  );
}
