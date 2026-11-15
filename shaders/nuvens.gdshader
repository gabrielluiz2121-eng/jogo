// Camada do mar de nuvens / neblina: manchas de aquarela que andam com o vento.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

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

uniform sampler2D profundidade : hint_depth_texture, filter_nearest;
uniform vec3 cor_luz : source_color = vec3(1.0, 0.97, 0.92);
uniform vec3 cor_sombra : source_color = vec3(0.62, 0.68, 0.8);
uniform float densidade = 0.8;
uniform float escala = 0.025;
uniform float cobertura = 0.42;   // menor = mais nuvem
uniform vec2 vento = vec2(0.6, 0.25);
uniform float raio_fim = 600.0;   // some nas bordas do plano
uniform float suavidade = 6.0;    // some ao encostar nas rochas

varying vec3 pos_mundo;

// Verdadeiro quando o jogo roda no modo "Compatibilidade" (OpenGL).
uniform bool compatibilidade = false;

void vertex() {
	pos_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = pos_mundo.xz * escala + vento * TIME * 0.01;
	float n = fbm2(p);
	float detalhe = fbm2(p * 3.1 + 7.0);
	float forma = n * 0.75 + detalhe * 0.25;
	float a = smoothstep(cobertura, cobertura + 0.25, forma) * densidade;
	a *= 1.0 - smoothstep(raio_fim * 0.6, raio_fim, length(pos_mundo.xz));

	// Some suavemente onde encosta em algo solido (rochas das ilhas).
	float d = texture(profundidade, SCREEN_UV).r;
	vec3 ndc;
	if (compatibilidade) {
		ndc = vec3(SCREEN_UV, d) * 2.0 - 1.0;
	} else {
		ndc = vec3(SCREEN_UV * 2.0 - 1.0, d);
	}
	vec4 v = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	float fundo = -v.z / v.w;
	a *= clamp((fundo + VERTEX.z) / suavidade, 0.0, 1.0);

	// Topo das nuvens iluminado, base em sombra azulada.
	vec3 c = mix(cor_sombra, cor_luz, smoothstep(cobertura, cobertura + 0.45, forma));
	// Grao de papel tambem nas nuvens.
	c *= 1.0 + (fbm2(FRAGCOORD.xy * 0.35) - 0.5) * 0.1;
	ALBEDO = c;
	ALPHA = clamp(a, 0.0, 1.0);
}
