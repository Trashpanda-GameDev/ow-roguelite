class_name Hero
extends Resource
## Data definition of a playable hero (Overwatch-inspired). Create instances as
## .tres files under res://resources/heroes/. Stats + five ability slots.

@export var id: StringName = &"hero"
@export var display_name: String = "Hero"
@export_multiline var description: String = ""
@export var portrait: Texture2D
@export var sprite_frames: SpriteFrames ## animations: idle, run, jump, fall, hurt

@export_group("Base Stats")
@export var max_health: float = 100.0
@export var move_speed: float = 320.0
@export var jump_velocity: float = 620.0
@export var air_control: float = 0.85 ## 0..1 accel multiplier while airborne
@export var max_air_jumps: int = 1

@export_group("Abilities")
@export var primary: Ability
@export var secondary: Ability
@export var dash: Ability ## the dash button (Shift / Circle); leave null for no dash
@export var ability_1: Ability
@export var ability_2: Ability
@export var ultimate: Ability

func get_ability(slot: Ability.Slot) -> Ability:
	match slot:
		Ability.Slot.PRIMARY: return primary
		Ability.Slot.SECONDARY: return secondary
		Ability.Slot.DASH: return dash
		Ability.Slot.ABILITY_1: return ability_1
		Ability.Slot.ABILITY_2: return ability_2
		Ability.Slot.ULTIMATE: return ultimate
	return null
