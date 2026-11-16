extends Node3D
## O camponês feito no Meshy e animado no Mixamo.
## Mesma "interface" do boneco simples (campones.gd): animar() e colher().
##
## Animações (personagem/animacoes.res, gerado por ferramentas/importar_animacoes.gd):
## parado, andar, correr, pular, colher.

const U = preload("res://scripts/util.gd")
const MODELO = preload("res://personagem/campones.fbx")
const ANIMACOES = preload("res://personagem/animacoes.res")
const SHADER_AQUARELA = preload("res://shaders/aquarela.gdshader")

## Altura do personagem no jogo (metros).
const ALTURA := 1.75
## Velocidade (m/s) em que as animações de andar e correr "encaixam" com os pés.
const VEL_NATURAL_ANDAR := 1.35
const VEL_NATURAL_CORRER := 3.9
## Trecho da animação de colher que é tocado (segundos).
const COLHER_INICIO := 0.0
const COLHER_FIM := 1.7

var _anim: AnimationPlayer
var _atual := ""
var _colhendo := 0.0
var _ar := 0.0


func _ready() -> void:
	var cena: Node3D = MODELO.instantiate()
	add_child(cena)
	# O modelo do Mixamo vem minúsculo e de costas para a frente do jogo (-Z).
	var esqueleto: Skeleton3D = cena.find_children("*", "Skeleton3D")[0]
	var altura_original := _altura(esqueleto)
	var escala := ALTURA / altura_original if altura_original > 0.0 else 1.0
	cena.scale = Vector3.ONE * escala
	cena.rotation.y = PI
	_aplicar_aquarela(cena)

	_anim = cena.find_children("*", "AnimationPlayer")[0]
	_anim.add_animation_library("c", ANIMACOES)
	_tocar("parado")


func _altura(esqueleto: Skeleton3D) -> float:
	var topo := esqueleto.find_bone("mixamorig_HeadTop_End")
	var pe := esqueleto.find_bone("mixamorig_LeftToe_End")
	if topo < 0 or pe < 0:
		return 0.0
	return esqueleto.get_bone_global_rest(topo).origin.y - esqueleto.get_bone_global_rest(pe).origin.y


## Troca o material do Meshy pelo de aquarela, mantendo a textura pintada.
func _aplicar_aquarela(cena: Node) -> void:
	for mi in cena.find_children("*", "MeshInstance3D"):
		var malha: MeshInstance3D = mi
		for s in malha.mesh.get_surface_count():
			var antigo := malha.get_active_material(s)
			var novo := ShaderMaterial.new()
			novo.shader = SHADER_AQUARELA
			novo.set_shader_parameter("cor", Color(1.15, 1.15, 1.15))
			novo.set_shader_parameter("manchas", 0.06)
			novo.set_shader_parameter("manchas_locais", true)
			if antigo is BaseMaterial3D and antigo.albedo_texture:
				novo.set_shader_parameter("textura", antigo.albedo_texture)
				novo.set_shader_parameter("usa_textura", true)
			malha.set_surface_override_material(s, novo)


func _tocar(nome: String, mistura := 0.2, velocidade := 1.0) -> void:
	if _atual != nome:
		_anim.play("c/" + nome, mistura)
		_atual = nome
	_anim.speed_scale = velocidade


func colher() -> void:
	_colhendo = COLHER_FIM - COLHER_INICIO
	_anim.play("c/colher", 0.15)
	_anim.seek(COLHER_INICIO, true)
	_anim.speed_scale = 1.0
	_atual = "colher"


## Chamado pelo jogador a cada quadro de física.
func animar(delta: float, velocidade: float, no_chao: bool, vel_vertical: float) -> void:
	if _colhendo > 0.0:
		_colhendo -= delta
		if velocidade < 0.5:
			return  # deixa o gesto terminar se o jogador estiver parado
		_colhendo = 0.0
	_ar = (_ar + delta) if not no_chao else 0.0
	if _ar > 0.12:
		# Pula a parte em que ele se agacha para tomar impulso.
		if _atual != "pular":
			_tocar("pular", 0.1, 1.3)
			_anim.seek(0.55, true)
		return
	if velocidade < 0.3:
		_tocar("parado", 0.25)
	elif velocidade < 4.5:
		_tocar("andar", 0.2, clampf(velocidade / VEL_NATURAL_ANDAR, 0.6, 2.2))
	else:
		_tocar("correr", 0.2, clampf(velocidade / VEL_NATURAL_CORRER, 0.7, 2.0))
