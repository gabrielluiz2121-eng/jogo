extends Node3D
## Base de tudo com que o jogador pode interagir apertando E.
## Os outros scripts (flor, secador, mercador, ponte) estendem este.

## Distância máxima para poder interagir.
var raio_interacao := 2.2


func _enter_tree() -> void:
	add_to_group("interagivel")


## Onde fica o "ponto" de interação no mundo.
func ponto_interacao() -> Vector3:
	return global_position


## Texto mostrado na tela. Vazio = não dá para interagir agora.
func texto_interacao(_jogador: Node) -> String:
	return ""


func interagir(_jogador: Node) -> void:
	pass
