## base_hub.gd
## Script da cena de teste / base do jogador (Fase 1).
## Responsável por inicializar o estado do jogo ao entrar nesta cena.
## Attach em: BaseHub (Node2D)
extends Node2D

func _ready() -> void:
	# Resetar managers — autoloads persistem entre cenas, então precisamos
	# garantir valores iniciais frescos a cada vez que a gameplay começa.
	SanityManager.set_sanity(SanityManager.MAX_SANITY)
	LanternManager.repair(LanternManager.MAX_DURABILITY)
	LanternManager.force_enable()
	LanternManager.turn_on()

	# Reseta HP do PlayerCombat (filho do Player instanciado nesta cena)
	var combat := get_node_or_null("Player/PlayerCombat")
	if combat:
		combat.reset()

	GameManager.set_state(GameManager.GameState.PLAYING)
