# OW Roguelite

2D sidescrolling roguelite (Godot **4.7**) — action-platformer combat in the vein
of *Nine Sols* / *Skul: The Hero Slayer*, with **Overwatch-inspired heroes** whose
kits (primary, secondary, two abilities, ultimate) define how each run plays.

## Run it

Open the project in Godot 4.7 and press **F5**. `scenes/main.tscn` boots straight
into a test level with the starter hero (`striker`) and two training dummies.

Debug hero switch: press **1** for Striker (melee bruiser) or **2** for Tracer
(fast skirmisher — Pulse Pistols, Blink, Recall, Pulse Bomb). Attacks auto-fire
while held; other abilities are single-press.

### Controls

Controller: DualSense / PS5 (Sony button labels below).

| Action | Keyboard / Mouse | PS5 |
|---|---|---|
| Move | A / D | Left stick |
| Aim | Mouse | Right stick |
| Jump (double) | Space | Cross |
| Dash | Shift | Circle |
| Slash (primary) | Left mouse | Square |
| Secondary | Right mouse | Triangle |
| Blink Dash (ability 1) | Q | L1 |
| Ability 2 | E | R1 |
| Ultimate | R | R2 |
| Interact | F | D-pad Up |
| Pause | Esc | Options |

Aim auto-switches to the right stick the moment you use the controller, and back
to the mouse when you move it — so melee/abilities fire the correct direction on
either device (right stick centered = aim in the facing direction).

## Architecture

Data-driven and component-based — the idiomatic Godot approach.

```
scripts/
  autoload/        EventBus (global signals), GameManager (flow/pause),
                   RunManager (per-run state: hero, currency, depth, upgrades)
  components/      HealthComponent, HitboxComponent, HurtboxComponent
                   (reusable, attach to any entity)
  heroes/          Hero (Resource: stats + 5 ability slots), Ability (Resource base)
    abilities/     Concrete abilities (MeleeSlash, Dash) — subclass Ability
  player/          Player controller + AbilityController (drives the hero's kit)
  enemies/         TrainingDummy
  core/            Main (entry point)
resources/heroes/  striker.tres — starter hero definition (.tres)
scenes/            main, levels/, player/, enemies/, ui/
```

### Key ideas

- **Heroes are data.** A `Hero` resource holds base stats and five `Ability`
  resources. Add a hero by creating a `.tres` under `resources/heroes/` — no new
  scenes required. `RunManager.hero_id` selects which one loads.
- **Abilities are subclassable resources.** Override `Ability.activate(caster, aim_dir)`.
  The player exposes hooks abilities call (`spawn_melee_hitbox`, `start_dash`, …),
  so abilities stay decoupled from the controller.
- **Combat = Hitbox → Hurtbox → Health.** A `HitboxComponent` (Area2D) overlaps a
  `HurtboxComponent` (Area2D), which applies damage to its `HealthComponent`.
- **EventBus** decouples systems: UI, audio, and progression listen to signals
  without referencing gameplay nodes.

### Collision layers

1 world · 2 player · 3 enemy · 4 player_hitbox · 5 player_hurtbox ·
6 enemy_hitbox · 7 enemy_hurtbox · 8 pickups

## Next steps

- Main menu + hero-select screen (replace the auto-boot in `Main`).
- Room/floor generation driving `RunManager.advance_depth()`.
- Real enemies (reuse Health/Hurtbox components + an AI/state machine).
- HUD: health bar, ability cooldowns, ultimate charge (all already emitted on EventBus).
- Reward/upgrade system feeding `RunManager.add_upgrade()`.
- Art: swap placeholder rects for `SpriteFrames` on each hero.
