## scar_tree_manager.gd
## Gerencia a Árvore de Cicatrizes: compra de nós, bloqueio de caminhos opostos
## e consulta de modificadores de stats para outros sistemas.
## Prioridade de Autoload: 6ª — carrega após InventoryManager.
extends Node

# ─────────────────────────────────────────────────────────────
# CONSTANTES
# ─────────────────────────────────────────────────────────────

const DEFINITION_PATH := "res://data/scar_tree_definition.json"

# ─────────────────────────────────────────────────────────────
# ESTADO
# ─────────────────────────────────────────────────────────────

## Nós comprados: node_id → true
var _purchased:    Dictionary = {}

## Caminhos bloqueados permanentemente: path_id → true
var _locked_paths: Dictionary = {}

## Definição completa carregada do JSON
var _definition:   Dictionary = {}

## Índice rápido: node_id → dados do nó (Dictionary)
var _node_index:      Dictionary = {}

## Índice rápido: node_id → path_id pai
var _node_path_index: Dictionary = {}

# ─────────────────────────────────────────────────────────────
# INICIALIZAÇÃO
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	_load_definition()

func _load_definition() -> void:
	if not FileAccess.file_exists(DEFINITION_PATH):
		push_error("ScarTreeManager: definição não encontrada em " + DEFINITION_PATH)
		return

	var f := FileAccess.open(DEFINITION_PATH, FileAccess.READ)
	var json := JSON.new()
	var err  := json.parse(f.get_as_text())
	f.close()

	if err != OK:
		push_error("ScarTreeManager: erro ao parsear JSON — " + json.get_error_message())
		return

	_definition = json.get_data()
	_build_index()

## Constrói índices rápidos de node_id → dados e node_id → path_id.
func _build_index() -> void:
	if not _definition.has("pairs"):
		return
	for pair in _definition["pairs"]:
		for path_key in ["path_a", "path_b"]:
			var path: Dictionary = pair[path_key]
			var path_id: String  = path["id"]
			for node in path.get("nodes", []):
				var nid: String          = node["id"]
				_node_index[nid]      = node
				_node_path_index[nid] = path_id

# ─────────────────────────────────────────────────────────────
# CONSULTAS
# ─────────────────────────────────────────────────────────────

## Retorna true se o nó foi comprado.
func is_purchased(node_id: String) -> bool:
	return _purchased.get(node_id, false)

## Retorna true se o caminho está bloqueado permanentemente.
func is_path_locked(path_id: String) -> bool:
	return _locked_paths.get(path_id, false)

## Retorna true se o nó PODE ser comprado agora:
## – path não bloqueado
## – pré-requisito cumprido (ou null)
## – ainda não comprado
## – player tem Taels e Fragmentos suficientes
func can_purchase(node_id: String) -> bool:
	if is_purchased(node_id):
		return false

	var path_id: String  = _node_path_index.get(node_id, "")
	if is_path_locked(path_id):
		return false

	var node: Dictionary = _node_index.get(node_id, {})
	if node.is_empty():
		return false

	# Verifica pré-requisito sequencial
	var req: Variant = node.get("requires", null)
	if req != null and req != "" and not is_purchased(req):
		return false

	# Verifica custo
	if not InventoryManager.has_taels(node.get("cost_taels", 0)):
		return false
	if InventoryManager.scar_fragments < node.get("cost_fragments", 0):
		return false

	return true

# ─────────────────────────────────────────────────────────────
# COMPRA
# ─────────────────────────────────────────────────────────────

## Tenta comprar o nó. Retorna true se bem-sucedido.
func purchase_node(node_id: String) -> bool:
	if not can_purchase(node_id):
		return false

	var node: Dictionary = _node_index[node_id]
	var path_id: String  = _node_path_index[node_id]

	# Deduzir custo
	InventoryManager.remove_taels(node.get("cost_taels", 0))
	InventoryManager.scar_fragments -= node.get("cost_fragments", 0)

	# Registrar compra
	_purchased[node_id] = true

	# Bloquear caminho oposto (apenas ao comprar o primeiro nó do caminho)
	var opposing := _get_opposing_path(path_id)
	if opposing != "" and not is_path_locked(opposing):
		lock_path(opposing)

	EventBus.scar_node_purchased.emit(node_id, path_id)
	return true

## Bloqueia permanentemente um caminho e emite scar_path_locked.
func lock_path(path_id: String) -> void:
	_locked_paths[path_id] = true
	EventBus.scar_path_locked.emit(path_id)

# ─────────────────────────────────────────────────────────────
# MODIFICADORES DE STATS
# ─────────────────────────────────────────────────────────────

## Retorna o multiplicador acumulado de todos os nós comprados para um stat.
## Uso: ScarTreeManager.get_multiplier("max_health") → 1.2
func get_multiplier(stat: String) -> float:
	var result := 1.0
	for node_id: String in _purchased:
		var node: Dictionary = _node_index.get(node_id, {})
		for effect: Dictionary in node.get("effects", []):
			if effect["stat"] == stat and effect["modifier"] == "multiply":
				result *= float(effect["value"])
	return result

## Retorna o modificador aditivo acumulado para um stat.
## Uso: ScarTreeManager.get_additive("hp_regen") → 1.0
func get_additive(stat: String) -> float:
	var result := 0.0
	for node_id: String in _purchased:
		var node: Dictionary = _node_index.get(node_id, {})
		for effect: Dictionary in node.get("effects", []):
			if effect["stat"] == stat and effect["modifier"] == "additive":
				result += float(effect["value"])
	return result

## Retorna true se algum nó comprado tem o stat como flag booleana ativada
## (additive ≥ 1.0). Uso: ScarTreeManager.has_effect("lantern_pulse_enabled")
func has_effect(stat: String) -> bool:
	return get_additive(stat) >= 1.0

## Retorna todos os nós comprados (para SaveManager serializar).
func get_purchased() -> Array:
	return _purchased.keys()

## Retorna todos os caminhos bloqueados (para SaveManager serializar).
func get_locked_paths() -> Array:
	return _locked_paths.keys()

# ─────────────────────────────────────────────────────────────
# RESET
# ─────────────────────────────────────────────────────────────

## Reseta a árvore completamente (nova partida).
func reset() -> void:
	_purchased.clear()
	_locked_paths.clear()

# ─────────────────────────────────────────────────────────────
# HELPERS PRIVADOS
# ─────────────────────────────────────────────────────────────

func _get_opposing_path(path_id: String) -> String:
	if not _definition.has("pairs"):
		return ""
	for pair: Dictionary in _definition["pairs"]:
		var pa: String = pair["path_a"]["id"]
		var pb: String = pair["path_b"]["id"]
		if path_id == pa:
			return pb
		elif path_id == pb:
			return pa
	return ""
