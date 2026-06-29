import { useState } from 'react';
import {
  BlockQuote,
  Box,
  Button,
  Flex,
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
  fragments_count: number;
  elapsed: number;
  max_duration: number;
};

export function AnnouncementRecorderModal() {
  const { act, data } = useBackend<RecorderData>();
  const {
    recording,
    range,
    fragments,
    fragments_count,
    elapsed,
    max_duration,
  } = data;

  const [pendingRange, setPendingRange] = useState(range);

  return (
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
                    act('set_range', { range: value });
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
                    : `${Math.floor(max_duration / 60)}:00`}
                </b>
              </Box>
            </Flex.Item>
            <Flex.Item>
              {!recording ? (
                <Button
                  icon="microphone"
                  color="good"
                  onClick={() => act('start')}
                >
                  RECORD
                </Button>
              ) : (
                <Button
                  icon="stop"
                  color="bad"
                  onClick={() => act('stop')}
                >
                  STOP
                </Button>
              )}
              <Button
                icon="times"
                color={recording ? 'average' : 'bad'}
                onClick={() => act('cancel')}
              >
                {recording ? 'CANCEL' : 'CLOSE'}
              </Button>
            </Flex.Item>
          </Flex>
        </Section>
      </Stack.Item>
      <Stack.Item grow>
        <Section
          title={`Captured Fragments (${fragments_count})`}
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
  );
}
