# Breaker Module — Bedwars (Roblox Fart Client)

## What This Prompt Is

This is a complete reference prompt for understanding and working with the **Breaker** module in the Bedwars game file (`games/6872274481.lua`). This covers the original Breaker only (lines ~14348–14708), which lives under the Minigames category.

---

## Architecture Overview

The Fart client is a Roblox exploit script (forked from Vape V4). It loads per-game scripts by Place ID. For Bedwars (Place ID `6872274481`), the game file contains dozens of modules organized by category (Combat, Blatant, Utility, Minigames, etc.). Each module is created via `vape.Categories.<Category>:CreateModule()`, which handles toggle state, keybinds, settings persistence, and the GUI panel.

Every module follows this pattern:
1. **Register** — `CreateModule()` with a Name, Function (enable/disable callback), and Tooltip
2. **Create sub-options** — sliders, toggles, dropdowns, text lists
3. **Run loop** — when enabled, run a `repeat...until` loop that ticks at a configurable rate
4. **Cleanup** — when disabled, destroy any created instances and clear tables

---

## Core Infrastructure Used by Breaker

### `collection(tags, module, customadd, customremove)` (line ~135)
Tracks Roblox instances by CollectionService tag in real time. Returns a table that auto-populates when tagged objects are added/removed from the game. This is how Breaker discovers beds, lucky blocks, ores, etc. without polling the entire workspace.

- Accepts a single tag string or a table of tags
- Connects to `CollectionService:GetInstanceAddedSignal` and `GetInstanceRemovedSignal`
- Optionally accepts `customadd` / `customremove` callbacks for filtering (e.g. only add blocks whose name is in a custom list, or only add enemy-placed teslas/hives)
- Returns the live table + a cleanup function
- Cleanup is auto-registered to the module via `module:Clean()`

### `getPlacedBlock(pos)` (line ~278)
Converts a world position to a block grid position via `bedwars.BlockController:getBlockPosition(pos)`, then looks up the block at that position in the block store. Returns the block instance and the rounded position.

### `roundPos(vec)` (line ~409)
Snaps a Vector3 to the Bedwars block grid (blocks are 3 studs apart): `math.round(vec.X / 3) * 3` for each axis.

### `getBlockHits(block, blockpos)` (line ~1104)
Calculates how many hits it takes to break a block:
1. Gets the block's `breakType` from `bedwars.ItemMeta[block.Name].block.breakType`
2. Finds the player's best tool for that type from `store.tools[breaktype]`
3. Gets the tool's damage from `bedwars.ItemMeta[tool.itemType].breakBlock[breaktype]` (defaults to 2 if no tool)
4. Divides the block's current health by the tool's damage

