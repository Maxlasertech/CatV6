# Breaker Module — Bedwars (Roblox Fart Client)

## What This Prompt Is

This is a complete reference prompt for understanding and working with the **Breaker** and **Bed Breaking** modules in the Bedwars game file (`games/6872274481.lua`). There are actually TWO breaker modules in the Bedwars file — the original **Breaker** and the more advanced **Bed Breaking**. Both live under the Minigames category.

---

## Architecture Overview

The Fart client is a Roblox exploit script (forked from Vape V4). It loads per-game scripts by Place ID. For Bedwars (Place ID `6872274481`), the game file contains dozens of modules organized by category (Combat, Blatant, Utility, Minigames, etc.). Each module is created via `vape.Categories.<Category>:CreateModule()`, which handles toggle state, keybinds, settings persistence, and the GUI panel.

Every module follows this pattern:
1. **Register** — `CreateModule()` with a Name, Function (enable/disable callback), and Tooltip
2. **Create sub-options** — sliders, toggles, dropdowns, text lists, color sliders
3. **Run loop** — when enabled, run a `repeat...until` loop that ticks at a configurable rate
4. **Cleanup** — when disabled, destroy any created instances and clear tables

---

## Core Infrastructure Used by Breaker

### `collection(tags, module, customadd, customremove)` (line ~135)
Tracks Roblox instances by CollectionService tag in real time. Returns a table that auto-populates when tagged objects are added/removed from the game. This is how Breaker discovers beds, lucky blocks, ores, etc. without polling the entire workspace.

### `getPlacedBlock(pos)` (line ~278)
Converts a world position to a block grid position via `bedwars.BlockController:getBlockPosition(pos)`, then looks up the block at that position in the block store. Returns the block instance and the rounded position.

### `roundPos(vec)` (line ~409)
Snaps a Vector3 to the Bedwars block grid (blocks are 3 studs apart): `math.round(vec.X / 3) * 3` for each axis.

### `getBlockHits(block, blockpos)` (line ~1104)
Calculates how many hits it takes to break a block. Looks up the block's break type from `bedwars.ItemMeta`, finds the player's best tool for that type, and divides the block's health by the tool's damage.

### `calculatePath(target, blockpos, method, angle, wallcheck)` (line ~1126)
Pathfinding using **Dijkstra's algorithm** in 3D block space. Starting from `blockpos`, it explores neighboring blocks (in 6 directions: up/down/left/right/forward/back, each 3 studs apart). It finds the cheapest path from the outside air to the target block, where "cost" is determined by how many hits each block takes. Respects angle limits (only considers blocks within the player's facing angle). Returns the best entry position, cost, and the path table.

### `bedwars.breakBlock(block, effects, anim, customHealthbar, visualise, sort, angle, wallcheck)` (line ~1185)
The core break function. Here's what it does step by step:

