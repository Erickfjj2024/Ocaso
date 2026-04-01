## player_combat.gd
## Componente de combate do Player: HP, recebimento de dano, iframes e ataque.
## Attach em: PlayerCombat (Node), filho do Player (CharacterBody2D).
extends Node

# ─────────────────────────────────────────────────────────────
# CONFIGURAÇÃO
# ─────────────────────────────────────────────────────────────

@export var max_hp: float = 100.0

## Duração dos iframes após receber dano (em segundos).
@export var iframe_duration: float = 0.6

## Duração da janela de dano do ataque (em segundos).
@export var attack_hit_duration: float = 0.18

## Dano causado pelo ataque melee do player.
@export var attack_damage: float = 25.0

# ─────────────────────────────────────────────────────────────
# ESTADO
# ─────────────────────────────────────────────────────────────

var current_hp: float = max_hp
var is_dead: bool     = false

# ─────────────────────────────────────────────────────────────
# NÓS FILHOS
# ─────────────────────────────────────────────────────────────

@onready var _hurtbox: Area2D = $"../HurtBox"
@onready var _hitbox:  Area2D = $"../HitBox"

# ─────────────────────────────────────────────────────────────
# INICIALIZAÇÃO
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	current_hp = max_hp
	_hurtbox.hurt.connect(_on_hurt)
	EventBus.player_hp_changed.emit(current_hp, max_hp)

	# Configura o HitBox com os parâmetros deste componente
	_hitbox.damage    = attack_damage
	_hitbox.source_id = "player_sword"

# ─────────────────────────────────────────────────────────────
# API PÚBLICA
# ─────────────────────────────────────────────────────────────

## Aplica dano ao player. Chamado pelo HurtBox ou diretamente por sistemas.
func take_damage(amount: float, source: String) -> void:
	if is_dead or _hurtbox.is_invulnerable:
		return

	current_hp = maxf(current_hp - amount, 0.0)
	EventBus.player_damaged.emit(amount, source)
	EventBus.player_hp_changed.emit(current_hp, max_hp)

	if current_hp <= 0.0:
		_die()
	else:
		# Iframes para evitar hits múltiplos no mesmo frame
		_hurtbox.start_invulnerability(iframe_duration)
		# Shake de câmera — delega ao player pai
		var player := get_parent()
		if player.has_method("camera_shake"):
			player.camera_shake(3.0, 0.25)

## Inicia o ataque melee: ativa o HitBox pela janela de impacto.
func start_attack() -> void:
	if is_dead:
		return
	_hitbox.activate(attack_hit_duration)

## Restaura HP (usado por itens, guardião, etc.).
func heal(amount: float) -> void:
	if is_dead:
		return
	current_hp = minf(current_hp + amount, max_hp)
	EventBus.player_hp_changed.emit(current_hp, max_hp)

## Reseta HP para o máximo (chamado pelo base_hub ao recarregar).
func reset() -> void:
	is_dead    = false
	current_hp = max_hp
	_hurtbox.is_invulnerable = false
	EventBus.player_hp_changed.emit(current_hp, max_hp)

# ─────────────────────────────────────────────────────────────
# MORTE
# ─────────────────────────────────────────────────────────────

func _die() -> void:
	is_dead = true
	# Delega a sequência de morte ao player.gd
	var player := get_parent()
	if player.has_method("die"):
		player.die()

# ─────────────────────────────────────────────────────────────
# CALLBACKS
# ─────────────────────────────────────────────────────────────

func _on_hurt(amount: float, source: String) -> void:
	take_damage(amount, source)
