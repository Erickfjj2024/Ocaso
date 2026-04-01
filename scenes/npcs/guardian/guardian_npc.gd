## guardian_npc.gd
## NPC Guardião — placeholder interativo para FASE 3/4.
## Interagir (E) mostra diálogo contextual via EventBus.
## O WorldFlags rastreia "base_visits" para escalar os diálogos.
## Na FASE 4, este nó será a semente do Mimic Boss.
extends Node2D

# ─────────────────────────────────────────────────────────────
# NÓS FILHOS
# ─────────────────────────────────────────────────────────────

@onready var _interaction_zone: Area2D = $InteractionZone

# ─────────────────────────────────────────────────────────────
# DIÁLOGOS (indexados por número de visitas — clamped)
# ─────────────────────────────────────────────────────────────

const DIALOGUES: Array[String] = [
	"...",
	"Você voltou.",
	"A escuridão te segue por onde você vai.",
	"Cuidado com o que cresce dentro de você.",
	"Eu estou sempre aqui. Sempre.",
]

# ─────────────────────────────────────────────────────────────
# ESTADO
# ─────────────────────────────────────────────────────────────

var _player_nearby: bool = false

# ─────────────────────────────────────────────────────────────
# INICIALIZAÇÃO
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	_interaction_zone.body_entered.connect(_on_body_entered)
	_interaction_zone.body_exited.connect(_on_body_exited)
	# Incrementa visitas à base a cada vez que o Guardião é instanciado
	WorldFlags.increment("base_visits")

# ─────────────────────────────────────────────────────────────
# INPUT
# ─────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if _player_nearby and event.is_action_pressed("interact"):
		_speak()

# ─────────────────────────────────────────────────────────────
# DIÁLOGO
# ─────────────────────────────────────────────────────────────

func _speak() -> void:
	var visits: int = int(WorldFlags.get_flag("base_visits", 1))
	var idx    := clampi(visits - 1, 0, DIALOGUES.size() - 1)
	EventBus.npc_dialogue_requested.emit(DIALOGUES[idx])

# ─────────────────────────────────────────────────────────────
# CALLBACKS
# ─────────────────────────────────────────────────────────────

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_nearby = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
