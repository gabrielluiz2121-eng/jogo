// Cachoeira: faixas brancas descendo, desfazendo-se em nevoa embaixo.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

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

uniform vec3 cor : source_color = vec3(0.95, 0.97, 1.0);
uniform vec3 cor_fundo : source_color = vec3(0.6, 0.7, 0.82);
uniform float velocidade = 0.6;

void fragment() {
	vec2 p = vec2(UV.x * 6.0, UV.y * 3.0 - TIME * velocidade);
	float faixas = fbm2(vec2(p.x * 2.0, p.y * 0.4));
	vec3 c = mix(cor_fundo, cor, smoothstep(0.35, 0.65, faixas));
	float borda = smoothstep(0.0, 0.2, UV.x) * smoothstep(1.0, 0.8, UV.x);
	float baixo = 1.0 - smoothstep(0.6, 1.0, UV.y);
	ALBEDO = c;
	ALPHA = clamp(borda * baixo * (0.55 + faixas * 0.5), 0.0, 1.0);
}
