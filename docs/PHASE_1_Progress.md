# Phase 1 Progress Report

This document tracks what we completed, what's ongoing, and the concrete files touched while building the Phase 1 core loop (movement, vehicle, inventory, worldgen, POIs, contracts) in Godot 4.

## Completed

- Inventory and Hotbar
  - Grid inventory with drag-and-drop, rotation (R), stacking, and weight affecting speed.
  - Hotbar accepts only Weapons/Consumables, enforces one slot per item_id, right-click assign/remove, and 1-5 activation.
  - UI visuals show multi-tile footprints clearly across occupied cells.
  - Dynamic grid sizing: InventoryData now supports custom grid dimensions via `new_with_size()` factory method.
  - Player inventory: 8×6 grid (48 slots)
  - Vehicle inventory: Configurable per VehicleData (default 12×8 = 96 slots for delivery van)
- Vehicle Inventory System
  - Fully functional vehicle storage accessible via interaction (F key near vehicle back)
  - Opens both player and vehicle inventories side-by-side (player on left, vehicle on right)
  - Cross-inventory drag-and-drop: transfer items between player and vehicle seamlessly
  - Dynamic UI sizing: panels auto-resize based on grid dimensions
  - Weight tracking: both inventories track weight independently
  - Interaction area: InventoryAccessArea2D on vehicle rear with "vehicle_inventory" interaction type
  - Vehicle inventory size defined in VehicleData.storage_grid_size (data-driven)
- Player and Vehicle wiring
  - Player exposes class_name Player; dynamic UI setup; inventory var rename.
  - Vehicle controller references Inventory node; van scene uses correct script.
  - Vehicle uses LookAheadCamera while driving; player camera on foot.
- World Streaming + Biomes
  - ChunkManager loads by active camera, with preload/unload margins and Chebyshev distance.
  - WorldGenerator selects biomes (Wasteland/Radioactive) using FastNoiseLite; exported tuning knobs.
  - Test scene added to validate streaming and biomes.
- POI Placement
  - Deterministic, data-driven POIs via per-type world-grid cells with jittered spawn positions.
  - Filters by allowed biomes; persistent parenting under WorldPOIs to avoid despawn flicker.
  - Deduplication per (type, cell) to prevent duplicates across chunk overlaps.
- Debug Tooling
  - Chunk debug overlay: loaded chunks, camera bounds, load/keep rectangles; toggle with P.
  - POI overlays: cell grids, accepted placements (green), biome rejections (orange).
  - POI debug label: multi-line summary per POI type (Settlements, Gas Stations, etc.) showing distance, direction, ETA; supports radial-forward compass and auto camera origin when in vehicle. Forward vector follows vehicle rotation when driving.
  - Bugfixes: fixed cardinal mapping (90 deg -> "S", -90 deg -> "N"); fixed invalid-instance cleanup in POIPlacer.
- Contracts (MVP)
  - Settlement interaction opens a Contract Board (press F near board); generates 3-5 straight-line offers and payment/km.
  - Accepting a contract adds cargo to inventory; one active contract at a time.
  - Enhanced HUD shows active cargo → destination with real-time distance, cardinal direction (N/S/E/W/etc.), and dynamic ETA based on current speed.
  - Distance-based color coding: green (<1km), yellow (<3km), white (farther).
  - Contract completes on proximity to destination settlement (140px radius).
- POI Identification
  - Unique POI naming: Settlements and Gas Stations get deterministic unique IDs (e.g., "Settlement_1234", "GasStation_5678")
  - IDs generated from cell coordinates + seed (range 1000-9999) - same world seed = same names
  - Generic delivery_point_marker.gd: unified component for any delivery destination (settlements, gas stations)
  - Both settlements and gas stations are valid delivery destinations

- Auto-save & Save/Load (MVP)
  - Auto-save disabled by default (can be enabled via export var)
  - Save cooldown system (5 seconds) prevents spam
  - Manual Save/Load input actions:
    - K → save_now (writes to `user://save_game.json`)
    - L → load_save (reads from `user://save_game.json`)
  - Serialized state includes:
    - Player: position, rotation, inventory grid with items/stacks/rotation/positions
    - Vehicle: position, rotation, fuel, and inventory (searches scene tree to ensure current state)
    - Contracts: minimal active-contract data (destination name, cargo, quantity, payment calc params)
  - On-screen toast notifications for save/load success or failure
  - Fixed: Vehicle inventory now properly restored even when accessed without entering vehicle

