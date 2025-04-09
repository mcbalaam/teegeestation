import { useState } from 'react';
import {
  Box,
  Button,
  Modal,
  ProgressBar,
  Section,
  Slider,
  Stack,
  Table,
} from 'tgui-core/components';
import { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type ManipulatorData = {
  active: BooleanLike;
  interaction_delay: number;
  worker_interaction: string;
  highest_priority: BooleanLike;
  interaction_mode: string;
  settings_list: PrioritySettings[];
  throw_range: number;
  item_as_filter: string;
  selected_type: string;
  delay_step: number;
  min_delay: number;
  max_delay: number;
  current_task_type: string;
  current_task_duration: number;
  pickup_points: PointData[];
  dropoff_points: PointData[];
};

type PrioritySettings = {
  name: string;
  priority_width: number;
};

type PointData = {
  name: string;
  turf: string;
  mode: string;
  filters: string[];
  item_filters: string[];
};

const MasterControls = () => {
  const { act, data } = useBackend<ManipulatorData>();
  const { delay_step, interaction_delay, min_delay, max_delay } = data;
  return (
    <Stack>
      <Stack.Item>Delay:</Stack.Item>
      <Stack.Item>
        {' '}
        <Button
          icon="backward-step"
          onClick={() =>
            act('changeDelay', {
              new_delay: min_delay,
            })
          }
        />
      </Stack.Item>
      <Stack.Item grow>
        <Slider
          style={{ marginTop: '-5px' }}
          step={delay_step}
          my={1}
          value={interaction_delay}
          minValue={min_delay}
          maxValue={max_delay}
          unit="sec."
          onDrag={(e, value) =>
            act('changeDelay', {
              new_delay: value,
            })
          }
        />
      </Stack.Item>
      <Stack.Item>
        <Button
          icon="forward-step"
          onClick={() =>
            act('changeDelay', {
              new_delay: max_delay,
            })
          }
        />
      </Stack.Item>
      <Stack.Item>
        {' '}
        <Button
          content="Drop"
          icon="eject"
          tooltip="Disengage the claws, dropping the held item"
          onClick={() => act('drop')}
        />
      </Stack.Item>
    </Stack>
  );
};

type ConfigRowProps = {
  label: string;
  content: string;
  onClick: () => void;
  tooltip: string;
  selected?: BooleanLike;
};

const ConfigRow = (props: ConfigRowProps) => {
  const { label, content, onClick, ...rest } = props;
  const { tooltip = '', selected = false } = rest;

  return (
    <Table.Row
      className="candystripe"
      style={{
        height: '2em',
        padding: '20px',
        lineHeight: '2em',
      }}
    >
      <Table.Cell>
        <Box style={{ marginLeft: '5px' }}>{label}</Box>
      </Table.Cell>
      <Table.Cell
        style={{
          width: 'min-content',
          whiteSpace: 'nowrap',
          textAlign: 'right',
        }}
      >
        <Button
          content={content}
          tooltip={tooltip}
          onClick={onClick}
          selected={!!selected}
        />
      </Table.Cell>
    </Table.Row>
  );
};

const PointSection = (props: {
  title: string;
  points: PointData[];
  onAdd: () => void;
  act: (action: string, params?: Record<string, any>) => void;
}) => {
  const { title, points, onAdd, act } = props;
  const [editingPoint, setEditingPoint] = useState<PointData | null>(null);

  const handleEditPoint = (point: PointData) => {
    setEditingPoint(point);
  };

  const handleDirectionClick = (dx: number, dy: number) => {
    if (!editingPoint) return;

    act('move_point', {
      index: points.indexOf(editingPoint),
      dx: dx,
      dy: dy,
    });
    setEditingPoint(null);
  };

  return (
    <>
      <Section
        title={title}
        buttons={<Button icon="plus" color="transparent" onClick={onAdd} />}
      >
        <Stack vertical>
          {points.map((point, index) => (
            <Stack.Item
              key={index}
              style={{
                padding: '5px',
              }}
              className="candystripe"
            >
              <Box>
                <Stack>
                  <Stack.Item grow>
                    <Box>
                      <strong>{point.name}</strong>
                      <br />
                      <small>Режим: {point.mode.toUpperCase()}</small>
                      <br />
                      <small>Фильтры: {point.item_filters.join(', ')}</small>
                    </Box>
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      icon="trash"
                      color="transparent"
                      onClick={() => act('remove_point', { index: index })}
                    />
                  </Stack.Item>
                  <Stack.Item>
                    <Button
                      icon="gear"
                      color="transparent"
                      onClick={() => handleEditPoint(point)}
                    />
                  </Stack.Item>
                </Stack>
              </Box>
            </Stack.Item>
          ))}
        </Stack>
      </Section>

      {editingPoint && (
        <Modal
          style={{
            padding: '6px',
            width: '340px',
            boxSizing: 'initial',
          }}
        >
          <Section title="Destination Point">
            <Stack>
              <Stack.Item>
                {' '}
                <Box
                  style={{
                    display: 'grid',
                    gridTemplateColumns: '2em 2em 2em',
                    gridAutoRows: '2em',
                    gap: '2px',
                    rowGap: '2px',
                  }}
                >
                  {[-1, 0, 1].map((dx) =>
                    [-1, 0, 1].map((dy) => {
                      const isCenter = dx === 0 && dy === 0;
                      let icon;
                      if (dx === 0 && dy === 1) icon = 'arrow-right';
                      if (dx === -1 && dy === 0) icon = 'arrow-up';
                      if (dx === 1 && dy === 0) icon = 'arrow-down';
                      if (dx === 0 && dy === -1) icon = 'arrow-left';
                      if (dx === 0 && dy === 0) icon = 'location-dot';

                      return (
                        <Button
                          key={`${dx},${dy}`}
                          icon={icon}
                          disabled={isCenter}
                          onClick={() =>
                            !isCenter && handleDirectionClick(dx, dy)
                          }
                          // color="transparent"
                          style={{
                            margin: '0px',
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            lineHeight: '2em',
                          }}
                        />
                      );
                    }),
                  )}
                </Box>
              </Stack.Item>
              <Stack.Item grow>
                <Table>
                  <ConfigRow
                    label="Overfill"
                    content="FALSE"
                    onClick={() => act('change_mode')}
                    tooltip=""
                  />
                  <ConfigRow
                    label="Object Type"
                    content="ITEM"
                    onClick={() => act('change_mode')}
                    tooltip=""
                  />
                  <ConfigRow
                    label="Filters"
                    content="NONE"
                    onClick={() => act('change_mode')}
                    tooltip=""
                  />
                </Table>
              </Stack.Item>
            </Stack>
          </Section>
        </Modal>
      )}
    </>
  );
};

export const BigManipulator = () => {
  const { data, act } = useBackend<ManipulatorData>();
  const {
    active,
    interaction_mode,
    settings_list,
    worker_interaction,
    highest_priority,
    throw_range,
    item_as_filter,
    selected_type,
    current_task_type,
    current_task_duration,
    pickup_points,
    dropoff_points,
  } = data;

  return (
    <Window title="Manipulator Interface" width={420} height={610}>
      <Window.Content overflowY="auto">
        <Box
          style={{
            height: '100%',
            overflowY: 'auto',
            scrollbarWidth: 'none',
            msOverflowStyle: 'none',
          }}
        >
          <Section
            title="Action Panel"
            buttons={
              <Button
                icon="power-off"
                selected={active}
                content={active ? 'On' : 'Off'}
                onClick={() => act('on')}
              />
            }
          >
            <Box
              style={{
                lineHeight: '1.8em',
                marginBottom: '-5px',
              }}
            >
              <MasterControls />
            </Box>
          </Section>

          <Section>
            <ProgressBar
              value={1}
              maxValue={1}
              style={{
                transitionDuration: `${current_task_duration}s`,
              }}
            >
              <Stack lineHeight="1.8em">
                <Stack.Item ml="-2px">Current task:</Stack.Item>
                <Stack.Item grow>{current_task_type.toUpperCase()}</Stack.Item>
              </Stack>
            </ProgressBar>
          </Section>

          <PointSection
            title="Pickup Points"
            points={pickup_points}
            onAdd={() => act('create_pickup_point')}
            act={act}
          />

          <PointSection
            title="Dropoff Points"
            points={dropoff_points}
            onAdd={() => act('create_dropoff_point')}
            act={act}
          />

          <Section title="Configuration">
            <Table>
              <ConfigRow
                label="Interaction Mode"
                content={interaction_mode.toUpperCase()}
                onClick={() => act('change_mode')}
                tooltip="Cycle through interaction modes"
              />

              {interaction_mode === 'throw' && (
                <ConfigRow
                  label="Throwing Range"
                  content={`${throw_range} TILE${throw_range > 1 ? 'S' : ''}`}
                  onClick={() => act('change_throw_range')}
                  tooltip="Cycle the distance an object will travel when thrown"
                />
              )}

              <ConfigRow
                label="Interaction Filter"
                content={selected_type.toUpperCase()}
                onClick={() => act('change_take_item_type')}
                tooltip="Cycle through types of items to filter"
              />
              {interaction_mode === 'use' && (
                <ConfigRow
                  label="Worker Interactions"
                  content={worker_interaction.toUpperCase()}
                  onClick={() => act('worker_interaction_change')}
                  tooltip={
                    worker_interaction === 'normal'
                      ? 'Interact using the held item'
                      : worker_interaction === 'single'
                        ? 'Drop the item after a single cycle'
                        : 'Interact with an empty hand'
                  }
                />
              )}
              <ConfigRow
                label="Item Filter"
                content={item_as_filter ? item_as_filter : 'NONE'}
                onClick={() => act('add_filter')}
                tooltip="Click while holding an item to set filtering type"
              />

              {interaction_mode !== 'throw' && (
                <ConfigRow
                  label="Override List Priority"
                  content={highest_priority ? 'TRUE' : 'FALSE'}
                  onClick={() => act('highest_priority_change')}
                  tooltip="Only interact with the highest dropoff point in the list"
                  selected={!!highest_priority}
                />
              )}
            </Table>
          </Section>

          {interaction_mode !== 'throw' && (
            <Section>
              <Table>
                {settings_list.map((setting) => (
                  <Table.Row
                    key={setting.name}
                    className="candystripe"
                    style={{
                      height: '2em',
                      paddingLeft: '20px',
                      lineHeight: '2em',
                    }}
                  >
                    <Table.Cell
                      style={{
                        paddingLeft: '2px',
                        width: '2em',
                      }}
                    >
                      <Button
                        icon="arrow-up"
                        onClick={() =>
                          act('change_priority', {
                            priority: setting.priority_width,
                          })
                        }
                      />
                    </Table.Cell>
                    <Table.Cell>{setting.name}</Table.Cell>
                    <Table.Cell>{setting.priority_width}</Table.Cell>
                  </Table.Row>
                ))}
              </Table>
            </Section>
          )}
        </Box>
      </Window.Content>
    </Window>
  );
};
