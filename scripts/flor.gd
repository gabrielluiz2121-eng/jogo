extends "res://scripts/interagivel.gd"
## Flor mágica: aperte E para colher. Ela volta a crescer depois de um tempo.

const U = preload("res://scripts/util.gd")
const M = preload("res://scripts/modelos.gd")

## Segundos para a flor nascer de novo depois de colhida.
const TEMPO_PARA_CRESCER := 40.0

var cor := Color(0.95, 0.35, 0.75)
var colhida := false
var _tempo := 0.0
var _visual: Node3D
var _botao: Node3D
## Qual dos dois modelos de flor usar (1 ou 2). 0 = sorteia.
var variante := 0


func _ready() -> void:
	raio_interacao = 1.8
	_visual = Node3D.new()
	add_child(_visual)
	if variante == 0:
		variante = 1 + randi() % 2
	# Modelo do Meshy (pétalas azuladas); `cor` tinge a flor e ela brilha de leve.
	var tinta := Color(1.1, 1.1, 1.1).lerp(cor * 1.3, 0.45)
	_botao = M.criar("flor%d" % variante, randf_range(0.6, 0.8), 1, tinta, 0.25)
	_visual.add_child(_botao)
	_visual.rotation.y = randf() * TAU
	_tempo = randf() * TAU


func _process(delta: float) -> void:
	_tempo += delta
	if colhida:
		if _tempo >= TEMPO_PARA_CRESCER:
			colhida = false
			_visual.visible = true
	else:
		# Pequeno balanço "mágico".
		_botao.rotation.z = sin(_tempo * 1.7) * 0.06
		_botao.rotation.x = sin(_tempo * 1.3 + 1.0) * 0.05


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
