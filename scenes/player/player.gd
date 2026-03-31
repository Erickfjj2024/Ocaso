## player.gd
## Controlador principal do Player: movimento 8-dir, facing direction, morte.
## Attach em: Player (CharacterBody2D)
## Cena: scenes/player/player.tscn
extends CharacterBody2D

# ─────────────────────────────────────────────────────────────
# CONFIGURAÇÃO
# ─────────────────────────────────────────────────────────────

## Velocidade de movimento em pixels/segundo.
@export var move_speed: float = 80.0

## Se true, o input de movimento está invertido (efeito de gaslighting).
var input_inverted: bool = false

# ─────────────────────────────────────────────────────────────
# ESTADO
# ─────────────────────────────────────────────────────────────

## Direção que o player está olhando, normalizada.
## Exposto para FacingDetector e BackstabDetector dos inimigos.
var facing_direction: Vector2 = Vector2.DOWN

## Última direção de movimento (usada quando parado para manter o facing).
var _last_move_direction: Vector2 = Vector2.DOWN

# ─────────────────────────────────────────────────────────────
# NÓS FILHOS (preenchidos no _ready)
# ─────────────────────────────────────────────────────────────

@onready var _sprite: Sprite2D             = $Sprite2D
@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var _camera: Camera2D             = $Camera2D

# ─────────────────────────────────────────────────────────────
# INICIALIZAÇÃO
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	# Escutar gaslighting para inverter controles
	EventBus.sanity_threshold_crossed.connect(_on_sanity_threshold_crossed)
	EventBus.force_gaslighting.connect(_on_force_gaslighting)

	# Garantir que o GameManager sabe que o jogo está rodando ao entrar na cena
	if GameManager.current_state == GameManager.GameState.MENU:
		GameManager.set_state(GameManager.GameState.PLAYING)

# ─────────────────────────────────────────────────────────────
# LOOP PRINCIPAL
# ─────────────────────────────────────────────────────────────

func _physics_process(_delta: float) -> void:
	if not GameManager.is_playing():
		velocity = Vector2.ZERO
		return

	_handle_movement()
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if not GameManager.is_playing():
		return

	# Delegar toggle de lanterna para o nó filho PlayerLantern
	if event.is_action_pressed("lantern_toggle"):
		_toggle_lantern()

# ─────────────────────────────────────────────────────────────
# MOVIMENTO
# ─────────────────────────────────────────────────────────────

func _handle_movement() -> void:
	# Lê o vetor de input normalizado (0.0–1.0 em cada eixo)
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# Gaslighting: inverte a direção do input
	if input_inverted:
		input_dir *= -1.0

	if input_dir != Vector2.ZERO:
		_last_move_direction = input_dir
		facing_direction = input_dir.normalized()
		velocity = input_dir * move_speed
		_play_walk_animation(input_dir)
	else:
		velocity = Vector2.ZERO
		_play_idle_animation()

# ─────────────────────────────────────────────────────────────
# ANIMAÇÕES (placeholder — substituir quando sprites existirem)
# ─────────────────────────────────────────────────────────────

func _play_walk_animation(dir: Vector2) -> void:
	if not is_instance_valid(_animation_player):
		return
	# Determina a animação pelo quadrante predominante da direção
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			_try_play("walk_right")
		else:
			_try_play("walk_left")
	else:
		if dir.y > 0:
			_try_play("walk_down")
		else:
			_try_play("walk_up")

func _play_idle_animation() -> void:
	if not is_instance_valid(_animation_player):
		return
	if abs(_last_move_direction.x) > abs(_last_move_direction.y):
		if _last_move_direction.x > 0:
			_try_play("idle_right")
		else:
			_try_play("idle_left")
	else:
		if _last_move_direction.y > 0:
			_try_play("idle_down")
		else:
			_try_play("idle_up")

## Toca animação somente se ela existir no AnimationPlayer (evita erros com placeholder).
func _try_play(anim_name: String) -> void:
	if _animation_player.has_animation(anim_name):
		if _animation_player.current_animation != anim_name:
			_animation_player.play(anim_name)

# ─────────────────────────────────────────────────────────────
# LANTERNA
# ─────────────────────────────────────────────────────────────

func _toggle_lantern() -> void:
	# Delegar ao LanternManager — ele emite o sinal lantern_toggled
	LanternManager.toggle()

# ─────────────────────────────────────────────────────────────
# CÂMERA — SHAKE
# ─────────────────────────────────────────────────────────────

## Aplica um shake à câmera (chamado externamente por dano, bosses, etc.).
## intensity: força do shake em pixels, duration: duração em segundos
func camera_shake(intensity: float = 4.0, duration: float = 0.3) -> void:
	if not is_instance_valid(_camera):
		return
	var original_offset := _camera.offset
	var elapsed := 0.0
	while elapsed < duration:
		var wait_time: float = 0.05
		_camera.offset = original_offset + Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		await get_tree().create_timer(wait_time).timeout
		elapsed += wait_time
	_camera.offset = original_offset

# ─────────────────────────────────────────────────────────────
# MORTE
# ─────────────────────────────────────────────────────────────

## Chamado pelo sistema de dano (HurtBox) quando o HP chega a zero.
func die() -> void:
	# Desativa processamento para evitar input durante sequência de morte
	set_physics_process(false)
	set_process_unhandled_input(false)
	velocity = Vector2.ZERO
	EventBus.player_died.emit()

# ─────────────────────────────────────────────────────────────
# CALLBACKS DE SINAIS
# ─────────────────────────────────────────────────────────────

func _on_sanity_threshold_crossed(threshold: String) -> void:
	match threshold:
		"critical_15":
			# Gaslighting: inverte os controles por 2–4 segundos
			_start_control_inversion(randf_range(2.0, 4.0))
		"zero":
			# SanityManager já emitiu o sinal — GameManager trata o Game Over
			pass

func _on_force_gaslighting(duration: float) -> void:
	_start_control_inversion(duration)

## Inverte os controles por `duration` segundos, depois restaura.
func _start_control_inversion(duration: float) -> void:
	input_inverted = true
	await get_tree().create_timer(duration).timeout
	input_inverted = false
