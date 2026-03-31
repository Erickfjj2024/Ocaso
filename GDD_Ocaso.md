# OCASO — Plano de Arquitetura Técnica
### RPG Dark Fantasy · HD-2D Pixel Art · Godot Engine 4.x

---

## 1. Árvore de Diretórios do Projeto

```
ocaso/
├── project.godot
├── export_presets.cfg
│
├── autoloads/                      # Singletons globais (registrados no project.godot)
│   ├── game_manager.gd             # Orquestrador central: estado do jogo, pause, transições
│   ├── sanity_manager.gd           # Sistema de Sanidade (0-100), dreno, thresholds, eventos
│   ├── lantern_manager.gd          # Durabilidade da lanterna, toggle, área de luz verde
│   ├── inventory_manager.gd        # Inventário do jogador, Taels, add/remove/penalidade
│   ├── scar_tree_manager.gd        # Árvore de Cicatrizes, nós comprados, bloqueios permanentes
│   ├── world_flags.gd              # Flags narrativas (has_murdered, npcs_sacrificados, etc.)
│   ├── event_bus.gd                # Barramento de sinais desacoplado (pub/sub global)
│   ├── audio_manager.gd            # Música, SFX, sons ambientes, manipulação por sanidade
│   └── save_manager.gd             # Serialização/deserialização de save (JSON ou Resource)
│
├── scenes/
│   ├── player/
│   │   ├── player.tscn             # Cena raiz do jogador
│   │   ├── player.gd               # Movimento, input, facing direction, morte
│   │   ├── player_lantern.tscn     # Sub-cena: PointLight2D + Area2D (cone de luz verde)
│   │   ├── player_lantern.gd       # Lógica de toggle, consumo de durabilidade
│   │   ├── player_combat.gd        # Componente de combate (atacar, receber dano)
│   │   └── player_animations.gd    # AnimationPlayer/AnimationTree, sprite states
│   │
│   ├── enemies/
│   │   ├── base/
│   │   │   ├── stalker_base.tscn   # Cena base para todos os Stalkers
│   │   │   ├── stalker_base.gd     # IA base: patrol, chase, light_reaction, backstab
│   │   │   └── stalker_state_machine.gd  # FSM: IDLE → PATROL → CHASE → ATTACK → STUNNED
│   │   ├── variants/               # Variações de Stalkers (herdam de stalker_base)
│   │   │   ├── shadow_crawler.tscn
│   │   │   ├── hollow_watcher.tscn
│   │   │   └── ...
│   │   └── bosses/
│   │       ├── lord_base.tscn      # Cena base dos 12 Lordes
│   │       ├── lord_base.gd        # Multi-Phase: HP check, iframe, pattern swap, arena mod
│   │       ├── lord_state_machine.gd  # FSM de boss: INTRO → PHASE_1 → TRANSITION → PHASE_2
│   │       ├── boss_arena.gd       # Controle da arena (luzes, armadilhas, modificações)
│   │       └── lords/              # Implementação individual de cada Lorde
│   │           ├── lord_01_vermina.tscn
│   │           ├── lord_01_vermina.gd
│   │           ├── lord_05_espelha.tscn
│   │           ├── lord_05_espelha.gd
│   │           └── ...
│   │
│   ├── npcs/
│   │   ├── npc_base.tscn           # NPC genérico com diálogo
│   │   ├── npc_base.gd
│   │   ├── guardian/               # O Falso Guardião (NPC da base)
│   │   │   ├── guardian.tscn
│   │   │   ├── guardian.gd         # Lógica de cura + 10% mimic trigger
│   │   │   └── guardian_mimic.tscn # Boss Mimic (transformação)
│   │   ├── lost_npc.tscn           # NPCs sacrificáveis
│   │   ├── lost_npc.gd             # Lógica de sacrifício → world_flags.has_murdered
│   │   └── guilt_ghost.tscn        # Fantasma do Eco da Culpa (dano puro de Sanidade)
│   │
│   ├── ui/
│   │   ├── hud/
│   │   │   ├── hud.tscn            # HUD principal (vida, sanidade, taels, lanterna)
│   │   │   ├── hud.gd              # Atualização reativa via sinais do EventBus
│   │   │   └── hud_gaslighter.gd   # Componente de mentira: fake HP, inversão, moedas zeradas
│   │   ├── menus/
│   │   │   ├── main_menu.tscn
│   │   │   ├── pause_menu.tscn
│   │   │   ├── inventory_screen.tscn
│   │   │   ├── scar_tree_screen.tscn  # Tela da Árvore de Cicatrizes (visual + interação)
│   │   │   └── game_over_screen.tscn
│   │   └── dialogue/
│   │       ├── dialogue_box.tscn
│   │       └── dialogue_box.gd
│   │
│   ├── world/
│   │   ├── base_hub/               # A base do jogador (safe zone relativa)
│   │   │   ├── base_hub.tscn
│   │   │   └── base_hub.gd
│   │   ├── zones/                  # Zonas exploráveis do mundo
│   │   │   ├── zone_template.tscn  # Template base de zona
│   │   │   ├── zone_01/
│   │   │   │   ├── zone_01.tscn
│   │   │   │   └── zone_01.gd
│   │   │   └── ...
│   │   ├── room_transition.gd      # Transição entre salas/zonas
│   │   └── spawn_manager.gd        # Spawner de inimigos e fantasmas condicionais
│   │
│   └── vfx/
│       ├── sanity_vfx.tscn         # Efeitos visuais de sanidade baixa (distorção, vinheta)
│       ├── lantern_flicker.tscn    # Efeito de lanterna morrendo
│       └── ghost_spawn_vfx.tscn
│
├── resources/
│   ├── items/                      # Resource (.tres) para cada item do jogo
│   │   ├── item_base.gd            # class_name ItemBase extends Resource
│   │   └── ...
│   ├── scar_nodes/                 # Resource para nós da Árvore de Cicatrizes
│   │   ├── scar_node.gd            # class_name ScarNode extends Resource
│   │   └── ...
│   ├── enemy_data/                 # Resource com stats de inimigos
│   │   └── enemy_stats.gd          # class_name EnemyStats extends Resource
│   └── boss_patterns/              # Resource com padrões de ataque dos Lordes
│       └── boss_phase.gd           # class_name BossPhase extends Resource
│
├── assets/
│   ├── sprites/
│   │   ├── player/
│   │   ├── enemies/
│   │   ├── bosses/
│   │   ├── npcs/
│   │   ├── ui/
│   │   ├── tilesets/
│   │   └── vfx/
│   ├── audio/
│   │   ├── music/
│   │   ├── sfx/
│   │   └── ambience/
│   ├── fonts/
│   └── shaders/
│       ├── sanity_distortion.gdshader   # Distorção de tela por sanidade
│       ├── lantern_glow.gdshader        # Luz verde da lanterna
│       ├── darkness_overlay.gdshader    # Escuridão do mundo
│       └── hd2d_depth.gdshader          # Efeito HD-2D (sprites 2D + profundidade)
│
├── data/
│   ├── dialogue/                   # Arquivos de diálogo (JSON ou .tres)
│   ├── scar_tree_definition.json   # Definição completa da árvore (nós, caminhos, bloqueios)
│   └── loot_tables.json            # Tabelas de loot e probabilidade
│
└── tests/                          # Scripts de teste (opcionais, QA)
    ├── test_sanity_drain.gd
    ├── test_scar_tree_lock.gd
    └── test_stalker_ai.gd
```

---

## 2. Hierarquia de Autoloads (Singletons)

Registrados em `Project > Project Settings > Autoload`, carregam antes de qualquer cena.

### 2.1 — `EventBus` (Prioridade: 1ª — carrega primeiro)

Barramento de sinais desacoplado. Nenhum sistema se referencia diretamente — todos publicam e escutam via EventBus.

```
Sinais declarados:
─────────────────────────────────────────────────────────────
SANIDADE
  sanity_changed(new_value: float, delta: float)
  sanity_threshold_crossed(threshold: String)      # "low_30", "critical_15", "zero"
  sanity_restored(amount: float)

LANTERNA
  lantern_toggled(is_on: bool)
  lantern_durability_changed(new_value: float)
  lantern_broken()                                 # Durabilidade chegou a 0
  lantern_force_disabled(source: String)            # Boss desligou a lanterna

COMBATE
  player_damaged(amount: float, source: String)
  player_died()
  enemy_damaged(enemy_id: String, amount: float)
  enemy_killed(enemy_id: String)
  boss_phase_changed(boss_id: String, new_phase: int)

INVENTÁRIO
  item_added(item: ItemBase)
  item_removed(item: ItemBase)
  taels_changed(new_amount: int)

ÁRVORE DE CICATRIZES
  scar_node_purchased(node_id: String, path: String)
  scar_path_locked(path: String)

FLAGS NARRATIVAS
  flag_changed(flag_name: String, value: Variant)
  npc_sacrificed(npc_id: String)
  guilt_ghosts_activated()

GAME STATE
  game_over_triggered(cause: String)
  zone_entered(zone_id: String)
  save_requested()
  load_requested()

GASLIGHTING & GUARDIÃO (adições da Seção 5)
  force_gaslighting(duration: float)
  item_used(item: ItemBase)
  guardian_transformation_started()
  base_lockdown(is_locked: bool)
─────────────────────────────────────────────────────────────
```

