## save_manager.gd
## Salva e carrega o estado completo do jogo em formato JSON.
## Prioridade de Autoload: 9ª — carrega por último, após todos os outros managers.
extends Node

# ─────────────────────────────────────────────────────────────
# CONSTANTES
# ─────────────────────────────────────────────────────────────

const SAVE_PATH    := "user://ocaso_save.json"
const SAVE_VERSION := 1

# ─────────────────────────────────────────────────────────────
# INICIALIZAÇÃO
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	EventBus.save_requested.connect(save_game)
	EventBus.load_requested.connect(load_game)

# ─────────────────────────────────────────────────────────────
# API PÚBLICA
# ─────────────────────────────────────────────────────────────

## Retorna true se existe um arquivo de save válido.
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

## Apaga o arquivo de save (nova partida).
func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)

## Serializa o estado de todos os managers e grava em JSON.
func save_game() -> void:
	var data := {
		"version": SAVE_VERSION,
		"scene":   GameManager._current_scene_path,
		"sanity": {
			"current": SanityManager.current_sanity
		},
		"lantern": {
			"is_on":      LanternManager.is_on,
			"durability": LanternManager.durability
		},
		"inventory": {
			"taels":          InventoryManager.taels,
			"scar_fragments": InventoryManager.scar_fragments,
			"item_ids":       _serialize_items()
		},
		"scar_tree": {
			"purchased":    ScarTreeManager.get_purchased(),
			"locked_paths": ScarTreeManager.get_locked_paths()
		},
		"world_flags": WorldFlags.get_all()
	}

	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("SaveManager: falha ao abrir arquivo para escrita — " + SAVE_PATH)
		return

	f.store_string(JSON.stringify(data, "\t"))
	f.close()

## Lê o JSON, verifica versão e restaura todos os estados.
func load_game() -> void:
	if not has_save():
		push_warning("SaveManager: nenhum arquivo de save encontrado.")
		return

	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		push_error("SaveManager: falha ao abrir arquivo para leitura.")
		return

	var json := JSON.new()
	var err  := json.parse(f.get_as_text())
	f.close()

	if err != OK:
		push_error("SaveManager: JSON inválido — " + json.get_error_message())
		return

	var data: Dictionary = json.get_data()
	if data.get("version", 0) != SAVE_VERSION:
		push_warning("SaveManager: versão incompatível (%d vs %d). Save ignorado." % [
			data.get("version", 0), SAVE_VERSION
		])
		return

	_restore_sanity(data.get("sanity", {}))
	_restore_lantern(data.get("lantern", {}))
	_restore_inventory(data.get("inventory", {}))
	_restore_scar_tree(data.get("scar_tree", {}))
	WorldFlags.load_from(data.get("world_flags", {}))

	# Retorna para a cena onde o save foi feito
	var scene: String = data.get("scene", "")
	if not scene.is_empty():
		GameManager.change_scene(scene)

# ─────────────────────────────────────────────────────────────
# RESTAURAÇÃO — HELPERS PRIVADOS
# ─────────────────────────────────────────────────────────────

func _restore_sanity(d: Dictionary) -> void:
	if d.is_empty():
		return
	SanityManager.set_sanity(float(d.get("current", SanityManager.MAX_SANITY)))

func _restore_lantern(d: Dictionary) -> void:
	if d.is_empty():
		return
	LanternManager.repair(float(d.get("durability", LanternManager.MAX_DURABILITY)))
	if d.get("is_on", true):
		LanternManager.turn_on()
	else:
		LanternManager.turn_off()

func _restore_inventory(d: Dictionary) -> void:
	if d.is_empty():
		return
	InventoryManager.taels          = int(d.get("taels", 0))
	InventoryManager.scar_fragments = int(d.get("scar_fragments", 0))
	EventBus.taels_changed.emit(InventoryManager.taels)
	# Restauração de instâncias de Resource por item_id depende do
	# catálogo de itens (ItemCatalog) — implementado em Sprint futuro.

func _restore_scar_tree(d: Dictionary) -> void:
	if d.is_empty():
		return
	ScarTreeManager.reset()
	for node_id: String in d.get("purchased", []):
		ScarTreeManager._purchased[node_id] = true
	for path_id: String in d.get("locked_paths", []):
		ScarTreeManager._locked_paths[path_id] = true

func _serialize_items() -> Array:
	var ids: Array = []
	for item: Resource in InventoryManager.get_items():
		var iid: Variant = item.get("item_id")
		if iid != null:
			ids.append(iid)
	return ids
