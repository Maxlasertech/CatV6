# Breaker

Breaker is a module in the Bedwars game file (`games/6872274481.lua`, lines ~14348–14708). It sits in the Minigames category and its job is to automatically break blocks around the player without any manual input.

When you turn it on, it scans for nearby breakable objects — beds, tesla traps, beehives, lucky blocks, iron ore, and any custom block names you add to the list. It checks them in priority order: beds first, then teslas, hives, custom blocks, lucky blocks, and iron ore last. The first valid target it finds, it breaks.

Before breaking anything, it checks:
- Is the block within your set range?
- Can the block actually be broken right now?
- Is it your own team's block? (skips unless Self Break is on)
- Does it have a bed shield active? (skips if shielded)
- Are you holding a tool? (only matters if Limit to items is on)

Once it picks a target, it uses Dijkstra pathfinding to figure out the best block to hit. If a bed is surrounded by wool or other defense blocks, it finds the cheapest path through them — "cheapest" meaning fewest hits based on what tool you have. It can sort by health (weakest block first) or distance (closest first). Then it sends a DamageBlock request to the server, same as if you hit the block yourself.

It can auto-switch to the best tool for whatever block type it's breaking, show a custom floating health bar above the block with an animated progress bar that goes from green to red, play the break animation, and visualize the pathfinding path with colored boxes (blue for target, green for path, red for entry point).

If Instant Break is on it fires as fast as possible with no delay, but if the server rejects a hit it backs off for 4.5 seconds. Nuker mode lets it break blocks that aren't exposed from the outside (ignores wall checks in the pathfinding). Closest break mode uses your mouse position instead of the sorting method to pick which block to go for.

The whole loop runs at a configurable tick rate (default 60hz) and waits a configurable delay between breaks (default 0.25 seconds).