- Ground Item System (Drop/Pickup)
  - Players can drop items from inventory (press D key while hovering over item)
  - Items spawn as WorldItem nodes in the world with visual representation
  - WorldItem uses `world_icon` texture from ItemData (falls back to `icon` if not set)
  - Pickup Prompt UI shows nearby items in scrollable list format
  - Selection via mouse wheel scroll OR arrow keys (↑↓)
  - Press F to pick up selected item
  - UI uses CanvasLayer to avoid inheriting player rotation
  - Mouse filter configuration prevents UI from blocking scroll events
  - Dual input handling (_input + _unhandled_input) ensures scroll works reliably
  - Items automatically added to player inventory on pickup
  - Dropped items spawn 60px in front of player (rotated with player direction)
  - Pickup radius: 80px (matches InteractionComponent detection range)

- DreadClock System (3-Band Night Cycle)
  - Time loop: 18:00 → 05:59 → resets to 18:00 (looping night)
  - 3 distinct time bands with global scalars:
    - **Calm** (18:00-23:59): danger 0.8x, visibility 1.0x, economy 0.9x, scarcity 0.9x
    - **Hunt** (00:00-02:59): danger 1.5x, visibility 0.9x, economy 1.2x, scarcity 1.1x
    - **False Dawn** (03:00-05:59): danger 0.6x, visibility 1.15x, economy 1.0x, scarcity 1.3x
  - Visual effects:
    - Ambient color overlay shifts per band (bluish → dark → warm glow)
    - Dynamic vignette intensity (20% → 50% → 10%)
    - Smooth 2-second transitions between bands
    - Loop reset glitch effect at 06:00 (screen shake + flash)
  - Audio system ready for band-change stingers and loop reset sounds
  - Resource-based configuration (.tres files):
    - All timing values configurable (start/end hours, band ranges)
    - All visual settings per band (ambient colors, vignette intensity)
    - Time scale adjustable (1.0 = realtime, 0.1 = 10x faster for testing)
  - Modular components:
    - DreadClockVisuals (ambient + vignette)
    - DreadClockAudio (stingers + loop reset)
    - DreadClockGlitch (visual snap effect)
  - Test scene with hotkeys (T/H/D/SPACE) for quick testing

    
## Ongoing / Next


- Roads: connect settlements (greedy/MST) and draw per-chunk.
- Gas station refueling interaction
- Fuel gauge UI element
- Money/credits display in HUD

## Files Changed / Added

- Inventory UI and Hotbar
  - ui/player_inventory_ui.gd
  - ui/item_slot_ui.gd
  - ui/hotbar_ui.gd
  - ui/player_inventory_ui.tscn
- Inventory Core and Items
  - components/Inventory.gd (added custom_grid_size, init_with_size())
  - components/InventoryData.gd (added grid_width/grid_height instance vars, new_with_size() factory)
  - resources/items/item_data.gd (added item_type)
  - resources/items/examples/medkit.tres
  - resources/items/examples/ammo_box.tres
  - resources/items/examples/water_bottle.tres
  - resources/items/examples/delivery_package.tres
  - resources/items/examples/package_small.tres
  - resources/items/examples/package_letter.tres
  - resources/items/examples/package_medium.tres
  - resources/items/examples/package_long.tres
  - resources/items/examples/package_large_crate.tres
- Vehicle Inventory System
  - ui/vehicle_inventory_ui.gd (dynamic grid sizing, cross-inventory transfers)
  - ui/vehicle_inventory_ui.tscn (right-side positioning, auto-resize)
  - ui/player_inventory_ui.gd (updated for cross-inventory transfers, dynamic sizing, left-side positioning)
  - ui/player_inventory_ui.tscn (left-side positioning)
  - components/vehicle_inventory_access.gd (interaction component for vehicle storage)
  - components/vehicle_storage_indicator.gd (optional proximity indicator)
  - actors/vehicles/van/delivery_van.tscn (added InventoryAccessArea2D with script)
  - resources/vehicles/examples/delivery_van.tres (added storage_grid_size = Vector2i(12, 8))
- Player and Vehicle
  - actors/player/player.gd
  - actors/player/player.tscn
  - actors/vehicles/vehicle_controller.gd
  - actors/vehicles/van/delivery_van.tscn
