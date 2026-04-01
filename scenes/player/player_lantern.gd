## player_lantern.gd
## Controla a representação visual da lanterna do player:
## PointLight2D (luz verde) + Area2D "LanternCone" (detecção de quem está na luz).
## Attach em: PlayerLantern (Node2D) — sub-cena de player.tscn
## Cena: scenes/player/player_lantern.tscn
extends Node2D

# ─────────────────────────────────────────────────────────────
# NÓS FILHOS
# ─────────────────────────────────────────────────────────────

@onready var _light: PointLight2D   = $PointLight2D
@onready var _cone: Area2D          = $LanternCone

# ─────────────────────────────────────────────────────────────
# CONFIGURAÇÃO DA LUZ
# ─────────────────────────────────────────────────────────────

## Cor da luz da lanterna — verde característico do jogo.
@export var light_color: Color    = Color(0.4, 1.0, 0.5, 1.0)

## Raio de influência da luz (em pixels).
@export var light_energy: float   = 1.2

## Raio da Area2D de detecção (cone de luz).
@export var cone_radius: float    = 64.0

# ─────────────────────────────────────────────────────────────
# ESTADO
# ─────────────────────────────────────────────────────────────

var _is_on: bool = false

# ─────────────────────────────────────────────────────────────
# INICIALIZAÇÃO
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	# Configurar luz
	_light.color   = light_color
	_light.energy  = light_energy
	_light.enabled = false  # Começa apagada

	# Escutar o LanternManager via EventBus
	EventBus.lantern_toggled.connect(_on_lantern_toggled)
	EventBus.lantern_broken.connect(_on_lantern_broken)
	EventBus.lantern_durability_changed.connect(_on_durability_changed)

	# Sincronizar com o estado atual do LanternManager (ex: cena recarregada)
	_set_visual_state(LanternManager.is_on)

# ─────────────────────────────────────────────────────────────
# ESTADO VISUAL
# ─────────────────────────────────────────────────────────────

## Atualiza a visibilidade da luz e ativa/desativa o cone de detecção.
func _set_visual_state(on: bool) -> void:
	_is_on = on
	_light.enabled       = on
	_cone.monitoring     = on   # Inimigos só são detectados "na luz" quando ela está acesa
	_cone.monitorable    = on

## Efeito de flickering quando a durabilidade está baixa (< 20%).
func _flicker() -> void:
	if not _is_on:
		return
	# Pisca brevemente desligando e religando a luz (efeito visual puro)
	_light.enabled = false
	await get_tree().create_timer(0.05).timeout
	if _is_on:
		_light.enabled = true

# ─────────────────────────────────────────────────────────────
# CALLBACKS DE SINAIS
# ─────────────────────────────────────────────────────────────

func _on_lantern_toggled(is_on: bool) -> void:
	_set_visual_state(is_on)

func _on_lantern_broken() -> void:
	_set_visual_state(false)
	# Efeito de piscar antes de apagar completamente
	_light.energy = 0.0

func _on_durability_changed(new_value: float) -> void:
	if not _is_on:
		return

	# Ajusta a energia da luz proporcionalmente à durabilidade restante.
	# Entre 100% e 20%: energia cheia.
	# Abaixo de 20%: diminui gradualmente e flickering.
	var pct: float = new_value / 100.0
	if pct > 0.2:
		_light.energy = light_energy
	else:
		# Mapeia 0–20% → 0.0–light_energy
		_light.energy = light_energy * (pct / 0.2)
		# Flickering aleatório quando crítico
		if randf() < 0.15:  # 15% de chance por mudança de durabilidade
			_flicker()
