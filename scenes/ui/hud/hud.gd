## hud.gd
## HUD principal: atualiza barras de sanidade e lanterna via EventBus.
## Attach em: HUD (CanvasLayer) — instanciado na base_hub.tscn
extends CanvasLayer

# ─────────────────────────────────────────────────────────────
# NÓS FILHOS
# ─────────────────────────────────────────────────────────────

@onready var _hp_fill:      ColorRect = $HPBG/HPFill
@onready var _sanity_fill:  ColorRect = $SanityBG/SanityFill
@onready var _lantern_fill: ColorRect = $LanternBG/LanternFill
@onready var _sanity_label:  Label    = $SanityLabel
@onready var _lantern_label: Label    = $LanternLabel
@onready var _damage_flash:  ColorRect = $DamageFlash
@onready var _taels_label:   Label     = $TaelsLabel
@onready var _dialogue_bg:   ColorRect = $DialogueBG
@onready var _dialogue_text: Label     = $DialogueBG/DialogueText

# Largura máxima das barras em pixels (deve coincidir com o BG de cada barra)
const BAR_MAX_WIDTH: float = 60.0

# HP máximo local — atualizado via player_hp_changed
var _max_hp: float = 100.0

## Flags de bloqueio usadas pelo HUDGaslighter para sobrescrever as barras.
## Quando true, o update real da barra é ignorado.
var hp_locked:     bool = false
var sanity_locked: bool = false
var taels_locked:  bool = false

# ─────────────────────────────────────────────────────────────
# INICIALIZAÇÃO
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	EventBus.player_hp_changed.connect(_on_player_hp_changed)
	EventBus.player_damaged.connect(_on_player_damaged)
	EventBus.sanity_changed.connect(_on_sanity_changed)
	EventBus.lantern_durability_changed.connect(_on_lantern_durability_changed)
	EventBus.lantern_toggled.connect(_on_lantern_toggled)
	EventBus.taels_changed.connect(_on_taels_changed)
	EventBus.npc_dialogue_requested.connect(_on_npc_dialogue)

	# Sincroniza com o estado atual dos managers ao entrar na cena
	_update_hp_bar(100.0, 100.0)
	_update_sanity_bar(SanityManager.current_sanity)
	_update_lantern_bar(LanternManager.durability)
	_update_lantern_label(LanternManager.is_on)
	_taels_label.text = "T: %d" % InventoryManager.taels

# ─────────────────────────────────────────────────────────────
# ATUALIZAÇÃO DAS BARRAS
# ─────────────────────────────────────────────────────────────

func _update_hp_bar(new_hp: float, max_hp: float) -> void:
	if hp_locked:
		return
	_max_hp = max_hp
	var pct := clampf(new_hp / max_hp, 0.0, 1.0)
	_hp_fill.size.x = BAR_MAX_WIDTH * pct
	if pct > 0.5:
		_hp_fill.color = Color(0.85, 0.2, 0.2)   # vermelho normal
	else:
		_hp_fill.color = Color(1.0, 0.1, 0.1)    # vermelho crítico

func _update_sanity_bar(value: float) -> void:
	if sanity_locked:
		return
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

func _on_player_hp_changed(new_hp: float, max_hp: float) -> void:
	_update_hp_bar(new_hp, max_hp)

func _on_taels_changed(new_amount: int) -> void:
	if taels_locked:
		return
	_taels_label.text = "T: %d" % new_amount

func _on_npc_dialogue(text: String) -> void:
	_dialogue_text.text = text
	_dialogue_bg.visible = true
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(_dialogue_bg):
		_dialogue_bg.visible = false

func _on_player_damaged(_amount: float, _source: String) -> void:
	_damage_flash.color.a = 0.45
	await get_tree().create_timer(0.08).timeout
	if is_instance_valid(_damage_flash):
		_damage_flash.color.a = 0.0

func _on_sanity_changed(new_value: float, _delta: float) -> void:
	_update_sanity_bar(new_value)

func _on_lantern_durability_changed(new_value: float) -> void:
	_update_lantern_bar(new_value)

func _on_lantern_toggled(is_on: bool) -> void:
	_update_lantern_label(is_on)
