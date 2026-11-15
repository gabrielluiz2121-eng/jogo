extends CharacterBody3D
## A camponesa/o camponês: anda em terceira pessoa com câmera orbital.

const U = preload("res://scripts/util.gd")
const Campones = preload("res://scripts/campones.gd")

const VEL_ANDAR := 5.0
const VEL_CORRER := 8.5
const FORCA_PULO := 5.5
const SENSIBILIDADE_MOUSE := 0.003
const ALTURA_QUEDA := -35.0  # abaixo disso, volta para o último chão seguro

signal alvo_mudou(texto: String)

var gravidade: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var pivo: Node3D
var braco: SpringArm3D
var camera: Camera3D
var modelo: Node3D
var alvo_atual: Node = null
var _texto_alvo := ""
var _ponto_seguro := Vector3.ZERO
var _tempo_seguro := 0.0


func _ready() -> void:
	add_to_group("jogador")
	_montar()
	_ponto_seguro = global_position
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _montar() -> void:
	var col := CollisionShape3D.new()
	var capsula := CapsuleShape3D.new()
	capsula.radius = 0.35
	capsula.height = 1.7
	col.shape = capsula
	col.position.y = 0.85
	add_child(col)

	# O camponês (modelo e animação ficam em scripts/campones.gd).
	modelo = Campones.new()
	add_child(modelo)

	pivo = Node3D.new()
	pivo.position.y = 1.5
	add_child(pivo)
	braco = SpringArm3D.new()
	braco.spring_length = 6.0
	var esfera := SphereShape3D.new()
	esfera.radius = 0.25
	braco.shape = esfera
	braco.add_excluded_object(get_rid())
	pivo.add_child(braco)
	pivo.rotation.x = -0.35
	camera = Camera3D.new()
	camera.fov = 70
	braco.add_child(camera)


func _unhandled_input(event: InputEvent) -> void:
	if Jogo.em_menu:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		pivo.rotation.y -= event.relative.x * SENSIBILIDADE_MOUSE
		pivo.rotation.x = clampf(pivo.rotation.x - event.relative.y * SENSIBILIDADE_MOUSE, -1.3, 0.4)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			braco.spring_length = maxf(2.5, braco.spring_length - 0.5)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			braco.spring_length = minf(14.0, braco.spring_length + 0.5)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event.is_action_pressed("interagir") and alvo_atual != null:
		modelo.colher()
		alvo_atual.interagir(self)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravidade * delta

	var entrada := Vector2.ZERO
	if not Jogo.em_menu:
		entrada = Input.get_vector("mover_esquerda", "mover_direita", "mover_frente", "mover_tras")
		if Input.is_action_just_pressed("pular") and is_on_floor():
			velocity.y = FORCA_PULO

	# A direção é relativa para onde a câmera está olhando.
	var direcao := Basis(Vector3.UP, pivo.rotation.y) * Vector3(entrada.x, 0, entrada.y)
	var vel := VEL_CORRER if Input.is_action_pressed("correr") else VEL_ANDAR
	if direcao.length() > 0.01:
		velocity.x = direcao.x * vel
		velocity.z = direcao.z * vel
		var angulo := atan2(-direcao.x, -direcao.z)
		modelo.rotation.y = lerp_angle(modelo.rotation.y, angulo, 12.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, 40.0 * delta)
		velocity.z = move_toward(velocity.z, 0, 40.0 * delta)

	move_and_slide()
	modelo.animar(delta, Vector2(velocity.x, velocity.z).length(), is_on_floor(), velocity.y)

	if is_on_floor():
		_tempo_seguro += delta
		if _tempo_seguro > 0.5:
			_tempo_seguro = 0.0
			_ponto_seguro = global_position
	if global_position.y < ALTURA_QUEDA:
		global_position = _ponto_seguro + Vector3(0, 0.5, 0)
		velocity = Vector3.ZERO
		Jogo.avisar("Ufa! Cuidado com a beirada da ilha.")

	_procurar_alvo()


## Acha a coisa interativa mais próxima (flor, varal, barco, obra...).
func _procurar_alvo() -> void:
	var melhor: Node = null
	var melhor_dist := INF
	var texto := ""
	for n in get_tree().get_nodes_in_group("interagivel"):
		var t: String = n.texto_interacao(self)
		if t == "":
			continue
		var d := global_position.distance_to(n.ponto_interacao())
		if d < n.raio_interacao and d < melhor_dist:
			melhor = n
			melhor_dist = d
			texto = t
	if Jogo.em_menu:
		texto = ""
	if melhor != alvo_atual or texto != _texto_alvo:
		alvo_atual = melhor
		_texto_alvo = texto
		alvo_mudou.emit(texto)
