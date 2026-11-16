// Material de aquarela para objetos 3D:
// cores chapadas em duas faixas de luz, sombra azulada e manchas de pigmento.
shader_type spatial;
render_mode specular_disabled;

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

uniform vec4 cor : source_color = vec4(1.0);
// Brilho proprio (flores magicas, lanternas).
uniform float brilho = 0.0;
// Quanto a cor varia em "manchas", como tinta aguada no papel.
uniform float manchas = 0.2;
// Deforma a malha (usado nas rochas para ficarem irregulares).
uniform float deformar = 0.0;
// Cor que a tinta ganha nos lados a sombra.
uniform vec3 cor_sombra : source_color = vec3(0.36, 0.42, 0.6);

// Para objetos que se movem (personagem): manchas presas ao objeto, nao ao mundo.
uniform bool manchas_locais = false;
// Padrao de palha/bambu trancado (cesto, chapeu, sandalias). 0 = desligado.
uniform float trama = 0.0;
// Textura pintada (modelos vindos do Meshy).
uniform sampler2D textura : source_color, filter_linear_mipmap;
uniform bool usa_textura = false;

varying vec3 pos_mundo;
varying vec3 pos_local;

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	if (deformar > 0.0) {
		vec2 radial = VERTEX.xz;
		float len = length(radial);
		if (len > 0.01) {
			float n = fbm3(w * 0.22) - 0.5;
			float fino = ruido3(w * 0.9) - 0.5;
			VERTEX.xz += radial / len * (n * 2.0 + fino * 0.5) * deformar;
			VERTEX.y += (ruido3(w * 0.4) - 0.5) * deformar * 0.6;
		}
	}
	pos_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	pos_local = VERTEX;
}

void fragment() {
	vec3 p = manchas_locais ? pos_local * 5.0 : pos_mundo;
	float n = fbm3(p * 0.12);
	float n2 = fbm3(p * 0.6 + 11.0);
	float grao = ruido3(p * 4.0);
	vec3 base = cor.rgb;
	if (usa_textura) {
		base *= texture(textura, UV).rgb;
	}
	vec3 c = base * (1.0 + (n - 0.5) * manchas * 2.4 + (n2 - 0.5) * manchas + (grao - 0.5) * 0.06);
	// Manchas amareladas/azuladas, como pigmentos misturados na agua.
	c = mix(c, c * vec3(1.08, 1.04, 0.85), smoothstep(0.55, 0.75, n) * 0.6);
	c = mix(c, c * vec3(0.88, 0.95, 1.08), smoothstep(0.45, 0.25, n) * 0.5);
	if (trama > 0.0) {
		// Linhas cruzadas como fibra trancada.
		float a = sin(UV.x * 140.0 + floor(UV.y * 24.0) * 1.57);
		float b = sin(UV.y * 150.0);
		c *= 1.0 - trama * (smoothstep(0.6, 1.0, a) * 0.5 + smoothstep(0.85, 1.0, b) * 0.6);
	}
	ALBEDO = clamp(c, 0.0, 1.0);
	ROUGHNESS = 1.0;
	if (brilho > 0.0) {
		EMISSION = base * brilho;
	}
}

void light() {
	// Duas faixas de luz suaves, como camadas de aguada.
	float ndl = dot(NORMAL, LIGHT);
	float faixa = smoothstep(-0.02, 0.22, ndl) * 0.7 + smoothstep(0.45, 0.75, ndl) * 0.3;
	float luz = faixa * ATTENUATION;
	vec3 tom = mix(cor_sombra, vec3(1.0), luz);
	DIFFUSE_LIGHT += LIGHT_COLOR / PI * luz * tom;
}
