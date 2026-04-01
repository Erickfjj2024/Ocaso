## inventory_manager.gd
## Gerencia o inventário do player: itens e moeda (Taels).
## Prioridade de Autoload: 5ª — carrega após LanternManager.
extends Node

# ─────────────────────────────────────────────────────────────
# CONFIGURAÇÃO
# ─────────────────────────────────────────────────────────────

## Número máximo de slots no inventário.
const MAX_SLOTS: int = 20

## Percentual de Taels perdidos na morte (GDD 3.3: 50%).
const DEATH_TAEL_LOSS_PCT: float = 0.5

## Máximo de itens perdidos na morte (GDD 3.3: 1–3).
const DEATH_ITEM_LOSS_MAX: int = 3

## Taels base dropados por Stalker ao morrer.
const STALKER_TAEL_DROP_MIN: int = 5
const STALKER_TAEL_DROP_MAX: int = 15

# ─────────────────────────────────────────────────────────────
# ESTADO
# ─────────────────────────────────────────────────────────────

var taels: int           = 0
var scar_fragments: int  = 0   # drop raro de Stalkers e Lordes
var _items: Array[Resource] = []

# ─────────────────────────────────────────────────────────────
# INICIALIZAÇÃO
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)

# ─────────────────────────────────────────────────────────────
# API — TAELS
# ─────────────────────────────────────────────────────────────

## Adiciona Taels e emite taels_changed.
func add_taels(amount: int) -> void:
	taels += amount
	EventBus.taels_changed.emit(taels)

## Remove Taels (mínimo 0) e emite taels_changed.
func remove_taels(amount: int) -> void:
	taels = maxi(taels - amount, 0)
	EventBus.taels_changed.emit(taels)

## Retorna true se o player tem pelo menos `amount` Taels.
func has_taels(amount: int) -> bool:
	return taels >= amount

# ─────────────────────────────────────────────────────────────
# API — ITENS
# ─────────────────────────────────────────────────────────────

## Adiciona um item ao inventário. Retorna false se não houver espaço.
func add_item(item: Resource) -> bool:
	if _items.size() >= MAX_SLOTS:
		return false
	_items.append(item)
	EventBus.item_added.emit(item)
	return true

## Remove um item do inventário. Retorna false se o item não existir.
func remove_item(item: Resource) -> bool:
	var idx := _items.find(item)
	if idx == -1:
		return false
	_items.remove_at(idx)
	EventBus.item_removed.emit(item)
	return true

## Retorna cópia do array de itens (não modifique o original diretamente).
func get_items() -> Array[Resource]:
	return _items.duplicate()

## Quantidade de itens no inventário.
func get_item_count() -> int:
	return _items.size()

# ─────────────────────────────────────────────────────────────
# PENALIDADE DE MORTE (GDD 3.3)
# ─────────────────────────────────────────────────────────────

## Aplica a penalidade de morte:
## -50% dos Taels atuais + perde 1–3 itens aleatórios.
## Chamado por GameManager.trigger_game_over().
func apply_death_penalty() -> void:
	# ── Perda de Taels ───────────────────────────────────────
	var lost_taels := int(taels * DEATH_TAEL_LOSS_PCT)
	if lost_taels > 0:
		remove_taels(lost_taels)

	# ── Perda de itens aleatórios ───────────────────────────
	var items_to_lose := mini(randi_range(1, DEATH_ITEM_LOSS_MAX), _items.size())
	for i in range(items_to_lose):
		if _items.is_empty():
			break
		var idx := randi() % _items.size()
		remove_item(_items[idx])

# ─────────────────────────────────────────────────────────────
# RESET
# ─────────────────────────────────────────────────────────────

## Adiciona Fragmentos de Cicatriz (drop raro de inimigos e lordes).
func add_fragments(amount: int) -> void:
	scar_fragments += amount

## Zera inventário e Taels completamente (nova partida / SaveManager).
func reset() -> void:
	taels           = 0
	scar_fragments  = 0
	_items.clear()
	EventBus.taels_changed.emit(taels)

# ─────────────────────────────────────────────────────────────
# CALLBACKS
# ─────────────────────────────────────────────────────────────

func _on_enemy_killed(_enemy_id: String) -> void:
	add_taels(randi_range(STALKER_TAEL_DROP_MIN, STALKER_TAEL_DROP_MAX))
	# 15% de chance de dropar 1 Fragmento de Cicatriz
	if randf() < 0.15:
		add_fragments(1)
