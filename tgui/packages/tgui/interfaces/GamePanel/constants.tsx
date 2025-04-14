import { GamePanelTab, GamePanelTabName } from './types';

export const GamePanelTabs = [
  {
    name: GamePanelTabName.createObject,
    content: 'Create Object',
    icon: 'wrench',
  },
  {
    name: GamePanelTabName.createTurf,
    content: 'Create Turf',
    icon: 'map',
  },
  {
    name: GamePanelTabName.createMob,
    content: 'Create Mob',
    icon: 'person',
  },
] as GamePanelTab[];

export const spawnLocationOptions = [
  'Current location',
  'Current location via droppod',
  "In own mob's hand",
  'At a marked object',
];
