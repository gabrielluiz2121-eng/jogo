extends "res://scripts/interagivel.gd"
## Varal de secagem: transforma flores em pacotes de chá com o tempo.

const U = preload("res://scripts/util.gd")

## Segundos para secar UMA flor.
const TEMPO_POR_FLOR := 5.0
const CAPACIDADE := 12

var secando := 0  # flores ainda secando
var prontos := 0  # pacotes de chá prontos para pegar
var _progresso := 0.0
var _rotulo: Label3D
var _slots: Array[MeshInstance3D] = []
var _mat_cha := U.material(Color(0.45, 0.3, 0.15))
var _mat_flor := U.material(Color(0.85, 0.95, 1.0), 0.5)


func _ready() -> void:
	raio_interacao = 2.8
	var madeira := Color(0.55, 0.42, 0.28)
	for x in [-1.3, 1.3]:
		for z in [-0.5, 0.5]:
			add_child(U.malha(U.cilindro(0.07, 0.07, 1.8, 6), madeira, Vector3(x, 0.9, z)))
	for y in [0.6, 1.1, 1.6]:
		add_child(U.malha(U.caixa(Vector3(2.8, 0.05, 1.1)), Color(0.75, 0.68, 0.45), Vector3(0, y, 0)))
	add_child(U.malha(U.caixa(Vector3(3.0, 0.08, 1.4)), Color(0.4, 0.3, 0.2), Vector3(0, 1.85, 0)))
	var corpo := U.solido(U.forma_caixa(Vector3(2.8, 1.8, 1.2)), Transform3D(Basis(), Vector3(0, 0.9, 0)))
	add_child(corpo)
	# Espaços que mostram flores (rosa) e chás (marrom) no varal.
	for i in CAPACIDADE:
		var nivel := i / 4
		var col := i % 4
		var slot := U.malha(U.caixa(Vector3(0.4, 0.12, 0.4)), Color.WHITE, Vector3(-1.05 + col * 0.7, 0.68 + nivel * 0.5, 0))
		slot.visible = false
		add_child(slot)
		_slots.append(slot)
	_rotulo = Label3D.new()
	_rotulo.position = Vector3(0, 2.5, 0)
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
			s.material_override = _mat_cha
		elif i < prontos + secando:
			s.visible = true
			s.material_override = _mat_flor
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
