extends Node3D
## Ilha flutuante com relevo de verdade, gerada por código:
## - topo com colinas, morros, terraços e trilhas pintadas (cores por vértice);
## - borda recortada e irregular;
## - penhasco embaixo, em camadas de rocha, com musgo escorrendo da borda;
## - colisão que acompanha o relevo.
##
## Quem decide a altura de cada ponto é a função `altura` (passada pelo main.gd),
## assim o resto do jogo (árvores, flores, varal) consegue saber onde fica o chão.
## Este nó fica na origem do mundo: posições locais = posições do mundo.

const U = preload("res://scripts/util.gd")

var centro := Vector3.ZERO
var raio := 20.0
var profundidade := 16.0
## Callable(x: float, z: float) -> float : altura do chão (mundo).
var altura: Callable
## Listas de pontos (Vector3) das trilhas de terra.
var trilhas: Array = []
## Ângulos (radianos) onde a borda não pode ser recortada (cais, ponte).
var angulos_protegidos: Array = []
var semente := 1

var cor_grama := Color(0.6, 0.66, 0.38)
var cor_grama_2 := Color(0.5, 0.62, 0.42)
var cor_terra := Color(0.72, 0.62, 0.46)
var cor_rocha := Color(0.52, 0.49, 0.46)
var cor_musgo := Color(0.42, 0.52, 0.27)

## Resolução da malha (anéis do centro até a borda e divisões em volta).
var aneis := 44
var divisoes := 140

var _ruido := FastNoiseLite.new()
var _ruido_cor := FastNoiseLite.new()


func _ready() -> void:
	_ruido.seed = semente
	_ruido.frequency = 1.0
	_ruido_cor.seed = semente + 7
	_ruido_cor.frequency = 0.08
	_montar_topo()
	_montar_penhasco()


## Raio da borda num ângulo (recortes irregulares).
func borda(ang: float) -> float:
	var c := cos(ang)
	var s := sin(ang)
	var n := (_ruido.get_noise_2d(c * 1.6, s * 1.6) * 0.5 + 0.5) * 0.75
	n += (_ruido.get_noise_2d(c * 6.0 + 40.0, s * 6.0) * 0.5 + 0.5) * 0.25
	var protecao := 1.0
	for a in angulos_protegidos:
		var dif := absf(wrapf(ang - a, -PI, PI))
		protecao = minf(protecao, smoothstep(0.1, 0.35, dif))
	return raio * (1.0 - 0.16 * n * protecao)


## Ponto da borda (no mundo) num ângulo.
func ponto_borda(ang: float) -> Vector3:
	var r := borda(ang)
	var x := centro.x + cos(ang) * r
	var z := centro.z + sin(ang) * r
	return Vector3(x, altura.call(x, z), z)


# ------------------------------------------------------------------ Topo

func _montar_topo() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Vértice central + anéis.
	var cx := centro.x
	var cz := centro.z
	_vertice(st, cx, cz, 0.0)
	for i in range(1, aneis + 1):
		var f := float(i) / aneis
		for j in divisoes:
			var ang := TAU * j / divisoes
			var r := borda(ang) * f
			_vertice(st, cx + cos(ang) * r, cz + sin(ang) * r, f)
	# Triângulos: leque no centro e faixas entre anéis.
	for j in divisoes:
		var j2 := (j + 1) % divisoes
		st.add_index(0)
		st.add_index(1 + j)
		st.add_index(1 + j2)
	for i in range(1, aneis):
		var a0 := 1 + (i - 1) * divisoes
		var a1 := 1 + i * divisoes
		for j in divisoes:
			var j2 := (j + 1) % divisoes
			st.add_index(a0 + j)
			st.add_index(a1 + j)
			st.add_index(a0 + j2)
			st.add_index(a0 + j2)
			st.add_index(a1 + j)
			st.add_index(a1 + j2)
	st.generate_normals()
	var malha := st.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = malha
	mi.material_override = _material()
	add_child(mi)
	# Colisão seguindo o relevo.
	var corpo := StaticBody3D.new()
	var col := CollisionShape3D.new()
	col.shape = malha.create_trimesh_shape()
	corpo.add_child(col)
	add_child(corpo)


func _vertice(st: SurfaceTool, x: float, z: float, f: float) -> void:
	var y: float = altura.call(x, z)
	# Borda levemente arredondada para baixo.
	y -= 0.4 * smoothstep(0.93, 1.0, f)
	st.set_color(_cor_chao(x, z, f).srgb_to_linear())
	st.set_uv(Vector2(x, z) * 0.1)
	st.add_vertex(Vector3(x, y, z))


