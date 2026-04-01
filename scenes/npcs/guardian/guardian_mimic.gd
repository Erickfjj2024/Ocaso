## guardian_mimic.gd
## Boss Guardião Mimic — surge após a traição de Eloah.
## Fase 1 (HP 100-40%): escuridão, perseguição rápida, drena Sanidade.
## Fase 2 (HP 40-0%): lanterna reativa, tenta lure + fuga.
extends CharacterBody2D

# ─────────────────────────────────────────────────────────────
# STATS
# ─────────────────────────────────────────────────────────────

@export var max_hp:        float = 120.0
@export var speed_phase1:  float = 90.0
@export var speed_phase2:  float = 110.0
@export var attack_damage: float = 20.0

const PHASE2_THRESHOLD: float = 0.4     # 40% HP
const ATTACK_RANGE:     float = 22.0
const SANITY_DRAIN_AURA: float = 3.0    # sanidade drenada por segundo na Fase 1 (aura)

# ─────────────────────────────────────────────────────────────
# ESTADO
# ─────────────────────────────────────────────────────────────

var current_hp:  float = max_hp
var _phase:      int   = 1
var _player_ref: Node2D = null
var _attack_cd:  float  = 0.0
var _lure_active: bool  = false
var _aura_timer: float  = 0.0

const ATTACK_CD:  float = 1.2
const AURA_TICK:  float = 1.0   # drena sanidade a cada 1s na Fase 1

# ─────────────────────────────────────────────────────────────
# NÓS FILHOS
# ─────────────────────────────────────────────────────────────

@onready var _hitbox:  Area2D = $HitBox
@onready var _hurtbox: Area2D = $HurtBox

# ─────────────────────────────────────────────────────────────
# INICIALIZAÇÃO
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	current_hp = max_hp
	add_to_group("enemies")

	_hitbox.damage    = attack_damage
	_hitbox.source_id = "guardian_mimic"

	_hurtbox.hurt.connect(_on_hurt)

	# Cura Vampírica: se player usa item de cura na Fase 1, Mimic recupera o dobro
	EventBus.item_used.connect(_on_item_used)

	call_deferred("_find_player")

func _find_player() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_player_ref = players[0]

# ─────────────────────────────────────────────────────────────
# LOOP
# ─────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if not GameManager.is_playing() or _player_ref == null:
		velocity = Vector2.ZERO
		return

	_attack_cd  = maxf(_attack_cd - delta, 0.0)
	_aura_timer += delta

	# Aura de dreno de Sanidade (Fase 1, a cada 1s)
	if _phase == 1 and _aura_timer >= AURA_TICK:
		_aura_timer = 0.0
		var dist := global_position.distance_to(_player_ref.global_position)
		if dist < 60.0:
			SanityManager.apply_sanity_damage(SANITY_DRAIN_AURA)

	match _phase:
		1: _behavior_phase1()
		2: _behavior_phase2()

	move_and_slide()

# ─────────────────────────────────────────────────────────────
# COMPORTAMENTO POR FASE
# ─────────────────────────────────────────────────────────────

func _behavior_phase1() -> void:
	if _player_ref == null:
		return
	var dist := global_position.distance_to(_player_ref.global_position)

	# Perseguição agressiva
	var dir := global_position.direction_to(_player_ref.global_position)
	velocity = dir * speed_phase1

	# Ataque melee ao chegar perto
	if dist <= ATTACK_RANGE and _attack_cd <= 0.0:
		_do_slash()

func _behavior_phase2() -> void:
	if _player_ref == null:
		return
	var dist := global_position.distance_to(_player_ref.global_position)

	if dist < 35.0 and not _lure_active:
		# Mimetismo de Cura: para e age como se estivesse curando
		velocity = Vector2.ZERO
		if _attack_cd <= 0.0:
			_do_lure()
	elif dist < ATTACK_RANGE and _lure_active:
		# Player caiu na armadilha
		_do_slash()
	else:
		_lure_active = false
		# Fuga rápida
		var flee_dir := _player_ref.global_position.direction_to(global_position)
		velocity = flee_dir * speed_phase2

# ─────────────────────────────────────────────────────────────
# ATAQUES
# ─────────────────────────────────────────────────────────────

func _do_slash() -> void:
	_attack_cd = ATTACK_CD
	_hitbox.activate(0.25)
	_flash_color(Color(0.8, 0.0, 0.9))   # roxo-magenta para o slash

func _do_lure() -> void:
	_lure_active = true
	_attack_cd   = 2.0
	# Janela de dano longa — player que se aproxima é atingido
	_hitbox.activate(1.0)

# ─────────────────────────────────────────────────────────────
# DANO E MORTE
# ─────────────────────────────────────────────────────────────

func take_damage(amount: float, source: String) -> void:
	current_hp = maxf(current_hp - amount, 0.0)
	EventBus.enemy_damaged.emit("guardian_mimic", amount)
	_flash_color(Color(1.0, 1.0, 1.0))

	if _phase == 1 and current_hp / max_hp <= PHASE2_THRESHOLD:
		_enter_phase2()

	if current_hp <= 0.0:
		_die()

func _enter_phase2() -> void:
	_phase = 2
	# Reativa a lanterna com 20% de durabilidade (GDD: transição 40% HP)
	LanternManager.force_enable()
	LanternManager.repair(20.0)
	LanternManager.turn_on()
	EventBus.boss_phase_changed.emit("guardian_mimic", 2)

func _die() -> void:
	# Vitória: Eloah nunca mais reaparece; altar funciona sem NPC
	WorldFlags.set_flag("guardian_mimic_defeated", true)
	EventBus.enemy_killed.emit("guardian_mimic")
	EventBus.base_lockdown.emit(false)
	EventBus.npc_dialogue_requested.emit("O que você fez... é permanente.")
	queue_free()

# ─────────────────────────────────────────────────────────────
# HELPERS VISUAIS
# ─────────────────────────────────────────────────────────────

func _flash_color(color: Color) -> void:
	var ph := get_node_or_null("BodyPlaceholder")
	if ph == null:
		return
	var orig: Color = ph.color
	ph.color = color
	await get_tree().create_timer(0.12).timeout
	if is_instance_valid(ph):
		ph.color = orig

# ─────────────────────────────────────────────────────────────
# CALLBACKS
# ─────────────────────────────────────────────────────────────

func _on_hurt(amount: float, source: String) -> void:
	take_damage(amount, source)

func _on_item_used(item: Resource) -> void:
	if _phase != 1 or item == null:
		return
	# Cura Vampírica: item de cura do player reverte para o Mimic (dobro)
	var heal: Variant = item.get("heal_amount") if item.get_script() != null else null
	if heal != null and float(heal) > 0.0:
		current_hp = minf(current_hp + float(heal) * 2.0, max_hp)
