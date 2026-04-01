## lost_npc.gd
## NPC Perdido: encontrável no mundo, pode ser salvo ou sacrificado.
## Salvar → NPC desaparece (sem recompensa).
## Sacrificar (pressionar Z/atacar) → Lanterna totalmente reparada + WorldFlags.has_murdered=true.
## Decisão permanente: ativa o Eco da Culpa.
extends Node2D

# ─────────────────────────────────────────────────────────────
# DIÁLOGOS
# ─────────────────────────────────────────────────────────────

@export var npc_id: String = "lost_npc_01"

const DIALOGUE_PLEA:   String = "Por favor... não me deixe aqui."
const DIALOGUE_CHOICE: String = "[E] Salvar   [Z] Sacrificar"
const DIALOGUE_SAVED:  String = "Obrigado... que a luz te proteja."
const DIALOGUE_SACR:   String = "N-não... por que?"

# ─────────────────────────────────────────────────────────────
# NÓS FILHOS
# ─────────────────────────────────────────────────────────────

@onready var _interaction_zone: Area2D = $InteractionZone

# ─────────────────────────────────────────────────────────────
# ESTADO
# ─────────────────────────────────────────────────────────────

enum State { IDLE, CHOICE, DONE }
var _state: State = State.IDLE
var _player_nearby: bool  = false
var _choice_timer:  float = 0.0
const CHOICE_DURATION: float = 4.0   # janela de tempo para decidir

# ─────────────────────────────────────────────────────────────
# INICIALIZAÇÃO
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	_interaction_zone.body_entered.connect(_on_body_entered)
	_interaction_zone.body_exited.connect(_on_body_exited)

# ─────────────────────────────────────────────────────────────
# LOOP
# ─────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _state != State.CHOICE:
		return
	_choice_timer -= delta
	if _choice_timer <= 0.0:
		_state = State.IDLE   # janela expirou sem escolha

# ─────────────────────────────────────────────────────────────
# INPUT
# ─────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not _player_nearby or _state == State.DONE:
		return

	if event.is_action_pressed("interact"):
		match _state:
			State.IDLE:
				# Primeira interação: mostrar súplica + opções
				EventBus.npc_dialogue_requested.emit(DIALOGUE_PLEA)
				await get_tree().create_timer(1.2).timeout
				if not is_inside_tree() or _state == State.DONE:
					return
				EventBus.npc_dialogue_requested.emit(DIALOGUE_CHOICE)
				_state         = State.CHOICE
				_choice_timer  = CHOICE_DURATION
			State.CHOICE:
				# Segunda pressão de E → Salvar
				_save()

	elif event.is_action_pressed("attack") and _state == State.CHOICE:
		# Pressionar Z durante a janela de escolha → Sacrificar
		_sacrifice()

# ─────────────────────────────────────────────────────────────
# AÇÕES
# ─────────────────────────────────────────────────────────────

func _save() -> void:
	_state = State.DONE
	EventBus.npc_dialogue_requested.emit(DIALOGUE_SAVED)
	await get_tree().create_timer(2.0).timeout
	if is_inside_tree():
		queue_free()

func _sacrifice() -> void:
	_state = State.DONE
	EventBus.npc_dialogue_requested.emit(DIALOGUE_SACR)

	# Recompensa: repara a Lanterna completamente
	LanternManager.repair(LanternManager.MAX_DURABILITY)

	# Consequência permanente: ativa os fantasmas da Culpa
	WorldFlags.set_flag("has_murdered", true)
	EventBus.npc_sacrificed.emit(npc_id)

	await get_tree().create_timer(1.0).timeout
	if is_inside_tree():
		queue_free()

# ─────────────────────────────────────────────────────────────
# CALLBACKS
# ─────────────────────────────────────────────────────────────

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_nearby = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		if _state == State.CHOICE:
			_state = State.IDLE
