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
const Terreno = preload("res://scripts/terreno.gd")
const M = preload("res://scripts/modelos.gd")

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


const RAMPA_BAIXO := Vector3(10, 0, -6)
const RAMPA_CIMA := Vector3(0.4, ALTURA_PLATO, -6)

## Trilhas de terra (pintadas no chão e mantidas planas).
var TRILHAS_A: Array = [
	[Vector3(0, 0, 21), Vector3(0, 0, 12), Vector3(4, 0, 4), Vector3(10, 0, -2), RAMPA_BAIXO, RAMPA_CIMA, Vector3(-8, 0, -6), Vector3(-12, 0, -10)],
	[Vector3(4, 0, 4), Vector3(12, 0, 2), Vector3(21, 0, 0)],
	[Vector3(1.2, 0, 9.6), Vector3(-4.0, 0, 6.6)],  # até a casinha de chá
]
var TRILHAS_B: Array = [
	[Vector3(38, 0, 0), Vector3(46, 0, 2), Vector3(54, 0, -2), Vector3(60, 0, 4)],
]
## Lugares que precisam de chão plano (x, z, raio): início, varal, cais, ponte.
const CASA := Vector3(-7, 0, 5)
const PLANOS_A := [Vector3(-7, 5, 4.5), Vector3(0, 14, 3.5), Vector3(7, 10, 4.0), Vector3(0, 20, 4.0), Vector3(20, 0, 3.5)]
const PLANOS_B := [Vector3(39.5, 0, 3.5), Vector3(58, 6, 3.0)]

var terreno_a: Node3D
var terreno_b: Node3D
var _ruido_morros := FastNoiseLite.new()

## Lugares onde não colocar árvores nem flores (x, z, raio).
var _ocupado: Array[Vector3] = []
var _rng := RandomNumberGenerator.new()
var ciclo: Node


func _ready() -> void:
	_rng.seed = 2026
	_ambiente()

	_ruido_morros.seed = 11
	_ruido_morros.frequency = 0.07

	# --- Ilha A: relevo com morro, rampa, terraços e colinas ---
	terreno_a = Terreno.new()
	terreno_a.centro = CENTRO_A
	terreno_a.raio = RAIO_A
	terreno_a.profundidade = 17.0
	terreno_a.altura = _altura_a
	terreno_a.trilhas = TRILHAS_A
	terreno_a.angulos_protegidos = [0.0, PI * 0.5]  # ponte e cais
	terreno_a.semente = 3
	add_child(terreno_a)
	for t in TRILHAS_A:
		for i in t.size() - 1:
			for j in 6:
				_livre(t[i].lerp(t[i + 1], j / 5.0), 2.0)
	for pl in PLANOS_A:
		_livre(Vector3(pl.x, 0, pl.y), pl.z)

	# --- Ilha B (um pouco mais alta) ---
	terreno_b = Terreno.new()
	terreno_b.centro = CENTRO_B
	terreno_b.raio = RAIO_B
	terreno_b.profundidade = 13.0
	terreno_b.altura = _altura_b
	terreno_b.trilhas = TRILHAS_B
	terreno_b.angulos_protegidos = [PI]
	terreno_b.semente = 8
	terreno_b.aneis = 30
	terreno_b.divisoes = 110
	terreno_b.cor_grama = COR_GRAMA_B
	add_child(terreno_b)
	for t in TRILHAS_B:
		for i in t.size() - 1:
			for j in 6:
				_livre(t[i].lerp(t[i + 1], j / 5.0), 2.0)
	for pl in PLANOS_B:
		_livre(Vector3(pl.x, 0, pl.y), pl.z)
	_pedra_mirante(_no_chao(Vector3(58, 0, 6)))
	_cachoeira(terreno_b, deg_to_rad(-106))
	_cachoeira(terreno_a, deg_to_rad(130))

	# --- Árvores e pedras ---
	_casa()
	_espalhar_pedras(terreno_a, 10)
	_espalhar_pedras(terreno_b, 5)
	_espalhar_arvores(terreno_a, 3.0, 28)
	_espalhar_arvores(terreno_b, 2.0, 12)

	# --- Flores mágicas ---
	_espalhar_flores(terreno_a, 3.0, 16, COR_FLOR_A)
	_espalhar_flores(terreno_b, 2.0, 16, COR_FLOR_B)

	# --- Varal de secagem ---
	var secador := Secador.new()
	secador.position = _no_chao(Vector3(7, 0, 10))
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
	jogador.position = _no_chao(Vector3(0, 0, 14)) + Vector3(0, 0.2, 0)
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


