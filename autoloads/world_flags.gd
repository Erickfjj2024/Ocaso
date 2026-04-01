## world_flags.gd
## Armazena flags narrativas persistentes do mundo.
## Ex: inimigos eliminados, NPCs encontrados, escolhas morais, lordes derrotados.
## Prioridade de Autoload: 7ª.
extends Node

# ─────────────────────────────────────────────────────────────
# ESTADO
# ─────────────────────────────────────────────────────────────

var _flags: Dictionary = {}

# ─────────────────────────────────────────────────────────────
# API
# ─────────────────────────────────────────────────────────────

## Define uma flag com qualquer valor. Emite flag_changed.
func set_flag(flag_name: String, value: Variant) -> void:
	_flags[flag_name] = value
	EventBus.flag_changed.emit(flag_name, value)

## Retorna o valor de uma flag, ou `default` se não existir.
func get_flag(flag_name: String, default: Variant = null) -> Variant:
	return _flags.get(flag_name, default)

## Retorna true se a flag existir (independente do valor).
func has_flag(flag_name: String) -> bool:
	return _flags.has(flag_name)

## Incrementa um contador inteiro. Cria com valor 1 se não existir.
func increment(flag_name: String) -> void:
	_flags[flag_name] = int(_flags.get(flag_name, 0)) + 1
	EventBus.flag_changed.emit(flag_name, _flags[flag_name])

## Retorna cópia de todas as flags (para SaveManager serializar).
func get_all() -> Dictionary:
	return _flags.duplicate()

## Restaura flags a partir de um dicionário (usado pelo SaveManager).
func load_from(data: Dictionary) -> void:
	_flags = data.duplicate()

## Reseta todas as flags (nova partida).
func reset() -> void:
	_flags.clear()
