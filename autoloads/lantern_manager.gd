## lantern_manager.gd
## Sistema de Lanterna: durabilidade, toggle, consumo e interações com bosses/NPCs.
## Prioridade de Autoload: 4ª — carrega após SanityManager.
extends Node

# ─────────────────────────────────────────────────────────────
# CONFIGURAÇÃO
# ─────────────────────────────────────────────────────────────

## Durabilidade máxima da lanterna.
const MAX_DURABILITY: float = 100.0

## Consumo de durabilidade por segundo enquanto a lanterna está LIGADA.
var drain_rate: float = 2.0

# ─────────────────────────────────────────────────────────────
# ESTADO
# ─────────────────────────────────────────────────────────────

var durability: float = MAX_DURABILITY

## Indica se a lanterna está ligada visualmente e funcionando.
var is_on: bool = false

## True quando a lanterna foi desligada à força (boss, guardião).
## Impede que o player a religue manualmente até que force_enable() seja chamado.
var _is_force_disabled: bool = false

# ─────────────────────────────────────────────────────────────
# INICIALIZAÇÃO
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	# Nenhum sinal externo precisa ser conectado na inicialização.
	# A lanterna é controlada pelo player e por sistemas de boss/NPC via API pública.
	pass

# ─────────────────────────────────────────────────────────────
# LOOP PRINCIPAL
# ─────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not GameManager.is_playing():
		return

	if is_on:
		_consume_durability(delta)

# ─────────────────────────────────────────────────────────────
# API PÚBLICA — CONTROLE DO PLAYER
# ─────────────────────────────────────────────────────────────

## Tenta alternar o estado da lanterna (toggle).
## Não funciona se a lanterna estiver force_disabled ou sem durabilidade.
func toggle() -> void:
	if _is_force_disabled:
		return  # Boss desligou — player não pode religar

	if not is_on and durability <= 0.0:
		return  # Sem carga — não pode ligar

	_set_state(not is_on)

## Liga a lanterna diretamente (sem verificar force_disable).
## Usado internamente e por force_enable().
func turn_on() -> void:
	if durability > 0.0:
		_set_state(true)

## Desliga a lanterna diretamente (sem verificar force_disable).
func turn_off() -> void:
	_set_state(false)

# ─────────────────────────────────────────────────────────────
# API PÚBLICA — INTERAÇÃO COM SISTEMAS EXTERNOS
# ─────────────────────────────────────────────────────────────

## Força o desligamento da lanterna por um agente externo (boss, guardião).
## source: identificador de quem forçou o desligamento ("boss", "guardian", etc.)
## O player não pode religar a lanterna até que force_enable() seja chamado.
func force_disable(source: String) -> void:
	_is_force_disabled = true
	_set_state(false)
	EventBus.lantern_force_disabled.emit(source)

## Reativa a lanterna após force_disable (usado na Fase 2 do Mimic Boss, por exemplo).
func force_enable() -> void:
	_is_force_disabled = false
	# Não liga automaticamente — o player precisa pressionar o botão.
	# Mas remove o bloqueio para que o toggle funcione.

## Repara a durabilidade da lanterna (usado pelo NPC Guardião).
## amount: quantidade de durabilidade restaurada (0–100)
func repair(amount: float) -> void:
	if amount <= 0.0:
		return

	var previous: float = durability
	durability = minf(durability + amount, MAX_DURABILITY)
	var actual_repaired: float = durability - previous

	if actual_repaired > 0.0:
		EventBus.lantern_durability_changed.emit(durability)

## Define a durabilidade diretamente (usado pelo SaveManager ao carregar).
func set_durability(value: float) -> void:
	durability = clampf(value, 0.0, MAX_DURABILITY)
	EventBus.lantern_durability_changed.emit(durability)

	# Se durabilidade chegou a 0 e lanterna estava ligada, desligar
	if durability <= 0.0 and is_on:
		_set_state(false)
		EventBus.lantern_broken.emit()

# ─────────────────────────────────────────────────────────────
# LÓGICA INTERNA
# ─────────────────────────────────────────────────────────────

## Aplica o consumo de durabilidade por frame (delta = tempo em segundos).
func _consume_durability(delta: float) -> void:
	if durability <= 0.0:
		return

	durability = maxf(durability - drain_rate * delta, 0.0)
	EventBus.lantern_durability_changed.emit(durability)

	# Verificar se a lanterna quebrou neste frame
	if durability <= 0.0:
		_set_state(false)
		EventBus.lantern_broken.emit()

## Muda o estado is_on e emite o sinal correspondente.
## Centraliza toda a lógica de estado para garantir consistência.
func _set_state(new_state: bool) -> void:
	if is_on == new_state:
		return  # Sem mudança — não emitir sinal desnecessariamente

	is_on = new_state
	EventBus.lantern_toggled.emit(is_on)
