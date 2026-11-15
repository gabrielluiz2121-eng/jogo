extends "res://scripts/interagivel.gd"
## Flor mágica: aperte E para colher. Ela volta a crescer depois de um tempo.

const U = preload("res://scripts/util.gd")

## Segundos para a flor nascer de novo depois de colhida.
const TEMPO_PARA_CRESCER := 40.0

var cor := Color(0.95, 0.35, 0.75)
var colhida := false
var _tempo := 0.0
var _visual: Node3D
var _botao: MeshInstance3D


func _ready() -> void:
	raio_interacao = 1.8
	_visual = Node3D.new()
	add_child(_visual)
	_visual.add_child(U.malha(U.cilindro(0.03, 0.04, 0.6, 6), Color(0.3, 0.6, 0.25), Vector3(0, 0.3, 0)))
	_visual.add_child(U.malha(U.caixa(Vector3(0.25, 0.02, 0.1)), Color(0.35, 0.65, 0.3), Vector3(0.08, 0.2, 0)))
	_botao = U.malha(U.esfera(0.16, 8), cor, Vector3(0, 0.65, 0), 0.8)
	_visual.add_child(_botao)
	_tempo = randf() * TAU


func _process(delta: float) -> void:
	_tempo += delta
	if colhida:
		if _tempo >= TEMPO_PARA_CRESCER:
			colhida = false
			_visual.visible = true
	else:
		# Pequeno balanço "mágico".
		_botao.position.y = 0.65 + sin(_tempo * 2.0) * 0.04
		_visual.rotation.y += delta * 0.5


func ponto_interacao() -> Vector3:
	return global_position + Vector3(0, 0.5, 0)


func texto_interacao(_jogador: Node) -> String:
	if colhida:
		return ""
	if Jogo.espaco_flores() <= 0:
		return "Mochila cheia de flores (%d/%d)" % [Jogo.qtd("flores"), Jogo.CAPACIDADE_FLORES]
	return "E: colher flor mágica"


func interagir(_jogador: Node) -> void:
	if colhida or Jogo.espaco_flores() <= 0:
		return
	Jogo.adicionar("flores")
	colhida = true
	_tempo = 0.0
	_visual.visible = false
