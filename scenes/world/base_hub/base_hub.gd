## base_hub.gd
## Script da cena de teste / base do jogador (Fase 1).
## Responsável por inicializar o estado do jogo ao entrar nesta cena.
## Attach em: BaseHub (Node2D)
extends Node2D

func _ready() -> void:
	# Inicia o jogo assim que a cena carrega
	GameManager.set_state(GameManager.GameState.PLAYING)
