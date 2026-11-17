extends RefCounted
## Liga o filtro de aquarela e nanquim na câmera do jogador.
## Para ver o jogo "cru" (sem filtro), mude ATIVO para false.

const ATIVO := true
## Contornos de nanquim. Para linhas mais fortes, aumente FORCA_CONTORNO
## (0 = sem linhas, 1 = bem marcadas) ou escureça COR_TINTA.
const COR_TINTA := Color(0.3, 0.27, 0.25)  # sépia acinzentado, não preto
const FORCA_CONTORNO := 0.5
const ESPESSURA := 1.15  # pixels
## Linhas de dobra (dentro dos objetos). 0 = só o contorno de fora.
const FORCA_DOBRAS := 0.2
const U = preload("res://scripts/util.gd")
const SHADER_TELA = preload("res://shaders/tela_aquarela.gdshader")


static func aplicar(camera: Camera3D) -> ShaderMaterial:
	if not ATIVO:
		return null
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	var mat := ShaderMaterial.new()
	mat.shader = SHADER_TELA
	mat.set_shader_parameter("compatibilidade", U.modo_compatibilidade())
	mat.set_shader_parameter("cor_tinta", COR_TINTA)
	mat.set_shader_parameter("forca_contorno", FORCA_CONTORNO)
	mat.set_shader_parameter("espessura", ESPESSURA)
	mat.set_shader_parameter("forca_dobras", FORCA_DOBRAS)
	# Desenha antes das nuvens transparentes, para elas ficarem por cima.
	mat.render_priority = -128
	var mi := MeshInstance3D.new()
	mi.mesh = quad
	mi.material_override = mat
	mi.extra_cull_margin = 16384.0
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(0, 0, -1)
	camera.add_child(mi)
	return mat
