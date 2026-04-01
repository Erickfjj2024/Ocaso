## hurtbox.gd
## Componente genérico de recebimento de dano — representa a área que RECEBE dano.
## Attach em: HurtBox (Area2D), filho de qualquer entidade que pode ser atingida.
## O nó pai deve ter um método take_damage(amount, source) OU conectar ao sinal `hurt`.
extends Area2D

# ─────────────────────────────────────────────────────────────
# SINAIS
# ─────────────────────────────────────────────────────────────

## Emitido quando este hurtbox é atingido por um hitbox ativo.
signal hurt(amount: float, source: String)

# ─────────────────────────────────────────────────────────────
# ESTADO
# ─────────────────────────────────────────────────────────────

## Quando true, ignora todos os golpes (iframes, invulnerabilidade).
var is_invulnerable: bool = false

# ─────────────────────────────────────────────────────────────
# INICIALIZAÇÃO
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	# HurtBox é sempre monitor — detecta HitBoxes que se tornam monitoráveis
	monitoring  = true
	monitorable = false
	area_entered.connect(_on_area_entered)

# ─────────────────────────────────────────────────────────────
# DETECÇÃO
# ─────────────────────────────────────────────────────────────

func _on_area_entered(area: Area2D) -> void:
	if is_invulnerable:
		return

	# Verifica se a área entrante é um HitBox válido e ativo
	if not area.has_method("get_damage"):
		return

	var amount: float  = area.get_damage()
	var source: String = area.get_source_id()

	hurt.emit(amount, source)

	# Delega ao nó pai se ele implementar take_damage (conveniência)
	var owner_node := get_parent()
	if owner_node.has_method("take_damage"):
		owner_node.take_damage(amount, source)

# ─────────────────────────────────────────────────────────────
# API PÚBLICA
# ─────────────────────────────────────────────────────────────

## Ativa iframes por `duration` segundos (após receber dano, por exemplo).
func start_invulnerability(duration: float) -> void:
	is_invulnerable = true
	await get_tree().create_timer(duration).timeout
	is_invulnerable = false
