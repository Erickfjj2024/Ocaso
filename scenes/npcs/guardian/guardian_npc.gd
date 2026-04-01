## guardian_npc.gd
## NPC Guardião Eloah — curandeiro da base.
## Interagir (E) mostra diálogo ou, se as condições forem cumpridas (GDD 5.4),
## dispara a transformação em Guardian Mimic (5 beats).
extends Node2D

# ─────────────────────────────────────────────────────────────
# CENA DO MIMIC (carregada só quando necessário)
# ─────────────────────────────────────────────────────────────

const MIMIC_SCENE_PATH := "res://scenes/npcs/guardian/guardian_mimic.tscn"

# ─────────────────────────────────────────────────────────────
# DIÁLOGOS — escalam com `base_visits`
# ─────────────────────────────────────────────────────────────

const DIALOGUES: Array[String] = [
	"...",
	"Você voltou.",
	"A escuridão te segue por onde você vai.",
	"Cuidado com o que cresce dentro de você.",
	"Eu estou sempre aqui. Sempre.",
]

# ─────────────────────────────────────────────────────────────
# NÓS FILHOS
# ─────────────────────────────────────────────────────────────

@onready var _interaction_zone: Area2D = $InteractionZone

# ─────────────────────────────────────────────────────────────
# ESTADO
# ─────────────────────────────────────────────────────────────

var _player_nearby:   bool = false
var _transforming:    bool = false   # lock durante a sequência de 5 beats

# ─────────────────────────────────────────────────────────────
# INICIALIZAÇÃO
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	_interaction_zone.body_entered.connect(_on_body_entered)
	_interaction_zone.body_exited.connect(_on_body_exited)
	WorldFlags.increment("base_visits")

# ─────────────────────────────────────────────────────────────
# INPUT
# ─────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if _player_nearby and not _transforming and event.is_action_pressed("interact"):
		_speak()

# ─────────────────────────────────────────────────────────────
# FALA / TRANSFORMAÇÃO
# ─────────────────────────────────────────────────────────────

func _speak() -> void:
	if _should_transform():
		_transforming = true
		_run_transformation()
	else:
		var visits: int = int(WorldFlags.get_flag("base_visits", 1))
		var idx := clampi(visits - 1, 0, DIALOGUES.size() - 1)
		EventBus.npc_dialogue_requested.emit(DIALOGUES[idx])

## Condições do GDD 5.4: Sanidade < 25, 10% de chance, 3+ visitas, primeira vez.
func _should_transform() -> bool:
	return (
		SanityManager.current_sanity < 25.0
		and randf() < 0.10
		and not WorldFlags.has_flag("guardian_mimic_triggered")
		and int(WorldFlags.get_flag("base_visits", 0)) >= 3
	)

# ─────────────────────────────────────────────────────────────
# SEQUÊNCIA DE TRANSFORMAÇÃO — 5 BEATS (GDD 5.4)
# ─────────────────────────────────────────────────────────────

func _run_transformation() -> void:
	WorldFlags.set_flag("guardian_mimic_triggered", true)

	# ── BEAT 1 (2s) — A ISCA ──────────────────────────────────
	# Cura real começa: a lanterna REALMENTE está sendo reparada.
	EventBus.npc_dialogue_requested.emit("Deixa-me olhar sua chama...")
	var repair_amount := 20.0
	LanternManager.repair(repair_amount)
	await _wait(2.0)
	if not is_inside_tree():
		return

	# ── BEAT 2 (1.5s) — O SINAL ──────────────────────────────
	# Input bloqueado. Texto glitchado.
	GameManager.set_state(GameManager.GameState.CUTSCENE)
	EventBus.npc_dialogue_requested.emit("E̶l̵o̷a̴h̸ ̷n̵ã̶o̴ ̸e̶x̵i̷s̴t̶e̷...")
	await _wait(1.5)
	if not is_inside_tree():
		return

	# ── BEAT 3 (1s) — O APAGÃO ───────────────────────────────
	# Lanterna apaga. Tela vai para preto. Cura da lanterna é revertida.
	LanternManager.force_disable("guardian")
	LanternManager.set_durability(LanternManager.durability - repair_amount)  # revert Beat 1
	EventBus.base_lockdown.emit(true)

	# Escurece a tela via SanityVFX (se disponível)
	var vfx := _get_sanity_vfx()
	if vfx:
		vfx.set_black(true)

	await _wait(1.0)
	if not is_inside_tree():
		return

	# ── BEAT 4 (2s) — A TRANSFORMAÇÃO ────────────────────────
	# Dano de Sanidade. Destrói o NPC. Instancia o Mimic no mesmo lugar.
	SanityManager.apply_sanity_damage(15.0)

	if ResourceLoader.exists(MIMIC_SCENE_PATH):
		var mimic: Node2D = load(MIMIC_SCENE_PATH).instantiate()
		mimic.global_position = global_position
		get_parent().add_child(mimic)

	await _wait(0.5)
	if not is_inside_tree():
		return

	# Revela o Mimic com flash
	if vfx:
		vfx.set_black(false)

	await _wait(1.5)
	if not is_inside_tree():
		return

	# ── BEAT 5 — O COMBATE ────────────────────────────────────
	# Libera input. O Mimic inicia Phase 1 autonomamente.
	GameManager.set_state(GameManager.GameState.PLAYING)

	queue_free()

# ─────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func _get_sanity_vfx() -> Node:
	var nodes := get_tree().get_nodes_in_group("sanity_vfx")
	return nodes[0] if not nodes.is_empty() else null

# ─────────────────────────────────────────────────────────────
# CALLBACKS
# ─────────────────────────────────────────────────────────────

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_nearby = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