### 2.2 — `GameManager` (Prioridade: 2ª)

- Controla estado geral: `PLAYING`, `PAUSED`, `GAME_OVER`, `CUTSCENE`, `MENU`.
- Gerencia transições de cena (`SceneTree.change_scene_to_packed()`).
- Processa lógica de Game Over: retorno à base, penalidade de 50% Taels, remoção de 1-3 itens.
- Escuta `EventBus.player_died` e `EventBus.sanity_threshold_crossed("zero")`.

### 2.3 — `SanityManager` (Prioridade: 3ª)

- `current_sanity: float` (0.0 — 100.0)
- Dreno passivo no escuro: `-X por segundo` (configurável, ex: -5/s).
- Quando lanterna ON → dreno pausado.
- Emite `sanity_changed` a cada frame que houver alteração.
- Detecta thresholds: 30 (efeitos visuais leves), 15 (gaslighting ativado), 0 (Game Over).
- Aplica dano puro de Sanidade (fantasmas do Eco da Culpa).

### 2.4 — `LanternManager` (Prioridade: 4ª)

- `durability: float` (0.0 — 100.0)
- Consumo por segundo quando ON.
- Emite `lantern_toggled`, `lantern_durability_changed`, `lantern_broken`.
- Método `force_disable(source)` → usado por bosses e pelo Falso Guardião.
- Método `force_enable()` → reativa lanterna (usado na Fase 2 do Mimic).
- Método `repair(amount)` → usado pelo NPC Guardião para curar.

### 2.5 — `InventoryManager` (Prioridade: 5ª)

- `items: Array[ItemBase]`
- `taels: int`
- Penalidade de morte: `apply_death_penalty()` → remove 50% taels, 1-3 itens `randi_range(1, 3)`.
- Emite sinais de alteração para a UI reagir.

### 2.6 — `ScarTreeManager` (Prioridade: 6ª)

- Carrega `scar_tree_definition.json` no `_ready()`.
- `purchased_nodes: Dictionary` — mapeia `node_id → true`.
- `locked_paths: Array[String]` — caminhos permanentemente bloqueados.
- Ao comprar um nó, verifica o par mutuamente exclusivo e bloqueia o oposto.
- Dados persistem via `SaveManager` — são **permanentes** (não resetam com morte).

### 2.7 — `WorldFlags` (Prioridade: 7ª)

- `flags: Dictionary` — armazena qualquer flag narrativa.
- Flags críticas pré-definidas:
  - `has_murdered: bool` — ativa spawns de fantasmas do Eco da Culpa.
  - `sacrificed_npcs: Array[String]` — IDs dos NPCs sacrificados.
  - `lords_defeated: Array[String]` — quais dos 12 Lordes foram derrotados.
  - `guardian_mimic_triggered: bool` — se o Mimic já apareceu.

### 2.8 — `AudioManager` (Prioridade: 8ª)

- Gerencia `AudioStreamPlayer` e `AudioStreamPlayer2D`.
- Reage a `sanity_changed` para distorcer música/adicionar sussurros.
- Crossfade entre músicas ao trocar de zona.

### 2.9 — `SaveManager` (Prioridade: 9ª)

- Coleta estado de todos os managers e serializa em JSON.
- `save_game(slot: int)` / `load_game(slot: int)`.
- Caminho: `user://saves/save_slot_X.json`.
- Dados salvos: sanidade, durabilidade, inventário, taels, scar_tree, world_flags, posição.

---

## 3. Diagrama de Classes/Nós e Comunicação

### 3.1 — Filosofia de Comunicação

```
REGRA DE OURO:
  ┌─────────────────────────────────────────────────┐
  │  Chamar PARA BAIXO (filhos), Sinalizar PARA     │
  │  CIMA (pais e sistemas). Nunca referenciar       │
  │  irmãos diretamente.                             │
  │                                                  │
  │  Sistemas globais comunicam-se EXCLUSIVAMENTE    │
  │  através do EventBus.                            │
  └─────────────────────────────────────────────────┘
```

### 3.2 — Cena do Player (player.tscn)

```
Player (CharacterBody2D)
├── player.gd                      # Movimento, input, facing
├── CollisionShape2D               # Hitbox de corpo
├── Sprite2D                       # Sprite pixel art
├── AnimationPlayer                # Animações
├── PlayerLantern (sub-cena)       # ← player_lantern.tscn instanciada
│   ├── PointLight2D               # Luz verde visual
│   ├── Area2D ("LanternCone")     # Detecção: quem está na luz
│   │   └── CollisionShape2D       # Cone/Círculo de alcance
│   └── player_lantern.gd
├── HurtBox (Area2D)               # Onde o player recebe dano
│   └── CollisionShape2D
├── HitBox (Area2D)                # Onde o player causa dano (ataque)
│   └── CollisionShape2D
├── FacingDetector                  # Componente que calcula dot product da direção
│   └── facing_detector.gd         # Emite sinal quando inimigo está "nas costas" por 2s
├── Camera2D                       # Câmera com shake e efeitos de sanidade
└── SanityVFX (CanvasLayer)        # Shaders de distorção vinculados à sanidade
```

**Fluxo de dados do Player:**
- `player.gd` lê input → move o CharacterBody2D.
- `player.gd` calcula `facing_direction` (Vector2) → expõe para `FacingDetector`.
- `PlayerLantern` → ao toggle, emite `EventBus.lantern_toggled(is_on)`.
- `HurtBox` detecta overlap com HitBox inimigo → `EventBus.player_damaged(amount, source)`.
- `SanityManager` escuta `player_damaged` para drenar sanidade em dano de fantasma.

### 3.3 — Cena do Stalker (stalker_base.tscn)

```
StalkerBase (CharacterBody2D)
├── stalker_base.gd
├── CollisionShape2D
├── Sprite2D
├── AnimationPlayer
├── StateMachine (Node)              # stalker_state_machine.gd
│   ├── IdleState
│   ├── PatrolState
│   ├── ChaseState (velocidade 150% no escuro, 30% na luz)
│   ├── AttackState
│   └── StunnedState
├── DetectionZone (Area2D)           # Raio de detecção do player
│   └── CollisionShape2D
├── LightSensor (Area2D)            # Detecta se está dentro do LanternCone do player
│   └── light_sensor.gd             # Escuta overlap com LanternCone
├── BackstabDetector                 # Verifica dot product com facing do player
│   └── backstab_detector.gd        # Timer de 2s → se player de costas, ataque especial
├── HurtBox (Area2D)
├── HitBox (Area2D)
└── NavigationAgent2D               # Pathfinding
```

**Lógica de IA Stalker:**
1. `LightSensor` detecta overlap com `Player/PlayerLantern/LanternCone`:
   - Se dentro → velocidade cai para 30%, estado muda para `StunnedState` ou `ChaseState(slow)`.
   - Se fora → velocidade sobe para 150%.
2. `BackstabDetector` calcula `dot_product(stalker_to_player.normalized(), player_facing)`:
   - Se `dot < 0` (inimigo está atrás do player) por 2 segundos contínuos → `AttackState` ignora luz.
3. Transições de estado controladas pela `StateMachine`, sem referência direta ao Player — usa `DetectionZone` overlaps.

### 3.4 — Cena do Boss / Lorde (lord_base.tscn)

```
LordBase (CharacterBody2D)
├── lord_base.gd                    # HP, multi-phase, iframes
├── CollisionShape2D
├── Sprite2D
├── AnimationPlayer
├── BossStateMachine (Node)
│   ├── IntroState                  # Cutscene de entrada
│   ├── Phase1State                 # Padrões de ataque da fase 1
│   ├── TransitionState             # Aos 50% HP: iframes, animação, arena mod
│   └── Phase2State                 # Padrões de ataque da fase 2
├── AttackPatterns (Node)           # Container de sub-nós com padrões
│   ├── pattern_sweep.gd
│   ├── pattern_projectile.gd
│   └── ...
├── ArenaController                 # boss_arena.gd — modifica o cenário
│   └── arena_effects.gd           # Desligar lanterna, spawnar hazards, etc.
├── HurtBox (Area2D)
├── HitBox (Area2D)
└── BossHealthBar (Control)         # Barra de HP específica do boss
```

**Fluxo de Multi-Phase:**
1. `lord_base.gd` monitora HP.
2. Ao cruzar 50%: `BossStateMachine` → `TransitionState`.
3. `TransitionState`: ativa iframes (`is_invulnerable = true`), emite `EventBus.boss_phase_changed`.
4. `ArenaController` escuta `boss_phase_changed` e executa modificação da arena.
5. Método específico: `ArenaController.disable_player_lantern()` → chama `LanternManager.force_disable("boss")`.

### 3.5 — Cena da UI / HUD (hud.tscn)

```
HUD (CanvasLayer)
├── hud.gd                         # Conecta sinais do EventBus aos elementos visuais
├── hud_gaslighter.gd              # Componente de manipulação (Sanidade < 15)
├── HealthBar (TextureProgressBar)
├── SanityBar (TextureProgressBar)
├── LanternIndicator (TextureRect + Label)
├── TaelCounter (Label)
└── StatusEffects (HBoxContainer)
```

