extends "res://scripts/interagivel.gd"
## Fica na origem do mundo, então posições locais = posições do mundo.
## Canteiro de obra da ponte de corda. Com materiais suficientes, aperte E para construir.

const U = preload("res://scripts/util.gd")

const CUSTO_TABUAS := 8
const CUSTO_CORDAS := 4
const LARGURA := 2.2

## Pontos (em coordenadas do mundo) onde a ponte começa e termina.
var inicio := Vector3.ZERO
var fim := Vector3.ZERO
var construida := false
var _fantasma: Node3D
var _placa: Label3D


func _ready() -> void:
	raio_interacao = 3.5
	_fantasma = _montar_tabuas(Color(0.8, 0.8, 0.9, 0.25))
	add_child(_fantasma)
	_placa = Label3D.new()
	_placa.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_placa.font_size = 48
	_placa.outline_size = 12
	_placa.pixel_size = 0.01
	_placa.text = "Ponte de corda\n%d tábuas + %d cordas" % [CUSTO_TABUAS, CUSTO_CORDAS]
	_placa.position = inicio + Vector3(0, 2.2, 0)
	add_child(_placa)
	# Duas estacas marcando o começo da obra.
	for lado in [-1.0, 1.0]:
		add_child(U.malha(U.cilindro(0.1, 0.12, 1.4, 6), Color(0.5, 0.38, 0.25), inicio + Vector3(0, 0.7, lado * (LARGURA * 0.5 + 0.2))))


func _montar_tabuas(cor: Color) -> Node3D:
	var raiz := Node3D.new()
	var comprimento := inicio.distance_to(fim)
	var n := int(comprimento / 0.6)
	var base := Basis.looking_at((fim - inicio).normalized(), Vector3.UP)
	for i in n + 1:
		var p := inicio.lerp(fim, float(i) / n)
		var tabua := U.malha(U.caixa(Vector3(LARGURA, 0.1, 0.45)), cor)
		tabua.transform = Transform3D(base, p - base.y * 0.05)
		raiz.add_child(tabua)
	return raiz


func ponto_interacao() -> Vector3:
	return inicio


func texto_interacao(_jogador: Node) -> String:
	if construida:
		return ""
	var t := Jogo.qtd("tabuas")
	var c := Jogo.qtd("cordas")
	if t >= CUSTO_TABUAS and c >= CUSTO_CORDAS:
		return "E: construir ponte de corda"
	return "Ponte: precisa de %d tábuas (tem %d) e %d cordas (tem %d)" % [CUSTO_TABUAS, t, CUSTO_CORDAS, c]


func interagir(_jogador: Node) -> void:
	if construida or Jogo.qtd("tabuas") < CUSTO_TABUAS or Jogo.qtd("cordas") < CUSTO_CORDAS:
		return
	Jogo.remover("tabuas", CUSTO_TABUAS)
	Jogo.remover("cordas", CUSTO_CORDAS)
	construida = true
	_fantasma.queue_free()
	_placa.queue_free()
	_construir()
	Jogo.avisar("Ponte construída! Atravesse para a outra ilha.")


func _construir() -> void:
	add_child(_montar_tabuas(Color(0.6, 0.45, 0.28)))
	# Piso sólido (invisível) por baixo das tábuas.
	var piso := U.transform_prancha(inicio, fim, 0.3)
	var comprimento := inicio.distance_to(fim)
	add_child(U.solido(U.forma_caixa(Vector3(LARGURA, 0.3, comprimento)), piso))
	# Cordas laterais (com paredes invisíveis para não cair com facilidade).
	var base := piso.basis
	for lado in [-1.0, 1.0]:
		var desloc: Vector3 = base.x * lado * (LARGURA * 0.5)
		var meio := (inicio + fim) * 0.5 + desloc + Vector3(0, 1.0, 0)
		var corda := U.malha(U.caixa(Vector3(0.05, 0.05, comprimento)), Color(0.8, 0.7, 0.5))
		corda.transform = Transform3D(base, meio)
		add_child(corda)
		add_child(U.solido(U.forma_caixa(Vector3(0.1, 1.4, comprimento)), Transform3D(base, meio - Vector3(0, 0.3, 0))))
		for p in [inicio, fim]:
			add_child(U.malha(U.cilindro(0.1, 0.12, 1.4, 6), Color(0.5, 0.38, 0.25), p + desloc + Vector3(0, 0.6, 0)))
