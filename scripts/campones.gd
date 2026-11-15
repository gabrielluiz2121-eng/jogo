extends Node3D
## O camponês (protagonista), montado com formas simples seguindo a folha de
## conceito: chapéu cônico de palha, túnica azul-acinzentada cruzada com lapela
## de linho, faixa escura amarrada, calça oliva dobrada, sandálias e o cesto de
## bambu nas costas com ferramentas e plantas colhidas.
## Também faz uma animação simples (andar, correr, pular, colher) movendo as juntas.
## A frente do personagem é -Z; as costas (cesto) ficam em +Z.
##
## Quando existir um modelo 3D de verdade (.glb), ele substitui este script.

const U = preload("res://scripts/util.gd")

# --- Cores tiradas da folha de conceito ---
const PELE := Color(0.86, 0.68, 0.52)
const CABELO := Color(0.12, 0.1, 0.1)
const TUNICA := Color(0.42, 0.46, 0.6)
const LINHO := Color(0.7, 0.58, 0.4)
const FAIXA := Color(0.3, 0.27, 0.26)
const CALCA := Color(0.45, 0.48, 0.36)
const PALHA := Color(0.82, 0.7, 0.45)
const BAMBU := Color(0.74, 0.6, 0.38)
const MADEIRA := Color(0.48, 0.34, 0.22)
const FERRO := Color(0.5, 0.52, 0.55)
const FOLHA := Color(0.42, 0.58, 0.3)
const ALCA := Color(0.42, 0.45, 0.52)

# Juntas que a animação move.
var quadril: Node3D
var tronco: Node3D
var cabeca: Node3D
var chapeu: Node3D
var cesto: Node3D
var ombro := [null, null]   # [esquerdo, direito]
var cotovelo := [null, null]
var coxa := [null, null]
var joelho := [null, null]

var _fase := 0.0
var _colher := 0.0     # > 0 enquanto faz o gesto de colher
var _ar := 0.0         # 0 no chão, 1 no ar (suavizado)
var _vel_suave := 0.0


func _ready() -> void:
	_montar()


# ---------------------------------------------------------------- Montagem

func _mat(cor: Color, trama: float = 0.0) -> ShaderMaterial:
	var m: ShaderMaterial = U.material(cor)
	m.set_shader_parameter("manchas_locais", true)
	m.set_shader_parameter("manchas", 0.12)
	m.set_shader_parameter("trama", trama)
	return m