**Gaslighting de UI (hud_gaslighter.gd):**

Escuta `EventBus.sanity_threshold_crossed("critical_15")`:
- **Vida falsa:** `HealthBar.value = max_health` (mostra cheia independente do real).
- **Inversão de controles:** Emite sinal para `player.gd` inverter input (`input_direction *= -1`).
- **Taels zerados:** `TaelCounter.text = "0"` por 2 segundos, depois restaura.
- Ativação/desativação é baseada em timer + random para ser imprevisível.

### 3.6 — Fluxo de Comunicação Geral (Diagrama de Sinais)

```
┌──────────┐        sinal         ┌──────────┐
│  Player   │ ──────────────────► │ EventBus  │
│  Lantern  │  lantern_toggled    │ (global)  │
└──────────┘                      └─────┬─────┘
                                        │
                    ┌───────────────────┼───────────────────┐
                    │                   │                   │
                    ▼                   ▼                   ▼
            ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
            │ SanityManager │   │  Stalker IA  │   │     HUD      │
            │ (pausa dreno) │   │ (reage à luz)│   │ (atualiza UI)│
            └──────────────┘   └──────────────┘   └──────────────┘

┌──────────┐     sinal          ┌──────────┐
│  Stalker  │ ──────────────►   │ EventBus  │
│  Attack   │  player_damaged   │           │
└──────────┘                    └─────┬─────┘
                                      │
                    ┌─────────────────┼─────────────────┐
                    ▼                 ▼                  ▼
            ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
            │ SanityManager │  │     HUD      │  │ AudioManager │
            │ (drena sanity)│  │ (pisca tela) │  │ (som de hit) │
            └──────────────┘  └──────────────┘  └──────────────┘

┌──────────────┐    sinal       ┌──────────┐
│ SanityManager │ ─────────────►│ EventBus │
│               │  threshold    │          │
│               │  "critical_15"│          │
└──────────────┘                └─────┬────┘
                                      │
                    ┌─────────────────┼──────────────────┐
                    ▼                 ▼                   ▼
            ┌──────────────┐  ┌──────────────┐   ┌──────────────┐
            │ HUD Gaslighter│  │   Player     │   │ AudioManager │
            │ (mente na UI) │  │(inverte ctrl)│   │ (sussurros)  │
            └──────────────┘  └──────────────┘   └──────────────┘
```

---

## 4. Fases de Execução

### FASE 1 — Fundação (Esqueleto Jogável)
**Objetivo:** Player anda num mapa escuro, lanterna funciona, sanidade drena.

| # | Tarefa | Detalhes |
|---|--------|---------|
| 1.1 | Criar projeto Godot 4.x | Configurar resolução (pixel-perfect), importar configurações. |
| 1.2 | Implementar Autoloads | `EventBus`, `GameManager`, `SanityManager`, `LanternManager`. Apenas estrutura + sinais. |
| 1.3 | Cena do Player (básica) | CharacterBody2D com movimento 8-dir, sprite placeholder, collider. |
| 1.4 | Sistema de Lanterna | PointLight2D + Area2D. Toggle com input. Consumo de durabilidade. |
| 1.5 | Sistema de Sanidade | Dreno no escuro, pausa na luz. Barra de sanidade na HUD (simples). |
| 1.6 | Mapa de teste | TileMap básico com paredes, escuridão via CanvasModulate + shader. |
| 1.7 | Game Over básico | Sanidade = 0 → tela de game over → reload da cena. |

**Entregável:** Player anda, liga/desliga lanterna, sanidade drena no escuro e para na luz. Morrer reseta.

---

### FASE 2 — Combate e IA Stalker
**Objetivo:** Inimigos reagem à luz e atacam pelas costas.

| # | Tarefa | Detalhes |
|---|--------|---------|
| 2.1 | HitBox/HurtBox system | Sistema genérico de dano com componentes reutilizáveis. |
| 2.2 | Stalker base + FSM | StateMachine: IDLE → PATROL → CHASE → ATTACK → STUNNED. |
| 2.3 | LightSensor | Stalker detecta LanternCone. Velocidade 150% (escuro) / 30% (luz). |
| 2.4 | BackstabDetector | Dot product do facing do player. Timer de 2s. Ataque ignorando luz. |
| 2.5 | NavigationAgent2D | Pathfinding para Stalkers perseguirem o player. |
| 2.6 | Player combat | Ataque básico do player (melee), animação, hitbox ativação por frame. |

**Entregável:** Stalkers patrulham, perseguem, reagem à luz, e atacam pelas costas. Player pode atacar de volta.

---

### FASE 3 — Sistemas de Progressão e Economia
**Objetivo:** Inventário, Taels, Árvore de Cicatrizes, penalidade de morte.

| # | Tarefa | Detalhes |
|---|--------|---------|
| 3.1 | InventoryManager | Array de ItemBase (Resource). Add/remove. UI de inventário. |
| 3.2 | Sistema de Taels | Moeda. Drop de inimigos. Contador na HUD. |
| 3.3 | Penalidade de morte | -50% taels, perda de 1-3 itens aleatórios, retorno à base. |
| 3.4 | Base Hub | Cena da base: ponto de spawn seguro, NPC Guardião (placeholder). |
| 3.5 | Árvore de Cicatrizes | UI visual da árvore. Comprar nó → bloquear caminho oposto. |
| 3.6 | ScarTreeManager | Persistência dos nós comprados e caminhos bloqueados. |
| 3.7 | SaveManager | Salvar/carregar todos os estados. |

**Entregável:** Loop completo: explorar → coletar → morrer → perder → voltar à base → melhorar na árvore.

---

### FASE 4 — Terror Psicológico e Metagame
**Objetivo:** A UI mente, o Guardião trai, os mortos assombram.

| # | Tarefa | Detalhes |
|---|--------|---------|
| 4.1 | HUD Gaslighter | Sanidade < 15: vida falsa, inversão de controles (2-4s), taels zerados, mapa fantasma, cura falsa. |
| 4.2 | Sanity VFX | Shaders: vinheta crescente, distorção cromática, ruído visual. |
| 4.3 | Falso Guardião | 10% chance (se Sanidade < 25, base visitada 3+ vezes): transformação em Mimic Boss. |
| 4.4 | Guardian Mimic Boss | Sequência de 5 beats. Tranca sala, apaga luz, padrões de ataque únicos. Absorve cura do player. |
| 4.5 | NPCs Perdidos | Encontráveis no mundo. Opção de sacrificar → cura lanterna. |
| 4.6 | Eco da Culpa | `has_murdered = true` → fantasmas spawnam aleatoriamente. Dano puro de sanidade. |
| 4.7 | Audio distortion | AudioManager reage à sanidade: pitch bending, sussurros, glitches sonoros. |

**Entregável:** O jogo mente para o player. NPCs são armadilhas morais. Consequências permanentes.

---

### FASE 5 — Os 12 Lordes (Bosses)
**Objetivo:** Sistema de bosses Multi-Phase completo.

| # | Tarefa | Detalhes |
|---|--------|---------|
| 5.1 | lord_base.gd | HP, detecção de 50%, iframes, transição de fase. |
| 5.2 | BossStateMachine | INTRO → PHASE_1 → TRANSITION → PHASE_2, com padrões modulares. |
| 5.3 | ArenaController | Modificação de arena por fase (desligar lanterna, spawnar hazards). |
| 5.4 | Boss Health Bar UI | Barra de vida estilizada com nome do Lorde. |
| 5.5 | Vérmina (Lorde 01) | Boss de atrito: devora cenário, apaga lanterna a cada 20s, poças de ácido. |
| 5.6 | Espelha (Lorde 05) | Boss de confusão: clona player, força gaslighting, inverte sprite. |
| 5.7 | WorldFlags update | Registrar `lords_defeated` após cada vitória. |

**Entregável:** Dois bosses funcionais com duas fases, padrões distintos, e modificação de arena.

---

### FASE 6 — HD-2D, Polimento e Conteúdo
**Objetivo:** Visual HD-2D, efeitos de profundidade, conteúdo final.

| # | Tarefa | Detalhes |
|---|--------|---------|
| 6.1 | Shader HD-2D | Sprites 2D com efeito de profundidade (parallax, iluminação volumétrica). |
| 6.2 | Pixel art final | Substituir todos os placeholders por sprites finais. |
| 6.3 | Tileset e level design | Mapas completos de todas as zonas e arenas de boss. |
| 6.4 | Sistema de diálogo | Caixa de diálogo com portraits, escolhas, integração com WorldFlags. |
| 6.5 | Lordes 02-12 | Implementar os 10 bosses restantes com mecânicas únicas. |
| 6.6 | Variantes de Stalker | Implementar todas as variações de inimigos comuns. |
| 6.7 | Audio & Trilha Sonora | Música ambiente, SFX, trilha dos bosses, manipulação por sanidade. |
| 6.8 | Balanceamento | Ajustar todas as curvas: dreno de sanidade, consumo de lanterna, dano, loot. |
| 6.9 | QA e testes | Rodar scripts de teste, playtest, corrigir edge cases. |

