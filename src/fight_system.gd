extends Node

## Central combat state. Tracks health, applies damage, detects knock-outs.
## Autoload singleton: connected to by both fighters and the HUD.

signal health_changed(fighter_id: int, new_health: float)
signal fighter_ko(fighter_id: int)
signal round_reset

const MAX_HEALTH := 100.0
const JAB_DAMAGE := 8.0
const JAB_KNOCKBACK := 220.0
const HITSTUN_TIME := 0.18

var health := {1: MAX_HEALTH, 2: MAX_HEALTH}
var _koed := {1: false, 2: false}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	round_reset.connect(_on_round_reset)


func register_fighter(fighter: Player) -> void:
	health[fighter.fighter_id] = MAX_HEALTH
	_koed[fighter.fighter_id] = false
	fighter.health = MAX_HEALTH
	fighter.on_health_changed()


## A fighter's hitbox touched an opponent's hurtbox.
func on_attack_connected(attacker: Player, victim: Player) -> void:
	if attacker == null or victim == null:
		return
	if attacker.fighter_id == victim.fighter_id:
		return
	if _koed[victim.fighter_id]:
		return
	if victim.hitstun_remaining > 0.0:
		return

	var direction: float = 1.0 if (victim.global_position.x - attacker.global_position.x) > 0 else -1.0
	print("HIT: %d -> %d dmg=%f" % [attacker.fighter_id, victim.fighter_id, JAB_DAMAGE])
	deal_damage(victim.fighter_id, JAB_DAMAGE)
	victim.get_hit(JAB_KNOCKBACK * direction)


func deal_damage(fighter_id: int, amount: float) -> void:
	health[fighter_id] = maxf(0.0, health[fighter_id] - amount)
	health_changed.emit(fighter_id, health[fighter_id])
	if health[fighter_id] <= 0.0 and not _koed[fighter_id]:
		_koed[fighter_id] = true
		fighter_ko.emit(fighter_id)


func is_koed(fighter_id: int) -> bool:
	return _koed[fighter_id]


func _on_round_reset() -> void:
	for fighter_id in health:
		health[fighter_id] = MAX_HEALTH
		_koed[fighter_id] = false
		health_changed.emit(fighter_id, MAX_HEALTH)
	for fighter in get_tree().get_nodes_in_group("fighters"):
		var player := fighter as Player
		if player:
			player.reset_fighter()