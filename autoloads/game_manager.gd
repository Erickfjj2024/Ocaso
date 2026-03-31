## game_manager.gd
## Orquestrador central do jogo: estado global, pause, transições de cena e Game Over.
## Prioridade de Autoload: 2ª — carrega após EventBus.
extends Node

# ─────────────────────────────────────────────────────────────
# ENUMS
# ─────────────────────────────────────────────────────────────

enum GameState {
	MENU,       # Nos menus principais
	PLAYING,    # Jogando normalmente
	PAUSED,     # Jogo pausado
	CUTSCENE,   # Cutscene em reprodução (sem controle do player)
	GAME_OVER,  # Estado de Game Over (antes de ir para a tela)
}

# ─────────────────────────────────────────────────────────────
# ESTADO ATUAL
# ─────────────────────────────────────────────────────────────

var current_state: GameState = GameState.MENU

# Cena atual carregada (usada para recarregar após Game Over)
var _current_scene_path: String = ""

# ─────────────────────────────────────────────────────────────
# REFERÊNCIAS DE CENAS (preencher conforme as cenas forem criadas)
# ─────────────────────────────────────────────────────────────

const GAME_OVER_SCENE_PATH := "res://scenes/ui/menus/game_over_screen.tscn"
const MAIN_MENU_SCENE_PATH := "res://scenes/ui/menus/main_menu.tscn"

# ─────────────────────────────────────────────────────────────
# INICIALIZAÇÃO
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	# Conectar sinais do EventBus
	EventBus.player_died.connect(_on_player_died)
	EventBus.sanity_threshold_crossed.connect(_on_sanity_threshold_crossed)
	EventBus.save_requested.connect(_on_save_requested)
	EventBus.load_requested.connect(_on_load_requested)

# ─────────────────────────────────────────────────────────────
# CONTROLE DE ESTADO
# ─────────────────────────────────────────────────────────────

## Retorna true se o jogo está no estado PLAYING
func is_playing() -> bool:
	return current_state == GameState.PLAYING

## Muda o estado do jogo e aplica efeitos colaterais (pause da SceneTree, etc.)
func set_state(new_state: GameState) -> void:
	if current_state == new_state:
		return

	current_state = new_state

	match current_state:
		GameState.PLAYING:
			get_tree().paused = false
		GameState.PAUSED:
			get_tree().paused = true
		GameState.CUTSCENE:
			get_tree().paused = false  # Cutscenes podem rodar normalmente
		GameState.GAME_OVER:
			get_tree().paused = true
		GameState.MENU:
			get_tree().paused = false

# ─────────────────────────────────────────────────────────────
# TRANSIÇÕES DE CENA
# ─────────────────────────────────────────────────────────────

## Carrega uma cena de forma assíncrona-segura usando call_deferred.
## scene_path: caminho "res://" para o arquivo .tscn
func change_scene(scene_path: String) -> void:
	_current_scene_path = scene_path
	# Usar call_deferred garante que a mudança ocorre no início do próximo frame,
	# evitando problemas de nós sendo destruídos no meio de callbacks.
	get_tree().call_deferred("change_scene_to_file", scene_path)

## Recarrega a cena atual (usado no reload pós-Game Over de forma simples).
func reload_current_scene() -> void:
	if _current_scene_path.is_empty():
		get_tree().call_deferred("reload_current_scene")
	else:
		change_scene(_current_scene_path)

# ─────────────────────────────────────────────────────────────
# GAME OVER
# ─────────────────────────────────────────────────────────────

## Aciona a sequência de Game Over.
## cause: motivo do game over para exibição na tela ("sanity_zero", "player_death")
func trigger_game_over(cause: String) -> void:
	if current_state == GameState.GAME_OVER:
		return  # Evita duplo acionamento

	set_state(GameState.GAME_OVER)

	# Aplicar penalidades de morte no InventoryManager (Fase 3 implementará isso)
	# Por ora, emite o sinal para a UI reagir
	EventBus.game_over_triggered.emit(cause)

	# Aguardar um frame antes de carregar a tela de Game Over
	await get_tree().process_frame
	_load_game_over_screen(cause)

## Carrega a cena de Game Over e passa o motivo via metadado da SceneTree.
func _load_game_over_screen(cause: String) -> void:
	if ResourceLoader.exists(GAME_OVER_SCENE_PATH):
		# Guarda o motivo antes de trocar a cena — game_over_screen.gd lê via get_meta
		get_tree().set_meta("game_over_cause", cause)
		# Preserva a cena de gameplay para o game_over_screen retornar a ela
		get_tree().set_meta("gameplay_scene", _current_scene_path)
		get_tree().call_deferred("change_scene_to_file", GAME_OVER_SCENE_PATH)
	else:
		push_warning("GameManager: game_over_screen.tscn não encontrada. Recarregando cena atual.")
		await get_tree().create_timer(2.0).timeout
		set_state(GameState.PLAYING)
		reload_current_scene()

# ─────────────────────────────────────────────────────────────
# CALLBACKS DE SINAIS
# ─────────────────────────────────────────────────────────────

func _on_player_died() -> void:
	trigger_game_over("player_death")

func _on_sanity_threshold_crossed(threshold: String) -> void:
	if threshold == "zero":
		trigger_game_over("sanity_zero")

func _on_save_requested() -> void:
	# SaveManager (Fase 3) irá implementar a lógica real.
	push_warning("GameManager: save_requested recebido. SaveManager ainda não implementado.")

func _on_load_requested() -> void:
	# SaveManager (Fase 3) irá implementar a lógica real.
	push_warning("GameManager: load_requested recebido. SaveManager ainda não implementado.")

# ─────────────────────────────────────────────────────────────
# INPUT — PAUSA
# ─────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	# Tecla de pausa só funciona durante PLAYING ou PAUSED
	if event.is_action_pressed("ui_cancel"):
		match current_state:
			GameState.PLAYING:
				set_state(GameState.PAUSED)
			GameState.PAUSED:
				set_state(GameState.PLAYING)