**Entregável:** Jogo completo, polido, com todas as mecânicas do GDD implementadas.

---

## 5. Camada de Game Design e Conteúdo

> *Esta seção expande o plano técnico com a carne do design: sistemas de progressão,
> bosses, manipulação psicológica e a traição do Guardião. Cada elemento mapeia
> diretamente para os scripts e cenas já definidos nas seções 1-4.*

---

### 5.1 — Árvore de Cicatrizes: Caminhos Mutuamente Exclusivos

A árvore é composta por **pares de ramos opostos**. Cada par parte de um nó raiz
compartilhado. Ao comprar o primeiro nó de um ramo, o `ScarTreeManager` executa
`lock_path(opposing_path_id)` e todos os nós do ramo oposto ficam permanentemente
inacessíveis (visual: ficam rachados/apagados na UI).

**Custo:** Cada nó custa Taels + um número crescente de "Fragmentos de Cicatriz"
(drop raro de Stalkers e Lordes derrotados).

#### Caminho 1 — CORPO vs. ESPÍRITO

```
                    [NÓ RAIZ: Marca da Carne]
                     /                    \
          ── CORPO ──                      ── ESPÍRITO ──
          (Bloqueia Espírito)              (Bloqueia Corpo)

CORPO (Caminho A):                    ESPÍRITO (Caminho B):
┌─────────────────────────┐           ┌──────────────────────────┐
│ Nó 1: Pele de Ferro     │           │ Nó 1: Véu Interior      │
│ +20% Vida Máxima        │           │ +15% Sanidade Máxima     │
│                         │           │                          │
│ Nó 2: Sangue Espesso    │           │ Nó 2: Meditação Passiva  │
│ Regenera 1 HP/5s        │           │ Regenera 2 Sanidade/5s   │
│                         │           │ (mesmo no escuro)        │
│ Nó 3: Coração Blindado  │           │                          │
│ Reduz dano recebido 25% │           │ Nó 3: Olho Interior      │
│ mas Sanidade drena 30%  │           │ Vê contorno de Stalkers  │
│ mais rápido no escuro   │           │ no escuro (range curto)  │
│                         │           │ mas -25% Vida Máxima     │
└─────────────────────────┘           └──────────────────────────┘
```

**Dilema de design:** O jogador tanky (Corpo) sobrevive a hits mas enlouquece rápido.
O jogador perceptivo (Espírito) vê os perigos mas morre em poucos golpes.

#### Caminho 2 — LÂMINA vs. MALDIÇÃO

```
                    [NÓ RAIZ: Juramento de Sangue]
                     /                    \
         ── LÂMINA ──                      ── MALDIÇÃO ──
         (Bloqueia Maldição)               (Bloqueia Lâmina)

LÂMINA (Caminho A):                  MALDIÇÃO (Caminho B):
┌─────────────────────────┐           ┌──────────────────────────┐
│ Nó 1: Fio Afiado        │           │ Nó 1: Toque Entrópico   │
│ +30% Dano Melee         │           │ Ataque melee drena 5 de  │
│                         │           │ Sanidade do alvo         │
│ Nó 2: Golpe Faminto     │           │                          │
│ Matar inimigo recupera  │           │ Nó 2: Sífon de Almas    │
│ 5% da Lanterna          │           │ Matar inimigo recupera   │
│                         │           │ 10 de Sanidade           │
│ Nó 3: Execução Brutal   │           │                          │
│ Dano crítico (2x) se    │           │ Nó 3: Praga Rastejante  │
│ inimigo está com <25%HP │           │ Inimigos atingidos ficam │
│ mas cada kill drena 3   │           │ lentos por 3s (mesmo sem │
│ de Sanidade do player   │           │ luz) mas -20% Dano Melee │
└─────────────────────────┘           └──────────────────────────┘
```

**Dilema de design:** O guerreiro (Lâmina) mata rápido mas enlouquece matando.
O ocultista (Maldição) controla o campo mas causa dano fraco.

#### Caminho 3 — LANTERNA vs. SOMBRA

```
                    [NÓ RAIZ: Pacto com a Chama]
                     /                    \
        ── LANTERNA ──                     ── SOMBRA ──
        (Bloqueia Sombra)                  (Bloqueia Lanterna)

LANTERNA (Caminho A):                SOMBRA (Caminho B):
┌─────────────────────────┐           ┌──────────────────────────┐
│ Nó 1: Chama Duradoura   │           │ Nó 1: Olhos da Noite    │
│ -30% consumo de         │           │ Dreno de Sanidade no     │
│ Durabilidade             │           │ escuro reduzido em 40%  │
│                         │           │                          │
│ Nó 2: Pulso Esmeralda   │           │ Nó 2: Passo Silente     │
│ Lanterna emite pulso    │           │ Stalkers demoram 2x mais │
│ a cada 10s que empurra  │           │ para detectar o player   │
│ Stalkers (knockback)    │           │ no escuro                │
│                         │           │                          │
│ Nó 3: Farol Abrasador   │           │ Nó 3: Abraço do Vazio   │
│ Stalkers na luz recebem │           │ Abaixo de 20 Sanidade,  │
│ 2 DPS (dano passivo)    │           │ player fica invisível    │
│ mas raio da lanterna    │           │ por 4s (cooldown 30s)    │
│ reduzido em 40%         │           │ mas Lanterna desliga     │
│                         │           │ automaticamente ao ativar│
└─────────────────────────┘           └──────────────────────────┘
```

**Dilema de design:** O faroleiro (Lanterna) transforma a luz em arma mas perde alcance.
O fantasma (Sombra) abraça a escuridão mas depende de ficar à beira da loucura.

#### Implementação Técnica (scar_tree_definition.json)

```json
{
  "pairs": [
    {
      "root_id": "root_flesh",
      "root_name": "Marca da Carne",
      "path_a": {
        "id": "path_body",
        "name": "Corpo",
        "locks": "path_spirit",
        "nodes": [
          {
            "id": "body_01", "name": "Pele de Ferro",
            "cost_taels": 150, "cost_fragments": 1,
            "effects": [{"stat": "max_health", "modifier": "multiply", "value": 1.2}]
          }
        ]
      },
      "path_b": {
        "id": "path_spirit",
        "name": "Espírito",
        "locks": "path_body",
        "nodes": []
      }
    }
  ]
}
```

O `ScarTreeManager` aplica os `effects` ao comprar, iterando e chamando o sistema
correspondente (ex: `SanityManager.set_max_sanity()`, `player_combat.set_damage_modifier()`).

---

### 5.2 — Design dos Lordes da Ruína (2 de 12)

#### LORDE 01 — VÉRMINA, O Lorde da Fome

**Conceito:** Um ser esquelético gigante feito de ossos entrelaçados, com uma boca
vertical no torso que nunca para de mastigar. Sua arena é um salão de banquete
apodrecido com uma mesa central longa.

**Arquivos:**
- `scenes/enemies/bosses/lords/lord_01_vermina.tscn`
- `scenes/enemies/bosses/lords/lord_01_vermina.gd`
- `resources/boss_patterns/vermina_phase_1.tres`
- `resources/boss_patterns/vermina_phase_2.tres`

**FASE 1 — O Banquete (HP 100%-50%)**

| Padrão | Descrição Técnica |
|--------|------------------|
| Enxame de Vermes | Spawna 3-5 `Area2D` projeteis rastejantes no chão que se movem em onda senoidal (`sin(time * freq) * amplitude`). Dano de contato. Destruíveis com 1 hit. |
| Língua Chicote | Ataque melee de longo alcance. `RayCast2D` frontal, 180° sweep via `AnimationPlayer`. Dano alto, knockback. Telegrafado por 0.8s (brilho vermelho no sprite). |
| Absorver Cadeira | Puxa uma cadeira da mesa (`AnimatedSprite2D`) até si e a devora, recuperando 5% HP. O player pode destruir a cadeira antes (3 hits). Total: 6 cadeiras na arena. |

**TRANSIÇÃO (aos 50% HP)**

1. `BossStateMachine` → `TransitionState`.
2. Vérmina grita — `AudioManager` toca SFX + screen shake (`Camera2D.shake()`).
3. Iframes ativados por 3 segundos.
4. `ArenaController` executa:
   - `destroy_table()`: a mesa central explode em fragmentos (debris estático) que viram obstáculos.
   - `spawn_floor_hazards()`: poças de ácido gástrico (`Area2D` com dano por tick) aparecem onde a mesa estava.
   - `dim_arena_lights(0.3)`: luminosidade ambiente cai 70%, forçando mais dependência da lanterna.

**FASE 2 — A Fome Eterna (HP 50%-0%)**

