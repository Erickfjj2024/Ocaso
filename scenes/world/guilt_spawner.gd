## guilt_spawner.gd
## Spawna Fantasmas da Culpa periodicamente quando WorldFlags["has_murdered"]=true.
## Adicionar este nó a qualquer cena onde os fantasmas devem aparecer.
extends Node

# ─────────────────────────────────────────────────────────────
# CONFIGURAÇÃO
# ─────────────────────────────────────────────────────────────

const GHOST_SCENE_PATH: String = "res://scenes/enemies/guilt_ghost/guilt_ghost.tscn"

const MAX_GHOSTS:      int   = 3
const SPAWN_DIST_MIN:  float = 80.0    # distância mínima do player ao spawnar
const SPAWN_DIST_MAX:  float = 120.0   # distância máxima
const INTERVAL_MIN:    float = 8.0
const INTERVAL_MAX:    float = 20.0

# ─────────────────────────────────────────────────────────────
# ESTADO
# ─────────────────────────────────────────────────────────────

var _active:       bool  = false
var _spawn_timer:  float = 0.0
var _next_spawn:   float = INTERVAL_MAX
var _ghost_count:  int   = 0

# ─────────────────────────────────────────────────────────────
# INICIALIZAÇÃO
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	EventBus.npc_sacrificed.connect(_on_npc_sacrificed)
	# Reativa se o save já tinha has_murdered=true
	if WorldFlags.get_flag("has_murdered", false):
		_activate()

# ─────────────────────────────────────────────────────────────
# LOOP
# ─────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not _active or not GameManager.is_playing():
		return

	_spawn_timer += delta
	if _spawn_timer >= _next_spawn and _ghost_count < MAX_GHOSTS:
		_spawn_timer = 0.0
		_next_spawn  = randf_range(INTERVAL_MIN, INTERVAL_MAX)
		_spawn_ghost()

# ─────────────────────────────────────────────────────────────
# SPAWN
# ─────────────────────────────────────────────────────────────

func _spawn_ghost() -> void:
	if not ResourceLoader.exists(GHOST_SCENE_PATH):
		return

	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var angle    := randf() * TAU
	var dist     := randf_range(SPAWN_DIST_MIN, SPAWN_DIST_MAX)
	var spawn_pos: Vector2 = player.global_position + Vector2(cos(angle), sin(angle)) * dist

	var ghost: Node2D = load(GHOST_SCENE_PATH).instantiate()
	ghost.global_position = spawn_pos
	# Quando o fantasma for destruído, decrementar o contador
	ghost.tree_exited.connect(func() -> void: _ghost_count -= 1, CONNECT_ONE_SHOT)

	get_parent().add_child(ghost)
	_ghost_count += 1

# ─────────────────────────────────────────────────────────────
# ATIVAR
# ─────────────────────────────────────────────────────────────

func _activate() -> void:
	if _active:
		return
	_active      = true
	_spawn_timer = 0.0
	_next_spawn  = randf_range(INTERVAL_MIN, INTERVAL_MAX)
	EventBus.guilt_ghosts_activated.emit()

# ─────────────────────────────────────────────────────────────
# CALLBACKS
# ─────────────────────────────────────────────────────────────

func _on_npc_sacrificed(_npc_id: String) -> void:
	_activate()