func _cor_chao(x: float, z: float, f: float) -> Color:
	# Grama com manchas de dois tons, como aguada.
	var n := _ruido_cor.get_noise_2d(x, z) * 0.5 + 0.5
	var c := cor_grama.lerp(cor_grama_2, smoothstep(0.35, 0.7, n))
	c = c.lerp(c * Color(1.1, 1.05, 0.8), smoothstep(0.7, 0.9, n) * 0.5)
	# Encostas íngremes viram rocha.
	var d := 0.6
	var dx: float = altura.call(x + d, z) - altura.call(x - d, z)
	var dz: float = altura.call(x, z + d) - altura.call(x, z - d)
	var inclinacao := Vector2(dx, dz).length() / (2.0 * d)
	c = c.lerp(cor_rocha, smoothstep(0.7, 1.2, inclinacao))
	# Trilhas de terra (borda irregular).
	var dt := _distancia_trilha(Vector2(x, z))
	var irregular := _ruido_cor.get_noise_2d(x * 4.0, z * 4.0) * 0.35
	c = c.lerp(cor_terra, smoothstep(1.35 + irregular, 0.85 + irregular, dt))
	# Musgo mais escuro perto da borda.
	c = c.lerp(cor_musgo, smoothstep(0.88, 1.0, f) * 0.7)
	return c


func _distancia_trilha(p: Vector2) -> float:
	var melhor := INF
	for trilha in trilhas:
		for i in trilha.size() - 1:
			var a := Vector2(trilha[i].x, trilha[i].z)
			var b := Vector2(trilha[i + 1].x, trilha[i + 1].z)
			var ab := b - a
			var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
			melhor = minf(melhor, p.distance_to(a + ab * t))
	return melhor


## Distância (no plano) até a trilha mais próxima; usado também pelo main.gd.
func distancia_trilha(x: float, z: float) -> float:
	return _distancia_trilha(Vector2(x, z))


# ------------------------------------------------------------------ Penhasco

func _montar_penhasco() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var camadas := 14
	var div := divisoes  # igual ao topo, para a borda encaixar sem frestas
	for k in camadas + 1:
		var t := float(k) / camadas
		for j in div:
			var ang := TAU * j / div
			var rb := borda(ang)
			var bx := centro.x + cos(ang) * rb
			var bz := centro.z + sin(ang) * rb
			var y_borda: float = altura.call(bx, bz) - 0.4
			# Afina para baixo, com saliências irregulares.
			var encolhe := 1.0 - 0.93 * pow(t, 1.35)
			var sal := _ruido.get_noise_2d(cos(ang) * 4.0 + k * 0.7, sin(ang) * 4.0 + 13.0)
			var r := rb * encolhe + sal * (0.5 + 2.0 * t) * (1.0 if k > 0 else 0.0)
			# Degraus de rocha (estratos).
			var degrau: float = floorf(t * 7.0) / 7.0
			var y := lerpf(y_borda, centro.y - profundidade, lerpf(t, degrau, 0.35))
			if k == 0:
				r = rb + 0.02
			if k == camadas:
				r = 0.3
			st.set_color(_cor_rocha(ang, t, y).srgb_to_linear())
			st.add_vertex(Vector3(centro.x + cos(ang) * r, y, centro.z + sin(ang) * r))
	for k in camadas:
		var a0 := k * div
		var a1 := (k + 1) * div
		for j in div:
			var j2 := (j + 1) % div
			st.add_index(a0 + j)
			st.add_index(a1 + j)
			st.add_index(a0 + j2)
			st.add_index(a0 + j2)
			st.add_index(a1 + j)
			st.add_index(a1 + j2)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _material()
	add_child(mi)
	_pendurar_raizes()


func _cor_rocha(ang: float, t: float, y: float) -> Color:
	var n := _ruido.get_noise_2d(cos(ang) * 8.0, sin(ang) * 8.0 + 3.0) * 0.5 + 0.5
	# Faixas de rocha mais clara/escura.
	var faixa := 0.85 + 0.15 * sin(y * 2.3 + n * 3.0)
	var c := cor_rocha * faixa
	c = c.lerp(cor_rocha.darkened(0.25) * Color(0.95, 0.95, 1.05), smoothstep(0.5, 1.0, t))
	# Musgo escorrendo da borda.
	var escorre := 0.08 + 0.22 * n
	c = c.lerp(cor_musgo, smoothstep(escorre + 0.05, escorre - 0.03, t))
	c.a = 1.0
	return c


## Raízes e cipós pendurados embaixo da borda.
func _pendurar_raizes() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = semente
	for i in int(raio * 2.0):
		var ang := rng.randf() * TAU
		var pb := ponto_borda(ang)
		var dentro := Vector3(centro.x - pb.x, 0, centro.z - pb.z).normalized()
		var topo := pb + dentro * rng.randf_range(0.6, 2.5) + Vector3(0, -rng.randf_range(0.6, 2.0), 0)
		var comprimento := rng.randf_range(2.0, 7.0)
		var verde := rng.randf() < 0.5
		var cor := cor_musgo.darkened(0.15) if verde else Color(0.3, 0.24, 0.18)
		var raiz := U.malha(U.cilindro(0.09 if not verde else 0.05, 0.02, comprimento, 4), cor)
		raiz.position = topo - Vector3(0, comprimento * 0.5, 0)
		raiz.rotation = Vector3(rng.randf_range(-0.2, 0.2), 0, rng.randf_range(-0.2, 0.2))
		raiz.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(raiz)


func _material() -> ShaderMaterial:
	var m: ShaderMaterial = U.material(Color.WHITE)
	m.set_shader_parameter("usa_cor_vertice", true)
	m.set_shader_parameter("manchas", 0.12)
	return m
