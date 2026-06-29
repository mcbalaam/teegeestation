import { useState } from 'react';
import {
  BlockQuote,
  Box,
  Button,
  Flex,
  Modal,
  Section,
  Slider,
  Stack,
} from 'tgui-core/components';

import { useBackend } from '../../backend';

type Fragment = {
  speaker_name: string;
  text: string;
};

type RecorderData = {
  recording: boolean;
  range: number;
  fragments: Fragment[];
  fragmentsCount: number;
  elapsed: number;
  maxDuration: number;
};

type Props = {
  recorderData: RecorderData;
};

export function RecorderModal(props: Props) {
  const { act } = useBackend();
  const { recorderData } = props;
  const {
    recording,
    range,
    fragments,
    fragmentsCount,
    elapsed,
    maxDuration,
  } = recorderData;

  const [pendingRange, setPendingRange] = useState(range);

  return (
    <Modal>
      <Stack vertical fill>
        <Stack.Item>
          <Section title="Recording Controls">
            <Flex direction="column">
              <Flex.Item mb={1}>
                <Box fontSize="14px">
                  Range (tiles): <b>{recording ? range : pendingRange}</b>
                </Box>
                {!recording && (
                  <Slider
                    minValue={1}
                    maxValue={5}
                    step={1}
                    value={pendingRange}
                    onChange={(_e, value) => {
                      setPendingRange(value);
                      act('recorderAct', { sub: 'setRange', range: value });
                    }}
                  >
                    {pendingRange}
                  </Slider>
                )}
              </Flex.Item>
              <Flex.Item mb={1}>
                <Box fontSize="14px">
                  Time:{' '}
                  <b>
                    {recording
                      ? `${Math.floor(elapsed / 60)}:${String(elapsed % 60).padStart(2, '0')}`
                      : `${Math.floor(maxDuration / 60)}:00`}
                  </b>
                </Box>
              </Flex.Item>
              <Flex.Item>
                {!recording ? (
                  <Button
                    icon="microphone"
                    color="good"
                    onClick={() => act('recorderAct', { sub: 'start' })}
                  >
                    RECORD
                  </Button>
                ) : (
                  <Button
                    icon="stop"
                    color="bad"
                    onClick={() => act('recorderAct', { sub: 'stop' })}
                  >
                    STOP
                  </Button>
                )}
                <Button
                  icon="times"
                  color={recording ? 'average' : 'bad'}
                  onClick={() => act('recorderAct', { sub: 'cancel' })}
                >
                  {recording ? 'CANCEL' : 'CLOSE'}
                </Button>
              </Flex.Item>
            </Flex>
          </Section>
        </Stack.Item>
        <Stack.Item grow>
          <Section
            title={`Captured Fragments (${fragmentsCount})`}
            fill
            scrollable
          >
            {fragments.length === 0 && !recording && (
              <Box textAlign="center" color="gray">
                No fragments captured.
              </Box>
            )}
            {fragments.length === 0 && recording && (
              <Box textAlign="center" color="green">
                Listening for speech...
              </Box>
            )}
            {fragments.map((frag, idx) => (
              <BlockQuote key={idx}>
                <b>{frag.speaker_name}:</b> {frag.text}
              </BlockQuote>
            ))}
          </Section>
        </Stack.Item>
      </Stack>
    </Modal>
  );
}
