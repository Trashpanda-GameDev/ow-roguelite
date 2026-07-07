class_name AbilityController
extends Node
## Drives a Hero's five abilities from input. Owns per-slot cooldown state and
## ultimate charge. Attach as a child of the player and call setup(hero).

var hero: Hero
var _caster: Node

# Remaining cooldown per slot (0 = ready).
var _cooldowns := {
	Ability.Slot.PRIMARY: 0.0,
	Ability.Slot.SECONDARY: 0.0,
	Ability.Slot.DASH: 0.0,
	Ability.Slot.ABILITY_1: 0.0,
	Ability.Slot.ABILITY_2: 0.0,
}
var ult_charge: float = 0.0

# Ammo/reload state per slot (only used when the ability has max_ammo > 0).
var _ammo := {}
var _reload := {} # slot -> seconds of reload remaining
# Charge stock per slot (only used when the ability has max_charges > 0).
var _charges := {}
var _recharge := {} # slot -> seconds until the next charge is restored

const _ACTION_BY_SLOT := {
	Ability.Slot.PRIMARY: &"attack_primary",
	Ability.Slot.SECONDARY: &"attack_secondary",
	Ability.Slot.DASH: &"dash",
	Ability.Slot.ABILITY_1: &"ability_1",
	Ability.Slot.ABILITY_2: &"ability_2",
	Ability.Slot.ULTIMATE: &"ultimate",
}

@export var ult_charge_per_damage: float = 1.0 ## ult charge gained per point of damage dealt

func _ready() -> void:
	EventBus.damage_dealt.connect(_on_damage_dealt)

func _on_damage_dealt(_target: Node, amount: float, source: Node, grants_ult_charge: bool) -> void:
	if source == _caster and grants_ult_charge:
		add_ult_charge(amount * ult_charge_per_damage)

func setup(new_hero: Hero, caster: Node) -> void:
	hero = new_hero
	_caster = caster
	for slot in _cooldowns:
		_cooldowns[slot] = 0.0
	ult_charge = 0.0
	_ammo.clear()
	_reload.clear()
	_charges.clear()
	_recharge.clear()
	for slot in _ACTION_BY_SLOT:
		var ability := hero.get_ability(slot) if hero else null
		if ability == null:
			continue
		if ability.max_ammo > 0:
			_ammo[slot] = ability.max_ammo
			_reload[slot] = 0.0
			EventBus.ammo_changed.emit(_ACTION_BY_SLOT[slot], ability.max_ammo, ability.max_ammo)
		if ability.max_charges > 0:
			_charges[slot] = ability.max_charges
			_recharge[slot] = 0.0
			EventBus.charges_changed.emit(_ACTION_BY_SLOT[slot], ability.max_charges, ability.max_charges)

func _physics_process(delta: float) -> void:
	if hero == null:
		return
	for slot in _cooldowns:
		if _cooldowns[slot] > 0.0:
			_cooldowns[slot] = maxf(0.0, _cooldowns[slot] - delta)
	_tick_reloads(delta)
	_tick_charges(delta)
	var pi: PlayerInput = _caster.input if _caster and "input" in _caster else null
	if pi == null:
		return
	for slot in _ACTION_BY_SLOT:
		var action: StringName = _ACTION_BY_SLOT[slot]
		# Attacks auto-repeat while held (rate limited by cooldown); other
		# abilities require a fresh press.
		var triggered := pi.is_pressed(action) if _is_attack(slot) else pi.is_just_pressed(action)
		if triggered:
			_try_use(slot)

func _is_attack(slot: Ability.Slot) -> bool:
	return slot == Ability.Slot.PRIMARY or slot == Ability.Slot.SECONDARY

func _try_use(slot: Ability.Slot) -> void:
	var ability := hero.get_ability(slot)
	if ability == null:
		return
	if slot == Ability.Slot.ULTIMATE:
		if ult_charge < ability.ult_charge_cost or not ability.can_activate(_caster):
			return
		if ability.activate(_caster, _aim_dir()):
			ult_charge = 0.0
			EventBus.player_ultimate_charged.emit(false)
		return
	if _cooldowns[slot] > 0.0 or not ability.can_activate(_caster):
		return
	# Ammo gate: block while reloading; trigger reload when empty.
	if ability.max_ammo > 0:
		if _reload.get(slot, 0.0) > 0.0:
			return
		if _ammo.get(slot, 0) <= 0:
			_start_reload(slot, ability)
			return
	# Charge gate: need at least one charge in stock.
	if ability.max_charges > 0 and _charges.get(slot, 0) <= 0:
		return
	if ability.activate(_caster, _aim_dir()):
		_cooldowns[slot] = ability.cooldown
		EventBus.ability_used.emit(_ACTION_BY_SLOT[slot], ability.cooldown)
		if ability.max_ammo > 0:
			_ammo[slot] -= 1
			EventBus.ammo_changed.emit(_ACTION_BY_SLOT[slot], _ammo[slot], ability.max_ammo)
			if _ammo[slot] <= 0:
				_start_reload(slot, ability)
		if ability.max_charges > 0:
			_charges[slot] -= 1
			EventBus.charges_changed.emit(_ACTION_BY_SLOT[slot], _charges[slot], ability.max_charges)

