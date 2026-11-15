extends Node3D
## Monta o mundo do protótipo: duas ilhas flutuantes, trilha, árvores,
## flores, varal de secagem, cais com barco mercador e a obra da ponte.
## Tudo é feito com formas simples (cubos, cilindros, esferas).

const U = preload("res://scripts/util.gd")
const Flor = preload("res://scripts/flor.gd")
const Secador = preload("res://scripts/secador.gd")
const Mercador = preload("res://scripts/mercador.gd")
const Ponte = preload("res://scripts/ponte.gd")
const Jogador = preload("res://scripts/jogador.gd")
const Hud = preload("res://scripts/hud.gd")
const Ciclo = preload("res://scripts/ciclo.gd")
const Estilo = preload("res://scripts/estilo.gd")

const COR_GRAMA := Color(0.6, 0.66, 0.38)
const COR_GRAMA_B := Color(0.56, 0.63, 0.36)
const COR_ROCHA := Color(0.5, 0.47, 0.44)
const COR_TERRA := Color(0.72, 0.62, 0.46)
const COR_MADEIRA := Color(0.42, 0.32, 0.22)
const COR_ROCHA_LONGE := Color(0.5, 0.52, 0.56)
const COR_MUSGO := Color(0.45, 0.55, 0.28)
const COR_PINHEIRO := Color(0.22, 0.36, 0.24)
const COR_PINHEIRO_CLARO := Color(0.5, 0.58, 0.28)
const COR_FLOR_A := Color(0.8, 0.95, 1.0)
const COR_FLOR_B := Color(1.0, 0.62, 0.8)

# Ilha principal (A) e segunda ilha (B).
const CENTRO_A := Vector3(0, 0, 0)
const RAIO_A := 22.0
const PLATO_A := Vector3(-8, 0, -6)  # morro (segundo nível de altura)
const RAIO_PLATO := 8.0
const ALTURA_PLATO := 3.0
const CENTRO_B := Vector3(52, 1, 0)
const RAIO_B := 14.0


## Lugares onde não colocar árvores nem flores (x, z, raio).
var _ocupado: Array[Vector3] = []
var _rng := RandomNumberGenerator.new()
var ciclo: Node


