## hud_gaslighter.gd
## Orquestra as 5 manipulações psicológicas da HUD quando Sanidade < 15.
## Attach em: HUDGaslighter (Node), filho do nó HUD (CanvasLayer).
##
## Manipulações (índice):
##   0 — HP Falso       : mostra HP cheio por 2-4s
##   1 — Inversão       : inverte controles do player via force_gaslighting
##   2 — Taels Zerados  : exibe "T: 0" por 2s
##   3 — Mapa Fantasma  : seta vermelha em direção sem inimigos, 3-5s
##   4 — Cura Falsa     : barra de SAN sobe para 65% e colapsa (1x/crise)
extends Node

# ─────────────────────────────────────────────────────────────
# REFERÊNCIAS AOS NÓS IRMÃOS (dentro do CanvasLayer HUD)
# ─────────────────────────────────────────────────────────────

@onready var _hp_fill:     ColorRect = $"../HPBG/HPFill"
@onready var _sanity_fill: ColorRect = $"../SanityBG/SanityFill"
@onready var _taels_label: Label     = $"../TaelsLabel"
@onready var _phantom:     Label     = $PhantomArrow
@onready var _hud:         Node      = get_parent()

# ─────────────────────────────────────────────────────────────
# CONFIGURAÇÃO (GDD 5.3)
# ─────────────────────────────────────────────────────────────

## Pesos para sorteio ponderado das manipulações (soma = 11).
const WEIGHTS:   Array[int]   = [3, 2, 3, 2, 1]

## Cooldown individual por manipulação (segundos). 0 = sem cooldown (máx 1x/crise).
const COOLDOWNS: Array[float] = [15.0, 20.0, 10.0, 20.0, 0.0]

## Intervalo entre disparos do scheduler (segundos).
const SCHED_MIN: float = 6.0
const SCHED_MAX: float = 12.0

## Tempo mínimo com Sanidade < 15 antes de disparar a Cura Falsa.
const FAKE_HEAL_DELAY: float = 10.0

# ─────────────────────────────────────────────────────────────
# ESTADO
# ─────────────────────────────────────────────────────────────

var _active:         bool  = false
var _busy:           bool  = false
var _cd:             Array = [0.0, 0.0, 0.0, 0.0, 0.0]
var _fake_heal_used: bool  = false
var _low_san_timer:  float = 0.0
var _sched_timer:    float = 0.0
var _next_sched:     float = SCHED_MAX

# ─────────────────────────────────────────────────────────────
# INICIALIZAÇÃO
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	EventBus.sanity_threshold_crossed.connect(_on_threshold_crossed)
	EventBus.sanity_changed.connect(_on_sanity_changed)
	_phantom.visible = false

# ─────────────────────────────────────────────────────────────
# LOOP
# ─────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not _active or not GameManager.is_playing():
		return

	for i in range(_cd.size()):
		_cd[i] = maxf(_cd[i] - delta, 0.0)

	_low_san_timer += delta
	_sched_timer   += delta

	if _sched_timer >= _next_sched and not _busy:
		_sched_timer = 0.0
		_next_sched  = randf_range(SCHED_MIN, SCHED_MAX)
		_trigger_random()

# ─────────────────────────────────────────────────────────────
# SELEÇÃO PONDERADA
# ─────────────────────────────────────────────────────────────

func _trigger_random() -> void:
	var candidates: Array[int] = []
	var total_w: int = 0

	for i in range(5):
		if _cd[i] > 0.0:
			continue
		if i == 4 and (_fake_heal_used or _low_san_timer < FAKE_HEAL_DELAY):
			continue
		candidates.append(i)
		total_w += WEIGHTS[i]

	if candidates.is_empty():
		return

	var roll := randi() % total_w
	var acc  := 0
	for idx in candidates:
		acc += WEIGHTS[idx]
		if roll < acc:
			_execute(idx)
			return

func _execute(m: int) -> void:
	_busy  = true
	_cd[m] = COOLDOWNS[m]
	match m:
		0: await _fake_hp()
		1: await _invert_controls()
		2: await _fake_taels()
		3: await _phantom_arrow()
		4: await _fake_sanity_heal()
	_busy = false

# ─────────────────────────────────────────────────────────────
# MANIPULAÇÕES
# ─────────────────────────────────────────────────────────────

## 0 — HP Falso: exibe HP cheio por 2-4s, bloqueando o update real da barra.
func _fake_hp() -> void:
	_hud.hp_locked   = true
	var orig: float  = _hp_fill.size.x
	_hp_fill.size.x  = 60.0
	_hp_fill.color   = Color(0.85, 0.2, 0.2)
	await get_tree().create_timer(randf_range(2.0, 4.0)).timeout
	if is_instance_valid(_hp_fill):
		_hp_fill.size.x = orig
	_hud.hp_locked = false

## 1 — Inversão de Controles: emite force_gaslighting; player.gd já escuta.
func _invert_controls() -> void:
	var dur: float = randf_range(2.0, 4.0)
	EventBus.force_gaslighting.emit(dur)
	await get_tree().create_timer(dur).timeout

