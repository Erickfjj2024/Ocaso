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

## SPRINT 3 — CONCLUÍDO ✅

- [x] `scenes/ui/hud/hud.gd` + `hud.tscn` — Barras SAN/LAN, cor muda por limiar, CanvasLayer imune ao escuro
- [x] `scenes/ui/menus/game_over_screen.gd` + `.tscn` — Tela preta, mensagem de causa, retorno em 3s
- [x] `autoloads/game_manager.gd` — Passa cause via SceneTree.set_meta
- [x] `scenes/world/base_hub/base_hub.tscn` — HUD instanciada

## FASE 1 — COMPLETA ✅
| 1.1 | project.godot | ✅ | 1.2 | Autoloads | ✅ | 1.3 | Player | ✅ |
| 1.4 | Lanterna | ✅ | 1.5 | Sanidade | ✅ | 1.6 | Mapa | ✅ | 1.7 | Game Over | ✅ |

## FASE 2 — COMPLETA ✅
| 2.1 | HitBox/HurtBox | ✅ | 2.2 | Stalker + FSM | ✅ | 2.3 | LightSensor | ✅ |
| 2.4 | BackstabDetector | ✅ | 2.5 | NavigationAgent2D | ✅ | 2.6 | Player Combat | ✅ |

---

## SPRINT 7 — FASE 3 Parte 1: Progressão e Economia — CONCLUÍDO ✅

### O que foi feito
- [x] `resources/items/item_base.gd` — Resource base para todos os itens (id, nome, icon, stackable, value_taels)
- [x] `autoloads/inventory_manager.gd` — Taels + itens, add/remove, penalidade de morte (-50% taels + 1–3 itens perdidos)
- [x] `autoloads/world_flags.gd` — Flags narrativas persistentes (set/get/has/increment/reset)
- [x] `project.godot` — InventoryManager e WorldFlags registrados como Autoloads (prioridade 5ª e 7ª)
- [x] `game_manager.gd` — trigger_game_over chama InventoryManager.apply_death_penalty()
- [x] `hud.gd` + `hud.tscn` — Contador de Taels ("T: 0") atualizado via EventBus.taels_changed

---

## SPRINT 8 — FASE 3 Parte 2: Árvore de Cicatrizes — CONCLUÍDO ✅

### O que foi feito
- [x] `data/scar_tree_definition.json` — 3 pares × 2 caminhos × 3 nós = 18 nós compráveis
  - Par 1: Corpo vs. Espírito (Vida/Regen vs. Sanidade/Visão)
  - Par 2: Lâmina vs. Maldição (Dano/Execute vs. Controle/Almas)
  - Par 3: Lanterna vs. Sombra (Chama/Pulso vs. Noite/Invisibilidade)
- [x] `autoloads/scar_tree_manager.gd` (6ª prioridade)
  - Carrega JSON, constrói índices node→dados, node→path
  - `can_purchase()`: valida path livre, pré-req sequencial, custo Taels+Fragmentos
  - `purchase_node()`: deduz custo, bloqueia caminho oposto, emite sinais
  - `get_multiplier(stat)` / `get_additive(stat)` / `has_effect(stat)` para outros sistemas
  - `reset()` para nova partida
- [x] `inventory_manager.gd` — adicionado `scar_fragments`, `add_fragments()`, drop 15% por kill
- [x] `project.godot` — ScarTreeManager registrado como 6ª Autoload

### Arquivos criados/modificados
```
data/scar_tree_definition.json    ← NOVO
autoloads/scar_tree_manager.gd    ← NOVO
autoloads/inventory_manager.gd    ← +scar_fragments, +add_fragments(), drop 15%
project.godot                     ← +ScarTreeManager
```

---

## SPRINT 9 — FASE 3 Parte 3: SaveManager + Guardião — CONCLUÍDO ✅

### O que foi feito
- [x] `autoloads/save_manager.gd` (9ª prioridade)
  - `save_game()`: serializa Sanidade, Lanterna, Inventário (taels+frags+item_ids), ScarTree, WorldFlags, scene_path → JSON em `user://ocaso_save.json`
  - `load_game()`: desserializa e restaura todos os estados; muda para a cena salva
  - `has_save()`, `delete_save()` para gerenciamento de nova partida
  - Escuta `EventBus.save_requested` e `EventBus.load_requested`