func _ready() -> void:
	_rng.seed = 2026
	_ambiente()

	# --- Ilha A: chão, morro, rampa e trilha ---
	_ilha(CENTRO_A, RAIO_A, 16.0, COR_GRAMA)
	_plato(PLATO_A, RAIO_PLATO, ALTURA_PLATO)
	var rampa_baixo := Vector3(10, 0, -6)
	var rampa_cima := Vector3(0.6, ALTURA_PLATO, -6)
	_rampa(rampa_baixo, rampa_cima, 3.0)
	# Patamar plano no topo da rampa, para não tropeçar na borda do morro.
	var patamar := Transform3D(Basis(), Vector3(-0.9, ALTURA_PLATO - 0.3, -6))
	var tam_patamar := Vector3(3.0, 0.6, 3.0)
	var m_patamar := U.malha(U.caixa(tam_patamar), COR_TERRA)
	m_patamar.transform = patamar
	add_child(m_patamar)
	add_child(U.solido(U.forma_caixa(tam_patamar), patamar))
	_trilha([Vector3(0, 0, 21), Vector3(0, 0, 12), Vector3(4, 0, 4), Vector3(10, 0, -2), rampa_baixo])
	_trilha([Vector3(4, 0, 4), Vector3(12, 0, 2), Vector3(21, 0, 0)])
	_trilha([rampa_cima, Vector3(-8, ALTURA_PLATO, -6), Vector3(-12, ALTURA_PLATO, -10)])
	_livre(Vector3(PLATO_A.x, 0, PLATO_A.z), RAIO_PLATO + 1.5)  # chão em volta do morro
	_livre(Vector3(4, 0, -6), 3.5)
	_livre(Vector3(8, 0, -6), 3.0)
	_livre(Vector3(7, 0, 10), 3.5)  # varal
	_livre(Vector3(0, 0, 14), 3.0)  # início do jogador

	# --- Ilha B (um pouco mais alta) ---
	_ilha(CENTRO_B, RAIO_B, 12.0, COR_GRAMA_B)
	_trilha([Vector3(39, 1, 0), Vector3(46, 1, 2), Vector3(54, 1, -2), Vector3(60, 1, 4)])
	_pedra_mirante(CENTRO_B + Vector3(6, 0, 6))
	_cachoeira(CENTRO_B + Vector3(-4, 0, -RAIO_B + 0.3), 0.0)
	_cachoeira(Vector3(-14, 0, 16.6), deg_to_rad(-40))

	# --- Árvores e pedras ---
	_espalhar_arvores(CENTRO_A, 3.0, RAIO_A - 2.0, 22, 0.0)
	_espalhar_arvores(Vector3(PLATO_A.x, ALTURA_PLATO, PLATO_A.z), 2.0, RAIO_PLATO - 1.5, 5, ALTURA_PLATO, true)
	_espalhar_arvores(CENTRO_B, 2.0, RAIO_B - 2.0, 12, CENTRO_B.y)

	# --- Flores mágicas ---
	_espalhar_flores(CENTRO_A, 4.0, RAIO_A - 2.0, 10, 0.0, COR_FLOR_A)
	_espalhar_flores(Vector3(PLATO_A.x, ALTURA_PLATO, PLATO_A.z), 1.5, RAIO_PLATO - 1.5, 6, ALTURA_PLATO, COR_FLOR_A, true)
	_espalhar_flores(CENTRO_B, 2.0, RAIO_B - 2.0, 16, CENTRO_B.y, COR_FLOR_B)

	# --- Varal de secagem ---
	var secador := Secador.new()
	secador.position = Vector3(7, 0, 10)
	secador.rotation_degrees.y = -30
	add_child(secador)

	# --- Cais e barco mercador ---
	_cais()
	var mercador := Mercador.new()
	mercador.ponto_cais = Vector3(0, 0, 27)
	mercador.pos_atracado = Vector3(4.6, 0.4, 25)
	add_child(mercador)

	# --- Obra da ponte (de A para B) ---
	var ponte := Ponte.new()
	ponte.inicio = Vector3(20.0, 0, 0)
	ponte.fim = Vector3(39.5, CENTRO_B.y, 0)
	add_child(ponte)

	# --- Jogador e interface ---
	var jogador := Jogador.new()
	jogador.position = Vector3(0, 0.2, 14)
	add_child(jogador)
	var hud := Hud.new()
	add_child(hud)
	hud.conectar(jogador, mercador, ciclo)
	ciclo.tela = Estilo.aplicar(jogador.camera)
	ciclo.aplicar()
	Jogo.avisar("Colha flores mágicas, seque no varal e venda o chá ao barco mercador.")


# ---------------- Ambiente: céu, sol, névoa e mar de nuvens ----------------