- World Streaming and Generation
  - systems/chunk_manager.gd
  - systems/world_generator.gd
  - systems/chunk_debug_overlay.gd (toggle P, POI layers)
  - resources/world/biome_data.gd
  - resources/world/examples/biome_wasteland.tres
  - resources/world/examples/biome_radioactive.tres
- POI System
  - resources/world/poi_data.gd (allowed_biomes, cell_size_pixels, spawn_chance)
  - resources/world/examples/poi_settlement.tres
  - resources/world/examples/poi_gas_station.tres
  - systems/poi_placer.gd (persistent parenting, dedup, cleanup, distance-based culling, safe cleanup)
  - scenes/world/settlement.tscn (placeholder + board/marker wiring)
  - scenes/world/gas_station.tscn (placeholder)
  - ui/poi_debug_label.gd (nearest/ETA/radial compass; fixed cardinal mapping; per-type summaries; vehicle-forward)
- Contracts
  - autoload/contract_manager.gd (offers, accept, active tracking, delivery completion)
  - components/contract_board_area.gd (Area2D interactable; layer/collision wiring)
  - components/delivery_point_marker.gd (unified marker for settlements and gas stations)
  - ui/contract_board_ui.tscn, ui/contract_board_ui.gd (simple list with Accept/Close)
  - ui/contract_hud.tscn, ui/contract_hud.gd (enhanced HUD: cargo → destination, real-time distance, cardinal direction, ETA, color coding)
- POI System Updates
  - systems/poi_placer.gd (added _generate_poi_id() for unique POI naming)
  - scenes/world/settlement.tscn (updated to use delivery_point_marker.gd)
  - scenes/world/gas_station.tscn (added delivery_point_marker.gd for delivery support)

## Run & Validate

- World streaming demo: scenes/tests/test_worldgen.tscn
  - Move the player or drive the van to load/unload chunks.
  - Press P to toggle debug overlay (chunk bounds, POI cells, placements).
  - Observe POI label multi-line summary for nearest-by-type.
- Inventory/Hotbar demo: scenes/tests/test_inventory.tscn
  - Press TAB to open inventory; drag, rotate (R), and assign to hotbar (1-5). Right-click hotbar slot to remove.
- Contract demo: scenes/tests/test_worldgen.tscn
  - Walk to a settlement Contract Board and press F to open the board; accept an offer (cargo appears in inventory).
  - Enhanced HUD shows active destination with real-time distance, cardinal direction, and ETA that updates as you move.
  - HUD changes color based on proximity: green (<1km), yellow (<3km), white (farther).
  - Enter destination settlement radius (140px) to auto-complete contract and receive payment.
- Vehicle Inventory demo: scenes/tests/test_worldgen.tscn or test_vehicle.tscn
  - Walk to the back/left side of delivery van and press F to access vehicle storage.
  - Both player inventory (left, 8×6) and vehicle inventory (right, 12×8) open simultaneously.
  - Drag items between inventories - weight updates automatically on both sides.
  - Press R to rotate items while dragging; ESC to close both inventories.

- Ground Item System demo: scenes/tests/test_worldgen.tscn
  - Press TAB to open inventory, hover over any item, press D to drop it
  - Item spawns as WorldItem node in front of player with visual representation
  - Walk near dropped items - pickup prompt UI appears automatically
  - Use arrow keys (↑↓) or mouse wheel to select item from list
  - Selected item highlighted in yellow with > brackets <
  - Press F to pick up selected item into inventory
  - Prompt disappears when all nearby items picked up

- DreadClock System demo: scenes/tests/test_dread_clock.tscn
  - SPACE - Toggle fast mode (10x speed) to see band transitions quickly
  - T - Jump to 23:55 (watch Calm → Hunt transition with darker visuals)
  - H - Jump to 02:55 (watch Hunt → False Dawn transition with warm glow)
  - D - Jump to 05:55 (watch loop reset glitch at 06:00)
  - Debug panel shows: current time, band, total minutes, global scalars
  - Visual effects: ambient color overlay and vignette intensity change per band
  - Console logs: band changes, visual updates, glitch triggers

