# Wasteland Courier

A Death Stranding-inspired top-down courier simulator with survival and action elements, built in Godot 4.x.

## Project Status

**Current Phase:** Setup Complete - Ready for Phase 1 Development
**Version:** 0.1 MVP
**Engine:** Godot 4.x (GDScript)

## Quick Start

1. Open project in Godot 4.x
2. Read `docs/GDD.md` for complete game design
3. Check `docs/PHASE_1_CORE_DELIVERY_LOOP.md` to see what's being built first
4. Follow `docs/CODING_STANDARDS.md` when writing code

## Documentation

- **[GDD.md](docs/GDD.md)** - Master Game Design Document
- **[CODING_STANDARDS.md](docs/CODING_STANDARDS.md)** - Code style guide
- **[PHASE_1_CORE_DELIVERY_LOOP.md](docs/PHASE_1_CORE_DELIVERY_LOOP.md)** - MVP core systems
- **[PHASE_2_SURVIVAL_PROGRESSION.md](docs/PHASE_2_SURVIVAL_PROGRESSION.md)** - Survival & skills
- **[PHASE_3_DANGER_COMBAT.md](docs/PHASE_3_DANGER_COMBAT.md)** - Combat & enemies
- **[PHASE_4_POLISH_DEPTH.md](docs/PHASE_4_POLISH_DEPTH.md)** - Optional enhancements

## Game Overview

**Core Concept:**
Complete delivery contracts across a dangerous procedurally generated wasteland while managing survival needs, avoiding raiders, and building reputation.

**Key Features:**
- Delivery-focused gameplay (like Death Stranding)
- Skill progression through use (like Project Zomboid)
- Grid-based inventory (like Resident Evil)
- Realistic vehicle driving with fuel management
- Survival mechanics (hunger, thirst, fatigue)
- Defensive combat (avoid when possible)
- Procedural open world
- Reputation system (high rep = better contracts, more danger)

## Development Phases

### Phase 1: Core Delivery Loop ✅ (Planned)
- Player movement & vehicle driving
- Grid inventory system
- Procedural world generation
- Basic contract system
- Auto-save

### Phase 2: Survival & Progression (Planned)
- Hunger/thirst/fatigue mechanics
- Project Zomboid-style skill system
- Contract tiers (Novice/Experienced/Expert)
- Reputation system
- Time limits & failure consequences

### Phase 3: Danger & Combat (Planned)
- Enemy AI (raiders)
- Defensive combat system
- Vehicle ramming
- Ambush system (higher rep = more danger)
- Damage & repair

### Phase 4: Polish & Depth (Optional)
- Vehicle variety & upgrades
- Weather system
- Map & navigation
- Contract variety (fragile, urgent, escort)
- Permadeath mode

## Folder Structure

```
res://
├── actors/           Player, enemies, vehicles
├── components/       Reusable components (health, inventory, etc.)
├── resources/        All .tres data files (items, contracts, vehicles)
├── systems/          Game systems (world gen, contracts, saves)
├── scenes/           .tscn scene files
├── ui/               UI scenes and scripts
├── assets/           Art, audio, fonts
├── autoload/         Singleton scripts (GameManager, EventBus)
├── docs/             All documentation
└── OLD_CODE/         Salvageable code from previous versions
```

## Code Philosophy

### Resource-Driven Development
- Data lives in `.tres` files, not hardcoded in scripts
- Designers can modify game content without touching code
- Hot-reloading for rapid iteration
- Beginner-friendly and modding-friendly

### Component-Based Architecture
- Small, focused components (HealthComponent, InventoryComponent)
- Composition over inheritance
- Reusable across entities

### Godot Best Practices
- **snake_case** for files and variables
- **Type hints** everywhere
- **Tabs** for indentation
- **Signals** for decoupling

## Salvageable Code

**OLD_CODE/driving_camera/**
- `LookAheadCamera.gd` - Production-ready 8-quadrant racing camera
- Will be integrated into vehicle system in Phase 1

## Contributing

This is currently a solo/small team project. If contributing:
1. Read `docs/CODING_STANDARDS.md`
2. Follow established patterns
3. Use `.tres` resources for data
4. Write self-documenting code

## License

TBD

## Contact

Project maintained by: [Your Name/Team]
