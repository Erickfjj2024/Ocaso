## audio_manager.gd
## Gerencia todos os sons do jogo: música ambiente, SFX e manipulação por sanidade.
## Prioridade de Autoload: 8ª — carrega após WorldFlags.
##
## FASE 4: Stub estruturado. AudioStreams reais serão adicionados na FASE 6.
## A estrutura de pitch_scale e volume_db já está funcional — basta alimentar
## os AudioStreamPlayers com arquivos de áudio quando disponíveis.
extends Node

# ─────────────────────────────────────────────────────────────
# PLAYERS
# ─────────────────────────────────────────────────────────────

var _ambient: AudioStreamPlayer
var _music:   AudioStreamPlayer
var _sfx:     AudioStreamPlayer

# ─────────────────────────────────────────────────────────────
# ESTADO
# ─────────────────────────────────────────────────────────────

var _current_sanity: float = 100.0

## Volume master de cada categoria (0.0–1.0 linear)
var volume_ambient: float = 0.7
var volume_music:   float = 0.8
var volume_sfx:     float = 1.0

# ─────────────────────────────────────────────────────────────
# INICIALIZAÇÃO
# ─────────────────────────────────────────────────────────────

func _ready() -> void:
	_ambient = AudioStreamPlayer.new()
	_ambient.name = "AmbientPlayer"
	_ambient.bus  = "Ambient"
	add_child(_ambient)

	_music = AudioStreamPlayer.new()
	_music.name = "MusicPlayer"
	_music.bus  = "Music"
	add_child(_music)

	_sfx = AudioStreamPlayer.new()
	_sfx.name = "SFXPlayer"
	_sfx.bus  = "SFX"
	add_child(_sfx)

	EventBus.sanity_changed.connect(_on_sanity_changed)
	EventBus.lantern_toggled.connect(_on_lantern_toggled)
	EventBus.game_over_triggered.connect(_on_game_over)

# ─────────────────────────────────────────────────────────────
# API PÚBLICA
# ─────────────────────────────────────────────────────────────

## Toca um SFX pelo caminho do recurso.
## FASE 6: substituir `pass` pelo carregamento real do AudioStream.
func play_sfx(sfx_path: String) -> void:
	if sfx_path.is_empty():
		return
	# TODO FASE 6:
	# var stream := load(sfx_path) as AudioStream
	# if stream: _sfx.stream = stream; _sfx.play()
	pass

## Define e toca a trilha ambiente (com fade in de 1s).
func play_ambient(track_path: String) -> void:
	if track_path.is_empty():
		return
	# TODO FASE 6:
	# var stream := load(track_path) as AudioStream
	# if stream: _ambient.stream = stream; _fade_in(_ambient, 1.0)
	pass

## Define e toca a trilha musical (com fade in de 2s).
func play_music(track_path: String) -> void:
	if track_path.is_empty():
		return
	# TODO FASE 6:
	# var stream := load(track_path) as AudioStream
	# if stream: _music.stream = stream; _fade_in(_music, 2.0)
	pass

## Para todos os players com fade out de `duration` segundos.
func stop_all(duration: float = 1.0) -> void:
	_fade_out(_ambient, duration)
	_fade_out(_music,   duration)
	_fade_out(_sfx,     0.1)

# ─────────────────────────────────────────────────────────────
# REAÇÃO À SANIDADE (GDD 4.7)
# ─────────────────────────────────────────────────────────────

func _apply_sanity_effects() -> void:
	var pct := clampf(_current_sanity / 100.0, 0.0, 1.0)

	# Pitch bending: sanidade baixa → voz mais lenta e distorcida
	# sanidade > 30: 1.0 | 15-30: 0.95-1.0 | < 15: 0.85-0.95 com ruído
	var target_pitch := lerpf(0.85, 1.0, pct)
	if _current_sanity < SanityManager.THRESHOLD_CRITICAL:
		target_pitch += randf_range(-0.04, 0.04)   # tremulo

	_ambient.pitch_scale = target_pitch
	_music.pitch_scale   = lerpf(0.92, 1.0, pct)  # música distorce menos

	# Volume ambiente aumenta levemente no escuro psicológico
	_ambient.volume_db = linear_to_db(volume_ambient * lerpf(1.2, 1.0, pct))

# ─────────────────────────────────────────────────────────────
# HELPERS
# ─────────────────────────────────────────────────────────────

func _fade_in(player: AudioStreamPlayer, duration: float) -> void:
	player.volume_db = -80.0
	player.play()
	var tw := get_tree().create_tween()
	tw.tween_property(player, "volume_db", 0.0, duration)

func _fade_out(player: AudioStreamPlayer, duration: float) -> void:
	if not player.playing:
		return
	var tw := get_tree().create_tween()
	tw.tween_property(player, "volume_db", -80.0, duration)
	tw.tween_callback(player.stop)

# ─────────────────────────────────────────────────────────────
# CALLBACKS
# ─────────────────────────────────────────────────────────────

func _on_sanity_changed(new_value: float, _delta: float) -> void:
	_current_sanity = new_value
	_apply_sanity_effects()

func _on_lantern_toggled(_is_on: bool) -> void:
	# TODO FASE 6: mudar bus mix conforme estado da lanterna
	pass

func _on_game_over(_cause: String) -> void:
	stop_all(0.5)