| Padrão | Descrição Técnica |
|--------|------------------|
| Vômito Ácido | Projétil em arco (`parabolic_trajectory()`). Ao impactar, cria `Area2D` de poça ácida persistente (dura 8s). Limita espaço seguro progressivamente. |
| Frenesi de Mandíbulas | Avança contra o player em dash reto (3x velocidade normal). Se acertar, agarra (disable input por 1.5s) e causa dano massivo. Evitável com dodge lateral. |
| Devorar Lanterna | **Mecânica-chave.** A cada 20s, Vérmina ruge e emite `EventBus.lantern_force_disabled("vermina")`. Lanterna do player apaga por 4 segundos. Durante esse blackout, o dreno de Sanidade é 2x o normal. `LanternManager` escuta e inicia timer de reativação. |
| Invocar Crias | Spawna 2 mini-Stalkers (variante `vermin_spawn.tscn`) que perseguem o player. Desaparecem ao morrer ou quando Vérmina morre. Pool máximo: 4. |

**Condição de vitória:** HP do boss chega a 0. Emite `EventBus.enemy_killed("lord_vermina")` → `WorldFlags` registra em `lords_defeated`.

---

#### LORDE 05 — ESPELHA, A Senhora dos Reflexos

**Conceito:** Uma figura feminina fragmentada como um espelho partido, cada estilhaço
refletindo uma versão distorcida do player. Sua arena é um salão de espelhos octogonal.

**Arquivos:**
- `scenes/enemies/bosses/lords/lord_05_espelha.tscn`
- `scenes/enemies/bosses/lords/lord_05_espelha.gd`
- `resources/boss_patterns/espelha_phase_1.tres`
- `resources/boss_patterns/espelha_phase_2.tres`

**FASE 1 — O Salão dos Reflexos (HP 100%-50%)**

| Padrão | Descrição Técnica |
|--------|------------------|
| Reflexo Falso | Spawna 2 clones visuais do player (`Sprite2D` com shader de espelho). Clones imitam o movimento do player com 0.5s de delay (buffer de posição). Clones causam dano de contato. Destruíveis com 2 hits. Apenas Espelha real recebe dano — player deve distinguir. |
| Lâmina de Vidro | Projéteis retos em 4 direções cardeais a partir dos espelhos nas paredes. `RayCast2D` visual (brilho de laser) por 0.6s como telegraph antes do disparo. |
| Trocar Posição | Espelha troca de posição instantaneamente com um dos clones (tween com `flash_vfx`). Confunde o player sobre quem é o boss real. |

**TRANSIÇÃO (aos 50% HP)**

1. Iframes por 4 segundos.
2. Espelha "parte" — sprite fragmenta (efeito de shatter via shader).
3. `ArenaController` executa:
   - `shatter_mirrors()`: os 8 espelhos da arena se quebram. Cacos no chão viram `Area2D` de dano ao pisar.
   - `activate_sanity_drain_field()`: a arena inteira emite dreno de Sanidade passivo (-3/s adicional). A lanterna NÃO bloqueia esse dreno — é dano ambiental.
   - `invert_player_sprite()`: via `EventBus`, o `player_animations.gd` recebe sinal para flippar o sprite horizontalmente por toda a Fase 2, desorientando o jogador.

**FASE 2 — Estilhaços de Identidade (HP 50%-0%)**

| Padrão | Descrição Técnica |
|--------|------------------|
| Chuva de Estilhaços | Projéteis caem do teto em posições semi-aleatórias (grid 3x3, 2 células escolhidas por tick). Shadow marker no chão 1s antes do impacto. |
| Roubo de Face | Espelha assume o sprite exato do player por 6 segundos. O boss e o player ficam visualmente idênticos. A câmera dá um zoom-out sutil para que o jogador não perca seu personagem. Hitbox do boss permanece maior (pista sutil). |
| Quebra de UI | **Mecânica-chave.** Espelha emite `EventBus.force_gaslighting(5.0)`, forçando o `hud_gaslighter.gd` a ativar MESMO se a sanidade real estiver acima de 15. Duração: 5 segundos. Cooldown: 20 segundos. |
| Duplicação Final | Abaixo de 20% HP, spawna 4 clones simultaneamente. Todos causam dano. Todos morrem em 1 hit. O real está entre eles. Pista: o real não pisa nos cacos sem tomar dano (animação de flutuar). |

**Condição de vitória:** Emite `EventBus.enemy_killed("lord_espelha")` → `WorldFlags`.

---

### 5.3 — Expansão do Gaslighting de UI (hud_gaslighter.gd)

O plano original define 3 manipulações (vida falsa, inversão de controles, taels
zerados). Abaixo estão **2 novas mecânicas** que ampliam o terror psicológico sem
exigir novos Autoloads.

#### Manipulação 4 — O Mapa Fantasma (Falso Indicador de Inimigo)

**Conceito:** Quando Sanidade < 15, a HUD exibe indicadores de proximidade de inimigo
(setas vermelhas pulsantes na borda da tela) apontando para direções onde **não há
nenhum inimigo**.

**Implementação técnica:**

```
Componente: hud_gaslighter.gd → função _spawn_phantom_indicator()

Trigger:
  EventBus.sanity_threshold_crossed("critical_15")

Lógica:
  1. Timer aleatório (8-15s de intervalo entre aparições).
  2. Gera um Vector2 de direção aleatória que NÃO coincide com a
     posição real de nenhum Stalker ativo (consulta via grupo "stalkers"
     no SceneTree → get_nodes_in_group("stalkers") → calcula ângulos
     → escolhe ângulo com delta > 45° de qualquer inimigo real).
  3. Instancia um Control node temporário na borda da HUD:
     - TextureRect com seta vermelha pulsante (AnimationPlayer: scale
       pulse + alpha oscillation).
     - Posição angular na borda da tela via polar_to_cartesian().
  4. Duração: 3-5 segundos. Fade out suave.
  5. AudioManager emite SFX sutil de "presença" (sussurro direcional
     via AudioStreamPlayer2D posicionado na direção falsa).

Mitigação anti-frustração:
  - Máximo 1 indicador fantasma por vez.
  - Se um inimigo REAL se aproximar durante o indicador falso, o
    indicador some imediatamente (não compete com ameaças reais).
  - Cooldown de 20s após cada aparição.
```

#### Manipulação 5 — A Cura Falsa (Fake Sanity Recovery)

**Conceito:** A barra de Sanidade na HUD exibe uma animação de recuperação rápida
mas o valor real no `SanityManager` não muda. A barra volta ao valor real após 3
segundos com um glitch visual.

**Implementação técnica:**

```
Componente: hud_gaslighter.gd → função _fake_sanity_recovery()

Trigger:
  Sanidade < 15 há pelo menos 10s (evita trigger imediato)

Lógica:
  1. Desconecta temporariamente o SanityBar do sinal real sanity_changed.
  2. Tween no SanityBar.value: de valor atual até valor fake (ex: 65).
     Duração: 1.5s, ease OUT_CUBIC.
  3. AudioManager toca SFX de cura (mesmo som que a cura real).
  4. Flash verde via SanityVFX.
  5. Após 3s: shader de ruído branco por 0.3s, tween instantâneo de
     volta ao valor real, SFX de distorção.
  6. Reconecta o SanityBar ao sinal real.

Mitigação anti-frustração:
  - Máximo 1 vez por crise de sanidade. Reseta quando Sanidade > 30.
  - Cancela se o jogador usar item de cura REAL durante a fake.
```

#### Tabela Completa de Gaslighting

| # | Manipulação | Trigger | Duração | Cooldown | Max/Sessão |
|---|------------|---------|---------|----------|------------|
| 1 | Vida Falsa (HP cheio) | Sanidade < 15 | 2-4s | 15s | Ilimitado |
| 2 | Inversão de Controles | Sanidade < 15 | 2-4s | 20s | Ilimitado |
| 3 | Taels Zerados (visual) | Sanidade < 15 | 2s | 10s | Ilimitado |
| 4 | Mapa Fantasma (seta falsa) | Sanidade < 15 | 3-5s | 20s | Ilimitado |
| 5 | Cura Falsa de Sanidade | Sanidade < 15 (10s+) | 4.5s | — | 1x por crise |

**Scheduler interno:** Timer principal (6-12s aleatório), sorteia manipulação com pesos:
Vida Falsa (3), Inversão (2), Taels (3), Mapa Fantasma (2), Cura Falsa (1).
Nunca dispara 2 simultaneamente.

---

### 5.4 — O Falso Guardião: Design Completo da Traição

#### Contexto Narrativo

O Guardião é um NPC chamado **Eloah**. Aparenta ser um velho curandeiro cego que
vive na Base Hub, sentado ao lado de um altar com uma chama verde. Ele é o ÚNICO
NPC que pode reparar a durabilidade da lanterna.

#### Trigger da Transformação

```
Arquivo: scenes/npcs/guardian/guardian.gd
Função: _on_player_interact()

Condições (TODAS devem ser verdadeiras):
  1. SanityManager.current_sanity < 25
  2. randf() < 0.10 (10% de chance)
  3. WorldFlags.get_flag("guardian_mimic_triggered") == false
  4. WorldFlags.get_flag("base_visits") >= 3
```

#### Sequência de Transformação (5 Beats)

