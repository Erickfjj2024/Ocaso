## item_base.gd
## Recurso base para todos os itens do jogo.
## Estender este Resource para criar itens específicos (consumíveis, equipamentos, etc.).
## Salvar como: res://resources/items/item_base.gd
extends Resource
class_name ItemBase

# ─────────────────────────────────────────────────────────────
# IDENTIFICAÇÃO
# ─────────────────────────────────────────────────────────────

## ID único do item (ex: "lantern_oil", "bandage", "scar_shard").
@export var item_id:     String    = ""

## Nome exibido na UI.
@export var item_name:   String    = ""

## Descrição curta exibida no tooltip ou tela de inventário.
@export var description: String    = ""

## Ícone exibido na UI (16×16 px recomendado).
@export var icon:        Texture2D = null

# ─────────────────────────────────────────────────────────────
# COMPORTAMENTO DE PILHA
# ─────────────────────────────────────────────────────────────

## Se true, múltiplas unidades ocupam um único slot.
@export var stackable:   bool = false

## Quantidade máxima por slot (irrelevante se stackable=false).
@export var max_stack:   int  = 1

# ─────────────────────────────────────────────────────────────
# ECONOMIA
# ─────────────────────────────────────────────────────────────

## Valor de venda/compra em Taels.
@export var value_taels: int  = 0