- Save System
  - systems/save_system.gd (autoload; serialize/toast/manual K/L handlers, cooldown system)
  - project.godot (added autoload SaveSystem and input actions `save_now`=K, `load_save`=L, `drop_item`=D)
  - components/Inventory.gd (get_save_data/load_save_data wrappers)
  - components/InventoryData.gd (get_save_data/load_save_data for grid + items)
  - autoload/contract_manager.gd (get_save_data/load_save_data for active contract)

- Ground Item System
  - actors/world_item.gd (Area2D representing dropped items; uses world_icon from ItemData)
  - actors/world_item.tscn (Area2D with Sprite2D, Label, CollisionShape2D on layer 2)
  - ui/pickup_prompt_ui.gd (CanvasLayer showing nearby items with scroll selection)
  - ui/pickup_prompt_ui.tscn (Panel with VBoxContainer for item list)
  - ui/player_inventory_ui.gd (added drop_item signal and _drop_item() method)
  - actors/player/player.gd (integrated pickup prompt UI, WorldItem spawning, and pickup handling)
  - resources/items/item_data.gd (added world_icon field for dropped item appearance)

- DreadClock System
  - autoload/dread_clock.gd (time loop manager with 3 bands, signals, and scalars)
  - resources/dreadclock/dread_clock_config.gd (resource script for all clock settings)
  - resources/dreadclock/default_clock_config.tres (default balanced configuration)
  - resources/dreadclock/fast_test_config.tres (10x speed for testing)
  - resources/dreadclock/README.md (configuration documentation)
  - components/dread_clock_visuals.gd/.tscn (ambient lighting + vignette component)
  - components/dread_clock_audio.gd/.tscn (band-change stingers + loop reset audio)
  - components/dread_clock_glitch.gd/.tscn (loop reset glitch effect with screen shake)
  - ui/dread_clock_ui.gd/.tscn (minimal clock display widget with time and band)
  - scenes/tests/test_dread_clock.gd/.tscn (test scene with hotkeys and debug info)
  - project.godot (added DreadClock autoload)


## Tuning Knobs

- WorldGenerator: biome_noise_frequency, biome_threshold (systems/world_generator.gd)
- ChunkManager: preload_margin_chunks, unload_margin_chunks, track_active_camera (systems/chunk_manager.gd)
- POIs: cell_size_pixels, spawn_chance, allowed_biomes (resources/world/examples/*.tres)
- POI Label: use_radial_compass, compass_sector_deg, use_auto_camera_when_in_vehicle (ui/poi_debug_label.gd)
- Contracts: delivery_radius_px (autoload/contract_manager.gd)
- Save System: autosave_check_interval, autosave_chunk_radius (systems/save_system.gd)
- DreadClock: All settings in DreadClockConfig resources (timing, bands, scalars, visuals)

## Known Issues / Fixes Applied

- ✅ Fixed: Item duplication when transferring between player and vehicle inventories
  - Enforced ownership checks in InventoryData (move/rotate/remove only if item exists in the grid)
  - Unified drop handling so both UIs perform cross-inventory transfers; mark input as handled to prevent double-processing
  - Inventory.init_with_size() now reinitializes data immediately so vehicle storage uses the correct grid size
  - Added transfer test + logs: scenes/tests/test_inventory_transfer.tscn, scenes/tests/test_inventory_transfer.gd

- ✓ Fixed: Contract HUD now visible with proper styling (white text, black outline, 20pt font)
- ✓ Fixed: All contracts showing same distance - POIs now have unique deterministic IDs
- ✓ Fixed: Dynamic UI sizing - panels now auto-resize to fit grid dimensions

- Pending: Roads between settlements are not yet drawn

## Usage Notes (Save/Load)

- Press K anytime to save to `user://save_game.json`.
- Press L anytime to load from the same file.
- Autosave runs every ~2 seconds and triggers when near a registered settlement.
- A small toast appears bottom-center for Save/Load feedback.

## Technical Achievements

- **Data-Driven Inventory System**: Grid sizes defined in VehicleData resources, fully configurable
- **Cross-Inventory Transfer Architecture**: Clean separation between same-inventory moves and cross-inventory transfers
- **Dynamic UI Resizing**: Panels calculate size based on grid dimensions at runtime
- **Shared Dragging State**: Both UIs synchronized during drag operations with proper source tracking
- **Deterministic POI Naming**: Unique IDs generated from cell coordinates ensuring consistency across sessions