1. **Guard checks** — returns if player has `DenyBlockBreak` attribute, is dead, or InfiniteFly is enabled
2. **Find entry point** — uses `calculatePath()` to find the optimal block to hit (the cheapest path through any surrounding defense to reach the target)
3. **Range check** — aborts if the best entry point is >30 studs away
4. **Auto tool** — if `visualise` is true, visually switches to the best tool for the block's break type via hotbar animation; otherwise silently equips it
5. **Track health** — maintains `blockhealthbar` state to show accurate damage numbers
6. **Send RPC** — fires `DamageBlock` to the server via `bedwars.ClientDamageBlock:Get('DamageBlock'):CallServerAsync()` with the block reference, hit position, and hit normal
7. **Handle response** — on success, updates the health bar UI (either the game's default or a custom one), plays break/hit particle effects, and optionally plays the break animation
8. **Return** — returns the hit position, path table, and target position (used for path visualization)

### `breakmethods` (line ~542)
Sorting methods that determine which block to break first when pathfinding:
- **Health** — fewest hits to break (calls `getBlockHits`)
- **Distance** — closest to player horizontally (ignores Y axis)

### `sortmethods` (line ~512)
These are for *entity* sorting (used by combat modules like Killaura), NOT for block breaking. Don't confuse these with `breakmethods`.

---

## Module 1: Breaker (line ~14348–14708)

The original, simpler breaker. Tooltip: *"Break blocks around you automatically"*

### How the Main Loop Works

1. On enable, creates 30 invisible `Part` instances with `BoxHandleAdornment` children (used to visualize the pathfinding path)
2. Sets up collections for: `bed`, `LuckyBlock`, `iron_ore_mesh_block`, `tesla-trap`, `beehive`, and `block` (custom list)
3. Enters main loop: `repeat task.wait(1 / UpdateRate.Value) ... until not Breaker.Enabled`
4. Each tick, if the player is alive:
   - Tries to break beds first (if `Break Bed` is on)
   - Then teslas, then hives, then custom list blocks, then lucky blocks, then iron ores
   - Uses `attemptBreak()` which iterates the collection, checks range + breakability + team + shields, then calls `bedwars.breakBlock()`
   - After breaking, waits either `BreakSpeed.Value` seconds or 0 seconds (if Instant Break) or 4.5 seconds (if server rejected the last break)
5. On disable, destroys all the path visualization parts

### `attemptBreak(tab, localPosition)` (line ~14499)
For each block in the collection:
- Checks distance < `Range.Value`
- Checks `bedwars.BlockController:isBlockBreakable()`
- Skips own blocks (unless `Self Break` is on) via `PlacedByUserId`
- Skips blocks with active bed shields (`BedShieldEndTime` > server time)
- Skips if `Limit to items` is on and player isn't holding a break-capable tool
- Calls `bedwars.breakBlock()` with all the configured options
- Visualizes the pathfinding result on the 30 adornment parts (blue = target, green = path, red = endpoint)

### Settings

| Setting | Type | Default | Range | What it does |
|---------|------|---------|-------|-------------|
| Break mode | Dropdown | Health | Health, Distance | How to sort/prioritize which block to break through first |
| Break range | Slider | 30 | 1–30 studs | Max distance to target blocks |
| Break speed | Slider | 0.25s | 0–0.3s | Delay between break attempts |
| Max angle | Slider | 120 | 1–360 degrees | Only breaks blocks within this angle of your camera's look direction |
| Update rate | Slider | 60hz | 1–120hz | How often the main loop ticks |
| Custom | Text List | — | — | Custom block names to target (matched against block `.Name`) |
| Break Bed | Toggle | ON | — | Target beds |
| Break Tesla | Toggle | ON | — | Target tesla traps (enemy only) |
| Break Hive | Toggle | ON | — | Target beehives (enemy only) |
| Break Lucky Block | Toggle | ON | — | Target lucky blocks |
| Break Iron Ore | Toggle | ON | — | Target iron ore |
| Show Healthbar & Effects | Toggle | ON | — | Show break particles, hit effects, and health bar |
| Custom Healthbar | Toggle | ON | — | Use custom floating health bar UI instead of game's default |
| Animation | Toggle | OFF | — | Play the block-breaking arm animation |
| Self Break | Toggle | OFF | — | Allow breaking your own team's blocks |
| Instant Break | Toggle | OFF | — | Skip the break speed delay (0 delay unless server rejects, then 4.5s cooldown) |
| Auto Tool | Toggle | OFF | — | Auto-switch to the best tool for the block type |
| Break through blocks (Nuker) | Toggle | OFF | — | Ignores wall-check in pathfinding — breaks blocks even if they aren't externally exposed |
| Closest break | Toggle | OFF | — | Uses mouse cursor position instead of Break mode sorting to pick the nearest block |
| Limit to items | Toggle | OFF | — | Only breaks when holding a tool that has `breakBlock` in its ItemMeta |

### Custom Health Bar UI (line ~14372)
When `Custom Healthbar` is on, creates a `BillboardGui` floating above the block being broken:
- Semi-transparent black background frame (160x50 px)
- Block name label (from `bedwars.ItemMeta[block.Name].displayName`)
- Animated progress bar that tweens its width and color based on remaining health percentage
- Color goes from green (full) through yellow to red (almost broken) using HSV: `Color3.fromHSV(percent / 2.5, 0.89, 0.75)`
- Auto-cleans up after 5 seconds if the block isn't re-hit
- Uses Roact for rendering

---

## Module 2: Bed Breaking (line ~14710–15655)

The advanced breaker. Tooltip: *"Advanced bed breaker with layer break, yeti breaker, block highlight and more"*

This module has everything the original Breaker has, PLUS these advanced features:

### Additional Features

#### Layer Break (line ~15557)
When targeting a bed, instead of pathfinding through the cheapest blocks, it raycasts from the player to the bed and breaks the **first blocking block** along that straight line. This strips defenses layer by layer from the outside in, which looks more natural and is harder to detect.

`findPathBlock(targetPos, playerPos)` — walks along the direction vector from player to target in 3-stud steps, returns the first placed breakable block it finds (skipping blocks too close to the target).

#### Yeti Breaker (line ~15549)
Specifically targets **frozen blocks** placed by the Yeti kit. Hooks into `bedwars.KnitClient.Controllers.FreezeBlocksController.freezeBlocks` to track which block positions are frozen. When enabled, prioritizes breaking frozen blocks that are between the player and a bed.

`hookFreezeController()` — replaces the game's freeze function with a wrapper that records frozen positions into `frozenBlockPositions`, then clears them after 8 seconds (freeze duration).

`findYetiPathBlock(bedPos, playerPos)` — walks from player to bed, finds frozen blocks that have another block behind them (confirming they're part of a wall, not isolated).

#### Ragnar Breaker (line ~15553)
When enabled and the player has the Berserker kit, automatically activates the `berserker_rage` ability before breaking. This increases break speed in-game.

#### Vulnerability Check (line ~15623)
Uses **BFS flood-fill** to analyze each enemy bed's defense. Starting from the bed position, it explores outward through air (non-blocked positions). If it can reach a position >12 studs away without crossing any placed block, the bed is "vulnerable" (has an exposed opening). Results are cached for 2 seconds.

`isBedVulnerable(bed)` — counts nearby blocks (within 15 studs). If <4 blocks, it's undefended (not fake). Otherwise runs BFS through air positions. If any air path escapes 12 studs from the bed, an opening exists.

#### Vulnerable Only (line ~15637)
Only targets beds that pass the vulnerability check (have a detectable opening in their defense).

#### Bed Scanner (line ~15644)
Labels each enemy bed with a floating billboard: green "✓ EXPOSED" or red "✗ PROTECTED". Notifies the player when a bed's status changes. Runs on a 2.5-second update cycle.

#### Break Nearest (line ~15562)
Two modes:
- **Character** — breaks the closest block to your avatar
- **Mouse** — raycasts from your mouse cursor and breaks the closest breakable block to where you're pointing

#### Require Mouse Down (line ~15545)
Only breaks blocks when the player is holding left click.

#### Block Highlight (line ~15584)
Renders a `BoxHandleAdornment` around the block currently being broken. Color is configurable via a color slider.

#### Decoy Breaking (line ~15013)
When about to break a bed that has no outer block on the straight-line path (hollow/open defense), first breaks a random **outer block** from the defense to make it look like the player was mining through normally, rather than the bed just vanishing.

`findDecoyBlock(bed, playerPos)` — scans all placed blocks within 12 studs of the bed, scoring them by distance from bed minus distance from player. Picks the highest-scoring block (far from bed, close to player) as the decoy.

#### Show Path (line ~15579)
Visualizes the Dijkstra pathfinding result with colored box adornments (same as original Breaker).

#### Teammate Caching (line ~14753)
Caches teammate list every 2 seconds instead of checking on every block, reducing overhead. Used by `passesChecks()` to skip teammates' blocks.

### Settings (Bed Breaking only, in addition to shared ones)

| Setting | Type | Default | What it does |
|---------|------|---------|-------------|
| Break Pinata | Toggle | OFF | Target pinata blocks |
| Break Crops | Toggle | OFF | Target pumpkin, carrot, watermelon crops |
| Require Mouse Down | Toggle | OFF | Only break while holding left click |
| Yeti Breaker | Toggle | OFF | Focus on frozen blocks from Yeti kit |
| Ragnar | Toggle | OFF | Auto-use Berserker rage ability when breaking |
| Layer Break | Toggle | ON | Break outer defense layers first (looks more legit) |
| Break Nearest | Toggle | OFF | Always break closest block (by character or mouse) |
| Nearest Mode | Dropdown | Character | Character position vs mouse cursor |
| Show Path | Toggle | ON | Visualize pathfinding with colored boxes |
| Block Highlight | Toggle | OFF | Highlight the block being broken |
| Highlight Color | Color Slider | Yellow | Color for block highlight |
| Vulnerability Check | Toggle | OFF | BFS flood-fill to detect exposed beds |
| Vulnerable Only | Toggle | OFF | Skip beds with solid defenses |
| Bed Scanner | Toggle | OFF | Label beds as EXPOSED or PROTECTED with notifications |

---

## Data Flow Summary

```
Player enables Breaker/Bed Breaking
    ↓
collection() starts tracking tagged objects (beds, lucky blocks, etc.)
    ↓
Main loop ticks at UpdateRate hz
    ↓
For each tick:
    1. Get player position
    2. Iterate collections in priority order (beds first)
    3. For each block: check range, breakability, team, shields
    4. Call bedwars.breakBlock() on the first valid target
        ↓
        bedwars.breakBlock():
            a. calculatePath() — Dijkstra through surrounding blocks
            b. Find cheapest entry block to hit
            c. Auto-switch to best tool (if enabled)
            d. Fire DamageBlock RPC to server
            e. On response: update health bar, play effects
            f. Return path data for visualization
        ↓
    5. Wait BreakSpeed seconds (or 0 for instant)
    6. Continue to next tick
```

---

## Key Game APIs Referenced

- `bedwars.BlockController` — block grid management (get block at position, check breakability, get world position)
- `bedwars.BlockController:getStore()` — the block data store (block instances, health, attributes)
- `bedwars.BlockController:getHandlerRegistry():getHandler(name)` — block type handlers (multi-position blocks like beds)
- `bedwars.ItemMeta[name]` — metadata for every item/block (display name, break type, damage values, etc.)
- `bedwars.BlockBreaker` — the game's native block-breaking controller
- `bedwars.ClientDamageBlock:Get('DamageBlock')` — the RPC to damage a block server-side
- `bedwars.SwordController.lastAttack` — timestamp of last sword attack (used to avoid tool-switch during combat)
- `bedwars.BlockPlacer` — for placing blocks
- `bedwars.Roact` — React-like UI framework for the health bar
- `bedwars.AnimationUtil` / `bedwars.ViewmodelController` — break animations
- `bedwars.AbilityController` — kit abilities (Berserker rage)
- `bedwars.AdetundeUtil` — Yeti/Adetunde kit utilities
- `collectionService` — Roblox CollectionService for tag-based object tracking
- `store.blocks` — local cache of all placed blocks
- `store.tools` — best tool per break type
- `store.hand` — currently held item
- `store.inventory` — player inventory
- `store.damageBlockFail` — timestamp tracking server rejections