func _peca(pai: Node3D, mesh: Mesh, cor: Color, pos: Vector3, rot := Vector3.ZERO, trama := 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat(cor, trama)
	mi.position = pos
	mi.rotation = rot
	pai.add_child(mi)
	return mi


func _junta(pai: Node3D, pos: Vector3) -> Node3D:
	var j := Node3D.new()
	j.position = pos
	pai.add_child(j)
	return j


func _montar() -> void:
	quadril = _junta(self, Vector3(0, 0.9, 0))
	_montar_pernas()
	tronco = _junta(quadril, Vector3.ZERO)
	_montar_tronco()
	_montar_bracos()
	cabeca = _junta(tronco, Vector3(0, 0.58, 0))
	_montar_cabeca()
	cesto = _junta(tronco, Vector3(0, 0.3, 0.24))
	_montar_cesto()


func _montar_pernas() -> void:
	for i in 2:
		var lado := -1.0 if i == 0 else 1.0
		var c := _junta(quadril, Vector3(lado * 0.1, -0.02, 0))
		coxa[i] = c
		# Coxa (calça larga).
		_peca(c, U.cilindro(0.075, 0.095, 0.44, 8), CALCA, Vector3(0, -0.22, 0))
		var j := _junta(c, Vector3(0, -0.44, 0))
		joelho[i] = j
		# Barra da calça dobrada logo abaixo do joelho.
		_peca(j, U.cilindro(0.085, 0.08, 0.1, 8), CALCA.darkened(0.12), Vector3(0, -0.06, 0))
		# Canela à mostra.
		_peca(j, U.cilindro(0.045, 0.055, 0.34, 7), PELE, Vector3(0, -0.25, 0))
		# Pé + sandália de palha.
		_peca(j, U.caixa(Vector3(0.08, 0.05, 0.2)), PELE, Vector3(0, -0.42, -0.04))
		_peca(j, U.caixa(Vector3(0.1, 0.025, 0.24)), PALHA.darkened(0.1), Vector3(0, -0.455, -0.04), Vector3.ZERO, 0.8)
		_peca(j, U.caixa(Vector3(0.09, 0.015, 0.03)), PALHA.darkened(0.3), Vector3(0, -0.4, -0.08))


func _montar_tronco() -> void:
	# Barra da túnica (cobre o alto das coxas, com pontas desfiadas).
	_peca(tronco, U.cilindro(0.2, 0.25, 0.28, 10), TUNICA, Vector3(0, -0.08, 0))
	for k in 5:
		var a := -1.2 + k * 0.6
		_peca(tronco, U.caixa(Vector3(0.07, 0.07, 0.02)), TUNICA.darkened(0.08), Vector3(sin(a) * 0.24, -0.25, -cos(a) * 0.24), Vector3(0, -a, 0.3 * (k % 2)))
	# Peito.
	_peca(tronco, U.cilindro(0.21, 0.19, 0.46, 10), TUNICA, Vector3(0, 0.27, 0))
	_peca(tronco, U.esfera(0.21, 10), TUNICA, Vector3(0, 0.48, 0)).scale = Vector3(1.1, 0.5, 0.85)
	# Lapelas cruzadas de linho (gola em "V").
	_peca(tronco, U.caixa(Vector3(0.09, 0.44, 0.03)), LINHO, Vector3(0.08, 0.32, -0.19), Vector3(0.05, 0, -0.38))
	_peca(tronco, U.caixa(Vector3(0.09, 0.44, 0.03)), LINHO, Vector3(-0.08, 0.32, -0.195), Vector3(0.05, 0, 0.38))
	# Pescoço.
	_peca(tronco, U.cilindro(0.05, 0.06, 0.12, 7), PELE, Vector3(0, 0.55, 0))
	# Faixa escura na cintura, com as pontas do laço penduradas.
	_peca(tronco, U.cilindro(0.215, 0.215, 0.1, 10), FAIXA, Vector3(0, 0.07, 0))
	_peca(tronco, U.esfera(0.05, 6), FAIXA.darkened(0.1), Vector3(0.06, 0.07, -0.21))
	_peca(tronco, U.caixa(Vector3(0.06, 0.32, 0.02)), FAIXA, Vector3(0.09, -0.1, -0.22), Vector3(0, 0, 0.12))
	_peca(tronco, U.caixa(Vector3(0.06, 0.26, 0.02)), FAIXA, Vector3(0.02, -0.07, -0.225), Vector3(0, 0, -0.08))
	# Alças do cesto passando pelos ombros.
	for lado in [-1.0, 1.0]:
		_peca(tronco, U.caixa(Vector3(0.05, 0.4, 0.02)), ALCA, Vector3(lado * 0.12, 0.3, -0.205), Vector3(0, 0, lado * 0.1))
		_peca(tronco, U.caixa(Vector3(0.05, 0.02, 0.42)), ALCA, Vector3(lado * 0.12, 0.52, 0.0))


func _montar_bracos() -> void:
	for i in 2:
		var lado := -1.0 if i == 0 else 1.0
		var o := _junta(tronco, Vector3(lado * 0.25, 0.46, 0))
		ombro[i] = o
		# Manga larga.
		_peca(o, U.cilindro(0.07, 0.085, 0.3, 8), TUNICA, Vector3(0, -0.15, 0))
		var c := _junta(o, Vector3(0, -0.3, 0))
		cotovelo[i] = c
		# Manga dobrada e antebraço.
		_peca(c, U.cilindro(0.075, 0.07, 0.07, 8), TUNICA.darkened(0.12), Vector3(0, -0.02, 0))
		_peca(c, U.cilindro(0.04, 0.05, 0.24, 7), PELE, Vector3(0, -0.15, 0))
		_peca(c, U.esfera(0.05, 7), PELE, Vector3(0, -0.3, 0)).scale = Vector3(0.8, 1.1, 0.9)
	ombro[0].rotation.z = -0.12
	ombro[1].rotation.z = 0.12


func _montar_cabeca() -> void:
	# Rosto.
	_peca(cabeca, U.esfera(0.13, 12), PELE, Vector3(0, 0.12, 0)).scale = Vector3(0.95, 1.08, 1.0)
	# Cabelo preto curto (aparece na nuca e nas laterais).
	_peca(cabeca, U.esfera(0.135, 12), CABELO, Vector3(0, 0.15, 0.02)).scale = Vector3(1.0, 0.9, 0.95)
	# Olhos, sobrancelhas e nariz (a frente é -Z).
	for lado in [-1.0, 1.0]:
		_peca(cabeca, U.esfera(0.016, 5), CABELO, Vector3(lado * 0.045, 0.13, -0.122))
		_peca(cabeca, U.caixa(Vector3(0.04, 0.008, 0.01)), CABELO, Vector3(lado * 0.045, 0.165, -0.125), Vector3(0, 0, -lado * 0.15))
	_peca(cabeca, U.esfera(0.018, 5), PELE.darkened(0.08), Vector3(0, 0.1, -0.132))
	_peca(cabeca, U.esfera(0.035, 6), PELE, Vector3(-0.13, 0.12, 0)).scale = Vector3(0.5, 1, 0.8)
	_peca(cabeca, U.esfera(0.035, 6), PELE, Vector3(0.13, 0.12, 0)).scale = Vector3(0.5, 1, 0.8)

	# Chapéu cônico largo de palha, com fitinha passando pelo queixo.
	chapeu = _junta(cabeca, Vector3(0, 0.25, 0))
	_peca(chapeu, U.cilindro(0.015, 0.5, 0.24, 20), PALHA, Vector3(0, 0.07, 0), Vector3.ZERO, 0.6)
	_peca(chapeu, U.cilindro(0.5, 0.505, 0.02, 20), PALHA.darkened(0.15), Vector3(0, -0.05, 0))
	_peca(chapeu, U.cilindro(0.11, 0.12, 0.05, 10), PALHA.darkened(0.25), Vector3(0, -0.06, 0))
	for lado in [-1.0, 1.0]:
		_peca(chapeu, U.cilindro(0.005, 0.005, 0.24, 3), LINHO.darkened(0.3), Vector3(lado * 0.09, -0.19, -0.04), Vector3(0.25, 0, -lado * 0.35))


func _montar_cesto() -> void:
	# Cesto de bambu trançado.
	_peca(cesto, U.cilindro(0.24, 0.18, 0.55, 14), BAMBU, Vector3(0, 0, 0.05), Vector3.ZERO, 0.9)
	_peca(cesto, U.cilindro(0.25, 0.25, 0.04, 14), BAMBU.darkened(0.25), Vector3(0, 0.27, 0.05))
	_peca(cesto, U.cilindro(0.19, 0.19, 0.04, 14), BAMBU.darkened(0.25), Vector3(0, -0.26, 0.05))
	# Cordas em "X" nas costas do cesto.
	_peca(cesto, U.caixa(Vector3(0.04, 0.55, 0.02)), ALCA, Vector3(0, 0, 0.27), Vector3(0, 0, 0.6))
	_peca(cesto, U.caixa(Vector3(0.04, 0.55, 0.02)), ALCA, Vector3(0, 0, 0.27), Vector3(0, 0, -0.6))
	# Cestinhos laterais com ervas.
	for lado in [-1.0, 1.0]:
		var b := _junta(cesto, Vector3(lado * 0.27, -0.05, 0.08))
		_peca(b, U.cilindro(0.09, 0.07, 0.18, 10), BAMBU.darkened(0.05), Vector3.ZERO, Vector3.ZERO, 0.9)
		for k in 4:
			var r := Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5))
			_peca(b, U.cilindro(0.004, 0.012, 0.2, 3), FOLHA, Vector3(randf_range(-0.04, 0.04), 0.15, randf_range(-0.04, 0.04)), r)
		_peca(b, U.esfera(0.025, 5), Color(0.95, 0.8, 0.3), Vector3(0.02, 0.24, 0))
	# Corda enrolada pendurada do lado.
	var corda := TorusMesh.new()
	corda.inner_radius = 0.07
	corda.outer_radius = 0.1
	corda.rings = 12
	corda.ring_segments = 6
	_peca(cesto, corda, LINHO.darkened(0.15), Vector3(0.2, 0.05, 0.25), Vector3(1.4, 0.6, 0))
	# Ferramentas: enxada, pá e cabos saindo de dentro.
	_peca(cesto, U.cilindro(0.018, 0.018, 0.75, 5), MADEIRA, Vector3(-0.09, 0.4, 0.02), Vector3(0.1, 0, 0.15))
	_peca(cesto, U.caixa(Vector3(0.14, 0.05, 0.03)), FERRO, Vector3(-0.15, 0.76, 0.06), Vector3(0, 0, 0.5))
	_peca(cesto, U.cilindro(0.018, 0.018, 0.65, 5), MADEIRA, Vector3(0.1, 0.36, 0.05), Vector3(-0.1, 0, -0.2))
	_peca(cesto, U.cilindro(0.016, 0.016, 0.55, 5), MADEIRA.lightened(0.1), Vector3(0.02, 0.32, 0.12), Vector3(0.15, 0, 0.05))
	# Plantas e flores colhidas saindo do topo.
	var cores_flor := [Color(0.95, 0.8, 0.3), Color(0.6, 0.45, 0.85), Color(0.95, 0.55, 0.3), Color(0.9, 0.9, 0.95)]
	for k in 9:
		var p := Vector3(randf_range(-0.15, 0.15), 0.3, randf_range(-0.1, 0.18))
		var alt := randf_range(0.12, 0.3)
		_peca(cesto, U.cilindro(0.005, 0.012, alt, 3), FOLHA, p + Vector3(0, alt * 0.5, 0), Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.4, 0.4)))
		if k % 2 == 0:
			_peca(cesto, U.esfera(0.03, 5), cores_flor[k / 2 % cores_flor.size()], p + Vector3(0, alt, 0))
	_peca(cesto, U.esfera(0.14, 8), FOLHA.darkened(0.15), Vector3(0, 0.3, 0.05)).scale = Vector3(1.4, 0.45, 1.2)