func _ambiente() -> void:
	var ceu_mat := ShaderMaterial.new()
	ceu_mat.shader = preload("res://shaders/ceu.gdshader")
	var ceu := Sky.new()
	ceu.sky_material = ceu_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = ceu
	# Luz ambiente de cor controlada (fica azulada nas sombras, como aquarela).
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_energy = 1.0
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	# O ajuste de tom é feito no filtro de aquarela (shaders/tela_aquarela.gdshader).
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	# Neblina: fraca no geral e bem densa lá embaixo (camadas entre as ilhas).
	env.fog_enabled = true
	env.fog_density = 0.0035
	env.fog_sky_affect = 0.15
	env.fog_height = -20.0
	env.fog_height_density = 0.04
	env.fog_aerial_perspective = 0.3
	var mundo := WorldEnvironment.new()
	mundo.environment = env
	add_child(mundo)

	var sol := DirectionalLight3D.new()
	sol.shadow_enabled = true
	sol.shadow_blur = 2.0
	sol.directional_shadow_max_distance = 120.0
	add_child(sol)

	ciclo = Ciclo.new()
	ciclo.sol = sol
	ciclo.ambiente = env
	ciclo.ceu = ceu_mat
	add_child(ciclo)

	# Mar de nuvens: várias camadas transparentes, uma em cima da outra.
	var shader_nuvens := preload("res://shaders/nuvens.gdshader")
	var camadas := [
		# [altura, densidade, escala, cobertura]
		[-62.0, 1.0, 0.012, 0.0],
		[-52.0, 0.95, 0.016, 0.3],
		[-44.0, 0.9, 0.022, 0.4],
		[-36.0, 0.75, 0.03, 0.47],
		[-24.0, 0.45, 0.02, 0.55],
		[-10.0, 0.3, 0.03, 0.6],
	]
	for c in camadas:
		var plano := PlaneMesh.new()
		plano.size = Vector2(1400, 1400)
		var m := ShaderMaterial.new()
		m.shader = shader_nuvens
		m.set_shader_parameter("densidade", c[1])
		m.set_shader_parameter("escala", c[2])
		m.set_shader_parameter("cobertura", c[3])
		m.set_shader_parameter("compatibilidade", U.modo_compatibilidade())
		var mi := MeshInstance3D.new()
		mi.mesh = plano
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3(0, c[0], 0)
		add_child(mi)
		ciclo.nuvens.append(m)

	# Picos de pedra distantes, só para a paisagem (sem colisão), como nas artes.
	for i in 22:
		var ang := _rng.randf() * TAU
		var dist := _rng.randf_range(110, 320)
		var base := Vector3(cos(ang) * dist, _rng.randf_range(-40, -20), sin(ang) * dist)
		var r := _rng.randf_range(6, 14)
		var alt := _rng.randf_range(40, 90)
		var pico := U.malha(U.cilindro(r * 0.6, r, alt, 9, 10), COR_ROCHA_LONGE, base + Vector3(0, alt * 0.5, 0), 0.0, 3.5)
		add_child(pico)
		# Um segundo bloco por cima, torto, para o pico parecer pedra esculpida.
		var alt2 := alt * _rng.randf_range(0.2, 0.4)
		var bloco := U.malha(U.cilindro(r * 0.45, r * 0.6, alt2, 8, 4), COR_ROCHA_LONGE, base + Vector3(_rng.randf_range(-1.5, 1.5), alt + alt2 * 0.5 - 0.5, _rng.randf_range(-1.5, 1.5)), 0.0, 2.0)
		add_child(bloco)
		var topo := base + Vector3(0, alt + alt2 - 0.5, 0)
		add_child(U.malha(U.cilindro(r * 0.5, r * 0.45, 1.5, 8), COR_MUSGO, topo))
		_pinheiro(topo + Vector3(_rng.randf_range(-1, 1), 0, _rng.randf_range(-1, 1)), false)


# ---------------- Peças do terreno ----------------


## Ilha flutuante: disco de grama em cima, rocha afinando para baixo.
func _ilha(centro: Vector3, raio: float, profundidade: float, cor: Color) -> void:
	var lados := 20
	add_child(U.malha(U.cilindro(raio, raio, 2.0, lados), cor, centro - Vector3(0, 1.0, 0)))
	# Faixa de musgo na borda e rocha irregular afinando para baixo.
	add_child(U.malha(U.cilindro(raio * 1.01, raio * 0.96, 2.5, lados, 2), COR_MUSGO, centro - Vector3(0, 1.6, 0), 0.0, 0.6))
	add_child(U.malha(U.cilindro(raio * 0.96, raio * 0.12, profundidade, lados, 8), COR_ROCHA, centro - Vector3(0, 2.6 + profundidade * 0.5, 0), 0.0, 1.6))
	add_child(U.solido(U.forma_cilindro(raio, 2.0), Transform3D(Basis(), centro - Vector3(0, 1.0, 0))))
	# Raízes e cipós pendurados embaixo da ilha.
	for i in int(raio * 1.2):
		var ang := _rng.randf() * TAU
		var r := raio * _rng.randf_range(0.5, 0.93)
		var comprimento := _rng.randf_range(3.0, 9.0)
		var topo := centro + Vector3(cos(ang) * r, -2.5 - (1.0 - r / raio) * profundidade * 0.6, sin(ang) * r)
		var raiz := U.malha(U.cilindro(0.12, 0.03, comprimento, 4), COR_MUSGO.darkened(0.35))
		raiz.position = topo - Vector3(0, comprimento * 0.5, 0)
		raiz.rotation = Vector3(_rng.randf_range(-0.25, 0.25), 0, _rng.randf_range(-0.25, 0.25))
		add_child(raiz)


