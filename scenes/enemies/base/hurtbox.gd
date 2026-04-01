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

	# Verifica se a área entrante é um HitBox válido
	if not area.has_method("get_damage"):
		return

	# Emite sinal — quem precisa reagir deve conectar-se ao sinal `hurt`.
	# Não chama take_damage() diretamente para evitar dano duplo em entidades
	# que tanto conectam o sinal quanto têm take_damage() no pai.
	hurt.emit(area.get_damage(), area.get_source_id())

# ─────────────────────────────────────────────────────────────
# API PÚBLICA
# ─────────────────────────────────────────────────────────────

## Ativa iframes por `duration` segundos (após receber dano, por exemplo).
func start_invulnerability(duration: float) -> void:
	is_invulnerable = true
	await get_tree().create_timer(duration).timeout
	is_invulnerable = false