# ---------------------------------------------------------------- Animação

## Começa o gesto de abaixar e colher.
func colher() -> void:
	_colher = 0.7


## Chamado pelo jogador a cada quadro de física.
func animar(delta: float, velocidade: float, no_chao: bool, vel_vertical: float) -> void:
	_vel_suave = lerpf(_vel_suave, velocidade, 10.0 * delta)
	_ar = lerpf(_ar, 0.0 if no_chao else 1.0, 12.0 * delta)
	var correndo := clampf((_vel_suave - 5.0) / 3.5, 0.0, 1.0)
	var andando := clampf(_vel_suave / 4.0, 0.0, 1.0)

	# Passos: a fase avança conforme a distância percorrida.
	_fase += delta * _vel_suave * lerpf(2.1, 1.6, correndo)
	var s := sin(_fase)
	var amplitude := andando * lerpf(0.5, 0.85, correndo) * (1.0 - _ar)

	for i in 2:
		var lado := 1.0 if i == 0 else -1.0
		var passo := s * lado
		# Pernas: coxa vai para frente/trás, joelho dobra quando a perna volta.
		coxa[i].rotation.x = -passo * amplitude
		joelho[i].rotation.x = -maxf(0.0, -cos(_fase) * lado) * amplitude * 1.3
		# Braços balançam ao contrário das pernas.
		ombro[i].rotation.x = passo * amplitude * 0.8
		cotovelo[i].rotation.x = (0.15 + correndo * 1.0) * andando

	# Corpo sobe e desce a cada passo e inclina para frente ao correr.
	quadril.position.y = 0.9 - absf(cos(_fase)) * 0.05 * andando * (1.0 - _ar)
	tronco.rotation.x = -(0.05 * andando + 0.18 * correndo)
	tronco.rotation.y = s * 0.08 * andando
	cabeca.rotation.x = 0.06 * andando + 0.12 * correndo

	# Parado: respiração leve.
	var respira := sin(Time.get_ticks_msec() / 650.0) * 0.012 * (1.0 - andando)
	tronco.position.y = respira

	# No ar: pernas encolhidas e braços abertos.
	if _ar > 0.01:
		for i in 2:
			coxa[i].rotation.x = lerpf(coxa[i].rotation.x, 0.7 if i == 0 else 0.2, _ar)
			joelho[i].rotation.x = lerpf(joelho[i].rotation.x, -1.1 if i == 0 else -0.5, _ar)
			ombro[i].rotation.x = lerpf(ombro[i].rotation.x, 0.5, _ar)
		ombro[0].rotation.z = lerpf(-0.12, -0.6, _ar)
		ombro[1].rotation.z = lerpf(0.12, 0.6, _ar)
	else:
		ombro[0].rotation.z = -0.12
		ombro[1].rotation.z = 0.12

	# Chapéu e cesto balançam com atraso, dando sensação de peso.
	chapeu.rotation.z = lerpf(chapeu.rotation.z, -s * 0.04 * andando, 8.0 * delta)
	chapeu.rotation.x = lerpf(chapeu.rotation.x, clampf(-vel_vertical * 0.02, -0.15, 0.15), 8.0 * delta)
	cesto.rotation.x = lerpf(cesto.rotation.x, absf(cos(_fase)) * 0.06 * andando + clampf(vel_vertical * 0.02, -0.15, 0.15), 10.0 * delta)

	# Gesto de colher: abaixa, inclina e estica o braço direito.
	if _colher > 0.0:
		_colher -= delta
		var t := sin(clampf(1.0 - _colher / 0.7, 0.0, 1.0) * PI)
		quadril.position.y -= 0.3 * t
		tronco.rotation.x -= 0.7 * t
		for i in 2:
			coxa[i].rotation.x += 1.1 * t
			joelho[i].rotation.x -= 1.7 * t
		ombro[1].rotation.x += 1.0 * t
		cotovelo[1].rotation.x += 0.3 * t
