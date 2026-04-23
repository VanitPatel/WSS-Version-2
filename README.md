# Wilderness Survival System (WSS)
### CS3560 – Godot 4 Implementation

---

## How to Open & Run

1. **Install Godot 4.2+** from https://godotengine.org/download
2. Open Godot → **Import** → select the `WSS/` folder → open `project.godot`
3. Press **F5** (or the ▶ Play button) to run the game.

---

## Project Structure

```
WSS/
├── project.godot          # Godot project config (autoloads GameManager)
├── icon.svg
├── scenes/
│   └── Main.tscn          # Root scene (UI layout)
└── scripts/
	├── Terrain.gd          # Terrain types & costs (Plains/Mountain/Desert/Swamp/Forest)
	├── Item.gd             # Item types (Food/Water/Gold/Trader), repeating flag
	├── MapCell.gd          # One grid square: terrain + items
	├── GameMap.gd          # Map generator (weighted random terrain + item placement)
	├── Vision.gd           # Vision subclasses: Cautious / Standard / Broad
	├── Brain.gd            # Brain subclasses: Survival / Aggressive
	├── Player.gd           # Player stats, movement, item collection
	├── Trader.gd           # Trader state machine (negotiation logic, 3 personality types)
	├── GameManager.gd      # Autoload: turn loop, game-over detection
	└── Main.gd             # UI controller (setup form, map grid, log panel)
```

---

## Gameplay

The player starts on the **west edge** and must cross to the **east edge**.

| Setup Option | Choices |
|---|---|
| Map Width | 8 – 40 squares |
| Map Height | 5 – 20 squares |
| Difficulty | Easy / Normal / Hard (affects terrain distribution) |
| Vision | Cautious (N/S/E) · Standard (4-dir) · Broad (8-dir) |
| Brain | Survival (resource-first) · Aggressive (east-first) |

### Controls
- **⏭ Step** – advance one turn manually
- **▶ Auto** – play automatically (one turn every 0.4 s)
- **↺ Restart** – return to setup screen

### Terrain Costs (movement / water / food)

| Terrain | Move | Water | Food |
|---|---|---|---|
| Plains   | 1 | 1 | 1 |
| Mountain | 4 | 2 | 2 |
| Desert   | 2 | 3 | 1 |
| Swamp    | 3 | 1 | 2 |
| Forest   | 2 | 1 | 1 |

### Items
- **Food / Water / Gold Bonus** – collected on entry; may be repeating (once per turn)
- **Trader** – always repeating; auto-negotiates a trade if the player is thirsty

### Trader Personalities (`Trader.gd`)
| Trader | Rounds | Disposition |
|---|---|---|
| Merchant      | 5 | Fair |
| Old Trapper   | 3 | Stubborn |
| Friendly Nomad | 8 | Generous |

---

## Class Hierarchy (per assignment requirements)

```
Vision
  ├── CautiousVision  (N / S / E)
  ├── StandardVision  (N / S / E / W)
  └── BroadVision     (all 8 directions)

Brain
  ├── SurvivalBrain   (water → food → east)
  └── AggressiveBrain (east always, resources only when critical)

Trader (state machine: READY → COUNTERED → ACCEPTED / REJECTED)
  ├── Patient  (Merchant)
  ├── Stubborn (Old Trapper)
  └── Eager    (Friendly Nomad)
```

---

## Extending the Project (Homework 4 ideas)
- Add more terrain types (Tundra, River, Cave)
- Implement manual player control (keyboard movement)
- Add multiple simultaneous players competing for resources
- Display a post-run report comparing Vision/Brain combinations
- Connect Trader UI for manual negotiation input

---

*Built with Godot 4.2 · GDScript · CS3560 Spring 2025*