## Altura do chão da ilha A em (x, z).
## Chão base em 0, morro com paredão de pedra, rampa até ele, terraços no
## sudoeste e colinas suaves onde não há trilhas nem construções.
func _altura_a(x: float, z: float) -> float:
	var p := Vector2(x, z)
	# Morro (plato) com borda irregular e paredão íngreme.
	var dp := p.distance_to(Vector2(PLATO_A.x, PLATO_A.z))
	dp += _ruido_morros.get_noise_2d(x * 3.0 + 50.0, z * 3.0) * 0.9
	var h := ALTURA_PLATO * smoothstep(RAIO_PLATO + 1.2, RAIO_PLATO - 0.4, dp)
	# Rampa de terra subindo até o morro.
	var t := clampf((RAMPA_BAIXO.x - x) / (RAMPA_BAIXO.x - RAMPA_CIMA.x), 0.0, 1.0)
	var corredor := smoothstep(2.9, 1.5, absf(z - RAMPA_BAIXO.z)) * (1.0 if x < RAMPA_BAIXO.x + 0.5 else 0.0)
	h = maxf(h, ALTURA_PLATO * t * corredor)
	# Terraços (degraus de cultivo) subindo até a borda no sudoeste.
	var r := p.length() / RAIO_A
	var ang := atan2(z, x)
	var janela := smoothstep(0.75, 0.35, absf(wrapf(ang - deg_to_rad(135.0), -PI, PI)))
	var v := clampf((r - 0.5) / 0.45, 0.0, 1.0) * 4.0
	var degrau := floorf(v) + smoothstep(0.6, 0.95, v - floorf(v))
	h += 0.45 * degrau * janela
	# Colinas suaves (some perto de trilhas, construções e da borda).
	var n := smoothstep(0.05, 0.8, _ruido_morros.get_noise_2d(x, z)) * 1.7
	h += n * _mascara_plana(p, TRILHAS_A, PLANOS_A) * smoothstep(1.0, 0.82, r) * (1.0 - janela)
	return h


## Altura do chão da ilha B: base em CENTRO_B.y e um morrinho ao norte.
func _altura_b(x: float, z: float) -> float:
	var p := Vector2(x, z)
	var h := CENTRO_B.y
	var dm := p.distance_to(Vector2(50, -6))
	h += 2.2 * smoothstep(6.5, 1.0, dm)
	var r := p.distance_to(Vector2(CENTRO_B.x, CENTRO_B.z)) / RAIO_B
	var n := smoothstep(0.05, 0.8, _ruido_morros.get_noise_2d(x + 300.0, z)) * 1.2
	h += n * _mascara_plana(p, TRILHAS_B, PLANOS_B) * smoothstep(1.0, 0.8, r)
	return h


## 0 perto de trilhas e lugares planos, 1 longe deles.
func _mascara_plana(p: Vector2, trilhas: Array, planos: Array) -> float:
	var m := 1.0
	for pl in planos:
		m = minf(m, smoothstep(pl.z, pl.z + 3.0, p.distance_to(Vector2(pl.x, pl.y))))
	var melhor := INF
	for trilha in trilhas:
		for i in trilha.size() - 1:
			var a := Vector2(trilha[i].x, trilha[i].z)
			var b := Vector2(trilha[i + 1].x, trilha[i + 1].z)
			var ab := b - a
			var k := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
			melhor = minf(melhor, p.distance_to(a + ab * k))
	return minf(m, smoothstep(1.5, 4.5, melhor))


