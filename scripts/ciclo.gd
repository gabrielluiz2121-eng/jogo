extends Node
## Ciclo de dia e noite: move o sol (e a lua), muda as cores do céu,
## da neblina, das nuvens e acende as lanternas e flores à noite.

## Quantos segundos dura um dia inteiro no jogo.
const DURACAO_DIA := 480.0
## Hora em que o jogo começa (0 = meia-noite, 0.25 = amanhecer, 0.5 = meio-dia).
const HORA_INICIAL := 0.29
## Segure T para o tempo passar rápido (bom para ver o ciclo).
const ACELERACAO := 25.0

var hora := HORA_INICIAL
var sol: DirectionalLight3D
var ambiente: Environment
var ceu: ShaderMaterial
var nuvens: Array[ShaderMaterial] = []
var tela: ShaderMaterial

## Cores-chave ao longo do dia: [hora, topo do céu, horizonte, cor do sol,
## força do sol, luz ambiente, neblina]. Entre elas, as cores se misturam.
var _chaves := [
	[0.00, Color(0.05, 0.08, 0.17), Color(0.15, 0.19, 0.3), Color(0.6, 0.7, 1.0), 0.3, Color(0.2, 0.24, 0.38), Color(0.16, 0.2, 0.3)],
	[0.21, Color(0.12, 0.15, 0.3), Color(0.45, 0.35, 0.4), Color(0.7, 0.6, 0.8), 0.1, Color(0.28, 0.27, 0.38), Color(0.35, 0.3, 0.38)],
	[0.25, Color(0.3, 0.35, 0.55), Color(0.95, 0.65, 0.45), Color(1.0, 0.6, 0.35), 0.05, Color(0.42, 0.38, 0.45), Color(0.8, 0.62, 0.52)],
	[0.31, Color(0.48, 0.6, 0.76), Color(1.0, 0.86, 0.6), Color(1.0, 0.8, 0.55), 1.15, Color(0.55, 0.55, 0.62), Color(0.86, 0.84, 0.8)],
	[0.50, Color(0.5, 0.66, 0.85), Color(0.94, 0.93, 0.87), Color(1.0, 0.96, 0.9), 1.3, Color(0.6, 0.64, 0.72), Color(0.8, 0.84, 0.88)],
	[0.68, Color(0.45, 0.52, 0.72), Color(1.0, 0.78, 0.52), Color(1.0, 0.72, 0.45), 1.1, Color(0.56, 0.5, 0.55), Color(0.88, 0.76, 0.68)],
	[0.75, Color(0.25, 0.25, 0.45), Color(0.9, 0.5, 0.4), Color(1.0, 0.5, 0.35), 0.05, Color(0.4, 0.33, 0.42), Color(0.7, 0.45, 0.42)],
	[0.80, Color(0.1, 0.13, 0.27), Color(0.35, 0.28, 0.38), Color(0.6, 0.7, 1.0), 0.2, Color(0.25, 0.25, 0.38), Color(0.26, 0.25, 0.35)],
	[1.00, Color(0.05, 0.08, 0.17), Color(0.15, 0.19, 0.3), Color(0.6, 0.7, 1.0), 0.3, Color(0.2, 0.24, 0.38), Color(0.16, 0.2, 0.3)],
]


func _ready() -> void:
	if not InputMap.has_action("acelerar_tempo"):
		InputMap.add_action("acelerar_tempo")
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_T
		InputMap.action_add_event("acelerar_tempo", ev)


func _process(delta: float) -> void:
	var vel := ACELERACAO if Input.is_action_pressed("acelerar_tempo") else 1.0
	hora = fmod(hora + delta * vel / DURACAO_DIA, 1.0)
	aplicar()


func aplicar() -> void:
	var k := _amostrar(hora)
	var topo: Color = k[0]
	var horizonte: Color = k[1]
	var cor_sol: Color = k[2]
	var forca: float = k[3]
	var amb: Color = k[4]
	var neblina: Color = k[5]
	var noite := noite_fator()

	# Sol durante o dia; à noite, a mesma luz vira a lua (do lado oposto).
	var a := (hora - 0.25) * TAU
	var dir := Vector3(cos(a), sin(a) * 0.8, 0.45 + sin(a) * 0.25).normalized()
	if dir.y < 0.0:
		dir = -dir
	if sol:
		sol.look_at_from_position(Vector3.ZERO, -dir, Vector3.UP)
		sol.light_color = cor_sol
		sol.light_energy = forca
	if ambiente:
		ambiente.ambient_light_color = amb
		ambiente.fog_light_color = neblina
		ambiente.fog_sun_scatter = 0.6 * (1.0 - noite)
	if ceu:
		ceu.set_shader_parameter("cor_topo", topo)
		ceu.set_shader_parameter("cor_horizonte", horizonte)
		ceu.set_shader_parameter("cor_baixo", neblina.lerp(Color.WHITE, 0.3))
		ceu.set_shader_parameter("cor_nuvem", horizonte.lerp(Color(1, 0.97, 0.92), 0.5).darkened(noite * 0.5))
		ceu.set_shader_parameter("cor_halo", cor_sol)
		ceu.set_shader_parameter("estrelas", noite)
		ceu.set_shader_parameter("forca_raios", 1.0 - noite)
		ceu.set_shader_parameter("tamanho_astro", lerpf(1.0, 0.6, noite))
	var luz_nuvem := horizonte.lerp(Color(1, 1, 1), 0.55) * lerpf(1.0, 0.45, noite)
	var sombra_nuvem := amb.lerp(topo, 0.3).lightened(0.15)
	for m in nuvens:
		m.set_shader_parameter("cor_luz", luz_nuvem)
		m.set_shader_parameter("cor_sombra", sombra_nuvem)
	if tela:
		tela.set_shader_parameter("cor_papel", Color(0.97, 0.94, 0.87).lerp(Color(0.75, 0.8, 0.95), noite * 0.6))
	for n in get_tree().get_nodes_in_group("brilha_a_noite"):
		var base: float = n.get_meta("brilho_base", 1.0)
		n.material_override.set_shader_parameter("brilho", base * (1.0 + noite * 2.5))


## 0 de dia, 1 no meio da noite.
func noite_fator() -> float:
	var altura_sol := sin((hora - 0.25) * TAU)
	return clampf(-altura_sol * 3.0 + 0.1, 0.0, 1.0)


func nome_periodo() -> String:
	if hora < 0.22 or hora >= 0.8:
		return "Noite"
	if hora < 0.33:
		return "Amanhecer"
	if hora < 0.45:
		return "Manhã"
	if hora < 0.62:
		return "Tarde"
	return "Entardecer"


func _amostrar(t: float) -> Array:
	for i in _chaves.size() - 1:
		var a: Array = _chaves[i]
		var b: Array = _chaves[i + 1]
		if t >= a[0] and t <= b[0]:
			var f: float = smoothstep(0.0, 1.0, (t - a[0]) / (b[0] - a[0]))
			var r := []
			for j in range(1, a.size()):
				if a[j] is Color:
					r.append((a[j] as Color).lerp(b[j], f))
				else:
					r.append(lerpf(a[j], b[j], f))
			return r
	return _chaves[0].slice(1)
