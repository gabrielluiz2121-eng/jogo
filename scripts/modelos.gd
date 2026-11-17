extends RefCounted
## Carrega os modelos do Meshy (pasta modelos/) já no tamanho certo e com o
## material de aquarela por cima da textura pintada.
##
## Os arquivos em modelos/ são as versões leves (poucos polígonos) dos .glb
## que estão em meshy/modelos/ na pasta do Gabriel.

const SHADER_AQUARELA = preload("res://shaders/aquarela.gdshader")


## Instancia `modelos/<nome>.glb`.
## `medida`: tamanho em metros; `eixo`: qual medida usar (0 = largura X,
## 1 = altura Y, 2 = profundidade Z, -1 = a maior delas).
## O resultado fica com a base em y = 0 e centralizado em X e Z.
## `cor` tinge a textura (branco = sem mudança); `brilho` > 0 faz brilhar à noite.
static func criar(nome: String, medida: float, eixo := 1, cor := Color(1.12, 1.12, 1.12), brilho := 0.0) -> Node3D:
	var cena: Node3D = load("res://modelos/%s.glb" % nome).instantiate()
	var raiz := Node3D.new()
	raiz.name = nome.capitalize()
	raiz.add_child(cena)
	var caixa := limites(cena)
	var tam: float = caixa.size[eixo] if eixo >= 0 else maxf(caixa.size.x, maxf(caixa.size.y, caixa.size.z))
	var escala := medida / maxf(tam, 0.0001)
	cena.scale = Vector3.ONE * escala
	var c := caixa.get_center()
	cena.position = -Vector3(c.x, caixa.position.y, c.z) * escala
	aquarela(cena, cor, brilho)
	return raiz


## Caixa que envolve todas as malhas (no espaço do nó `cena`).
static func limites(cena: Node3D) -> AABB:
	var total := AABB()
	var primeiro := true
	for mi in cena.find_children("*", "MeshInstance3D", true, false):
		var t: Transform3D = cena.global_transform.affine_inverse() * mi.global_transform if cena.is_inside_tree() else _transform_relativo(cena, mi)
		var a: AABB = t * mi.get_aabb()
		total = a if primeiro else total.merge(a)
		primeiro = false
	return total


static func _transform_relativo(raiz: Node3D, no: Node3D) -> Transform3D:
	var t := Transform3D()
	var n: Node = no
	while n and n != raiz:
		if n is Node3D:
			t = n.transform * t
		n = n.get_parent()
	return t


## Troca o material do Meshy pelo de aquarela, mantendo a textura pintada
## (ou as cores pintadas nos vértices, como nas copas do pinheiro).
static func aquarela(cena: Node, cor: Color, brilho: float) -> void:
	for mi in cena.find_children("*", "MeshInstance3D", true, false):
		var malha: MeshInstance3D = mi
		var n := malha.mesh.get_surface_count()
		for s in n:
			var antigo := malha.get_active_material(s)
			var novo := ShaderMaterial.new()
			novo.shader = SHADER_AQUARELA
			novo.set_shader_parameter("cor", cor)
			novo.set_shader_parameter("manchas", 0.06)
			novo.set_shader_parameter("manchas_locais", true)
			novo.set_shader_parameter("brilho", brilho)
			if antigo is BaseMaterial3D:
				if antigo.albedo_texture:
					novo.set_shader_parameter("textura", antigo.albedo_texture)
					novo.set_shader_parameter("usa_textura", true)
				if antigo.vertex_color_use_as_albedo:
					novo.set_shader_parameter("usa_cor_vertice", true)
			if n == 1:
				malha.material_override = novo
			else:
				malha.set_surface_override_material(s, novo)
		if brilho > 0.0 and n == 1:
			malha.set_meta("brilho_base", brilho)
			malha.add_to_group("brilha_a_noite")


## Muda a cor (tinta) de todas as malhas de um modelo já criado.
static func tingir(modelo: Node, cor: Color) -> void:
	for mi in modelo.find_children("*", "MeshInstance3D", true, false):
		if mi.material_override is ShaderMaterial:
			mi.material_override.set_shader_parameter("cor", cor)
		for s in mi.mesh.get_surface_count():
			var m = mi.get_surface_override_material(s)
			if m is ShaderMaterial:
				m.set_shader_parameter("cor", cor)
