extends "res://scripts/interagivel.gd"
## Barco mercador voador (junco chinês, modelo do Meshy).
## Chega de tempos em tempos, compra seu chá e entrega o que você encomendou.
## Fica na origem do mundo; `ponto_cais` e `pos_atracado` são posições do mundo.

const U = preload("res://scripts/util.gd")
const M = preload("res://scripts/modelos.gd")

## --- Ajuste o ritmo do jogo aqui ---
const PRIMEIRA_VISITA := 20.0  # segundos até a primeira chegada
const TEMPO_FORA := 70.0       # segundos longe entre uma visita e outra
const TEMPO_NO_CAIS := 50.0    # segundos parado no cais
const TEMPO_VIAGEM := 9.0      # segundos para chegar/partir

enum Estado { FORA, CHEGANDO, NO_CAIS, PARTINDO }

signal partiu

var ponto_cais := Vector3.ZERO
var pos_atracado := Vector3.ZERO
var pos_chegada := Vector3(90, 30, 110)
var pos_partida := Vector3(-90, 30, 110)

var estado := Estado.FORA
var _cronometro := PRIMEIRA_VISITA
var barco: Node3D


func _ready() -> void:
	raio_interacao = 3.5
	barco = _montar_barco()
	add_child(barco)
	barco.position = pos_chegada
	barco.visible = false


func _montar_barco() -> Node3D:
	var b := Node3D.new()
	# Junco voador (modelo do Meshy). No arquivo a proa aponta para -X;
	# aqui ela precisa apontar para -Z. O convés fica em y = 0.62.
	var modelo := M.criar("barco", 10.0, 0)
	modelo.rotation.y = -PI * 0.5
	modelo.position.y = 0.62 - 1.9
	b.add_child(modelo)
	# Lanternas brilhando à noite (as do modelo são só pintura).
	for p in [Vector3(1.3, 2.4, 3.6), Vector3(-1.3, 2.4, 3.6)]:
		var luz := OmniLight3D.new()
		luz.position = p
		luz.light_color = Color(1.0, 0.55, 0.3)
		luz.light_energy = 0.6
		luz.omni_range = 4.0
		b.add_child(luz)
	# A criatura mercadora (placeholder: corpo, cabeça e orelhas).
	var criatura := Node3D.new()
	criatura.position = Vector3(-1.0, 0.65, 1.0)
	criatura.add_child(U.malha(U.esfera(0.45, 10), Color(0.85, 0.7, 0.4), Vector3(0, 0.45, 0)))
	criatura.add_child(U.malha(U.esfera(0.3, 10), Color(0.9, 0.78, 0.5), Vector3(0, 1.05, 0)))
	for x in [-0.15, 0.15]:
		criatura.add_child(U.malha(U.cilindro(0.0, 0.1, 0.3, 5), Color(0.8, 0.6, 0.35), Vector3(x, 1.4, 0)))
	b.add_child(criatura)
	return b


func _process(delta: float) -> void:
	match estado:
		Estado.FORA:
			_cronometro -= delta
			if _cronometro <= 0.0:
				_chegar()
		Estado.NO_CAIS:
			_cronometro -= delta
			# Balança de leve, como se flutuasse no vento.
			barco.position.y = pos_atracado.y + sin(Time.get_ticks_msec() / 700.0) * 0.15
			if _cronometro <= 0.0:
				_partir()


func _chegar() -> void:
	estado = Estado.CHEGANDO
	barco.visible = true
	barco.position = pos_chegada
	_virar_para(pos_atracado)
	var t := create_tween()
	t.tween_property(barco, "position", pos_atracado, TEMPO_VIAGEM).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(barco, "rotation:y", 0.0, TEMPO_VIAGEM).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.finished.connect(_atracou)
	Jogo.avisar("Um barco mercador se aproxima pelo céu!")


func _atracou() -> void:
	estado = Estado.NO_CAIS
	_cronometro = TEMPO_NO_CAIS
	var entregou := false
	for item in Jogo.encomenda:
		var n: int = Jogo.encomenda[item]
		if n > 0:
			Jogo.adicionar(item, n)
			Jogo.encomenda[item] = 0
			entregou = true
	if entregou:
		Jogo.avisar("O mercador chegou e entregou sua encomenda!")
	else:
		Jogo.avisar("O barco mercador atracou no cais.")


func _partir() -> void:
	estado = Estado.PARTINDO
	partiu.emit()
	_virar_para(pos_partida)
	var t := create_tween()
	t.tween_property(barco, "position", pos_partida, TEMPO_VIAGEM).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.finished.connect(_sumiu)
	Jogo.avisar("O barco mercador partiu.")


func _sumiu() -> void:
	estado = Estado.FORA
	_cronometro = TEMPO_FORA
	barco.visible = false


func _virar_para(alvo: Vector3) -> void:
	var dir := alvo - barco.position
	dir.y = 0
	if dir.length() > 0.1:
		barco.rotation.y = atan2(-dir.x, -dir.z)


## Texto para o canto da tela.
func status() -> String:
	match estado:
		Estado.FORA:
			return "Barco mercador chega em %ds" % ceili(_cronometro)
		Estado.CHEGANDO:
			return "Barco mercador chegando..."
		Estado.NO_CAIS:
			return "Barco no cais! Parte em %ds" % ceili(_cronometro)
	return "Barco mercador partindo..."


func ponto_interacao() -> Vector3:
	return ponto_cais


func texto_interacao(_jogador: Node) -> String:
	if estado == Estado.NO_CAIS:
		return "E: negociar com o mercador"
	return ""


func interagir(_jogador: Node) -> void:
	if estado != Estado.NO_CAIS:
		return
	var hud := get_tree().get_first_node_in_group("hud")
	if hud:
		hud.abrir_loja()
