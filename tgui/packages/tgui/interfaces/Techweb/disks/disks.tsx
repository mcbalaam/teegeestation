import { Section, VirtualList } from 'tgui-core/components';

import { useRemappedBackend } from '../helpers';
import { TechNode } from '../nodes/TechNode';
import type { TechwebNode } from '../types';

export function TechwebDesignDisk(props) {
  const { data } = useRemappedBackend();
  const { design_cache, d_disk } = data;
  if (!d_disk) return;

  const { blueprints, unreadable } = d_disk;

  if (unreadable) {
    return <Section title="Disk Error">Unreadable design disk.</Section>;
  }

  return (
    <>
      {blueprints.map((x, i) => (
        <Section key={i} title={`Slot ${i + 1}`}>
          {(x === null && 'Empty') || (
            <>
              Contains the design for <b>{design_cache[x].name}</b>:<br />
              <span
                className={`${design_cache[x].class} Techweb__DesignIcon`}
              />
            </>
          )}
        </Section>
      ))}
    </>
  );
}

export function TechwebTechDisk(props) {
  const { data } = useRemappedBackend();
  const { t_disk } = data;
  if (!t_disk) return;

  const { stored_research, unreadable } = t_disk;

  if (unreadable) {
    return <Section title="Disk Error">Unreadable technology disk.</Section>;
  }

  return (
    <Section scrollable fill>
      <VirtualList>
        {Object.keys(stored_research)
          .map((x) => ({ id: x }))
          .map((n) => (
            <TechNode key={n.id} nocontrols node={n as TechwebNode} />
          ))}
      </VirtualList>
    </Section>
  );
}
