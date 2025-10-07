# Testing Guide - Phase 1

## Current Build Status

**Completed Systems:**
- ✅ Player locomotion (WASD movement, Shift sprint)
- ✅ Grid-based inventory (8×6)
- ✅ Interaction component (F key)
- ✅ Player scene with visual placeholder
- ✅ Test scene for movement

**Not Yet Implemented:**
- ❌ Vehicles
- ❌ World generation
- ❌ Inventory UI
- ❌ Contracts

---

## How to Test Player Movement

### 1. Open Project in Godot

1. Launch Godot 4.x
2. Open project: `courier-quest - Copy`
3. Wait for import/compilation to complete

### 2. Test Player Scene

**Option A: Run Test Scene**
1. Open `res://scenes/test_player.tscn`
2. Press F5 or click "Run Current Scene"
3. You should see:
   - Blue square (player body)
   - White triangle (direction indicator)
   - Camera following player

**Option B: Run from Editor**
1. Open `res://actors/player/player.tscn`
2. Click "Instance Child Scene" button
3. Right-click player node → "Play Scene" (F6)

### 3. Controls

| Input | Action |
|-------|--------|
| **W** | Move up |
| **A** | Move left |
| **S** | Move down |
| **D** | Move right |
| **Shift** | Sprint (hold while moving) |
| **F** | Interact (not functional yet) |
| **Mouse** | Player rotates toward cursor |

### 4. What to Verify

**Movement:**
- [ ] Player moves smoothly with WASD
- [ ] Player rotates toward mouse cursor
- [ ] Sprint (Shift) makes player move faster
- [ ] Direction indicator (white triangle) points forward

**Components:**
- [ ] No errors in console
- [ ] LocomotionComponent updates velocity
- [ ] InventoryComponent exists (check in Remote tab)
- [ ] InteractionComponent has Area2D circle

---

## Known Issues / Expected Behavior

**Visual:**
- Player is a simple blue square with white arrow (placeholder art)
- No animations yet
- No camera smoothing yet

**Gameplay:**
- Inventory exists but has no UI (can't see items)
- Weight system works but isn't visible
- Interaction system detects objects but nothing to interact with yet
- Sprint works but doesn't drain stamina (Phase 2 feature)

**Technical:**
- Some warnings expected about missing nodes
- project.godot may need input actions configured manually

---

## Debugging Tips

### If player doesn't move:
1. Check console for errors
2. Verify `project.godot` has input actions:
   - `move_up`, `move_down`, `move_left`, `move_right`
   - `sprint`
   - `interact`
3. Check if LocomotionComponent is attached
4. Check if CharacterBody2D has collision enabled

### If errors appear:
- **"Can't find script"**: Verify all `.gd` files are in correct locations
- **"Invalid property"**: Check export variables match between script and scene
- **"Null reference"**: Check node connections in scene tree

### Manual Input Configuration

If input actions aren't defined, add them to `project.godot`:

1. Project → Project Settings → Input Map
2. Add actions:
   - `move_up` → W key
   - `move_down` → S key
   - `move_left` → A key
   - `move_right` → D key
   - `sprint` → Shift key
   - `interact` → F key

---

## Next Steps

Once player movement is working:
1. **Vehicle controller** - Drive vehicles
2. **World generation** - Procedural chunks and biomes
3. **Inventory UI** - Visual grid interface
4. **Contract system** - Delivery missions

---

## Performance Notes

**Expected FPS:** 60 FPS
**Memory Usage:** < 100 MB (very lightweight currently)

If experiencing issues:
- Check Godot version (requires 4.x)
- Verify no other heavy processes running
- Check console for warnings

---

## File Locations

**Player Files:**
- Scene: `res://actors/player/player.tscn`
- Script: `res://actors/player/player.gd`

**Components:**
- `res://components/locomotion_component.gd`
- `res://components/inventory_component.gd`
- `res://components/interaction_component.gd`

**Test Scene:**
- `res://scenes/test_player.tscn`

**Resource Definitions:**
- `res://resources/items/item_data.gd`
- `res://resources/vehicles/vehicle_data.gd`
- `res://resources/contracts/contract_data.gd`
