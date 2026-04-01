## guilt_ghost.gd
## Fantasma da Culpa — surge quando has_murdered=true.
## Flutua em direção ao player, drena Sanidade ao tocar, depois desaparece.
## Passa por todas as paredes (collision_mask=0 no corpo).
extends Area2D

# ─────────────────────────────────────────────────────────────
# CONFIGURAÇÃO
# ─────────────────────────────────────────────────────────────

const MOVE_SPEED:     float = 32.0
const SANITY_DAMAGE:  float = 8.0
const LIFETIME:       float = 12.0

# ─────────────────────────────────────────────────────────────
# ESTADO
# ─────────────────────────────────────────────────────────────

var _player_ref: Node2D = null
var _lifetime:   float  = LIFETIME
var _hit:        bool   = false

# ─────────────────────────────────────────────────────────────
# INICIALIZAÇÃO
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_player_ref = players[0]

# ─────────────────────────────────────────────────────────────
# LOOP
# ─────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	_lifetime -= delta
	if _lifetime <= 0.0:
		queue_free()
		return

	# Pulso visual: alpha oscila entre 0.35 e 0.85
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.004)
	modulate.a = lerpf(0.35, 0.85, pulse)

	if _player_ref == null or _hit:
		return

	# Move diretamente em direção ao player (atravessa paredes)
	var dir := global_position.direction_to(_player_ref.global_position)
	global_position += dir * MOVE_SPEED * delta

# ─────────────────────────────────────────────────────────────
# COLISÃO COM O PLAYER
# ─────────────────────────────────────────────────────────────

func _on_body_entered(body: Node) -> void:
	if _hit or not body.is_in_group("player"):
		return
	_hit = true
	SanityManager.apply_sanity_damage(SANITY_DAMAGE)
	EventBus.player_damaged.emit(0.0, "guilt_ghost")   # 0 HP damage — só sanidade
	EventBus.npc_dialogue_requested.emit("Você se lembra de mim?")
	queue_free()