func _tick_reloads(delta: float) -> void:
	for slot in _reload:
		if _reload[slot] <= 0.0:
			continue
		_reload[slot] = maxf(0.0, _reload[slot] - delta)
		if _reload[slot] == 0.0:
			var ability := hero.get_ability(slot) if hero else null
			if ability:
				_ammo[slot] = ability.max_ammo
				EventBus.ammo_changed.emit(_ACTION_BY_SLOT[slot], ability.max_ammo, ability.max_ammo)

func _start_reload(slot: Ability.Slot, ability: Ability) -> void:
	_reload[slot] = ability.reload_time
	EventBus.reload_started.emit(_ACTION_BY_SLOT[slot], ability.reload_time)

## Regain charges one at a time while below max. Timer runs whenever not full,
## so it effectively starts the moment you drop below max by using one.
func _tick_charges(delta: float) -> void:
	for slot in _charges:
		var ability := hero.get_ability(slot) if hero else null
		if ability == null or ability.charge_recharge_time <= 0.0:
			continue
		if _charges[slot] >= ability.max_charges:
			_recharge[slot] = 0.0
			continue
		if _recharge[slot] <= 0.0:
			_recharge[slot] = ability.charge_recharge_time
		_recharge[slot] -= delta
		if _recharge[slot] <= 0.0:
			_charges[slot] += 1
			EventBus.charges_changed.emit(_ACTION_BY_SLOT[slot], _charges[slot], ability.max_charges)
			_recharge[slot] = ability.charge_recharge_time if _charges[slot] < ability.max_charges else 0.0

func add_ult_charge(amount: float) -> void:
	var ult := hero.get_ability(Ability.Slot.ULTIMATE) if hero else null
	if ult == null:
		return
	var was_ready := ult_charge >= ult.ult_charge_cost
	ult_charge = clampf(ult_charge + amount, 0.0, ult.ult_charge_cost)
	if not was_ready and ult_charge >= ult.ult_charge_cost:
		EventBus.player_ultimate_charged.emit(true)

func cooldown_fraction(slot: Ability.Slot) -> float:
	var ability := hero.get_ability(slot) if hero else null
	if ability == null or ability.cooldown <= 0.0:
		return 0.0
	return _cooldowns.get(slot, 0.0) / ability.cooldown

## Remaining cooldown in seconds (0 = ready).
func cooldown_remaining(slot: Ability.Slot) -> float:
	return _cooldowns.get(slot, 0.0)

func ult_charge_fraction() -> float:
	var ult := hero.get_ability(Ability.Slot.ULTIMATE) if hero else null
	if ult == null or ult.ult_charge_cost <= 0.0:
		return 0.0
	return clampf(ult_charge / ult.ult_charge_cost, 0.0, 1.0)

## Reload progress 0..1 (0 = not reloading / done).
func reload_fraction(slot: Ability.Slot) -> float:
	var ability := hero.get_ability(slot) if hero else null
	if ability == null or ability.reload_time <= 0.0:
		return 0.0
	return _reload.get(slot, 0.0) / ability.reload_time

## Current ammo, or -1 if this slot has no magazine.
func ammo_count(slot: Ability.Slot) -> int:
	return _ammo.get(slot, -1)

## Current charges in stock, or -1 if this slot has no charge stock.
func charges_count(slot: Ability.Slot) -> int:
	return _charges.get(slot, -1)

## Progress 0..1 toward restoring the next charge (0 when full).
func charge_recharge_fraction(slot: Ability.Slot) -> float:
	var ability := hero.get_ability(slot) if hero else null
	if ability == null or ability.charge_recharge_time <= 0.0:
		return 0.0
	if _charges.get(slot, 0) >= ability.max_charges:
		return 0.0
	return clampf(1.0 - _recharge.get(slot, 0.0) / ability.charge_recharge_time, 0.0, 1.0)

func _aim_dir() -> Vector2:
	# Caster decides aim (gamepad right stick vs mouse); fall back to facing.
	if _caster and _caster.has_method("get_aim_dir"):
		return _caster.get_aim_dir()
	if _caster and _caster.has_method("get_facing"):
		return Vector2(_caster.get_facing(), 0.0)
	return Vector2.RIGHT
