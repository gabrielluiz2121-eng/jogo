extends "res://scripts/interagivel.gd"
## Varal de secagem: transforma flores em pacotes de chá com o tempo.

const U = preload("res://scripts/util.gd")
const M = preload("res://scripts/modelos.gd")

## Segundos para secar UMA flor.
const TEMPO_POR_FLOR := 5.0
const CAPACIDADE := 12

var secando := 0  # flores ainda secando
var prontos := 0  # pacotes de chá prontos para pegar
var _progresso := 0.0
var _rotulo: Label3D
var _slots: Array[Node3D] = []
## Altura (m) do fundo de cada bandeja, de baixo para cima.
const ALTURA_BANDEJAS := [0.42, 1.06, 1.7]
const COR_FRESCA := Color(0.75, 1.25, 0.8)  # folhas ainda verdes
const COR_SECA := Color(1.05, 0.72, 0.45)   # chá pronto


func _ready() -> void:
	raio_interacao = 2.8
	# Varal de bambu com 3 bandejas redondas (modelo do Meshy).
	add_child(M.criar("varal", 2.0))
	add_child(U.solido(U.forma_cilindro(1.0, 2.0), Transform3D(Basis(), Vector3(0, 1.0, 0))))
	# Montinhos de folhas: 4 por bandeja. Só aparecem quando há flores secando
	# (verdes) ou chá pronto (marrons).
	for i in CAPACIDADE:
		var nivel := i / 4
		var ang := TAU * (i % 4) / 4.0 + nivel * 0.6
		var slot := M.criar("folhas", 0.5, -1, COR_FRESCA)
		slot.position = Vector3(cos(ang) * 0.38, ALTURA_BANDEJAS[nivel] + 0.01, sin(ang) * 0.38)
		slot.rotation.y = ang * 1.7
		slot.visible = false
		add_child(slot)
		_slots.append(slot)
	_rotulo = Label3D.new()
	_rotulo.position = Vector3(0, 2.6, 0)
	_rotulo.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_rotulo.font_size = 48
	_rotulo.outline_size = 12
	_rotulo.pixel_size = 0.01
	add_child(_rotulo)
	_atualizar_visual()


func _process(delta: float) -> void:
	if secando > 0:
		_progresso += delta
		if _progresso >= TEMPO_POR_FLOR:
			_progresso -= TEMPO_POR_FLOR
			secando -= 1
			prontos += 1
			if secando == 0:
				_progresso = 0.0
		_atualizar_visual()


func _atualizar_visual() -> void:
	var txt := "Varal de secagem"
	if secando > 0:
		txt += "\nSecando: %d (próxima em %ds)" % [secando, ceili(TEMPO_POR_FLOR - _progresso)]
	if prontos > 0:
		txt += "\nChá pronto: %d" % prontos
	_rotulo.text = txt
	for i in CAPACIDADE:
		var s := _slots[i]
		if i < prontos:
			s.visible = true
			M.tingir(s, COR_SECA)
		elif i < prontos + secando:
			s.visible = true
			M.tingir(s, COR_FRESCA)
		else:
			s.visible = false


func texto_interacao(_jogador: Node) -> String:
	var espaco := CAPACIDADE - secando - prontos
	var colocar := mini(Jogo.qtd("flores"), espaco + prontos)
	var partes: Array[String] = []
	if prontos > 0:
		partes.append("pegar %d chá" % prontos)
	if colocar > 0:
		partes.append("pendurar %d flores" % colocar)
	if partes.is_empty():
		if secando > 0:
			return "Secando... volte daqui a pouco"
		return "Traga flores para secar"
	return "E: " + " e ".join(partes)


func interagir(_jogador: Node) -> void:
	if prontos > 0:
		Jogo.adicionar("cha", prontos)
		Jogo.avisar("Você pegou %d pacote(s) de chá." % prontos)
		prontos = 0
	var colocar := mini(Jogo.qtd("flores"), CAPACIDADE - secando)
	if colocar > 0:
		Jogo.remover("flores", colocar)
		secando += colocar
	_atualizar_visual()
