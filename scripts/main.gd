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

const COR_GRAMA := Color(0.42, 0.62, 0.32)
const COR_GRAMA_B := Color(0.5, 0.66, 0.36)
const COR_ROCHA := Color(0.55, 0.5, 0.45)
const COR_TERRA := Color(0.66, 0.54, 0.38)
const COR_MADEIRA := Color(0.5, 0.36, 0.22)

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

	# --- Árvores e pedras ---
	_espalhar_arvores(CENTRO_A, 3.0, RAIO_A - 2.0, 22, 0.0)
	_espalhar_arvores(Vector3(PLATO_A.x, ALTURA_PLATO, PLATO_A.z), 2.0, RAIO_PLATO - 1.5, 5, ALTURA_PLATO, true)
	_espalhar_arvores(CENTRO_B, 2.0, RAIO_B - 2.0, 12, CENTRO_B.y)

	# --- Flores mágicas ---
	_espalhar_flores(CENTRO_A, 4.0, RAIO_A - 2.0, 10, 0.0, Color(0.95, 0.35, 0.75))
	_espalhar_flores(Vector3(PLATO_A.x, ALTURA_PLATO, PLATO_A.z), 1.5, RAIO_PLATO - 1.5, 6, ALTURA_PLATO, Color(0.95, 0.35, 0.75), true)
	_espalhar_flores(CENTRO_B, 2.0, RAIO_B - 2.0, 16, CENTRO_B.y, Color(0.5, 0.6, 1.0))

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
	hud.conectar(jogador, mercador)
	Jogo.avisar("Colha flores mágicas, seque no varal e venda o chá ao barco mercador.")


# ---------------- Ambiente: céu, sol, névoa e mar de nuvens ----------------

func _ambiente() -> void:
	var ceu_mat := ProceduralSkyMaterial.new()
	ceu_mat.sky_top_color = Color(0.38, 0.56, 0.82)
	ceu_mat.sky_horizon_color = Color(0.86, 0.84, 0.78)
	ceu_mat.ground_horizon_color = Color(0.86, 0.84, 0.78)
	ceu_mat.ground_bottom_color = Color(0.92, 0.92, 0.94)
	var ceu := Sky.new()
	ceu.sky_material = ceu_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = ceu
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.88, 0.87, 0.85)
	env.fog_density = 0.006
	env.fog_sky_affect = 0.3
	env.glow_enabled = true
	var mundo := WorldEnvironment.new()
	mundo.environment = env
	add_child(mundo)

	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-48, -35, 0)
	sol.light_color = Color(1.0, 0.95, 0.85)
	sol.shadow_enabled = true
	sol.directional_shadow_max_distance = 120.0
	add_child(sol)

	# Mar de nuvens lá embaixo.
	var plano := PlaneMesh.new()
	plano.size = Vector2(3000, 3000)
	add_child(U.malha(plano, Color(0.95, 0.95, 0.97), Vector3(0, -60, 0)))
	for i in 40:
		var p := Vector3(_rng.randf_range(-250, 250), _rng.randf_range(-58, -45), _rng.randf_range(-250, 250))
		var nuvem := U.malha(U.esfera(_rng.randf_range(6, 16), 8), Color(1, 1, 1), p)
		nuvem.scale = Vector3(1.6, 0.5, 1.0)
		add_child(nuvem)
	# Ilhas distantes só para a paisagem (sem colisão).
	for d in [Vector3(-90, 10, -120), Vector3(130, -5, -80), Vector3(-150, 20, 60), Vector3(40, 30, -200)]:
		var r := _rng.randf_range(10, 25)
		add_child(U.malha(U.cilindro(r, r, 2.0, 10), COR_GRAMA, d))
		add_child(U.malha(U.cilindro(r * 0.95, r * 0.2, r * 0.9, 10), COR_ROCHA, d - Vector3(0, 1.0 + r * 0.45, 0)))


# ---------------- Peças do terreno ----------------

## Ilha flutuante: disco de grama em cima, rocha afinando para baixo.
func _ilha(centro: Vector3, raio: float, profundidade: float, cor: Color) -> void:
	var lados := 18
	add_child(U.malha(U.cilindro(raio, raio, 2.0, lados), cor, centro - Vector3(0, 1.0, 0)))
	add_child(U.malha(U.cilindro(raio * 0.97, raio * 0.15, profundidade, lados), COR_ROCHA, centro - Vector3(0, 2.0 + profundidade * 0.5, 0)))
	add_child(U.solido(U.forma_cilindro(raio, 2.0), Transform3D(Basis(), centro - Vector3(0, 1.0, 0))))


## Morro: um "degrau" mais alto em cima da ilha.
func _plato(base: Vector3, raio: float, altura: float) -> void:
	add_child(U.malha(U.cilindro(raio * 0.96, raio, altura, 14), COR_ROCHA, base + Vector3(0, altura * 0.5, 0)))
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
		var alt := _rng.randf_range(2.5, 4.5)
		add_child(U.malha(U.cilindro(0.2, 0.3, alt, 6), COR_MADEIRA, p + Vector3(0, alt * 0.5, 0)))
		var copa := _rng.randf_range(1.2, 2.0)
		var verde := COR_GRAMA.darkened(_rng.randf_range(0.1, 0.35))
		add_child(U.malha(U.cilindro(0.0, copa, copa * 2.0, 7), verde, p + Vector3(0, alt + copa * 0.6, 0)))
		add_child(U.malha(U.cilindro(0.0, copa * 0.7, copa * 1.5, 7), verde.lightened(0.1), p + Vector3(0, alt + copa * 1.6, 0)))
		add_child(U.solido(U.forma_cilindro(0.35, alt), Transform3D(Basis(), p + Vector3(0, alt * 0.5, 0))))


func _espalhar_flores(centro: Vector3, r_min: float, r_max: float, n: int, altura: float, cor: Color, no_plato := false) -> void:
	for p in _sortear_pontos(centro, r_min, r_max, n, altura, 1.0, no_plato):
		var flor := Flor.new()
		flor.cor = cor
		flor.position = p
		add_child(flor)
