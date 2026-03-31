## event_bus.gd
## Barramento de sinais desacoplado (pub/sub global).
## Prioridade de Autoload: 1ª — carrega antes de todos os outros sistemas.
## REGRA: Nenhum sistema referencia outro diretamente. Tudo passa pelo EventBus.
extends Node

# ─────────────────────────────────────────────────────────────
# SANIDADE
# ─────────────────────────────────────────────────────────────

## Emitido a cada frame em que a sanidade muda.
## new_value: valor atual (0.0–100.0), delta: variação (negativo = dreno)
signal sanity_changed(new_value: float, delta: float)

## Emitido quando a sanidade cruza um limiar importante.
## threshold: "low_30" | "critical_15" | "zero"
signal sanity_threshold_crossed(threshold: String)

## Emitido quando sanidade é restaurada (item, meditação, etc.)
signal sanity_restored(amount: float)

# ─────────────────────────────────────────────────────────────
# LANTERNA
# ─────────────────────────────────────────────────────────────

## Emitido ao ligar ou desligar a lanterna.
signal lantern_toggled(is_on: bool)

## Emitido a cada frame em que a durabilidade muda.
signal lantern_durability_changed(new_value: float)

## Emitido quando a durabilidade chega a 0.
signal lantern_broken()

## Emitido quando um sistema externo (boss, guardião) força o desligamento.
## source: identificador da origem ("boss", "guardian", etc.)
signal lantern_force_disabled(source: String)

# ─────────────────────────────────────────────────────────────
# COMBATE
# ─────────────────────────────────────────────────────────────

## Emitido quando o player recebe dano.
## source: identificador de quem causou o dano
signal player_damaged(amount: float, source: String)

## Emitido quando o player morre (HP ou Sanidade = 0).
signal player_died()

## Emitido quando um inimigo recebe dano.
signal enemy_damaged(enemy_id: String, amount: float)

## Emitido quando um inimigo é eliminado.
signal enemy_killed(enemy_id: String)

## Emitido quando um boss muda de fase (transição aos 50% HP).
signal boss_phase_changed(boss_id: String, new_phase: int)

# ─────────────────────────────────────────────────────────────
# INVENTÁRIO
# ─────────────────────────────────────────────────────────────

## Emitido ao adicionar um item ao inventário.
signal item_added(item: Resource)

## Emitido ao remover um item do inventário.
signal item_removed(item: Resource)

## Emitido quando a quantidade de Taels muda.
signal taels_changed(new_amount: int)

# ─────────────────────────────────────────────────────────────
# ÁRVORE DE CICATRIZES
# ─────────────────────────────────────────────────────────────

## Emitido ao comprar um nó da Árvore de Cicatrizes.
## path: caminho do ramo ("corpo", "espirito", "lamina", "maldicao", etc.)
signal scar_node_purchased(node_id: String, path: String)

## Emitido quando um caminho da Árvore é bloqueado permanentemente.
signal scar_path_locked(path: String)

# ─────────────────────────────────────────────────────────────
# FLAGS NARRATIVAS
# ─────────────────────────────────────────────────────────────

## Emitido quando qualquer flag narrativa muda de valor.
signal flag_changed(flag_name: String, value: Variant)

## Emitido quando o player sacrifica um NPC.
signal npc_sacrificed(npc_id: String)

## Emitido quando o sistema de Eco da Culpa é ativado (has_murdered = true).
signal guilt_ghosts_activated()

# ─────────────────────────────────────────────────────────────
# GAME STATE
# ─────────────────────────────────────────────────────────────

## Emitido para acionar a tela de Game Over.
## cause: motivo ("sanity_zero", "player_death", etc.)
signal game_over_triggered(cause: String)

## Emitido ao entrar em uma nova zona.
signal zone_entered(zone_id: String)

## Emitido para solicitar salvamento.
signal save_requested()

## Emitido para solicitar carregamento.
signal load_requested()

# ─────────────────────────────────────────────────────────────
# GASLIGHTING & GUARDIÃO
# ─────────────────────────────────────────────────────────────

## Emitido para forçar efeito de gaslighting por uma duração em segundos.
signal force_gaslighting(duration: float)

## Emitido quando o player usa um item.
signal item_used(item: Resource)

## Emitido quando o Guardião inicia a transformação em Mimic Boss.
signal guardian_transformation_started()

## Emitido para travar ou destravar a base do jogador.
signal base_lockdown(is_locked: bool)