## 2 — Taels Zerados: exibe "T: 0" por 2s, bloqueando update real.
func _fake_taels() -> void:
	_hud.taels_locked     = true
	var orig: String      = _taels_label.text
	_taels_label.text     = "T: 0"
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(_taels_label):
		_taels_label.text = orig
	_hud.taels_locked = false

## 3 — Mapa Fantasma: Label "▶" pulsante numa direção sem inimigos, 3-5s.
func _phantom_arrow() -> void:
	var dir := _get_false_direction()
	_phantom.position = Vector2(160.0, 90.0) + dir * 72.0 - Vector2(6.0, 6.0)
	_phantom.visible  = true

	var dur:     float = randf_range(3.0, 5.0)
	var elapsed: float = 0.0
	while elapsed < dur and is_instance_valid(_phantom):
		_phantom.modulate.a = 0.45 + 0.55 * sin(elapsed * 6.0)
		elapsed += get_process_delta_time()
		await get_tree().process_frame

	if is_instance_valid(_phantom):
		_phantom.visible = false

## 4 — Cura Falsa: SAN sobe para 65%, mantém 3s, colapsa com glitch. Máx 1x/crise.
func _fake_sanity_heal() -> void:
	_fake_heal_used    = true
	_hud.sanity_locked = true

	var real_pct := clampf(SanityManager.current_sanity / SanityManager.MAX_SANITY, 0.0, 1.0)
	var real_w   := 60.0 * real_pct

	# Tween: sobe para 65% em 1.5s
	var tw := get_tree().create_tween()
	tw.tween_property(_sanity_fill, "size:x", 60.0 * 0.65, 1.5).set_ease(Tween.EASE_OUT)
	_sanity_fill.color = Color(0.2, 0.8, 0.35)
	await tw.finished

	# Mantém por 3s
	await get_tree().create_timer(3.0).timeout

	# Glitch: pisca branco/vermelho 3x
	for _i in range(3):
		if not is_instance_valid(_sanity_fill):
			_hud.sanity_locked = false
			return
		_sanity_fill.color = Color(1.0, 1.0, 1.0)
		await get_tree().create_timer(0.07).timeout
		_sanity_fill.color = Color(0.9, 0.15, 0.15)
		await get_tree().create_timer(0.07).timeout

	# Cai instantaneamente para o valor real
	if is_instance_valid(_sanity_fill):
		_sanity_fill.size.x = real_w

	_hud.sanity_locked = false

# ─────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────

## Retorna direção (normalizada) que se afasta o máximo possível de todos
## os inimigos ativos — para o indicador fantasma não coincidir com ameaças reais.
func _get_false_direction() -> Vector2:
	var player  := get_tree().get_first_node_in_group("player")
	var enemies := get_tree().get_nodes_in_group("enemies")

	var real_angles: Array[float] = []
	if player != null:
		for e in enemies:
			if not (e is Node2D):
				continue
			var dir: Vector2 = (e.global_position - player.global_position).normalized()
			real_angles.append(dir.angle())

	# Tenta 10 candidatos aleatórios; escolhe o mais distante de qualquer inimigo real
	var best_angle := randf() * TAU
	var best_gap   := -1.0

	for _t in range(10):
		var angle := randf() * TAU
		var min_gap: float = TAU
		for ra in real_angles:
			var diff := absf(wrapf(angle - ra, -PI, PI))
			if diff < min_gap:
				min_gap = diff
		# Se não há inimigos, qualquer ângulo serve
		if real_angles.is_empty():
			min_gap = PI
		if min_gap > best_gap:
			best_gap   = min_gap
			best_angle = angle

	return Vector2(cos(best_angle), sin(best_angle))

# ─────────────────────────────────────────────────────────────
# ATIVAR / DESATIVAR
# ─────────────────────────────────────────────────────────────

func _activate() -> void:
	if _active:
		return
	_active        = true
	_sched_timer   = 0.0
	_next_sched    = randf_range(SCHED_MIN, SCHED_MAX)
	_low_san_timer = 0.0

func _deactivate() -> void:
	_active          = false
	_busy            = false
	_fake_heal_used  = false
	_low_san_timer   = 0.0
	if is_instance_valid(_hud):
		_hud.hp_locked     = false
		_hud.sanity_locked = false
		_hud.taels_locked  = false
	if is_instance_valid(_phantom):
		_phantom.visible   = false

# ─────────────────────────────────────────────────────────────
# CALLBACKS
# ─────────────────────────────────────────────────────────────

func _on_threshold_crossed(threshold: String) -> void:
	if threshold == "critical_15":
		_activate()

func _on_sanity_changed(new_value: float, _delta: float) -> void:
	# Desativa quando Sanidade sobe acima do limiar baixo (30)
	if _active and new_value > SanityManager.THRESHOLD_LOW:
		_deactivate()
