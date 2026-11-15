extends CanvasLayer
## Interface: mochila, avisos, status do barco e a loja do mercador.

var mercador: Node
var ciclo: Node
var _mochila: Label
var _status: Label
var _dica: Label
var _aviso: Label
var _tempo_aviso := 0.0
var _loja: PanelContainer
var _info_loja: Label
var _quadro_abertura := -1


func _ready() -> void:
	add_to_group("hud")
	var raiz := Control.new()
	raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(raiz)

	_mochila = _rotulo(raiz, 20, Control.PRESET_TOP_LEFT, Rect2(16, 16, 300, 200))
	_status = _rotulo(raiz, 20, Control.PRESET_TOP_RIGHT, Rect2(-416, 16, 400, 70))
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_dica = _rotulo(raiz, 24, Control.PRESET_BOTTOM_WIDE, Rect2(0, -130, 0, 40))
	_dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso = _rotulo(raiz, 26, Control.PRESET_TOP_WIDE, Rect2(0, 70, 0, 40))
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.add_theme_color_override("font_color", Color(1.0, 0.92, 0.6))
	var ajuda := _rotulo(raiz, 16, Control.PRESET_BOTTOM_WIDE, Rect2(16, -40, 0, 30))
	ajuda.text = "WASD andar · Shift correr · Espaço pular · Mouse câmera · Roda zoom · E interagir · T acelerar o tempo · Esc soltar mouse"
	ajuda.modulate.a = 0.75

	_montar_loja(raiz)
	Jogo.inventario_mudou.connect(_atualizar_mochila)
	Jogo.mensagem.connect(_mostrar_aviso)
	_atualizar_mochila()


func conectar(jogador: Node, merc: Node, ciclo_dia: Node) -> void:
	mercador = merc
	ciclo = ciclo_dia
	jogador.alvo_mudou.connect(func(t: String) -> void: _dica.text = t)
	merc.partiu.connect(fechar_loja)


## Cria um texto preso a um canto/borda da tela.
## `caixa` = deslocamento (x, y) e tamanho (largura, altura); largura 0 = largura toda.
func _rotulo(pai: Control, tamanho: int, ancora: Control.LayoutPreset, caixa: Rect2) -> Label:
	var l := Label.new()
	pai.add_child(l)
	l.set_anchors_preset(ancora)
	l.offset_left = caixa.position.x
	l.offset_top = caixa.position.y
	l.offset_bottom = caixa.position.y + caixa.size.y
	if caixa.size.x > 0:
		l.offset_right = caixa.position.x + caixa.size.x
	else:
		l.offset_right = -caixa.position.x
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _process(delta: float) -> void:
	if mercador:
		_status.text = mercador.status()
		if ciclo:
			_status.text = ciclo.nome_periodo() + "\n" + _status.text
	if _tempo_aviso > 0.0:
		_tempo_aviso -= delta
		_aviso.modulate.a = clampf(_tempo_aviso, 0.0, 1.0)


func _atualizar_mochila() -> void:
	var i := Jogo.inventario
	_mochila.text = "Mochila\nFlores: %d/%d\nChá: %d\nMoedas: %d\nTábuas: %d\nCordas: %d" % [
		i.flores, Jogo.CAPACIDADE_FLORES, i.cha, i.moedas, i.tabuas, i.cordas]
	if _loja and _loja.visible:
		_atualizar_loja()


func _mostrar_aviso(texto: String) -> void:
	_aviso.text = texto
	_tempo_aviso = 4.0
	_aviso.modulate.a = 1.0


# ---------------- Loja do mercador ----------------

func _montar_loja(raiz: Control) -> void:
	_loja = PanelContainer.new()
	_loja.set_anchors_preset(Control.PRESET_CENTER)
	_loja.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_loja.grow_vertical = Control.GROW_DIRECTION_BOTH
	_loja.custom_minimum_size = Vector2(460, 0)
	raiz.add_child(_loja)
	var margem := MarginContainer.new()
	for lado in ["left", "right", "top", "bottom"]:
		margem.add_theme_constant_override("margin_" + lado, 18)
	_loja.add_child(margem)
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 8)
	margem.add_child(caixa)

	var titulo := Label.new()
	titulo.text = "Mercador do Céu"
	titulo.add_theme_font_size_override("font_size", 28)
	titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caixa.add_child(titulo)
	_info_loja = Label.new()
	_info_loja.add_theme_font_size_override("font_size", 18)
	caixa.add_child(_info_loja)

	_botao(caixa, "Vender todo o chá (%d moedas cada)" % Jogo.PRECO_CHA, _vender_cha)
	_botao(caixa, "Encomendar 1 tábua (%d moedas)" % Jogo.PRECO_TABUA, func() -> void: _encomendar("tabuas", 1, Jogo.PRECO_TABUA))
	_botao(caixa, "Encomendar 1 corda (%d moedas)" % Jogo.PRECO_CORDA, func() -> void: _encomendar("cordas", 1, Jogo.PRECO_CORDA))
	var kit := 8 * Jogo.PRECO_TABUA + 4 * Jogo.PRECO_CORDA
	_botao(caixa, "Kit da ponte: 8 tábuas + 4 cordas (%d moedas)" % kit, _encomendar_kit)
	_botao(caixa, "Fechar (Esc)", fechar_loja)
	_loja.visible = false


func _botao(pai: Control, texto: String, acao: Callable) -> void:
	var b := Button.new()
	b.text = texto
	b.add_theme_font_size_override("font_size", 18)
	b.pressed.connect(acao)
	pai.add_child(b)


func abrir_loja() -> void:
	_loja.visible = true
	_quadro_abertura = Engine.get_process_frames()
	Jogo.em_menu = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_atualizar_loja()


func fechar_loja() -> void:
	if not _loja.visible:
		return
	_loja.visible = false
	Jogo.em_menu = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if Engine.get_process_frames() == _quadro_abertura:
		return  # a mesma tecla E que abriu a loja não deve fechá-la
	if _loja.visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("interagir")):
		fechar_loja()
		get_viewport().set_input_as_handled()


func _atualizar_loja() -> void:
	var e := Jogo.encomenda
	var txt := "Você tem %d chá e %d moedas." % [Jogo.qtd("cha"), Jogo.qtd("moedas")]
	if e.tabuas > 0 or e.cordas > 0:
		txt += "\nEncomenda: %d tábuas e %d cordas\n(chegam na próxima visita do barco)" % [e.tabuas, e.cordas]
	else:
		txt += "\nO que você encomendar chega na próxima visita."
	_info_loja.text = txt


func _vender_cha() -> void:
	var n := Jogo.qtd("cha")
	if n == 0:
		Jogo.avisar("Você não tem chá para vender.")
		return
	Jogo.remover("cha", n)
	Jogo.adicionar("moedas", n * Jogo.PRECO_CHA)
	Jogo.avisar("Vendeu %d chá por %d moedas." % [n, n * Jogo.PRECO_CHA])


func _encomendar(item: String, n: int, preco: int) -> void:
	if not Jogo.remover("moedas", preco):
		Jogo.avisar("Moedas insuficientes.")
		return
	Jogo.encomenda[item] += n
	_atualizar_loja()


func _encomendar_kit() -> void:
	var custo := 8 * Jogo.PRECO_TABUA + 4 * Jogo.PRECO_CORDA
	if not Jogo.remover("moedas", custo):
		Jogo.avisar("Moedas insuficientes (precisa de %d)." % custo)
		return
	Jogo.encomenda.tabuas += 8
	Jogo.encomenda.cordas += 4
	_atualizar_loja()
