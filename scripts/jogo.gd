extends Node
## Estado global do jogo (carregado automaticamente como "Jogo").
## Guarda a mochila, as moedas e a encomenda feita ao mercador.

signal inventario_mudou
signal mensagem(texto: String)

## Quantas flores cabem na mochila ao mesmo tempo.
const CAPACIDADE_FLORES := 12
## Preços do mercador (em moedas).
const PRECO_CHA := 6
const PRECO_TABUA := 4
const PRECO_CORDA := 3

var inventario := {"flores": 0, "cha": 0, "moedas": 0, "tabuas": 0, "cordas": 0}
## O que você pagou e o barco vai trazer na próxima visita.
var encomenda := {"tabuas": 0, "cordas": 0}
## Verdadeiro enquanto uma janela (ex.: a loja) está aberta.
var em_menu := false


func _ready() -> void:
	_registrar_controles()


func _registrar_controles() -> void:
	_acao("mover_frente", [KEY_W, KEY_UP])
	_acao("mover_tras", [KEY_S, KEY_DOWN])
	_acao("mover_esquerda", [KEY_A, KEY_LEFT])
	_acao("mover_direita", [KEY_D, KEY_RIGHT])
	_acao("pular", [KEY_SPACE])
	_acao("correr", [KEY_SHIFT])
	_acao("interagir", [KEY_E])


func _acao(nome: String, teclas: Array) -> void:
	if InputMap.has_action(nome):
		return
	InputMap.add_action(nome)
	for tecla in teclas:
		var ev := InputEventKey.new()
		ev.physical_keycode = tecla
		InputMap.action_add_event(nome, ev)


func qtd(item: String) -> int:
	return inventario.get(item, 0)


func adicionar(item: String, n: int = 1) -> void:
	inventario[item] = qtd(item) + n
	inventario_mudou.emit()


func remover(item: String, n: int = 1) -> bool:
	if qtd(item) < n:
		return false
	inventario[item] -= n
	inventario_mudou.emit()
	return true


func espaco_flores() -> int:
	return CAPACIDADE_FLORES - qtd("flores")


func avisar(texto: String) -> void:
	mensagem.emit(texto)