### `calculatePath(target, blockpos, method, angle, wallcheck)` (line ~1126)
Pathfinding using **Dijkstra's algorithm** in 3D block space:
1. Starts from `blockpos` with cost 0
2. Explores neighboring blocks in 6 directions (up/down/left/right/forward/back, each 3 studs apart via the `sides` table)
3. Skips visited nodes, unbreakable blocks, `NoBreak` blocks, and the target block itself
4. Skips blocks outside the `angle` limit (checks dot product of camera look vector vs direction to block)
5. Cost of each block = `method(block, pos)` if provided, otherwise `getBlockHits(block, pos)` (number of hits to break)
6. Tracks which positions are "air" (no block present) — these are potential entry points
7. After exploring (up to 10,000 iterations), picks the air node with the lowest total cost
8. If `wallcheck` is true, also requires the air node to be "minable" (has at least one neighbor that's either air or player-placed)
9. Returns: `pos` (best entry point), `cost`, `path` (table mapping each node to its predecessor)
10. Results are cached in `cache[blockpos]`

### `bedwars.breakBlock(block, effects, anim, customHealthbar, visualise, sort, angle, wallcheck)` (line ~1185)
The core break function. Parameters:
- `block` — the target block Instance to break
- `effects` — boolean, show health bar + break/hit particles
- `anim` — boolean, play the arm swing animation
- `customHealthbar` — function or nil, custom health bar callback (or falls back to game's default `bedwars.BlockBreaker.updateHealthbar`)
- `visualise` — boolean, use visual hotbar switch (vs silent equip)
- `sort` — function or nil, block sorting method for pathfinding cost
- `angle` — number, max angle in degrees for pathfinding
- `wallcheck` — boolean, require blocks to be externally exposed

Step by step:
1. **Guard checks** — returns nil if player has `DenyBlockBreak` attribute, is dead, or `InfiniteFly` is enabled
2. **Get contained positions** — for multi-part blocks (like beds), gets all block positions via the handler's `getContainedPositions()`
3. **Find cheapest entry** — calls `calculatePath()` for each contained position, picks the one with lowest cost
4. **Range check** — aborts if the best entry point is >30 studs from the player
5. **Get block at entry** — calls `getPlacedBlock(pos)` to get the actual block to hit
6. **Auto tool** — checks `bedwars.SwordController.lastAttack` to avoid switching during combat (0.4s cooldown). Gets the block's `breakType`, finds the best tool from `store.tools`, and either visually switches via `hotbarSwitch()` or silently via `switchItem()`
7. **Track health** — maintains `blockhealthbar` state (`blockHealth` and `breakingBlockPosition`) for accurate damage tracking across multiple hits
8. **Send RPC** — fires `DamageBlock` to the server:
   ```lua
   bedwars.ClientDamageBlock:Get('DamageBlock'):CallServerAsync({
       blockRef = {blockPosition = dpos},
       hitPosition = pos,
       hitNormal = Vector3.FromNormalId(Enum.NormalId.Top)
   })
   ```
9. **Handle response** — the `:andThen()` callback processes the server result:
   - `'cancelled'` — sets `store.damageBlockFail = tick() + 1` (triggers 4.5s cooldown on next attempt)
   - Otherwise — calculates damage dealt, calls the health bar function, updates tracked health
   - If health reaches 0: plays break effect + cleans up health bar
   - If health > 0: plays hit effect
   - If `anim` is true: plays break animation for 0.3 seconds
10. **Return** — returns `pos` (hit position), `path` (path table), `target` (original block position) when effects are enabled; nil otherwise

### `breakmethods` (line ~542)
Sorting methods that determine pathfinding cost (which block to break through first):
- **Health** — `getBlockHits(block, pos)` — fewest hits to break = lowest cost (breaks the weakest blocks first)
- **Distance** — distance from player to block horizontally (ignores Y axis) — breaks closest blocks first

### `getMousePosition()` (line ~14474)
Gets the block position the player's mouse is pointing at:
1. Calls `bedwars.BlockBreaker.clientManager:getBlockSelector():getMouseInfo(0)`
2. If the mouse is on a block, returns `mouseinfo.target.blockRef.blockPosition * 3`
3. If on a placement position, returns `mouseinfo.placementPosition * 3`
4. Returns nil if nothing valid

### `closetMethod(block)` (line ~14491)
Alternative sorting method used when `Closest break` is enabled. Returns the distance from the mouse position (or player root if mouse has no target) to the block. Caches the mouse position for 0.01 seconds to avoid recalculating every call.

---

## The Breaker Module (line ~14348–14708)

Tooltip: *"Break blocks around you automatically"*

### Variable Declarations (line ~14349–14370)
```
Breaker       — the module object
Mode          — break mode dropdown (Health/Distance)
Range         — break range slider
Angle         — max angle slider
AutoTool      — auto tool toggle
BreakSpeed    — delay between breaks slider
UpdateRate    — loop tick rate slider
Custom        — custom block name text list
Bed           — break bed toggle
Tesla         — break tesla toggle
Hive          — break hive toggle
LuckyBlock    — break lucky block toggle
IronOre       — break iron ore toggle
Effect        — show healthbar & effects toggle
CustomHealth  — custom healthbar toggle
Animation     — play animation toggle
SelfBreak     — break own blocks toggle
InstantBreak  — instant break toggle
LimitItem     — limit to items toggle
Nuker         — break through blocks toggle
Closet        — closest break toggle
customlist    — table of custom-targeted blocks
parts         — table of path visualization parts
```

### Custom Health Bar UI (line ~14372–14470)

`customHealthbar(self, blockRef, health, maxHealth, changeHealth, block)`

When `Custom Healthbar` is enabled, creates a floating UI above the block being broken using Roact:

**Structure:**
- Invisible anchored `Part` at the block's world position (query-ignored so raycasts pass through)
- `BillboardGui` (249x102 offset size, 2.5 studs above block, max distance 40, always on top)
  - `Frame` (160x50, black background at 50% transparency, 5px corner radius)
    - `ImageLabel` — blur/glow background image from `fart/assets/new/blur.png`
    - `TextLabel` (shadow) — block display name, black text, positioned at (13, 12)
    - `TextLabel` (main) — block display name, theme text color darkened 16%, positioned at (12, 11)
    - `Frame` (138x4, theme main color) — health bar background
      - `Frame` (progress bar) — width = health percentage, color from HSV

**Health bar color formula:** `Color3.fromHSV(math.clamp(percent / 2.5, 0, 1), 0.89, 0.75)`
- At 100% health: green (hue ~0.4)
- At 50% health: yellow (hue ~0.2)
- At 0% health: red (hue 0)

**Behavior:**
- If a new block is targeted, cleans up old health bar and creates a new one
- Progress bar animates via `TweenService` (0.3 second tween)
- Auto-cleans up after 5 seconds if no new hits land
- Cleanup: unmounts Roact tree, destroys the adornee part

### `attemptBreak(tab, localPosition)` (line ~14499–14527)

The per-collection break function. For each block `v` in the collection table:

1. **Range check** — `(v.Position - localPosition).Magnitude < Range.Value`
2. **Breakability check** — `bedwars.BlockController:isBlockBreakable({blockPosition = v.Position / 3}, lplr)`
3. **Self break check** — if `SelfBreak` is off, skips blocks where `PlacedByUserId == lplr.UserId`
4. **Shield check** — skips blocks where `BedShieldEndTime` attribute > `workspace:GetServerTimeNow()`
5. **Limit item check** — if `LimitItem` is on, skips unless `store.hand.tool` exists and its ItemMeta has `breakBlock`
6. **Break** — increments `hit` counter, calls:
   ```lua
   bedwars.breakBlock(v, Effect.Enabled, Animation.Enabled,
       CustomHealth.Enabled and customHealthbar or nil,
       AutoTool.Enabled,
       Closet.Enabled and closetMethod or breakmethods[Mode.Value],
       Angle.Value,
       not Nuker.Enabled)
   ```
7. **Path visualization** — if `breakBlock` returns a path, iterates through the 30 visualization parts and positions them along the path:
   - Blue = target block position
   - Green = intermediate path blocks
   - Red = entry point (where the actual hit happens)
8. **Wait** — `task.wait(InstantBreak.Enabled and (store.damageBlockFail > tick() and 4.5 or 0) or BreakSpeed.Value)`
   - Normal: waits `BreakSpeed.Value` seconds
   - Instant Break ON + no server rejection: 0 seconds
   - Instant Break ON + server rejected recently: 4.5 second cooldown
9. **Returns true** if a block was broken (causes the main loop to `continue` to the next tick)

### Main Loop (line ~14529–14603)

The `CreateModule` Function callback:

**On enable (`callback == true`):**
1. Creates 30 invisible parts with `BoxHandleAdornment` for path visualization
2. Sets up 6 collections:
   - `beds` — tagged `'bed'`
   - `luckyblock` — tagged `'LuckyBlock'`
   - `ironores` — tagged `'iron_ore_mesh_block'`
   - `teslas` — tagged `'tesla-trap'`, custom filter: only adds if placer's team differs from local player's team (delayed 0.1s for attribute loading)
   - `hives` — tagged `'beehive'`, same enemy-only filter as teslas
   - `customlist` — tagged `'block'`, custom filter: only adds if block name is in `Custom.ListEnabled`
3. Main loop runs at `1 / UpdateRate.Value` seconds per tick
4. Each tick, tries collections in **priority order** (first match wins, then `continue`):
   1. Beds (if `Bed.Enabled`)
   2. Teslas (if `Tesla.Enabled`)
   3. Hives (if `Hive.Enabled`)
   4. Custom list (always, if not empty)
   5. Lucky blocks (if `LuckyBlock.Enabled`)
   6. Iron ores (if `IronOre.Enabled`)
5. If nothing was broken, resets all 30 visualization parts to `Vector3.zero`

**On disable (`callback == false`):**
1. Destroys all children + the parts themselves
2. Clears the `parts` table

### Settings Creation (line ~14604–14707)

| Setting | Type | API Call | Default | Config |
|---------|------|----------|---------|--------|
| Break mode | Dropdown | `CreateDropdown` | First method in `breakmethods` | List built from `breakmethods` keys |
| Break range | Slider | `CreateSlider` | 30 | Min 1, Max 30, suffix "stud"/"studs" |
| Break speed | Slider | `CreateSlider` | 0.25 | Min 0, Max 0.3, Decimal 100, suffix "seconds" |
| Max angle | Slider | `CreateSlider` | 120 | Min 1, Max 360 |
| Update rate | Slider | `CreateSlider` | 60 | Min 1, Max 120, suffix "hz" |
| Custom | Text List | `CreateTextList` | — | On change: clears `customlist`, rebuilds from `store.blocks` matching `Custom.ListEnabled` |
| Break Bed | Toggle | `CreateToggle` | true | — |
| Break Tesla | Toggle | `CreateToggle` | true | — |
| Break Hive | Toggle | `CreateToggle` | true | — |
| Break Lucky Block | Toggle | `CreateToggle` | true | — |
| Break Iron Ore | Toggle | `CreateToggle` | true | — |
| Show Healthbar & Effects | Toggle | `CreateToggle` | true | On change: shows/hides Custom Healthbar sub-toggle |
| Custom Healthbar | Toggle | `CreateToggle` | true | `Darker = true` (indented sub-option) |
| Animation | Toggle | `CreateToggle` | false | — |
| Self Break | Toggle | `CreateToggle` | false | — |
| Instant Break | Toggle | `CreateToggle` | false | — |
| Auto Tool | Toggle | `CreateToggle` | false | — |
| Break through blocks | Toggle | `CreateToggle` | false | Tooltip: "Ignores blocks around bed defense, and check if the server validates where ur breaking" |
| Closest break | Toggle | `CreateToggle` | false | Tooltip: "Uses ur mouse's position to get the closet block to you". On change: hides/shows Mode dropdown |
| Limit to items | Toggle | `CreateToggle` | false | Tooltip: "Only breaks when tools are held" |

---

## Data Flow Summary

```
Player enables Breaker
    |
    v
Creates 30 path visualization parts
Sets up 6 CollectionService trackers (bed, LuckyBlock, iron_ore, tesla-trap, beehive, block)
    |
    v
Main loop starts (ticks at UpdateRate hz)
    |
    v
Each tick (if player is alive):
    |
    v
Try collections in priority order: Beds > Teslas > Hives > Custom > Lucky Blocks > Iron Ores
    |
    v
attemptBreak() for the first enabled collection with targets:
    |-- Check range (< Break range studs)
    |-- Check bedwars.BlockController:isBlockBreakable()
    |-- Check team (skip own blocks unless Self Break)
    |-- Check bed shield (skip if shield active)
    |-- Check held item (skip if Limit to items + no tool)
    |
    v
bedwars.breakBlock():
    |-- Guard: skip if DenyBlockBreak / dead / InfiniteFly
    |-- Get all block positions (multi-part blocks like beds)
    |-- calculatePath() for each position (Dijkstra pathfinding)
    |   |-- Explore 6 directions, 3 studs each
    |   |-- Cost = getBlockHits() or custom sort method
    |   |-- Respect angle limit
    |   |-- Find cheapest air node (entry point)
    |   |-- If wallcheck: require externally exposed
    |-- Pick cheapest entry across all positions
    |-- Range check (< 30 studs)
    |-- Auto-switch to best tool for block's breakType
    |-- Fire DamageBlock RPC to server
    |-- On response:
    |   |-- 'cancelled' -> set damageBlockFail cooldown
    |   |-- success -> update health bar, play effects
    |   |-- health <= 0 -> play break effect, clean up
    |   |-- health > 0 -> play hit effect
    |-- Return hit position + path for visualization
    |
    v
Visualize path on 30 parts (blue=target, green=path, red=entry)
    |
    v
Wait (BreakSpeed seconds / 0 for instant / 4.5s if server rejected)
    |
    v
Continue to next tick
```

---

## Key Game APIs Referenced

- `bedwars.BlockController` — block grid management (get block at position, check breakability, get world position)
- `bedwars.BlockController:getStore()` — the block data store (block instances at grid positions, health data via attributes)
- `bedwars.BlockController:getStore():getBlockAt(blockPosition)` — get block instance at a grid position
- `bedwars.BlockController:getStore():getBlockData(blockPosition)` — get block data (health attributes)
- `bedwars.BlockController:getBlockPosition(worldPos)` — convert world position to grid position
- `bedwars.BlockController:getWorldPosition(blockPos)` — convert grid position to world position
- `bedwars.BlockController:isBlockBreakable(breakTable, player)` — check if a block can be broken (hooked at line ~1082 to add custom NoBreak logic)
- `bedwars.BlockController:getHandlerRegistry():getHandler(name)` — block type handlers (multi-position blocks like beds have `getContainedPositions()`)
- `bedwars.BlockController:getAnimationController():getAssetId(1)` — break animation asset
- `bedwars.ItemMeta[name]` — metadata for every item/block: `.displayName`, `.block.breakType`, `.breakBlock[type]` (tool damage per break type), `.damage` (sword damage)
- `bedwars.BlockBreaker` — the game's native block-breaking controller (has `.updateHealthbar()`, `.breakEffect`, `.healthbarMaid`)
- `bedwars.BlockBreaker.clientManager:getBlockSelector():getMouseInfo(0)` — get what block the mouse is pointing at
- `bedwars.ClientDamageBlock:Get('DamageBlock')` — the RPC to damage a block server-side
- `bedwars.SwordController.lastAttack` — timestamp of last sword attack (0.4s cooldown before tool switching)
- `bedwars.Roact` — React-like UI framework for the custom health bar
- `bedwars.AnimationUtil:playAnimation(player, assetId)` — play character animation
- `bedwars.ViewmodelController:playAnimation(id)` — play first-person viewmodel animation
- `bedwars.QueryUtil:setQueryIgnored(instance, true)` — exclude instance from raycasts
- `collectionService` — Roblox CollectionService for tag-based object tracking
- `store.blocks` — local cache of all placed blocks (populated elsewhere in the game file)
- `store.tools` — best tool per break type (auto-tracked from inventory changes)
- `store.hand` — currently held item (`.tool` = the tool instance)
- `store.inventory` — player inventory (`.inventory.items` = table of items)
- `store.damageBlockFail` — tick() timestamp of last server rejection (triggers 4.5s cooldown)
- `store.blockPlacer` — BlockPlacer instance for placing blocks