## Mesmo ponto, mas na altura do chão (da ilha que estiver mais perto).
func _no_chao(p: Vector3) -> Vector3:
	var t := _terreno_de(p)
	return Vector3(p.x, t.altura.call(p.x, p.z), p.z)


func _terreno_de(p: Vector3) -> Node3D:
	var da := Vector2(p.x - CENTRO_A.x, p.z - CENTRO_A.z).length() / RAIO_A
	var db := Vector2(p.x - CENTRO_B.x, p.z - CENTRO_B.z).length() / RAIO_B
	return terreno_a if da < db else terreno_b


## Inclinação do chão (0 = plano, 1 = 45 graus).
func _inclinacao(t: Node3D, x: float, z: float) -> float:
	var d := 0.5
	var dx: float = t.altura.call(x + d, z) - t.altura.call(x - d, z)
	var dz: float = t.altura.call(x, z + d) - t.altura.call(x, z - d)
	return Vector2(dx, dz).length() / (2.0 * d)


func _cais() -> void:
	# Colisão: uma tábua lisa com o topo em y = 0.
	var tam := Vector3(3.0, 0.4, 9.0)
	add_child(U.solido(U.forma_caixa(tam), Transform3D(Basis(), Vector3(0, -0.2, 24.5))))
	# Modelo do Meshy: comprido em X no arquivo, aqui vai na direção +Z,
	# com o poste da lanterna na ponta. O piso fica 1,55 m acima do pé dos postes.
	var modelo := M.criar("cais", 9.5, 0)
	modelo.rotation.y = -PI * 0.5
	modelo.position = Vector3(0, -1.55, 24.6)
	add_child(modelo)
	_livre(Vector3(0, 0, 21), 3.0)


## Casinha de chá (modelo do Meshy) com a porta virada para a trilha.
func _casa() -> void:
	var pos := _no_chao(CASA)
	var casa := M.criar("casa", 4.6, 0)
	casa.position = pos - Vector3(0, 0.05, 0)
	casa.rotation.y = deg_to_rad(70)
	add_child(casa)
	add_child(U.solido(U.forma_caixa(Vector3(4.0, 4.0, 3.8)), Transform3D(Basis(Vector3.UP, casa.rotation.y), pos + Vector3(0, 2.0, 0))))
	_livre(pos, 4.0)
	# Lanternas: uma perto da casa e outra perto do varal.
	_lanterna(pos + Basis(Vector3.UP, casa.rotation.y) * Vector3(1.8, 0, 2.9))
	_lanterna(_no_chao(Vector3(8.6, 0, 12.4)))


## Poste de madeira com uma lanterna de papel que brilha à noite.
func _lanterna(pos: Vector3) -> void:
	add_child(U.malha(U.cilindro(0.07, 0.09, 2.3, 6), COR_MADEIRA.darkened(0.2), pos + Vector3(0, 1.15, 0)))
	var lanterna := M.criar("lanterna", 0.9, 1, Color(1.15, 1.1, 1.05), 0.6)
	lanterna.position = pos + Vector3(0, 1.45, 0)
	add_child(lanterna)
	_livre(pos, 1.2)


func _pedra_mirante(pos: Vector3) -> void:
	var pedra := M.criar("pedra2", 3.2, -1)
	pedra.position = pos - Vector3(0, 0.1, 0)
	pedra.rotation.y = 0.4
	add_child(pedra)
	var t := Transform3D(Basis(Vector3.UP, 0.4), pos + Vector3(0, 0.6, 0))
	add_child(U.solido(U.forma_caixa(Vector3(2.8, 1.2, 2.4)), t))
	_livre(pos, 3.0)


