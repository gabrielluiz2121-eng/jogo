extends SceneTree
## Ferramenta: junta as animações do Mixamo num arquivo só (personagem/animacoes.res).
##
## Como usar (no terminal, dentro da pasta do projeto):
##   godot --headless --import
##   godot --headless -s res://ferramentas/importar_animacoes.gd
##
## Ela lê os .fbx de personagem/fontes/ (parado, andar, correr, pular, colher),
## deixa andar/correr "no lugar" (quem move o personagem é o código), tira a curva
## da animação de andar e corta só o trecho útil da animação de colher.

const FONTES := "res://personagem/fontes/"
const SAIDA := "res://personagem/animacoes.res"
const QUADRIL := "Skeleton3D:mixamorig_Hips"

## [nome, arquivo, repetir?, início (s), fim (s, -1 = até o fim)]
const LISTA := [
	["parado", "parado.fbx", true, 0.0, -1.0],
	["andar", "andar.fbx", true, 0.0, -1.0],
	["correr", "correr.fbx", true, 0.0, -1.0],
	["pular", "pular.fbx", false, 0.0, -1.0],
	["colher", "colher.fbx", false, 0.0, -1.0],
]


func _init() -> void:
	var lib := AnimationLibrary.new()
	for item in LISTA:
		var caminho: String = FONTES + item[1]
		if not ResourceLoader.exists(caminho):
			print("Faltando: ", caminho)
			continue
		var cena: Node = load(caminho).instantiate()
		var ap: AnimationPlayer = cena.find_children("*", "AnimationPlayer")[0]
		var original := ap.get_animation(ap.get_animation_list()[0])
		var an := _cortar(original, item[3], item[4])
		_no_lugar(an)
		if item[0] == "andar":
			_tirar_curva(an)
		an.loop_mode = Animation.LOOP_LINEAR if item[2] else Animation.LOOP_NONE
		lib.add_animation(item[0], an)
		print("%s: %.2fs" % [item[0], an.length])
		cena.free()
	var erro := ResourceSaver.save(lib, SAIDA, ResourceSaver.FLAG_COMPRESS)
	print("Salvo em ", SAIDA, " (erro=", erro, ")")
	quit()


## Copia só o trecho [a, b] da animação.
func _cortar(an: Animation, a: float, b: float) -> Animation:
	if b < 0.0:
		b = an.length
	var nova := Animation.new()
	nova.length = b - a
	for t in an.get_track_count():
		var tipo := an.track_get_type(t)
		var nt := nova.add_track(tipo)
		nova.track_set_path(nt, an.track_get_path(t))
		nova.track_set_interpolation_type(nt, an.track_get_interpolation_type(t))
		# Valor no começo exato do corte.
		nova.track_insert_key(nt, 0.0, _valor(an, t, a))
		for k in an.track_get_key_count(t):
			var tempo := an.track_get_key_time(t, k)
			if tempo > a + 0.0001 and tempo < b - 0.0001:
				nova.track_insert_key(nt, tempo - a, an.track_get_key_value(t, k))
		nova.track_insert_key(nt, b - a, _valor(an, t, b))
	return nova


func _valor(an: Animation, t: int, tempo: float) -> Variant:
	match an.track_get_type(t):
		Animation.TYPE_POSITION_3D:
			return an.position_track_interpolate(t, tempo)
		Animation.TYPE_ROTATION_3D:
			return an.rotation_track_interpolate(t, tempo)
		Animation.TYPE_SCALE_3D:
			return an.scale_track_interpolate(t, tempo)
	return an.track_get_key_value(t, 0)


## Trava o quadril no lugar (mantém só o sobe e desce).
func _no_lugar(an: Animation) -> void:
	var t := an.find_track(NodePath(QUADRIL), Animation.TYPE_POSITION_3D)
	if t < 0:
		return
	var p0: Vector3 = an.track_get_key_value(t, 0)
	for k in an.track_get_key_count(t):
		var p: Vector3 = an.track_get_key_value(t, k)
		an.track_set_key_value(t, k, Vector3(p0.x, p.y, p0.z))


## A animação "Walking Left Turn" vai virando para a esquerda; aqui desfazemos
## o giro aos poucos para ela andar reto.
func _tirar_curva(an: Animation) -> void:
	var t := an.find_track(NodePath(QUADRIL), Animation.TYPE_ROTATION_3D)
	if t < 0:
		return
	var y0 := _guinada(an.track_get_key_value(t, 0))
	var y1 := _guinada(an.track_get_key_value(t, an.track_get_key_count(t) - 1))
	var desvio := wrapf(y1 - y0, -PI, PI)
	for k in an.track_get_key_count(t):
		var f := an.track_get_key_time(t, k) / an.length
		var q: Quaternion = an.track_get_key_value(t, k)
		an.track_set_key_value(t, k, (Quaternion(Vector3.UP, -desvio * f) * q).normalized())


func _guinada(q: Quaternion) -> float:
	var frente := Basis(q) * Vector3.FORWARD
	return atan2(frente.x, frente.z)
