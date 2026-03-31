## hud.gd
## HUD principal: atualiza barras de sanidade e lanterna via EventBus.
## Attach em: HUD (CanvasLayer) — instanciado na base_hub.tscn
extends CanvasLayer

# ─────────────────────────────────────────────────────────────
# NÓS FILHOS
# ─────────────────────────────────────────────────────────────

@onready var _sanity_fill:  ColorRect = $SanityBG/SanityFill
@onready var _lantern_fill: ColorRect = $LanternBG/LanternFill
@onready var _sanity_label:  Label    = $SanityLabel
@onready var _lantern_label: Label    = $LanternLabel

# Largura máxima das barras em pixels (deve coincidir com SanityBG.size.x)
const BAR_MAX_WIDTH: float = 60.0

# ─────────────────────────────────────────────────────────────
# INICIALIZAÇÃO
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	EventBus.sanity_changed.connect(_on_sanity_changed)
	EventBus.lantern_durability_changed.connect(_on_lantern_durability_changed)
	EventBus.lantern_toggled.connect(_on_lantern_toggled)

	# Sincroniza com o estado atual dos managers ao entrar na cena
	_update_sanity_bar(SanityManager.current_sanity)
	_update_lantern_bar(LanternManager.durability)
	_update_lantern_label(LanternManager.is_on)

# ─────────────────────────────────────────────────────────────
# ATUALIZAÇÃO DAS BARRAS
# ─────────────────────────────────────────────────────────────

func _update_sanity_bar(value: float) -> void:
	var pct := clampf(value / SanityManager.MAX_SANITY, 0.0, 1.0)
	_sanity_fill.size.x = BAR_MAX_WIDTH * pct

	# Muda a cor da barra conforme o nível de sanidade
	if pct > 0.3:
		_sanity_fill.color = Color(0.2, 0.8, 0.35)   # verde
	elif pct > 0.15:
		_sanity_fill.color = Color(0.9, 0.7, 0.1)    # amarelo
	else:
		_sanity_fill.color = Color(0.9, 0.15, 0.15)  # vermelho

func _update_lantern_bar(value: float) -> void:
	var pct := clampf(value / LanternManager.MAX_DURABILITY, 0.0, 1.0)
	_lantern_fill.size.x = BAR_MAX_WIDTH * pct

	# Cor da barra de lanterna: verde quando ok, laranja quando baixo
	if pct > 0.25:
		_lantern_fill.color = Color(0.4, 1.0, 0.5)   # verde lanterna
	else:
		_lantern_fill.color = Color(1.0, 0.5, 0.1)   # laranja crítico

func _update_lantern_label(is_on: bool) -> void:
	_lantern_label.text = "LAN [ON]" if is_on else "LAN [--]"

# ─────────────────────────────────────────────────────────────
# CALLBACKS
# ─────────────────────────────────────────────────────────────

func _on_sanity_changed(new_value: float, _delta: float) -> void:
	_update_sanity_bar(new_value)

func _on_lantern_durability_changed(new_value: float) -> void:
	_update_lantern_bar(new_value)

func _on_lantern_toggled(is_on: bool) -> void:
	_update_lantern_label(is_on)