## Pedras com musgo espalhadas (4 modelos do Meshy, tamanhos variados).
func _espalhar_pedras(t: Node3D, n: int) -> void:
	for p in _sortear_pontos(t, 4.0, n, 2.0):
		var tam := _rng.randf_range(0.7, 2.4)
		var pedra := M.criar("pedra%d" % _rng.randi_range(1, 4), tam, -1)
		pedra.position = p - Vector3(0, tam * 0.08, 0)
		pedra.rotation.y = _rng.randf() * TAU
		add_child(pedra)
		if tam > 1.3:
			add_child(U.solido(U.forma_cilindro(tam * 0.38, tam * 0.4), Transform3D(Basis(), p + Vector3(0, tam * 0.2, 0))))


# ---------------- Espalhar árvores e flores ----------------


func _livre(p: Vector3, raio: float) -> void:
	_ocupado.append(Vector3(p.x, p.z, raio))


func _esta_livre(p: Vector3, folga: float) -> bool:
	for o in _ocupado:
		if Vector2(p.x - o.x, p.z - o.y).length() < o.z + folga:
			return false
	return true


## Sorteia `n` pontos no chão de uma ilha, longe da borda, de lugares
## ocupados e de encostas íngremes.
func _sortear_pontos(t: Node3D, r_min: float, n: int, folga: float) -> Array[Vector3]:
	var pontos: Array[Vector3] = []
	var tentativas := 0
	while pontos.size() < n and tentativas < 800:
		tentativas += 1
		var ang := _rng.randf() * TAU
		var r_max: float = t.borda(ang) - 1.8
		var r := sqrt(_rng.randf_range(r_min * r_min, r_max * r_max))
		var x: float = t.centro.x + cos(ang) * r
		var z: float = t.centro.z + sin(ang) * r
		if _inclinacao(t, x, z) > 0.45:
			continue
		var p := Vector3(x, t.altura.call(x, z), z)
		if not _esta_livre(p, folga):
			continue
		pontos.append(p)
		_livre(p, folga)
	return pontos


func _espalhar_arvores(t: Node3D, r_min: float, n: int) -> void:
	for p in _sortear_pontos(t, r_min, n, 1.6):
		_pinheiro(p - Vector3(0, 0.1, 0), true)


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


func _espalhar_flores(t: Node3D, r_min: float, n: int, cor: Color) -> void:
	for p in _sortear_pontos(t, r_min, n, 1.0):
		var flor := Flor.new()
		flor.cor = cor
		flor.position = p
		add_child(flor)


## Cachoeira que cai da beirada da ilha (no ângulo `ang`) até o mar de nuvens,
## com um riacho que vem de dentro da ilha seguindo o chão.
func _cachoeira(t: Node3D, ang: float) -> void:
	var borda: Vector3 = t.ponto_borda(ang)
	var dentro := Vector3(t.centro.x - borda.x, 0, t.centro.z - borda.z).normalized()
	var fora := -dentro
	var pos := borda + dentro * 0.2 + Vector3(0, -0.3, 0)
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/cachoeira.gdshader")
	var altura := 45.0
	var quad := QuadMesh.new()
	quad.size = Vector2(2.2, altura)
	var mi := MeshInstance3D.new()
	mi.mesh = quad
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos + fora * 0.3 + Vector3(0, -altura * 0.5 + 0.1, 0)
	mi.rotation.y = atan2(fora.x, fora.z)
	add_child(mi)
	# Riacho: pedacinhos que acompanham o relevo até a beirada.
	for i in 6:
		var c := borda + dentro * (0.5 + i * 0.9)
		var y: float = t.altura.call(c.x, c.z)
		if i == 0:
			y = minf(y, pos.y + 0.25)
		var rio := U.malha(U.caixa(Vector3(1.4 - i * 0.08, 0.06, 1.05)), Color(0.7, 0.82, 0.9))
		rio.position = Vector3(c.x, y + 0.04, c.z)
		rio.rotation.y = atan2(dentro.x, dentro.z)
		rio.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(rio)
	_livre(borda + dentro * 2.5, 3.5)
