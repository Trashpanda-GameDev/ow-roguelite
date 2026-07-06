@tool
class_name Ability
extends Resource
## Base class for a hero ability. Subclass and override _activate() to define
## behavior. Instances live in a Hero resource's ability slots and are driven
## by the player's AbilityController (which owns cooldown state).

enum Slot { PRIMARY, SECONDARY, DASH, ABILITY_1, ABILITY_2, ULTIMATE }

@export var display_name: String = "Ability"
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var cooldown: float = 1.0            ## seconds between uses
@export var is_ultimate: bool = false:
	set(value):
		is_ultimate = value
		notify_property_list_changed() # refresh inspector to show/hide ult fields
@export var ult_charge_cost: float = 100.0   ## for ultimates, charge needed
@export var projectile_scene: PackedScene    ## optional, for ranged abilities

@export_group("Ammo")
@export var max_ammo: int = 0                ## 0 = unlimited; >0 uses a magazine
@export var reload_time: float = 1.0         ## seconds to reload when empty

@export_group("Charges")
@export var max_charges: int = 0             ## 0 = plain cooldown; >0 = a recharging stock
@export var charge_recharge_time: float = 3.0 ## seconds to regain one charge while below max

## Override this. `caster` is the player node; `aim_dir` is a normalized aim
## vector. Return true if the ability actually fired (starts cooldown).
func activate(_caster: Node, _aim_dir: Vector2) -> bool:
	push_warning("Ability.activate() not overridden for '%s'" % display_name)
	return false

## Optional gate beyond cooldown (e.g. needs a target, resource, grounded).
func can_activate(_caster: Node) -> bool:
	return true

## Hide ultimate-only fields in the inspector when this isn't an ultimate.
func _validate_property(property: Dictionary) -> void:
	if property.name == "ult_charge_cost" and not is_ultimate:
		property.usage &= ~PROPERTY_USAGE_EDITOR