- [x] `scenes/npcs/guardian/guardian_npc.gd` + `.tscn`
  - Area2D de interação (r=20, mask=1); player pressiona E → fala diálogo
  - 5 diálogos indexados por `WorldFlags["base_visits"]`; incrementa a cada instanciação
  - Placeholder visual: Polygon2D corpo + cabeça (cinza-roxo escuro)
- [x] `autoloads/event_bus.gd` — sinal `npc_dialogue_requested(text: String)` adicionado
- [x] `scenes/ui/hud/hud.gd` + `.tscn` — caixa de diálogo (DialogueBG + DialogueText); aparece 3s ao receber `npc_dialogue_requested`, depois some
- [x] `scenes/world/base_hub/base_hub.tscn` — GuardianNPC instanciado em (-100, -40)
- [x] `project.godot` — SaveManager registrado como 9ª Autoload
- [x] `game_manager.gd` — stubs `_on_save_requested`/`_on_load_requested` delegam ao SaveManager

### Arquivos criados/modificados
```
autoloads/save_manager.gd                   ← NOVO
scenes/npcs/guardian/guardian_npc.gd        ← NOVO
scenes/npcs/guardian/guardian_npc.tscn      ← NOVO
autoloads/event_bus.gd                      ← +npc_dialogue_requested
scenes/ui/hud/hud.gd                        ← +diálogo NPC
scenes/ui/hud/hud.tscn                      ← +DialogueBG/DialogueText
scenes/world/base_hub/base_hub.tscn         ← +GuardianNPC
project.godot                               ← +SaveManager
autoloads/game_manager.gd                   ← stubs conectados
```

---

## SPRINT 10 — FASE 4 Parte 1: HUD Gaslighter — CONCLUÍDO ✅

### O que foi feito
- [x] `scenes/ui/hud/hud_gaslighter.gd` — 5 manipulações + scheduler ponderado
  - Ativa no `critical_15`, desativa quando Sanidade > 30
  - Scheduler: timer 6-12s, sorteio ponderado [3,2,3,2,1] entre manipulações disponíveis
  - **0 — HP Falso:** exibe HP cheio por 2-4s (cooldown 15s)
  - **1 — Inversão:** `EventBus.force_gaslighting.emit(dur)` por 2-4s (cooldown 20s)
  - **2 — Taels Zerados:** exibe "T: 0" por 2s (cooldown 10s)
  - **3 — Mapa Fantasma:** Label "▶" vermelha pulsante na borda da tela, direção calculada longe de inimigos reais, 3-5s (cooldown 20s)
  - **4 — Cura Falsa:** SAN sobe para 65% via Tween, mantém 3s, colapsa com glitch branco/vermelho (1x/crise, delay mínimo 10s)
- [x] `scenes/ui/hud/hud.gd` — flags `hp_locked`, `sanity_locked`, `taels_locked`; update das barras respeitam os locks do gaslighter
- [x] `scenes/ui/hud/hud.tscn` — nó `HUDGaslighter` + `PhantomArrow` (Label "▶" oculta)

### Arquivos criados/modificados
```
scenes/ui/hud/hud_gaslighter.gd    ← NOVO
scenes/ui/hud/hud.gd               ← +flags de lock nas barras
scenes/ui/hud/hud.tscn             ← +HUDGaslighter, +PhantomArrow
```

## FASE 3 — COMPLETA ✅
| 3.1 | InventoryManager | ✅ | 3.2 | Taels | ✅ | 3.3 | Penalidade de morte | ✅ |
| 3.4 | Base Hub + Guardião | ✅ | 3.5/3.6 | ScarTree + Manager | ✅ | 3.7 | SaveManager | ✅ |

---

### Lógica de drop de Taels
- Stalker morto → `enemy_killed` → InventoryManager escuta → adiciona 5–15 Taels aleatórios
- Morte do player → GameManager → `apply_death_penalty()` → perde 50% dos Taels acumulados

### Arquivos criados/modificados
```
resources/items/item_base.gd     ← NOVO
autoloads/inventory_manager.gd   ← NOVO
autoloads/world_flags.gd         ← NOVO
project.godot                    ← +InventoryManager, +WorldFlags
autoloads/game_manager.gd        ← penalidade de morte conectada
scenes/ui/hud/hud.gd             ← +TaelsLabel, +_on_taels_changed
scenes/ui/hud/hud.tscn           ← +TaelsLabel node
```

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