```
BEAT 1 — A ISCA (2s): Cura normal inicia. Lanterna REALMENTE começa a ser curada.

BEAT 2 — O SINAL (1.5s): Animação trava. Música corta (seco). Texto glitchado.
  Input bloqueado (GameManager.state = CUTSCENE).

BEAT 3 — O APAGÃO (1s): Lanterna apaga. CanvasModulate → preto. Portas trancam.
  Cura da lanterna é REVERTIDA.

BEAT 4 — A TRANSFORMAÇÃO (2s): Shader morph de Eloah → Mimic.
  guardian.tscn → queue_free() → instancia guardian_mimic.tscn.
  SanityManager.apply_damage(15, "guardian_betrayal").

BEAT 5 — O COMBATE: Input liberado. Mimic entra em Phase1.
```

#### Guardian Mimic — Padrões de Combate

**FASE 1 — No Escuro (HP 100%-40%)**

| Padrão | Descrição Técnica |
|--------|------------------|
| Garras Cegas | 3 swipes em arco. Rápido (0.3s entre golpes). Telegraph sonoro (0.4s). |
| Grito Parasita | AoE circular. Drena 10 de Sanidade (sem dano físico). |
| Cura Vampírica | Se player usa item de cura, Mimic recupera o DOBRO. Escuta `EventBus.item_used`. |

**TRANSIÇÃO (40% HP):** Lanterna reativa automaticamente (20% durabilidade). Luzes da base voltam a 50%.

**FASE 2 — A Fuga (HP 40%-0%)**

| Padrão | Descrição Técnica |
|--------|------------------|
| Mimetismo de Cura | Assume pose de cura de Eloah. Armadilha se player se aproxima. |
| Corrida nas Paredes | Escala paredes, dive attack com shadow marker. 200% velocidade. |
| Abrir a Porta | Abaixo de 15% HP, destrava UMA porta e tenta fugir. 4s para matar. |

**Consequências:**
- Vitória: Drop "Olho de Eloah" (revela Stalkers no escuro). Eloah nunca reaparece. Altar funciona sem NPC.
- Derrota: Game Over normal. Eloah reaparece na base. Evento pode repetir. Fala sutil: "Teve um pesadelo?"

---

## 6. Direção de Arte — Visual Bible

> *Este guia é a lei visual de Ocaso. Todo asset, tileset, shader e decisão de
> level design deve ser validado contra estas regras. O objetivo é um mundo que
> pareça estar DOENTE — não apenas escuro, mas infectado por algo que não deveria
> existir.*

---

### 6.1 — A Paleta da Ruína

O mundo de Ocaso opera com **três forças cromáticas** em conflito permanente.
Nenhuma cor existe sozinha — ela sempre está em tensão com as outras duas.

