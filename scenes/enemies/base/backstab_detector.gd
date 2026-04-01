## backstab_detector.gd
## Detecta quando o player está de costas para o Stalker por 2 segundos.
## Dot product: dot(stalker_pos - player_pos, player_facing) < threshold
## → Stalker está atrás do player → ataque ignora luz da lanterna.
## Attach em: BackstabDetector (Node), filho do StalkerBase.
extends Node

# ─────────────────────────────────────────────────────────────
# SINAIS
# ─────────────────────────────────────────────────────────────

## Emitido quando o backstab está pronto (player de costas por tempo suficiente).
signal backstab_ready()

# ─────────────────────────────────────────────────────────────
# CONFIGURAÇÃO
# ─────────────────────────────────────────────────────────────

## Tempo contínuo que o player precisa ficar de costas para ativar.
@export var required_duration: float = 2.0

## Limiar do dot product abaixo do qual o stalker está "atrás" do player.
## -0.3 dá uma margem de ~107° de ângulo morto nas costas.
@export var backstab_threshold: float = -0.3

# ─────────────────────────────────────────────────────────────
# ESTADO
# ─────────────────────────────────────────────────────────────

var _timer: float     = 0.0
var _triggered: bool  = false

# ─────────────────────────────────────────────────────────────
# LOOP
# ─────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if not GameManager.is_playing():
		return

	var stalker: Node2D    = get_parent()
	var player_ref: Node2D = stalker.get(&"player_ref") as Node2D

	if player_ref == null:
		_reset()
		return

	# Vetor do player ao stalker (normalizado)
	var dir_to_stalker: Vector2 = (stalker.global_position - player_ref.global_position).normalized()

	# Direção que o player está olhando
	var player_facing: Vector2 = player_ref.get(&"facing_direction")

	# dot < threshold → stalker está atrás do player
	var dot: float = dir_to_stalker.dot(player_facing)

	if dot < backstab_threshold:
		_timer += delta
		if _timer >= required_duration and not _triggered:
			_triggered = true
			backstab_ready.emit()
	else:
		_reset()

# ─────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────

func _reset() -> void:
	_timer     = 0.0
	_triggered = false

## Reseta manualmente (chamado pelo StalkerBase quando perde o player).
func reset() -> void:
	_reset()
