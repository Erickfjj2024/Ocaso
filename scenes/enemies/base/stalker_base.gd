## stalker_base.gd
## Controlador base do Stalker: stats, movimento, dano e morte.
## Attach em: StalkerBase (CharacterBody2D).
## A lógica de IA (quando mover, quando atacar) fica no StateMachine filho.
extends CharacterBody2D

# ─────────────────────────────────────────────────────────────
# CONFIGURAÇÃO (editável por variante)
# ─────────────────────────────────────────────────────────────

@export var enemy_id:      String = "stalker_base"
@export var max_hp:        float  = 60.0
@export var speed_base:    float  = 55.0
@export var attack_range:  float  = 18.0
@export var attack_damage: float  = 15.0

## Multiplicador de velocidade no escuro (GDD: 150%).
const SPEED_DARK_MULT:  float = 1.5
## Multiplicador de velocidade na luz (GDD: 30%).
const SPEED_LIGHT_MULT: float = 0.3

# ─────────────────────────────────────────────────────────────
# ESTADO — EXPOSTO PARA O StateMachine
# ─────────────────────────────────────────────────────────────

var current_hp:        float   = max_hp
var player_ref:        Node2D  = null   # preenchido pelo DetectionZone
var is_in_light:       bool    = false  # preenchido pelo LightSensor
var is_backstab_ready: bool    = false  # preenchido pelo BackstabDetector

# ─────────────────────────────────────────────────────────────
# NÓS FILHOS
# ─────────────────────────────────────────────────────────────

@onready var _state_machine: Node          = $StateMachine
@onready var _nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var _hitbox:  Area2D              = $HitBox
@onready var _hurtbox: Area2D              = $HurtBox

# ─────────────────────────────────────────────────────────────
# PATRULHA
# ─────────────────────────────────────────────────────────────

var _patrol_dir:   int   = 1    # 1 = direita, -1 = esquerda
var _patrol_timer: float = 0.0
const PATROL_FLIP_TIME: float = 2.2

# ─────────────────────────────────────────────────────────────
# INICIALIZAÇÃO
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	current_hp = max_hp
	add_to_group("enemies")

	# HitBox
	_hitbox.damage    = attack_damage
	_hitbox.source_id = enemy_id

	# HurtBox → recebe dano
	_hurtbox.hurt.connect(_on_hurt)

	# LightSensor → reage à lanterna
	$LightSensor.light_state_changed.connect(_on_light_state_changed)

	# DetectionZone → detecta corpo do player (CharacterBody2D no grupo "player")
	$DetectionZone.body_entered.connect(_on_detection_body_entered)
	$DetectionZone.body_exited.connect(_on_detection_body_exited)

	# BackstabDetector → backstab pronto
	$BackstabDetector.backstab_ready.connect(_on_backstab_ready)

# ─────────────────────────────────────────────────────────────
# LOOP PRINCIPAL
# ─────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if not GameManager.is_playing():
		return
	_patrol_timer += delta
	move_and_slide()

# ─────────────────────────────────────────────────────────────
# API DE MOVIMENTO — chamada pelo StateMachine
# ─────────────────────────────────────────────────────────────

## Velocidade atual conforme estado de iluminação.
func get_current_speed() -> float:
	return speed_base * (SPEED_LIGHT_MULT if is_in_light else SPEED_DARK_MULT)

## Move o stalker em direção ao player. Usa NavigationAgent2D se disponível.
func move_toward_player() -> void:
	if player_ref == null:
		velocity = Vector2.ZERO
		return

	var spd := get_current_speed()
	_nav_agent.target_position = player_ref.global_position

	if not _nav_agent.is_navigation_finished():
		var next := _nav_agent.get_next_path_position()
		velocity = global_position.direction_to(next) * spd
	else:
		# Fallback: movimento direto (sem NavigationRegion2D configurado)
		velocity = global_position.direction_to(player_ref.global_position) * spd

## Move o stalker em patrulha simples (vai-e-vem horizontal).
func move_patrol() -> void:
	if _patrol_timer >= PATROL_FLIP_TIME:
		_patrol_timer = 0.0
		_patrol_dir  *= -1
	velocity = Vector2(_patrol_dir * speed_base * 0.5, 0.0)

## Ativa o HitBox pelo tempo de impacto do ataque.
func try_attack() -> void:
	_hitbox.activate(0.2)

# ─────────────────────────────────────────────────────────────
# DANO E MORTE
# ─────────────────────────────────────────────────────────────

func take_damage(amount: float, source: String) -> void:
	current_hp = maxf(current_hp - amount, 0.0)
	EventBus.enemy_damaged.emit(enemy_id, amount)
	# Flash de dano (clareia o placeholder por 0.1s)
	_flash_damage()
	if current_hp <= 0.0:
		_die()

func _die() -> void:
	EventBus.enemy_killed.emit(enemy_id)
	queue_free()

func _flash_damage() -> void:
	var placeholder := get_node_or_null("BodyPlaceholder")
	if placeholder == null:
		return
	var original_color: Color = placeholder.color
	placeholder.color = Color(1.0, 1.0, 1.0, 1.0)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(placeholder):
		placeholder.color = original_color

# ─────────────────────────────────────────────────────────────
# CALLBACKS
# ─────────────────────────────────────────────────────────────

func _on_light_state_changed(in_light: bool) -> void:
	is_in_light = in_light

func _on_detection_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_ref = body

func _on_detection_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_ref = null
		is_backstab_ready = false
		$BackstabDetector.reset()

func _on_backstab_ready() -> void:
	is_backstab_ready = true

func _on_hurt(amount: float, source: String) -> void:
	take_damage(amount, source)
