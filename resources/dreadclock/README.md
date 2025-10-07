# DreadClock Configuration Resources

This directory contains configuration resources for the DreadClock system.

## Files

### `dread_clock_config.gd`
Resource script that defines all configurable parameters for the DreadClock system.

### `default_clock_config.tres`
Default configuration with balanced settings:
- Time scale: 1.0 (realtime - 1 second = 1 game minute)
- Loop: 18:00 → 05:59 → reset to 18:00
- Calm band (18:00-23:59): Lower danger, normal visibility
- Hunt band (00:00-02:59): High danger, reduced visibility
- False Dawn band (03:00-05:59): Lowest danger, increased visibility

### `fast_test_config.tres`
Testing configuration with accelerated time:
- Time scale: 0.1 (10x faster - 0.1 seconds = 1 game minute)
- Same band settings as default
- Useful for quickly testing band transitions and loop resets

## Creating Custom Configurations

1. In Godot, right-click in FileSystem panel
2. Select "New Resource"
3. Choose "DreadClockConfig"
4. Configure the properties in the Inspector:

### Time Loop Settings
- **start_hour**: Hour when loop begins (default: 18)
- **end_hour**: Hour when loop resets (default: 6)
- **time_scale**: Real seconds per game minute (1.0 = realtime, 0.1 = 10x faster)

### Band Timing
- **calm_start_hour / calm_end_hour**: Calm band time range
- **hunt_start_hour / hunt_end_hour**: Hunt band time range
- **false_dawn_start_hour / false_dawn_end_hour**: False Dawn band time range

### Band Scalars
Each band has 4 multipliers that affect game systems:

**Calm Band:**
- danger_mult: 0.8 (20% less dangerous)
- visibility_mult: 1.0 (normal visibility)
- economy_mult: 0.9 (10% worse economy)
- scarcity_mult: 0.9 (more resources available)

**Hunt Band:**
- danger_mult: 1.5 (50% more dangerous)
- visibility_mult: 0.9 (10% reduced visibility)
- economy_mult: 1.2 (20% better payouts)
- scarcity_mult: 1.1 (slightly fewer resources)

**False Dawn Band:**
- danger_mult: 0.6 (40% less dangerous)
- visibility_mult: 1.15 (15% better visibility)
- economy_mult: 1.0 (normal economy)
- scarcity_mult: 1.3 (30% fewer resources - best time to move)

## Using Configs in Code

The DreadClock autoload uses `default_clock_config.tres` by default. To use a different config:

1. Open `autoload/dread_clock.gd` in the Godot editor
2. In the Inspector, change the "Config" property to your custom .tres file

Or access programmatically:
```gdscript
# Read current scalars
var danger = DreadClock.danger_mult
var visibility = DreadClock.visibility_mult

# Get current time
var time_str = DreadClock.get_time_string()  # "18:00"
var band_name = DreadClock.get_band_name()  # "Calm"

# Subscribe to events
DreadClock.band_changed.connect(_on_band_changed)
DreadClock.loop_reset.connect(_on_loop_reset)
```

## Testing

Use `scenes/tests/test_dread_clock.tscn` to test configurations:
- Press SPACE to toggle 10x speed mode
- Press T/H/D to jump to specific times
- Watch debug info update in real-time
