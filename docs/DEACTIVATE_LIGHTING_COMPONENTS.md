# Deactivate Lighting Components Plan

## Overview
Before implementing DreadConeRefactored, we need to deactivate the existing lighting/visibility components to avoid conflicts and performance issues.

## Components to Deactivate

### 1. Player Lighting Components
**File:** `actors/player/player.tscn`

**Action:** Comment out or remove these nodes:
- `ConeLight` (PointLight2D with cone_light.gd script)

**Reason:** Will be replaced by DreadConeController system

### 2. Vehicle Lighting Components  
**File:** `actors/vehicles/van/delivery_van.tscn`

**Action:** Comment out or remove these nodes:
- `HeadlightLeft` (PointLight2D with cone_light.gd script)
- `HeadlightRight` (PointLight2D with cone_light.gd script)

**Reason:** Will be replaced by DreadConeController system

### 3. Component Scripts to Deactivate
**Files to rename (add `_deactivated` suffix):**
- `components/cone_light.gd` → `components/cone_light_deactivated.gd`
- `components/flashlight_component.gd` → `components/flashlight_component_deactivated.gd`
- `components/simple_flashlight.gd` → `components/simple_flashlight_deactivated.gd`
- `components/ambient_darkness.gd` → `components/ambient_darkness_deactivated.gd`
- `components/dread_clock_lighting.gd` → `components/dread_clock_lighting_deactivated.gd`
- `components/dread_cone_vignette.gd` → `components/dread_cone_vignette_deactivated.gd`

**Reason:** Prevents accidental usage and maintains code for reference

### 4. Scene Files to Update
**Files to modify:**
- `components/dread_clock_lighting.tscn` → Rename to `_deactivated`
- `components/dread_cone_vignette.tscn` → Rename to `_deactivated`

## Implementation Steps

### Step 1: Backup Existing Code
```bash
# Create backup directory
mkdir -p components/deactivated_backup

# Copy files to backup
cp components/cone_light.gd components/deactivated_backup/
cp components/flashlight_component.gd components/deactivated_backup/
cp components/simple_flashlight.gd components/deactivated_backup/
cp components/ambient_darkness.gd components/deactivated_backup/
cp components/dread_clock_lighting.gd components/deactivated_backup/
cp components/dread_cone_vignette.gd components/deactivated_backup/
cp components/dread_clock_lighting.tscn components/deactivated_backup/
cp components/dread_cone_vignette.tscn components/deactivated_backup/
```

### Step 2: Update Scene Files
**Player Scene (`actors/player/player.tscn`):**
- Comment out the ConeLight node:
```gdscript
# [node name="ConeLight" type="PointLight2D" parent="."]
# DEACTIVATED: Replaced by DreadConeRefactored system
```

**Vehicle Scene (`actors/vehicles/van/delivery_van.tscn`):**
- Comment out headlight nodes:
```gdscript
# [node name="HeadlightLeft" type="PointLight2D" parent="."]
# DEACTIVATED: Replaced by DreadConeRefactored system

# [node name="HeadlightRight" type="PointLight2D" parent="."]
# DEACTIVATED: Replaced by DreadConeRefactored system
```

### Step 3: Rename Component Files
```bash
# Rename GDScript files
mv components/cone_light.gd components/cone_light_deactivated.gd
mv components/flashlight_component.gd components/flashlight_component_deactivated.gd
mv components/simple_flashlight.gd components/simple_flashlight_deactivated.gd
mv components/ambient_darkness.gd components/ambient_darkness_deactivated.gd
mv components/dread_clock_lighting.gd components/dread_clock_lighting_deactivated.gd
mv components/dread_cone_vignette.gd components/dread_cone_vignette_deactivated.gd

# Rename scene files
mv components/dread_clock_lighting.tscn components/dread_clock_lighting_deactivated.tscn
mv components/dread_cone_vignette.tscn components/dread_cone_vignette_deactivated.tscn
```

### Step 4: Update Code References
**Files that reference deactivated components:**

**`actors/player/player.gd`:**
- Comment out flashlight-related code:
```gdscript
# @onready var flashlight: ConeLight = $ConeLight  # DEACTIVATED
```

**`actors/vehicles/vehicle_controller.gd`:**
- Comment out headlight references:
```gdscript
# @onready var headlight_left: ConeLight = $HeadlightLeft  # DEACTIVATED
# @onready var headlight_right: ConeLight = $HeadlightRight  # DEACTIVATED
```

### Step 5: Clean Up Resources
**Remove or deactivate these resource files:**
- `resources/lighting/flashlight_data.gd`
- `resources/lighting/generate_cone_texture.gd`
- Any example `.tres` files in `resources/lighting/examples/`

## Verification Steps

### 1. Check for Compilation Errors
- Open project in Godot
- Check for any missing script references
- Verify no scenes try to load deactivated components

### 2. Test Basic Functionality
- Player should spawn without cone light
- Vehicle should spawn without headlights
- Game should run without lighting-related errors

### 3. Performance Check
- Monitor that no unnecessary Light2D nodes are active
- Verify memory usage is lower without old lighting system

## Reactivation Plan (If Needed)

If you need to reactivate the old system:

1. Restore files from `components/deactivated_backup/`
2. Remove `_deactivated` suffix from filenames
3. Uncomment nodes in scene files
4. Restore code references in player/vehicle controllers
5. Remove DreadConeRefactored components

## Notes

- **Keep the deactivated files** for reference during implementation
- **Document any special behavior** from the old system that needs to be replicated
- **Test thoroughly** after deactivation to ensure no functionality is lost
- **Consider creating a git branch** for this major change

## Next Steps

After deactivation:
1. Implement `DreadConeController` component
2. Add to player and vehicle scenes
3. Test new visibility system
4. Remove deactivated files once new system is confirmed working

---

**Status:** Ready for implementation
**Priority:** HIGH (must be done before DreadConeRefactored implementation)
**Estimated Time:** 30 minutes
