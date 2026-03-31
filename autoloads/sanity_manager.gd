## sanity_manager.gd
## Sistema de Sanidade: controla o valor de 0–100, dreno passivo, limiares e efeitos.
## Prioridade de Autoload: 3ª — carrega após GameManager.
extends Node

# ─────────────────────────────────────────────────────────────
# CONFIGURAÇÃO (ajustável no Inspector ao registrar como Autoload Resource
# ou via constantes por ora)
# ─────────────────────────────────────────────────────────────

## Sanidade máxima do player.
const MAX_SANITY: float = 100.0

## Dreno passivo por segundo quando a lanterna está DESLIGADA.
## Valor configurável — pode ser modificado por nós da Árvore de Cicatrizes.
var passive_drain_rate: float = 5.0

## Limiares de sanidade que disparam eventos.
## "low_30" → efeitos visuais leves
## "critical_15" → gaslighting ativado
## "zero" → Game Over
const THRESHOLD_LOW: float      = 30.0
const THRESHOLD_CRITICAL: float = 15.0
const THRESHOLD_ZERO: float     = 0.0

# ─────────────────────────────────────────────────────────────
# ESTADO
# ─────────────────────────────────────────────────────────────

var current_sanity: float = MAX_SANITY

## True quando a lanterna está ligada (pausa o dreno passivo).
var _is_lantern_on: bool = false

## Controle de limiares já cruzados (evita emitir o mesmo sinal várias vezes).
var _threshold_crossed: Dictionary = {
	"low_30":    false,
	"critical_15": false,
	"zero":      false,
}

# ─────────────────────────────────────────────────────────────
# INICIALIZAÇÃO
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	# Escutar toggle da lanterna para pausar/retomar dreno
	EventBus.lantern_toggled.connect(_on_lantern_toggled)
	# Escutar dano do player (fantasmas causam dano direto de sanidade)
	EventBus.player_damaged.connect(_on_player_damaged)

# ─────────────────────────────────────────────────────────────
# LOOP PRINCIPAL
# ─────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	# Só drena se o jogo estiver em estado PLAYING
	if not GameManager.is_playing():
		return

	# Dreno passivo ocorre apenas no escuro (lanterna OFF)
	if not _is_lantern_on:
		_apply_drain(passive_drain_rate * delta)

# ─────────────────────────────────────────────────────────────
# API PÚBLICA
# ─────────────────────────────────────────────────────────────

## Aplica dano direto de sanidade (usado por fantasmas, bosses, etc.).
## Não é bloqueado pelo estado da lanterna.
func apply_sanity_damage(amount: float) -> void:
	_apply_drain(amount)

## Restaura sanidade pelo valor especificado.
## Não ultrapassa MAX_SANITY.
func restore_sanity(amount: float) -> void:
	if amount <= 0.0:
		return

	var previous: float = current_sanity
	current_sanity = minf(current_sanity + amount, MAX_SANITY)
	var actual_restored: float = current_sanity - previous

	if actual_restored > 0.0:
		EventBus.sanity_restored.emit(actual_restored)
		EventBus.sanity_changed.emit(current_sanity, actual_restored)
		# Reverter limiares já cruzados se a sanidade subiu acima deles
		_check_threshold_resets()

## Define diretamente o valor de sanidade (usado pelo SaveManager e pelo reset de cena).
func set_sanity(value: float) -> void:
	current_sanity = clampf(value, 0.0, MAX_SANITY)
	_reset_thresholds_from_current_value()
	EventBus.sanity_changed.emit(current_sanity, 0.0)

## Modifica o dreno passivo (usado por nós da Árvore de Cicatrizes).
## multiplier: 1.0 = normal, 1.3 = 30% mais rápido, etc.
func set_drain_multiplier(multiplier: float) -> void:
	passive_drain_rate = 5.0 * multiplier

# ─────────────────────────────────────────────────────────────
# LÓGICA INTERNA
# ─────────────────────────────────────────────────────────────

## Aplica dreno à sanidade e dispara sinais apropriados.
func _apply_drain(amount: float) -> void:
	if amount <= 0.0 or current_sanity <= 0.0:
		return

	var previous: float = current_sanity
	current_sanity = maxf(current_sanity - amount, 0.0)
	var actual_delta: float = current_sanity - previous  # será negativo

	EventBus.sanity_changed.emit(current_sanity, actual_delta)
	_check_thresholds()

## Verifica se algum limiar foi cruzado e emite o sinal correspondente.
func _check_thresholds() -> void:
	# Limiar "zero"
	if current_sanity <= THRESHOLD_ZERO and not _threshold_crossed["zero"]:
		_threshold_crossed["zero"] = true
		EventBus.sanity_threshold_crossed.emit("zero")
		return  # Game Over detectado — não precisa verificar outros

	# Limiar "critical_15"
	if current_sanity <= THRESHOLD_CRITICAL and not _threshold_crossed["critical_15"]:
		_threshold_crossed["critical_15"] = true
		EventBus.sanity_threshold_crossed.emit("critical_15")

	# Limiar "low_30"
	if current_sanity <= THRESHOLD_LOW and not _threshold_crossed["low_30"]:
		_threshold_crossed["low_30"] = true
		EventBus.sanity_threshold_crossed.emit("low_30")

## Reseta limiares quando a sanidade é restaurada acima deles.
func _check_threshold_resets() -> void:
	if current_sanity > THRESHOLD_LOW:
		_threshold_crossed["low_30"]      = false
		_threshold_crossed["critical_15"] = false
		_threshold_crossed["zero"]        = false
	elif current_sanity > THRESHOLD_CRITICAL:
		_threshold_crossed["critical_15"] = false
		_threshold_crossed["zero"]        = false
	elif current_sanity > THRESHOLD_ZERO:
		_threshold_crossed["zero"]        = false

## Recalcula limiares com base no valor atual (chamado pelo set_sanity).
func _reset_thresholds_from_current_value() -> void:
	_threshold_crossed["low_30"]      = current_sanity <= THRESHOLD_LOW
	_threshold_crossed["critical_15"] = current_sanity <= THRESHOLD_CRITICAL
	_threshold_crossed["zero"]        = current_sanity <= THRESHOLD_ZERO

# ─────────────────────────────────────────────────────────────
# CALLBACKS DE SINAIS
# ─────────────────────────────────────────────────────────────

func _on_lantern_toggled(is_on: bool) -> void:
	_is_lantern_on = is_on

func _on_player_damaged(amount: float, source: String) -> void:
	# Dano de fantasmas (source == "guilt_ghost") vai direto para sanidade.
	# Outros tipos de dano físico NÃO drenam sanidade por aqui.
	if source == "guilt_ghost":
		apply_sanity_damage(amount)