## Morro: um "degrau" mais alto em cima da ilha.
func _plato(base: Vector3, raio: float, altura: float) -> void:
	add_child(U.malha(U.cilindro(raio * 0.96, raio, altura, 16, 3), COR_ROCHA, base + Vector3(0, altura * 0.5, 0), 0.0, 0.25))
	add_child(U.malha(U.cilindro(raio * 0.96, raio * 0.96, 0.1, 14), COR_GRAMA.lightened(0.05), base + Vector3(0, altura + 0.0, 0)))
	add_child(U.solido(U.forma_cilindro(raio * 0.96, altura + 1.0), Transform3D(Basis(), base + Vector3(0, (altura - 1.0) * 0.5, 0))))


func _rampa(de: Vector3, ate: Vector3, largura: float) -> void:
	var espessura := 0.6
	var t := U.transform_prancha(de, ate, espessura)
	var tam := Vector3(largura, espessura, de.distance_to(ate) + 0.5)
	var m := U.malha(U.caixa(tam), COR_TERRA)
	m.transform = t
	add_child(m)
	add_child(U.solido(U.forma_caixa(tam), t))


## Trilha de terra (só visual), ligando uma lista de pontos.
func _trilha(pontos: Array) -> void:
	for i in pontos.size() - 1:
		var a: Vector3 = pontos[i]
		var b: Vector3 = pontos[i + 1]
		var plano := Vector3(b.x - a.x, 0, b.z - a.z)
		if plano.length() < 0.1 or absf(b.y - a.y) > 0.01:
			continue  # trechos inclinados (rampa) já têm cor de terra
		var tam := Vector3(1.6, 0.04, plano.length() + 1.0)
		var m := U.malha(U.caixa(tam), COR_TERRA)
		m.transform = Transform3D(Basis.looking_at(plano.normalized(), Vector3.UP), (a + b) * 0.5 + Vector3(0, 0.02, 0))
		add_child(m)
		var passos := int(plano.length() / 2.0) + 1
		for j in passos + 1:
			_livre(a.lerp(b, float(j) / passos), 2.0)


func _cais() -> void:
	var tam := Vector3(3.0, 0.4, 9.0)
	var pos := Vector3(0, -0.2, 24.5)
	add_child(U.malha(U.caixa(tam), COR_MADEIRA, pos))
	add_child(U.solido(U.forma_caixa(tam), Transform3D(Basis(), pos)))
	for z in [21.0, 24.5, 28.5]:
		for x in [-1.4, 1.4]:
			add_child(U.malha(U.cilindro(0.15, 0.15, 3.0, 6), COR_MADEIRA.darkened(0.2), Vector3(x, -0.6, z)))
	# Lanterna no fim do cais.
	add_child(U.malha(U.cilindro(0.08, 0.08, 2.2, 6), COR_MADEIRA.darkened(0.3), Vector3(-1.2, 1.1, 28.6)))
	add_child(U.malha(U.esfera(0.25, 8), Color(1.0, 0.4, 0.2), Vector3(-1.2, 2.3, 28.6), 1.5))
	_livre(Vector3(0, 0, 21), 3.0)


func _pedra_mirante(pos: Vector3) -> void:
	var tam := Vector3(3.0, 1.6, 3.0)
	var t := Transform3D(Basis(Vector3.UP, 0.4), pos + Vector3(0, 0.8, 0))
	var m := U.malha(U.caixa(tam), COR_ROCHA)
	m.transform = t
	add_child(m)
	add_child(U.solido(U.forma_caixa(tam), t))
	_livre(pos, 3.0)


# ---------------- Espalhar árvores e flores ----------------


func _livre(p: Vector3, raio: float) -> void:
	_ocupado.append(Vector3(p.x, p.z, raio))


func _esta_livre(p: Vector3, folga: float) -> bool:
	for o in _ocupado:
		if Vector2(p.x - o.x, p.z - o.y).length() < o.z + folga:
			return false
	return true


