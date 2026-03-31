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

## SPRINT 2 — PENDENTE ⏳

### Próximos passos (aguardando autorização do usuário)
Tarefa 1.3 do GDD — Cena do Player (básica):
- `scenes/player/player.gd` — CharacterBody2D, movimento 8-dir, facing direction
- `scenes/player/player_lantern.gd` — PointLight2D + Area2D, toggle via input

Tarefa 1.4 do GDD — Sistema de Lanterna (cena):
- Instruções para montar `player_lantern.tscn` na engine

Tarefa 1.5 do GDD — HUD básica:
- `scenes/ui/hud/hud.gd` — Barra de sanidade + indicador de lanterna reativos via EventBus

Tarefa 1.6 do GDD — Mapa de teste:
- `scenes/world/base_hub/base_hub.gd` — TileMap placeholder
- Shader básico de escuridão

Tarefa 1.7 do GDD — Game Over visual:
- `scenes/ui/menus/game_over_screen.tscn` + script de reload

---

## INSTRUÇÕES PARA O GODOT (Sprint 1)

### Registrar Autoloads no Godot
1. Abra **Project > Project Settings > Autoload**
2. Adicione na ordem exata:
   | Nome           | Caminho                         | Ordem |
   |----------------|---------------------------------|-------|
   | `EventBus`     | `res://autoloads/event_bus.gd`      | 1ª    |
   | `GameManager`  | `res://autoloads/game_manager.gd`   | 2ª    |
   | `SanityManager`| `res://autoloads/sanity_manager.gd` | 3ª    |
   | `LanternManager`| `res://autoloads/lantern_manager.gd`| 4ª    |
3. Salve e faça reload do projeto.

### Verificação rápida
No output do Godot, se não houver erros de parse ao abrir o projeto, os 4 autoloads estão funcionais.
