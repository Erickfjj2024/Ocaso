## sanity_vfx.gd
## Efeitos visuais de sanidade: vinheta crescente + tint roxo/vermelho.
## Attach em: SanityVFX (CanvasLayer, layer=2), instanciado na cena principal.
extends CanvasLayer

# ─────────────────────────────────────────────────────────────
# NÓS FILHOS
# ─────────────────────────────────────────────────────────────

@onready var _vignette: ColorRect = $VignetteRect
@onready var _tint:     ColorRect = $TintRect
@onready var _flash:    ColorRect = $BlackFlash

# ─────────────────────────────────────────────────────────────
# PARÂMETROS POR LIMIAR DE SANIDADE
# ─────────────────────────────────────────────────────────────

## sanity > 30   → sem efeito
## sanity 15–30  → vinheta leve, sem tint
## sanity < 15   → vinheta intensa + tint roxo pulsante

const VIGNETTE_NORMAL:   float = 0.0
const VIGNETTE_LOW:      float = 0.7
const VIGNETTE_CRITICAL: float = 1.6

const TINT_ALPHA_NORMAL:   float = 0.0
const TINT_ALPHA_LOW:      float = 0.0
const TINT_ALPHA_CRITICAL: float = 0.12

# ─────────────────────────────────────────────────────────────
# ESTADO
# ─────────────────────────────────────────────────────────────

var _pulse_timer: float = 0.0

# ─────────────────────────────────────────────────────────────
# INICIALIZAÇÃO
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	add_to_group("sanity_vfx")
	EventBus.sanity_changed.connect(_on_sanity_changed)
	_flash.visible = false
	_update_vfx(SanityManager.current_sanity)

# ─────────────────────────────────────────────────────────────
# LOOP — PULSE NA SANIDADE CRÍTICA
# ─────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if SanityManager.current_sanity > SanityManager.THRESHOLD_CRITICAL:
		return
	# Pulso sutil no tint (alpha oscila ±0.04)
	_pulse_timer += delta
	var pulse := TINT_ALPHA_CRITICAL + 0.04 * sin(_pulse_timer * 3.5)
	_tint.color.a = clampf(pulse, 0.0, 0.3)

# ─────────────────────────────────────────────────────────────
# API PÚBLICA
# ─────────────────────────────────────────────────────────────

## Funde a tela para preto em `duration` segundos (usado na transformação do Guardião).
func flash_to_black(duration: float) -> void:
	_flash.visible = true
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 1.0, duration * 0.4)
	tw.tween_interval(duration * 0.2)
	tw.tween_property(_flash, "color:a", 0.0, duration * 0.4)
	await tw.finished
	_flash.visible = false

## Mantém a tela em preto até `restore_black()` ser chamado.
func set_black(is_black: bool) -> void:
	_flash.visible = is_black
	_flash.color.a = 1.0 if is_black else 0.0

# ─────────────────────────────────────────────────────────────
# ATUALIZAÇÃO DE VFX
# ─────────────────────────────────────────────────────────────

func _update_vfx(sanity: float) -> void:
	var mat := _vignette.material as ShaderMaterial
	if mat == null:
		return

	if sanity > SanityManager.THRESHOLD_LOW:
		# Sem efeito
		mat.set_shader_parameter("strength", VIGNETTE_NORMAL)
		_tint.color.a = TINT_ALPHA_NORMAL

	elif sanity > SanityManager.THRESHOLD_CRITICAL:
		# Leve: interpola de 0 a VIGNETTE_LOW conforme desce de 30 a 15
		var t := 1.0 - (sanity - SanityManager.THRESHOLD_CRITICAL) / (SanityManager.THRESHOLD_LOW - SanityManager.THRESHOLD_CRITICAL)
		mat.set_shader_parameter("strength", lerpf(VIGNETTE_NORMAL, VIGNETTE_LOW, t))
		_tint.color.a = TINT_ALPHA_NORMAL

	else:
		# Crítico: interpola de VIGNETTE_LOW a VIGNETTE_CRITICAL conforme desce de 15 a 0
		var t := 1.0 - (sanity / SanityManager.THRESHOLD_CRITICAL)
		mat.set_shader_parameter("strength", lerpf(VIGNETTE_LOW, VIGNETTE_CRITICAL, t))
		_tint.color.a = lerpf(TINT_ALPHA_LOW, TINT_ALPHA_CRITICAL, t)

# ─────────────────────────────────────────────────────────────
# CALLBACKS
# ─────────────────────────────────────────────────────────────

func _on_sanity_changed(new_value: float, _delta: float) -> void:
	_update_vfx(new_value)
