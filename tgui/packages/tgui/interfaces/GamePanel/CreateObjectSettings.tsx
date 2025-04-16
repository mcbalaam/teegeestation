import { useState } from 'react';
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
import { spawnLocationOptions } from './constants';

const spawnLocationIcons = {
  'Current location': 'map-marker',
  'Current location via droppod': 'parachute-box',
  "In own mob's hand": 'hand-holding',
  'At a marked object': 'crosshairs',
};

const directionIcons = {
  1: 'arrow-up',
  2: 'arrow-down',
  4: 'arrow-right',
  8: 'arrow-left',
};

const directionNames = {
  1: 'NORTH',
  2: 'SOUTH',
  4: 'EAST',
  8: 'WEST',
};

export function CreateObjectSettings(props) {
  const { act } = useBackend();
  const [cordsType, setCordsType] = useState(1);
  const [spawnLocation, setSpawnLocation] = useState('Current location');
  const [direction, setDirection] = useState(0);

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
                  value={1}
                  onChange={(value) =>
                    act('number-changed', { newNumber: value })
                  }
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
                      icon={cordsType === 0 ? 'r' : 'a'}
                      height="19px"
                      fontSize="14"
                      onClick={() => {
                        setCordsType(cordsType === 0 ? 1 : 0);
                        act('set-relative-cords');
                      }}
                      tooltip={cordsType === 0 ? 'Relative' : 'Absolute'}
                      tooltipPosition="top"
                    />
                  </Stack.Item>
                  <Stack.Item grow>
                    <Input
                      placeholder="x, y, z"
                      onChange={(e, value) =>
                        value
                          ? act('offset-changed', { newOffset: value })
                          : undefined
                      }
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
                  onChange={(e, value) =>
                    act('name-changed', { newName: value })
                  }
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
