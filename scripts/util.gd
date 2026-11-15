extends RefCounted
## Funções de ajuda para montar formas simples (protótipo cinza).


static func material(cor: Color, brilho: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.95
	if brilho > 0.0:
		m.emission_enabled = true
		m.emission = cor
		m.emission_energy_multiplier = brilho
	if cor.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


static func caixa(tam: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = tam
	return b


static func cilindro(raio_topo: float, raio_base: float, altura: float, lados: int = 10) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = raio_topo
	c.bottom_radius = raio_base
	c.height = altura
	c.radial_segments = lados
	c.rings = 1
	return c


static func esfera(raio: float, lados: int = 10) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = raio
	s.height = raio * 2.0
	s.radial_segments = lados
	s.rings = maxi(lados / 2, 3)
	return s


static func malha(mesh: Mesh, cor: Color, pos: Vector3 = Vector3.ZERO, brilho: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material(cor, brilho)
	mi.position = pos
	return mi


## Cria um corpo sólido (o jogador colide com ele).
static func solido(forma: Shape3D, transformacao: Transform3D) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	corpo.transform = transformacao
	var col := CollisionShape3D.new()
	col.shape = forma
	corpo.add_child(col)
	return corpo


static func forma_caixa(tam: Vector3) -> BoxShape3D:
	var f := BoxShape3D.new()
	f.size = tam
	return f


static func forma_cilindro(raio: float, altura: float) -> CylinderShape3D:
	var f := CylinderShape3D.new()
	f.radius = raio
	f.height = altura
	return f


## Transform de uma "prancha" inclinada que vai de `de` até `ate`.
## A face de cima da prancha fica exatamente sobre a linha entre os dois pontos.
static func transform_prancha(de: Vector3, ate: Vector3, espessura: float) -> Transform3D:
	var dir := (ate - de).normalized()
	var base := Basis.looking_at(dir, Vector3.UP)
	var meio := (de + ate) * 0.5 - base.y * espessura * 0.5
	return Transform3D(base, meio)
