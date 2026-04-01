## light_sensor.gd
## Detecta se o Stalker está dentro do LanternCone do player.
## Attach em: LightSensor (Area2D), filho do StalkerBase.
## Collision mask = 4 (camada "lantern_cone" da LanternCone do player).
extends Area2D

# ─────────────────────────────────────────────────────────────
# SINAIS
# ─────────────────────────────────────────────────────────────

## Emitido quando o estado de iluminação muda.
signal light_state_changed(is_in_light: bool)

# ─────────────────────────────────────────────────────────────
# ESTADO
# ─────────────────────────────────────────────────────────────

var is_in_light: bool = false

# ─────────────────────────────────────────────────────────────
# INICIALIZAÇÃO
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	monitoring  = true
	monitorable = false
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

# ─────────────────────────────────────────────────────────────
# DETECÇÃO
# ─────────────────────────────────────────────────────────────

func _on_area_entered(area: Area2D) -> void:
	# LanternCone está na layer 4 — bit 3 (0-indexed)
	if area.collision_layer & 4:
		is_in_light = true
		light_state_changed.emit(true)

func _on_area_exited(area: Area2D) -> void:
	if area.collision_layer & 4:
		is_in_light = false
		light_state_changed.emit(false)
