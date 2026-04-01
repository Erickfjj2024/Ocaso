## hitbox.gd
## Componente genérico de ataque — representa a área que CAUSA dano.
## Attach em: HitBox (Area2D), filho de qualquer entidade atacante.
## Uso: chamar activate(duration) durante a animação de ataque.
extends Area2D

# ─────────────────────────────────────────────────────────────
# CONFIGURAÇÃO
# ─────────────────────────────────────────────────────────────

## Dano causado por este hitbox.
@export var damage: float = 20.0

## Identificador da fonte de dano (ex: "player_sword", "stalker_claw").
## Usado pelo EventBus para diferenciar tipos de dano.
@export var source_id: String = "unknown"

# ─────────────────────────────────────────────────────────────
# ESTADO
# ─────────────────────────────────────────────────────────────

var _active: bool = false

# ─────────────────────────────────────────────────────────────
# INICIALIZAÇÃO
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	# HitBox começa inativo — só fica monitorável durante o ataque
	monitorable = false
	monitoring  = false

# ─────────────────────────────────────────────────────────────
# API PÚBLICA
# ─────────────────────────────────────────────────────────────

## Ativa o HitBox por `duration` segundos (janela de dano).
## Chamar durante o frame de impacto da animação de ataque.
func activate(duration: float = 0.15) -> void:
	if _active:
		return
	_active     = true
	monitorable = true
	await get_tree().create_timer(duration).timeout
	deactivate()

## Desativa imediatamente o HitBox.
func deactivate() -> void:
	_active     = false
	monitorable = false

## Retorna o dano configurado (usado pelo HurtBox ao detectar sobreposição).
func get_damage() -> float:
	return damage

## Retorna o identificador da fonte.
func get_source_id() -> String:
	return source_id
