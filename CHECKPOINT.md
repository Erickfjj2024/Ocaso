# CHECKPOINT — Ocaso Dev Progress

## Branch de desenvolvimento
`claude/ocaso-phase1-foundation-ctCXD`

---

## SPRINT 1 — CONCLUÍDO ✅

### O que foi feito
- [x] Árvore completa de diretórios criada (`autoloads/`, `scenes/`, `resources/`, `assets/`, `data/`, `tests/`)
- [x] `autoloads/event_bus.gd` — Todos os sinais da Seção 2.1 do GDD declarados
- [x] `autoloads/game_manager.gd` — Estados PLAYING/PAUSED/GAME_OVER/CUTSCENE/MENU, transições de cena, Game Over
- [x] `autoloads/sanity_manager.gd` — Dreno passivo, limiares (30/15/0), pausa na luz, dano de fantasma
- [x] `autoloads/lantern_manager.gd` — Toggle, consumo de durabilidade, force_disable/enable, repair

### Arquivos criados
```
project.godot         ← adicionado na correção pós-Sprint 1
autoloads/
  event_bus.gd
  game_manager.gd
  sanity_manager.gd
  lantern_manager.gd
CHECKPOINT.md (este arquivo)
```

---

## SPRINT 2 — CONCLUÍDO ✅

### O que foi feito
- [x] `scenes/player/player.gd` — Movimento 8-dir (WASD + setas), facing_direction, gaslighting (inversão de controles), camera_shake, die()
- [x] `scenes/player/player_lantern.gd` — PointLight2D (verde), Area2D LanternCone, flickering por durabilidade, sincronizado ao LanternManager via EventBus

### Arquivos criados
```
scenes/player/
  player.gd
  player_lantern.gd
```

---

## SPRINT 2 — CORREÇÕES PÓS-TESTE ✅
- [x] Removido `@onready _sprite` inexistente em `player.gd`
- [x] `warnings/unused_signal=0` em `project.godot` (EventBus é pub/sub)
- [x] Lanterna inicia ligada via `call_deferred` no `LanternManager`

---

## SPRINT 3 — PENDENTE ⏳

### Próximos passos (aguardando autorização do usuário)
Tarefa 1.5 do GDD — HUD básica:
- `scenes/ui/hud/hud.gd` — Barra de sanidade + indicador de lanterna reativos via EventBus

Tarefa 1.6 do GDD — Mapa de teste / base_hub:
- `scenes/world/base_hub/base_hub.gd` — Script da cena de teste
- Shader de escuridão: `assets/shaders/darkness_overlay.gdshader`

Tarefa 1.7 do GDD — Game Over:
- `scenes/ui/menus/game_over_screen.tscn` (placeholder) + `game_over_screen.gd`

---

## INSTRUÇÕES PARA O GODOT (Sprint 2)

### Montar player_lantern.tscn
1. **Scene > New Scene** → nó raiz: `Node2D`, renomear para `PlayerLantern`
2. Adicionar filho: `PointLight2D`
   - `texture`: qualquer textura circular branca (ex: padrão do Godot)
   - `color`: `(0.4, 1.0, 0.5, 1)` (verde)
   - `energy`: `1.2`
   - `shadow_enabled`: `true`
3. Adicionar filho: `Area2D`, renomear para `LanternCone`
   - Dentro dele: `CollisionShape2D` com `CircleShape2D`, radius `64`
   - Layer/Mask: Layer 3 (definir como "lantern_cone" em Project Settings > Layer Names > 2D Physics)
4. Attach script: `res://scenes/player/player_lantern.gd`
5. Salvar como `res://scenes/player/player_lantern.tscn`

### Montar player.tscn
1. **Scene > New Scene** → nó raiz: `CharacterBody2D`, renomear para `Player`
2. Adicionar filhos (nesta ordem):
   - `CollisionShape2D` com `CapsuleShape2D` (h: 10, w: 6)
   - `Sprite2D` (placeholder: qualquer sprite 16×16)
   - `AnimationPlayer`
   - `Camera2D` (`zoom: (3, 3)`, `position_smoothing_enabled: true`)
   - Instanciar cena filha: `res://scenes/player/player_lantern.tscn` (nome: `PlayerLantern`)
3. Attach script: `res://scenes/player/player.gd`
4. Salvar como `res://scenes/player/player.tscn`

### Registrar Autoloads no Godot (caso ainda não feito)
1. **Project > Project Settings > Autoload** — verificar se os 4 autoloads estão listados.
   (O `project.godot` já os registra automaticamente ao abrir o projeto.)