#### As Três Forças

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   VERDE RADIOATIVO          ROXO PROFUNDO         PRETO ABSOLUTO│
│   (Vida / Corrupção)        (Cosmos / Loucura)    (Vazio / Morte│
│                                                                 │
│   A lanterna. A esperança   O céu. A névoa.       A escuridão   │
│   doentia. O parasita       Os tentáculos. O      real. Onde os │
│   dentro do vidro.          que olha de cima.     Stalkers vivem│
│                                                                 │
│   Hex primário: #39FF14     Hex primário: #2D1B4E Hex: #000000  │
│   Hex glow:     #7FFF00     Hex névoa:    #4A2875 (sem variação)│
│   Hex doentio:  #ADFF2F     Hex carne:    #6B3FA0              │
│   Hex parasita: #00FF41     Hex sangue:   #1A0A2E              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

#### Paleta Secundária (Materiais do Mundo)

| Material | Hex Base | Hex Highlight (na luz) | Hex Shadow | Notas |
|----------|----------|----------------------|------------|-------|
| Pedra Gótica | `#2C2C34` | `#3D4A3A` (tinge verde) | `#0D0D10` | Paredes, pilares, arcos |
| Madeira Podre | `#3B2F2F` | `#4A3D2E` | `#1A1210` | Cais, portas, móveis |
| Água Pantanosa | `#0A1A0F` | `#1A3A1F` (reflexo verde) | `#050D08` | Canais, poças, docks |
| Metal Enferrujado | `#5C3A2A` | `#6E4E38` | `#2D1A14` | Grade, correntes, lanterna |
| Carne Cósmica | `#4A1A3A` | `#6B2A5A` (pulsa roxo) | `#2A0A1A` | Tentáculos, biomassa |
| Osso Antigo | `#D4C8A0` | `#E0D8B0` | `#8A7E60` | Esqueletos, Vérmina |

#### Regras de Aplicação Cromática

**REGRA 1 — A Hierarquia da Luz:**
Nada no mundo possui luz própria exceto a lanterna do player e fontes
narrativamente justificadas (altar do Guardião, olhos dos Lordes). Toda
iluminação de tileset é RECEBIDA, nunca EMITIDA. Artistas nunca desenham
highlights "pintados" nos tiles — os highlights vêm do PointLight2D da engine.

**REGRA 2 — Verde Contamina, Roxo Corrompe:**
Quando a luz verde da lanterna toca uma superfície, ela não a ilumina de forma
limpa. A cor resultante deve parecer uma INFECÇÃO. Tiles devem ter normal maps
sutis para que a luz verde grude nas rachaduras e fissuras. Quando o roxo
(ambiente, céu) é a fonte, a superfície parece VIVA — veias púrpura pulsam
nas pedras, a água borbulha.

**REGRA 3 — O Preto Não É Vazio:**
O preto (`#000000`) do CanvasModulate é absoluto. Porém, na fronteira entre
luz e escuridão (o "limiar"), os artistas devem garantir que os tiles tenham
detalhes sutis visíveis a 10-15% de opacidade: olhos que brilham no breu,
veios púrpura na pedra, reflexos mínimos na água. Isso cria a sensação de
que algo ESTÁ na escuridão, mesmo quando a engine está renderizando preto.

---

### 6.2 — Diretrizes para Assets (Tilesets e Props)

#### Resolução e Grid

```
Resolução de tile:    16x16 pixels (base)
Sprites de Props:     16x16, 16x32, 32x32 (múltiplos do grid)
Sprite do Player:     16x32 (personagem alto, silhueta vertical)
Sprites de Stalkers:  16x24 a 24x32 (variados, sempre menores que bosses)
Sprites de Lordes:    32x48 a 64x64 (imponentes, dominam a tela)
Escala de renderização: x3 ou x4 (viewport stretch, pixel-perfect)
```

#### Como Desenhar para Luz Dinâmica

Cada tileset precisa de **3 camadas** de textura para reagir bem à
iluminação do Godot 4:

```
1. DIFFUSE (Sprite2D base)
   ─────────────────────────────────
   A cor "real" do material. Desenhada ESCURA (como se estivesse em
   sombra parcial). Sem highlights pintados. Os valores de brilho
   do diffuse nunca devem ultrapassar 40% luminosidade no HSV.
   
   Razão: a PointLight2D do Godot SOMA luz ao diffuse. Se o diffuse
   já for claro, a luz ficará estourada (washed out).

2. NORMAL MAP (gerado ou pintado)
   ─────────────────────────────────
   Obrigatório para: paredes de pedra, madeira com veios, água,
   qualquer superfície com textura tátil.
   
   Geração: Usar ferramenta como Laigter (grátis) ou sprite-lamp
   para gerar normal maps a partir do diffuse. A PointLight2D do
   Godot usa o normal map para calcular onde a luz verde "gruda"
   nas rachaduras e saliências.
   
   Aplicação: No Sprite2D ou TileSet, ativar CanvasItem > Material
   > CanvasItemMaterial > light_mode = "Normal". Atribuir normal
   map na textura.

3. OCCLUDER (LightOccluder2D)
   ─────────────────────────────────
   Todo objeto sólido (paredes, pilares, móveis, barris) DEVE ter
   um LightOccluder2D com polígono manual que defina seu contorno.
   
   Regra: O occluder deve ser levemente MAIOR que o sprite (1-2px)
   para criar sombras grossas e pesadas. Sombras finas parecem
   técnicas; sombras grossas parecem opressivas.
   
   Otimização mobile: Usar polígonos simples (4-8 vértices max).
   Evitar formas côncavas quando possível.
```

#### Integração Cósmica na Arquitetura Gótica

O horror cósmico não é decoração — é INVASÃO. Elementos orgânicos alienígenas
devem parecer estar CRESCENDO a partir da arquitetura, não colocados sobre ela.

```
COMO FAZER:                           COMO NÃO FAZER:
──────────────────────────────────     ──────────────────────────────
Um tentáculo SAINDO de dentro          Um tentáculo SOBRE uma parede
de uma rachadura numa parede.          como se fosse um adesivo.

Biomassa SUBSTITUINDO tijolos          Biomassa flutuando ao lado de
na parte inferior de um muro,          uma construção sem ponto de
como se comesse a alvenaria.           contato.

Olhos EMBUTIDOS na argamassa           Olhos desenhados numa
entre pedras, como se a parede         superfície lisa. Parecem
estivesse viva e observando.           pintados, não orgânicos.

Tentáculos colossais que               Tentáculo aleatório no
ESMAGARAM uma torre de sino —          cenário sem interação com
debris de pedra caída ao redor,        a arquitetura ao redor.
rachadura estrutural visível.
```

**Regra dos 3 Estágios de Invasão (por zona):**

| Estágio | Descrição | Exemplo Visual |
|---------|-----------|----------------|
| 1 — Sussurro | Paredes com veios roxos sutis, musgo bioluminescente em cantos, água com borbulhas estranhas. O player pode nem perceber na primeira vez. | Zona 01 (vila) |
| 2 — Infestação | Tentáculos médios saem de rachaduras, olhos nas paredes piscam quando iluminados, o chão pulsa em seções. Props orgânicos substituem props normais (mesa de carne em vez de madeira). | Zonas intermediárias |
| 3 — Dominação | Arquitetura quase totalmente consumida. Paredes são mais carne que pedra. O céu é visível e nele há silhuetas colossais. Tiles de chão têm heartbeat (shader de pulsação). O mundo é o monstro. | Zonas finais / arenas de Lordes |

---

### 6.3 — Design de Silhuetas (Inimigos vs. Protagonista)

A escuridão é o estado padrão de Ocaso. Antes de ver detalhes, o jogador vê
SILHUETAS. A leitura instantânea de "o que é isso?" à distância de 3-5 tiles
é questão de vida ou morte.

#### O Protagonista (O Portador) — Silhueta Inconfundível

```
                    ████
                   ██████         ← Chapéu de abas largas: forma
                  ████████           horizontal ÚNICA no jogo.
                   ██████            Nenhum inimigo tem chapéu.
                    ████
                   ██████
                  ████████
                 ██  ██  ██       ← Sobretudo esfarrapado: bordas
                ██  ████  ██        irregulares (pixels soltos nas
               ██  ██████  ██      pontas simulando tecido rasgado)
              ██    ████    ██
             ██      ██      ██
            ████     ██     ████
           ██████    ██    ██████
  CUTELO→ ████████   ██   ████████ ← LANTERNA
          ████████   ██     ██████
                     ██
                    ████
                   ██  ██
                  ██    ██
```

**Regras de silhueta do protagonista:**
- O chapéu cria uma linha horizontal que nenhuma outra entidade possui.
- O cutelo na mão esquerda é largo e reto (não curvado como garras de inimigos).
- A lanterna na mão direita é o único ponto brilhante no sprite — sempre emite
  glow verde mesmo quando a luz mecânica (PointLight2D) está desligada (apenas o
  sprite brilha, como um LED fraco de 2x2 pixels).
- Em idle, o sobretudo balança sutilmente (2 frames de animação, pontas do tecido).

#### Os Stalkers — Terror na Fronteira da Luz

Os Stalkers são desenhados para serem **ambíguos no escuro e aterrorizantes na luz**.

```
REGRA DE DESIGN DOS STALKERS:

NO ESCURO (silhueta apenas):
  - Forma vagamente humanoide mas ERRADA.
  - Proporções distorcidas: braços longos demais, cabeça pequena
    demais ou grande demais, costas arqueadas.
  - Movimentação: idle animation com micro-twitches (1-2 pixel shifts
    aleatórios a cada 0.5s). Parecem estar vibrando.
  - O jogador deve pensar: "É uma pessoa? É uma estátua? Está se
    movendo?"

NA LUZ VERDE (detalhes revelados):
  - O ROSTO é o ponto focal do horror. Cada variante de Stalker tem
    um rosto projetado para ser a primeira coisa que o jogador vê
    quando a luz os atinge:
    
    Shadow Crawler: Rosto SEM OLHOS. Boca aberta em grito perpétuo.
    Buracos negros onde eram os olhos. Quando iluminado, pixels de
    "lágrimas pretas" escorrem (2 frames de animação).
    
    Hollow Watcher: Rosto com MUITOS OLHOS (5-7 olhos pequenos
    espalhados pelo crânio). Todos viram na direção do player quando
    iluminados. Shader simples: calcula ângulo player→stalker,
    ajusta UV dos olhos.
    
  - Paleta de cores dos Stalkers:
    Pele/corpo:   #1A1A2E (quase preto-azulado)
    Detalhes:     #3D1A4A (roxo escuro para veios, garras)
    Olhos/boca:   #000000 (preto puro) ou #FF3333 (vermelho doentio)
    Reação à luz: Quando na LanternCone, um shader de RIM LIGHT
                  verde (#39FF14, 20% opacity) contorna o sprite,
                  fazendo a criatura parecer "radioativa".
```

#### Contraste Visual (Tabela de Leitura Rápida)

| Elemento | Largura Silhueta | Altura | Forma Dominante | Identificador Único |
|----------|-----------------|--------|-----------------|---------------------|
| Player | Média (chapéu largo) | Alta (32px) | Horizontal (chapéu) + Vertical (corpo) | Brilho verde constante |
| Shadow Crawler | Estreita | Baixa (24px) | Horizontal (rasteja) | Movimentação rente ao chão |
| Hollow Watcher | Média | Alta (28px) | Vertical (parado, reto) | Imóvel até detectar player |
| Vérmina (Boss) | Muito larga | Muito alta (48px) | Massa irregular | Boca vertical brilha roxo |
| Espelha (Boss) | Média | Alta | Fragmentada (borda pixelada) | Reflexo/espelhamento |

---

### 6.4 — A Regra da Sombra (Level Design Visual)

Estas 3 regras governam como os level designers posicionam geometria nos mapas
para que a engine do Godot 4 crie bolsões de terror naturalmente.

#### REGRA 1 — O Corredor Estrangulado

```
CONCEITO: Vielas e corredores devem ser estreitos o suficiente para que
a lanterna ilumine AMBAS as paredes, mas com pilares ou detritos no meio
que FRAGMENTAM a luz, criando sombras atrás deles.

IMPLEMENTAÇÃO:
  Largura do corredor: 3-4 tiles (48-64px reais).
  Lanterna raio: ~5 tiles.
  
  ████████████████████████████████████
  ██                                ██
  ██    ▓▓    ← pilar com           ██
  ██    ▓▓      LightOccluder2D     ██
  ██                                ██
  ██         ☼ → Player com luz     ██
  ██                                ██
  ██    ▓▓    ← outro pilar         ██
  ██    ▓▓                          ██
  ██                                ██
  ████████████████████████████████████
  
  Resultado: A luz passa entre os pilares mas projeta sombras cônicas
  ATRÁS de cada um. Stalkers podem se esconder nessas sombras e avançar
  quando o player muda de direção (dot product + backstab).
  
  Regra derivada: Nunca colocar menos de 2 occluders num corredor.
  Um pilar sozinho não cria tensão. Dois criam múltiplos ângulos cegos.
```

#### REGRA 2 — A Encruzilhada Cega

```
CONCEITO: Interseções em T ou em cruz onde a lanterna só ilumina UM
caminho de cada vez. O jogador PRECISA escolher para onde apontar a
luz, sabendo que os outros caminhos estão em escuridão total.

IMPLEMENTAÇÃO:
  
         ████    ████
         ██        ██
         ██   ??   ██        ← Caminho Norte (escuro)
         ██        ██
  ████████          ████████
  ??                      ??  ← Caminho Oeste (escuro) / Leste (escuro)
  ████████    ☼     ████████
         ██  ↑     ██
         ██ Player ██        ← Caminho Sul (iluminado)
         ██        ██
         ████████████
  
  O raio da PointLight2D revela ~5 tiles à frente. Os 3 caminhos
  perpendiculares ficam totalmente escuros. As paredes da interseção
  funcionam como LightOccluders naturais.
  
  Regra derivada: Pelo menos 1 em cada 3 encruzilhadas deve ter um
  Stalker posicionado em patrol no caminho que o player NÃO está
  iluminando. Isso condiciona o medo de TODA encruzilhada.
```

#### REGRA 3 — O Teatro de Escombros

```
CONCEITO: Áreas abertas (praças, salões, docas) são MAIS perigosas que
corredores porque a luz da lanterna se dispersa e não atinge as bordas.
Destroços espalhados criam "ilhas de sombra" no meio do espaço aberto.

IMPLEMENTAÇÃO:
  
  ████████████████████████████████████████████
  ██                                        ██
  ██   ░░░░                    ▓▓▓▓         ██
  ██   ░░░░ ← carroça          ▓▓▓▓ ← muro  ██
  ██   ░░░░   tombada           partido      ██
  ██                                        ██
  ██              ☼ Player                  ██
  ██                                        ██
  ██        ▓▓                              ██
  ██        ▓▓ ← barril           ░░░░      ██
  ██        ▓▓   empilhado        ░░░░ ← cais██
  ██                              ░░░░  partido║
  ██                                        ██
  ████████████████████████████████████████████
  
  Cada prop/destroço tem LightOccluder2D. A luz do player projeta
  sombras longas e angulares atrás de cada obstáculo. As "ilhas de
  sombra" são espaços entre obstáculos onde a luz não chega.
  
  Regra derivada: Em áreas abertas, o artista de level design deve
  posicionar destroços de forma que NENHUM ponto da área esteja a
  mais de 3 tiles de uma sombra projetada. O player nunca deve se
  sentir "seguro" numa área aberta.
  
  Spawn rule: Stalkers em áreas abertas patrulham ENTRE os destroços,
  usando as ilhas de sombra como cobertura. NavigationAgent2D com
  waypoints posicionados nos pontos mais escuros.
```

---

### 6.5 — Conceitos de Shaders e VFX

#### VFX 1 — Reflexo Verde na Água (lantern_water_reflect.gdshader)

**Descrição visual:** Quando a lanterna ilumina água (tiles com tag "water"),
a superfície exibe um reflexo vertical distorcido da luz verde, ondulando
lentamente como se algo se mexesse debaixo d'água.

**Implementação Godot 4:**

```
Tipo: ShaderMaterial aplicado nos tiles de água (Sprite2D ou TileMap layer).

Lógica do shader:
  - Input: posição do player (uniform vec2 light_pos), intensidade
    da lanterna (uniform float light_intensity).
  - Calcula distância do fragmento ao light_pos.
  - Se dentro do raio: aplica cor verde (#39FF14) com falloff
    quadrático (mais forte perto, fraco longe).
  - Distorção: UV.y oscila com sin(TIME * 2.0 + UV.x * 10.0) * 0.02
    para criar ondulação.
  - Reflexo: inverte a componente Y do fragmento para simular reflexão
    vertical, com alpha de 30%.
  - Opcionalmente: noise texture animada (Perlin) para simular
    algo se movendo sob a superfície.

Performance mobile:
  - Shader roda apenas em tiles visíveis na viewport.
  - Complexidade: baixa (apenas operações de fragmento, sem vertex
    displacement). ~15 instruções.
```

#### VFX 2 — Névoa Volumétrica Roxa (purple_fog.gdshader)

**Descrição visual:** Névoa roxa semi-transparente que paira sobre o mundo,
mais densa nas bordas da tela e nas zonas mais distantes da lanterna.
Lentamente ondula e pulsa, como se respirasse.

**Implementação Godot 4:**

```
Tipo: CanvasLayer com Sprite2D fullscreen + ShaderMaterial.
Camada: acima dos tiles, abaixo da UI (z_index entre world e HUD).

Lógica do shader:
  - Base: cor roxa (#2D1B4E) com alpha variável.
  - Densidade: mapeada pela distância ao centro da tela (vinheta).
    Mais densa nas bordas (alpha 0.4), quase invisível no centro
    (alpha 0.05).
  - Reação à lanterna: quando lanterna ON, o ponto ao redor do
    player "limpa" a névoa (alpha → 0 num raio de ~3 tiles).
    Quando OFF, a névoa avança e cobre tudo (alpha 0.5 uniform).
  - Animação: UV offset baseado em TIME para scroll lento da
    textura de noise (FBM noise, 2 octaves). Velocidade: ~5px/s.
  - Pulsação: alpha global oscila com sin(TIME * 0.5) * 0.05
    para simular "respiração".
  - Interação com sanidade: SanityManager passa valor de sanidade
    como uniform. Sanidade < 30: névoa fica mais VERMELHA
    (mix com #4A0A2A). Sanidade < 15: névoa pulsa mais rápido
    (frequência dobra).

Performance mobile:
  - Texture de noise: pré-calculada (256x256, tileable). Não gerar
    noise em runtime.
  - Um único fullscreen quad. ~20 instruções de fragmento.
```

#### VFX 3 — Distorção de Sanidade (sanity_distortion.gdshader)

**Descrição visual:** Conforme a sanidade cai, a tela inteira começa a
sofrer distorções progressivas: aberração cromática sutil, ondulação
nas bordas, e nos extremos, "rasgos" na realidade onde o roxo cósmico
sangra para dentro da tela.

**Implementação Godot 4:**

```
Tipo: CanvasLayer com ColorRect fullscreen + ShaderMaterial.
Camada: acima de TUDO (inclusive HUD) — a distorção é metalinguística.

3 estágios progressivos controlados por uniform float sanity (0.0-1.0):

ESTÁGIO 1 — Sanidade 30-50 (sutil, subliminar):
  - Aberração cromática leve: deslocamento de 1-2px nos canais R e B
    em direções opostas. O jogador pode nem perceber conscientemente.
  - Implementação: SCREEN_TEXTURE sampled 3x com UV offsets mínimos
    por canal.

ESTÁGIO 2 — Sanidade 15-30 (perturbador):
  - Vinheta pulsante: bordas escurecem e clareiam com sin(TIME).
  - Ondulação: UV.x e UV.y distorcidos por sin() com amplitude
    crescente conforme sanidade cai. O mundo parece "respirar".
  - Grain: noise texture multiplicada sobre a tela (alpha 0.1).
    Simula filme antigo/estática.

ESTÁGIO 3 — Sanidade 0-15 (horror total):
  - Todos os efeitos anteriores amplificados.
  - "Rasgos de realidade": linhas verticais aleatórias onde a
    textura da tela é substituída por cor roxa (#4A2875) pura
    por 0.1s. Parecem glitches de TV.
  - Flash frames: a cada 5-10s, a tela inteira fica branca por
    1 frame (0.016s). Simula relâmpago ou pulso cósmico.
  - O shader comunica com AudioManager para sincronizar glitches
    visuais com distorções sonoras (via sinal do SanityManager).

Performance mobile:
  - SCREEN_TEXTURE é caro. Usar HINT_SCREEN_TEXTURE com redução
    de resolução (0.5x) para o fullscreen pass.
  - Noise: pré-calculada (128x128). ~30 instruções no estágio 3,
    ~10 no estágio 1.
  - Pode ser desabilitado nas opções de acessibilidade (toggle
    "Reduzir efeitos visuais de sanidade").
```

#### Tabela de Shaders do Projeto

| Shader | Arquivo | Onde Aplicar | Custo GPU |
|--------|---------|-------------|-----------|
| Reflexo na Água | `lantern_water_reflect.gdshader` | Tiles com tag "water" | Baixo (~15 inst) |
| Névoa Roxa | `purple_fog.gdshader` | CanvasLayer fullscreen | Baixo (~20 inst) |
| Distorção de Sanidade | `sanity_distortion.gdshader` | CanvasLayer fullscreen | Médio (~30 inst max) |
| Glow da Lanterna | `lantern_glow.gdshader` | PlayerLantern Sprite | Baixo (~10 inst) |
| HD-2D Depth | `hd2d_depth.gdshader` | Props com profundidade | Baixo (~12 inst) |
| Escuridão Base | `darkness_overlay.gdshader` | CanvasModulate global | Nenhum (nativo) |

---

## Apêndice A — Convenções Técnicas

| Aspecto | Convenção |
|---------|-----------|
| Nomenclatura GDScript | `snake_case` para variáveis/funções, `PascalCase` para classes/nós |
| Sinais | Sempre via `EventBus` para comunicação cross-sistema |
| Resources (.tres) | Usado para dados estáticos (itens, stats, padrões de ataque) |
| Export vars | Usar `@export` em tudo que for ajustável por designers |
| Collision Layers | Layer 1: World, Layer 2: Player, Layer 3: Enemies, Layer 4: Lantern, Layer 5: HitBoxes, Layer 6: HurtBoxes |
| State Machines | Pattern: Node pai com filhos State, cada um com `enter()`, `exit()`, `update()`, `physics_update()` |
| Resolução Pixel Art | 16px grid base, viewport stretch x3/x4, filtro nearest neighbor |
| Normal Maps | Obrigatórios em todos os tilesets de superfície (pedra, madeira, água) |
| LightOccluders | Obrigatórios em todo prop sólido, polígonos 4-8 vértices max (mobile) |

## Apêndice B — Riscos Técnicos Identificados

| Risco | Mitigação |
|-------|-----------|
| Dot product de costas falhar em diagonais | Usar threshold de `< -0.3` em vez de `< 0` para margem de erro |
| Gaslighting de UI causar frustração excessiva | Limitar duração (2-4s), cooldown entre eventos, feedback sutil pós-mentira |
| Mimic Boss na base causar soft-lock | Garantir que o player sempre possa fugir após 30s OU morrer e respawnar |
| Árvore de Cicatrizes irreversível gerar arrependimento | Tela de confirmação dupla antes de bloquear um caminho |
| Performance com muitos fantasmas (Eco da Culpa) | Pool de objetos, limite máximo de 3 fantasmas simultâneos |
| Cura Falsa confundir sobre item gasto | Nunca ativa quando player usa item real — só via timer passivo |
| Mapa Fantasma coincidir com inimigo real | Algoritmo garante delta > 45° angular de qualquer Stalker ativo |
| Guardian Mimic Fase 1 (escuro total) injusto | Telegraph sonoro claro (0.4-0.8s), AoE visual mesmo no escuro |
| Player sem lanterna E sanidade durante Mimic | CanvasModulate clamp em 0.15 se Sanidade chegar a 5 durante fight |
| Mimic fugir sem player perceber | SFX alto + texto na HUD: "Ele está fugindo!" |
| SCREEN_TEXTURE pesado em mobile | HINT_SCREEN_TEXTURE com resolução 0.5x, noise pré-calculada |
| Múltiplos shaders fullscreen empilhados | Máximo 2 fullscreen shaders ativos simultaneamente (névoa + distorção) |
| Normal maps aumentarem tamanho dos assets | Normal maps em resolução 50% do diffuse (8x8 para tiles 16x16) |
