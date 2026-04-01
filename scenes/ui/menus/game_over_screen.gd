## game_over_screen.gd
## Tela de Game Over: exibe mensagem e retorna ao jogo após 3 segundos.
## Attach em: GameOverScreen (Control)
extends Control

# Cena de gameplay para retornar após o Game Over
const GAMEPLAY_SCENE := "res://scenes/world/base_hub/base_hub.tscn"

# Tempo de espera antes de recarregar (em segundos)
const RELOAD_DELAY: float = 3.0

@onready var _cause_label: Label = $VBox/CauseLabel

func _ready() -> void:
	# Lê o motivo e a cena de gameplay que o GameManager gravou na SceneTree
	var cause: String = get_tree().get_meta("game_over_cause", "")
	var return_scene: String = get_tree().get_meta("gameplay_scene", GAMEPLAY_SCENE)
	_cause_label.text = _get_cause_text(cause)

	# Restaura estado para PLAYING antes de recarregar
	GameManager.set_state(GameManager.GameState.PLAYING)

	# Aguarda e volta para o jogo
	await get_tree().create_timer(RELOAD_DELAY).timeout
	get_tree().change_scene_to_file(return_scene)

func _get_cause_text(cause: String) -> String:
	match cause:
		"sanity_zero":
			return "A escuridão consumiu sua mente."
		"player_death":
			return "Você sucumbiu às sombras."
		_:
			return "O Ocaso te reivindicou."