func _sortear_pontos(centro: Vector3, r_min: float, r_max: float, n: int, altura: float, folga: float, no_plato: bool) -> Array[Vector3]:
	var pontos: Array[Vector3] = []
	var tentativas := 0
	while pontos.size() < n and tentativas < 500:
		tentativas += 1
		var ang := _rng.randf() * TAU
		var r := sqrt(_rng.randf_range(r_min * r_min, r_max * r_max))
		var p := Vector3(centro.x + cos(ang) * r, altura, centro.z + sin(ang) * r)
		# No morro, ignoramos a "zona livre" do próprio morro.
		if no_plato:
			var ok := true
			for o in _ocupado:
				if o.z == RAIO_PLATO + 1.5:
					continue
				if Vector2(p.x - o.x, p.z - o.y).length() < o.z + folga:
					ok = false
					break
			if not ok:
				continue
		elif not _esta_livre(p, folga):
			continue
		pontos.append(p)
		_livre(p, folga)
	return pontos


func _espalhar_arvores(centro: Vector3, r_min: float, r_max: float, n: int, altura: float, no_plato := false) -> void:
	for p in _sortear_pontos(centro, r_min, r_max, n, altura, 1.6, no_plato):
		_pinheiro(p, true)


## Pinheiro torto de pintura chinesa: tronco em 2 partes e copas achatadas.
func _pinheiro(p: Vector3, com_colisao: bool) -> void:
	var alt := _rng.randf_range(2.5, 4.5)
	var inclina := Vector3(_rng.randf_range(-0.3, 0.3), 0, _rng.randf_range(-0.3, 0.3))
	var t1 := U.malha(U.cilindro(0.2, 0.32, alt * 0.6, 6), COR_MADEIRA)
	t1.position = p + Vector3(0, alt * 0.3, 0)
	add_child(t1)
	var meio := p + Vector3(0, alt * 0.6, 0)
	var t2 := U.malha(U.cilindro(0.12, 0.2, alt * 0.55, 6), COR_MADEIRA)
	t2.rotation = inclina
	t2.position = meio + Basis.from_euler(inclina) * Vector3(0, alt * 0.27, 0)
	add_child(t2)
	var topo := meio + Basis.from_euler(inclina) * Vector3(0, alt * 0.55, 0)
	var verde := COR_PINHEIRO.lerp(COR_PINHEIRO_CLARO, _rng.randf())
	var copas := _rng.randi_range(3, 5)
	for i in copas:
		var raio := _rng.randf_range(0.9, 1.6) * (1.0 - i * 0.12)
		var desloc := Vector3(_rng.randf_range(-1.2, 1.2), -i * 0.0 + _rng.randf_range(-0.9, 0.4), _rng.randf_range(-1.2, 1.2))
		if i == 0:
			desloc = Vector3.ZERO
		var copa := U.malha(U.esfera(raio, 9), verde.lightened(_rng.randf_range(0.0, 0.12)))
		copa.position = topo + desloc + Vector3(0, 0.2, 0)
		copa.scale = Vector3(1.5, 0.45, 1.5)
		add_child(copa)
	if com_colisao:
		add_child(U.solido(U.forma_cilindro(0.35, alt), Transform3D(Basis(), p + Vector3(0, alt * 0.5, 0))))


func _espalhar_flores(centro: Vector3, r_min: float, r_max: float, n: int, altura: float, cor: Color, no_plato := false) -> void:
	for p in _sortear_pontos(centro, r_min, r_max, n, altura, 1.0, no_plato):
		var flor := Flor.new()
		flor.cor = cor
		flor.position = p
		add_child(flor)


## Cachoeira que cai da beirada da ilha até o mar de nuvens.
func _cachoeira(pos: Vector3, giro_y: float) -> void:
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/cachoeira.gdshader")
	var altura := 45.0
	var quad := QuadMesh.new()
	quad.size = Vector2(2.2, altura)
	var mi := MeshInstance3D.new()
	mi.mesh = quad
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos + Vector3(0, -altura * 0.5 + 0.1, 0)
	mi.rotation.y = giro_y
	add_child(mi)
	# Riacho até a beirada.
	var rio := U.malha(U.caixa(Vector3(1.6, 0.05, 4.0)), Color(0.7, 0.82, 0.9))
	rio.position = pos + Vector3(0, 0.03, 0) + Basis(Vector3.UP, giro_y) * Vector3(0, 0, -2.0)
	rio.rotation.y = giro_y
	add_child(rio)
	_livre(pos, 2.5)
