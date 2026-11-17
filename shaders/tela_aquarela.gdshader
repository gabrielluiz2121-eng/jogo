// Pos-processamento da tela inteira: contorno de nanquim, borda de tinta
// acumulada, textura de papel e leve sangramento da aquarela.
// Fica num retangulo colado na camera (ver scripts/estilo.gd).
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, depth_test_disabled, fog_disabled, shadows_disabled;

// --- Funcoes de ruido (manchas de tinta, papel, nuvens) ---

float hash3(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float ruido3(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(mix(hash3(i + vec3(0, 0, 0)), hash3(i + vec3(1, 0, 0)), f.x),
			mix(hash3(i + vec3(0, 1, 0)), hash3(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash3(i + vec3(0, 0, 1)), hash3(i + vec3(1, 0, 1)), f.x),
			mix(hash3(i + vec3(0, 1, 1)), hash3(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

float fbm3(vec3 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * ruido3(p);
		p *= 2.03;
		a *= 0.5;
	}
	return v;
}

float ruido2(vec2 p) {
	return ruido3(vec3(p, 0.37));
}

float fbm2(vec2 p) {
	return fbm3(vec3(p, 0.37));
}

uniform sampler2D tela : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D profundidade : hint_depth_texture, filter_nearest;

uniform vec3 cor_tinta : source_color = vec3(0.12, 0.11, 0.12);
uniform vec3 cor_papel : source_color = vec3(0.97, 0.94, 0.87);
uniform float espessura = 1.6;          // grossura da linha (pixels)
uniform float forca_contorno = 0.85;
uniform float forca_dobras = 0.6;       // linhas de dobra dentro dos objetos
uniform float distancia_some = 150.0;    // linhas somem longe, como na pintura
uniform float forca_papel = 0.16;
uniform float sangramento = 0.0012;      // quanto a tinta "escorre"
uniform float borda_tinta = 0.35;
uniform float exposicao = 1.35;           // claridade geral da pintura        // pigmento acumulado nas bordas das cores

// Verdadeiro quando o jogo roda no modo "Compatibilidade" (OpenGL).
uniform bool compatibilidade = false;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float dist_linear(vec2 uv, mat4 inv_proj) {
	float d = texture(profundidade, uv).r;
	vec3 ndc;
	if (compatibilidade) {
		ndc = vec3(uv, d) * 2.0 - 1.0;
	} else {
		ndc = vec3(uv * 2.0 - 1.0, d);
	}
	vec4 v = inv_proj * vec4(ndc, 1.0);
	return -v.z / v.w;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 px = 1.0 / VIEWPORT_SIZE;
	vec2 pos_px = uv * VIEWPORT_SIZE;

	// --- Contorno de nanquim (pelas diferencas de profundidade) ---
	// O traco "treme" um pouco, como feito a mao.
	vec2 tremor = vec2(ruido2(pos_px * 0.02), ruido2(pos_px * 0.02 + 17.0)) - 0.5;
	vec2 uvl = uv + tremor * px * 2.5;
	float largura = espessura * (0.7 + 0.6 * ruido2(pos_px * 0.008 + 3.0));
	vec2 o = px * largura;
	float dc = dist_linear(uvl, INV_PROJECTION_MATRIX);
	float dl = dist_linear(uvl - vec2(o.x, 0.0), INV_PROJECTION_MATRIX);
	float dr = dist_linear(uvl + vec2(o.x, 0.0), INV_PROJECTION_MATRIX);
	float du = dist_linear(uvl - vec2(0.0, o.y), INV_PROJECTION_MATRIX);
	float dd = dist_linear(uvl + vec2(0.0, o.y), INV_PROJECTION_MATRIX);
	float salto = max(max(abs(dl - dc), abs(dr - dc)), max(abs(du - dc), abs(dd - dc))) / dc;
	float dobra = abs(dl + dr + du + dd - 4.0 * dc) / dc;
	float linha = max(smoothstep(0.04, 0.12, salto), smoothstep(0.03, 0.09, dobra) * forca_dobras);
	linha *= 1.0 - smoothstep(distancia_some * 0.4, distancia_some, dc);
	// Falhas no traco, como pincel seco.
	linha *= smoothstep(0.08, 0.3, ruido2(pos_px * 0.05));

	// --- Cor com sangramento de aquarela ---
	vec2 desvio = (vec2(fbm2(pos_px * 0.01), fbm2(pos_px * 0.01 + 9.0)) - 0.5) * sangramento;
	vec3 c = texture(tela, uv + desvio).rgb;
	vec3 borrado = textureLod(tela, uv, 3.0).rgb;
	// Curva suave de exposicao (a tela chega "crua", sem ajuste de tom).
	c = vec3(1.0) - exp(-c * exposicao);
	borrado = vec3(1.0) - exp(-borrado * exposicao);
	// Tinta se acumula onde a cor muda (bordas mais escuras).
	float diferenca = clamp(length(borrado - c) * 2.0, 0.0, 1.0);
	c *= 1.0 - diferenca * borda_tinta;
	// Aguada: leve achatamento das cores em direcao ao papel.
	c = mix(c, c * 0.88 + cor_papel * 0.12, 0.5);

	// --- Papel ---
	float fibra = fbm2(pos_px * 0.35);
	float lavagem = fbm2(pos_px * 0.004 + 5.0);
	float papel = 1.0 + (fibra - 0.5) * forca_papel + (lavagem - 0.5) * forca_papel * 1.2;
	c *= papel;
	c *= mix(vec3(1.0), cor_papel, 0.5);

	// --- Nanquim por cima ---
	// A tinta se mistura com a cor de baixo (fica mais escura, sem virar preto chapado).
	vec3 tinta = mix(cor_tinta, c * cor_tinta * 2.2, 0.4);
	c = mix(c, tinta, clamp(linha, 0.0, 1.0) * forca_contorno);

	// Vinheta suave, como a borda de uma folha.
	float vinheta = smoothstep(1.25, 0.55, length((uv - 0.5) * vec2(1.3, 1.0)));
	c = mix(c * 0.86, c, vinheta);

	ALBEDO = c;
}
