# SecondaryStats (WoW Midnight 12.0.x)

Lightweight addon that displays core secondary stats (Crit, Haste, Mastery, Versatility, Rune cooldown, Movement speed) in a clean overlay. Order and visibility are fully customizable via an in-game settings panel.

## Features
- Always-on overlay with real-time updates (0.25s ticker).
- Reorder stats with UP/DN buttons.
- Toggle visibility per stat (persisted).
- Drag to move overlay; position is saved.
- Settings panel position is also saved.
- Slash command: `/ss` or `/secondarystats`.

## Installation
1. Create folder `Interface/AddOns/SecondaryStats`.
2. Copy `SecondaryStats.toc` and `SecondaryStats.lua` into it.
3. Restart the game or reload UI.

## Compatibility
- Built and tested for WoW Midnight (12.0.x) APIs.
- Uses standard UI templates and whitelisted functions for this version.

## Known differences vs WeakAura
- "Rune CD" only shows data on Death Knights; you can toggle it off in settings.

## License
MIT
