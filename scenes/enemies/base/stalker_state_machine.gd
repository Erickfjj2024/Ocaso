## stalker_state_machine.gd
## FSM do Stalker: IDLE → PATROL → CHASE → ATTACK → STUNNED.
## Attach em: StateMachine (Node), filho do StalkerBase.
extends Node

# ─────────────────────────────────────────────────────────────
# ESTADOS
# ─────────────────────────────────────────────────────────────

enum State { IDLE, PATROL, CHASE, ATTACK, STUNNED }
var current_state: State = State.IDLE

# ─────────────────────────────────────────────────────────────
# CONFIGURAÇÃO
# ─────────────────────────────────────────────────────────────

## Tempo de espera no estado IDLE antes de iniciar patrulha.
const IDLE_DURATION:    float = 2.0
## Cooldown entre ataques consecutivos.
const ATTACK_COOLDOWN:  float = 1.2

# ─────────────────────────────────────────────────────────────
# ESTADO INTERNO
# ─────────────────────────────────────────────────────────────

var _stalker: CharacterBody2D   # referência ao pai (StalkerBase)
var _state_timer:   float = 0.0
var _attack_cd:     float = 0.0
var _is_attacking:  bool  = false

# ─────────────────────────────────────────────────────────────
# INICIALIZAÇÃO
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	_stalker = get_parent()

# ─────────────────────────────────────────────────────────────
# LOOP
# ─────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if not GameManager.is_playing():
		return

	_state_timer += delta
	_attack_cd = maxf(_attack_cd - delta, 0.0)

	match current_state:
		State.IDLE:    _update_idle()
		State.PATROL:  _update_patrol()
		State.CHASE:   _update_chase()
		State.ATTACK:  _update_attack()
		State.STUNNED: _update_stunned()

# ─────────────────────────────────────────────────────────────
# TRANSIÇÃO
# ─────────────────────────────────────────────────────────────

func transition_to(new_state: State) -> void:
	if current_state == new_state:
		return

	# Efeitos de saída do estado atual
	match current_state:
		State.ATTACK:
			_is_attacking = false

	current_state  = new_state
	_state_timer   = 0.0

	# Efeitos de entrada no novo estado
	match new_state:
		State.STUNNED:
			_stalker.velocity = Vector2.ZERO
		State.IDLE:
			_stalker.velocity = Vector2.ZERO

# ─────────────────────────────────────────────────────────────
# ATUALIZAÇÕES POR ESTADO
# ─────────────────────────────────────────────────────────────

func _update_idle() -> void:
	_stalker.velocity = Vector2.ZERO
	if _stalker.player_ref != null:
		transition_to(State.CHASE)
	elif _state_timer >= IDLE_DURATION:
		transition_to(State.PATROL)

func _update_patrol() -> void:
	_stalker.move_patrol()
	if _stalker.player_ref != null:
		transition_to(State.CHASE)

func _update_chase() -> void:
	if _stalker.player_ref == null:
		transition_to(State.PATROL)
		return

	# Luz da lanterna ativa → STUNNED (salvo em backstab)
	if _stalker.is_in_light and not _stalker.is_backstab_ready:
		transition_to(State.STUNNED)
		return

	# Perto o suficiente para atacar
	var dist: float = _stalker.global_position.distance_to(
		_stalker.player_ref.global_position
	)
	if dist <= _stalker.attack_range and _attack_cd <= 0.0 and not _is_attacking:
		transition_to(State.ATTACK)
		return

	_stalker.move_toward_player()

func _update_attack() -> void:
	if _is_attacking:
		return
	_is_attacking = true
	_stalker.try_attack()
	# Retorna ao CHASE após a duração do ataque
	get_tree().create_timer(0.45).timeout.connect(
		func() -> void:
			_is_attacking   = false
			_attack_cd      = ATTACK_COOLDOWN
			transition_to(State.CHASE),
		CONNECT_ONE_SHOT
	)

func _update_stunned() -> void:
	_stalker.velocity = Vector2.ZERO
	# Sai do atordoamento quando sair da luz
	if not _stalker.is_in_light:
		transition_to(State.CHASE)
