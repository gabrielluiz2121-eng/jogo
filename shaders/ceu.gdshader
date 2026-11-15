// Ceu pintado: degrade de aquarela, sol com raios, manchas de nuvem e estrelas.
shader_type sky;

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

uniform vec3 cor_topo : source_color = vec3(0.45, 0.58, 0.75);
uniform vec3 cor_horizonte : source_color = vec3(1.0, 0.86, 0.62);
uniform vec3 cor_baixo : source_color = vec3(0.9, 0.9, 0.92);
uniform vec3 cor_nuvem : source_color = vec3(1.0, 0.95, 0.88);
uniform vec3 cor_halo : source_color = vec3(1.0, 0.85, 0.55);
uniform float forca_raios = 1.0;
uniform float estrelas = 0.0;
uniform float tamanho_astro = 1.0;

void sky() {
	vec3 d = EYEDIR;
	float h = d.y;
	vec3 c = mix(cor_horizonte, cor_topo, smoothstep(-0.02, 0.55, h));
	c = mix(c, cor_baixo, smoothstep(0.0, -0.25, h));

	// Manchas de nuvem pintadas perto do horizonte.
	vec2 plano = d.xz / (abs(h) + 0.18);
	float n = fbm2(plano * 0.9);
	float nuvem = smoothstep(0.48, 0.78, n) * (1.0 - smoothstep(0.05, 0.6, h)) * smoothstep(-0.2, 0.0, h);
	c = mix(c, cor_nuvem, nuvem * 0.7);

	// Variacao da aguada no ceu.
	c *= 1.0 + (fbm2(plano * 3.0) - 0.5) * 0.08;

	if (LIGHT0_ENABLED) {
		vec3 sd = LIGHT0_DIRECTION;
		float s = max(dot(d, sd), 0.0);
		float halo = pow(s, 6.0) * 0.35 + pow(s, 48.0) * 0.6;
		float disco = smoothstep(1.0 - 0.0012 * tamanho_astro, 1.0 - 0.0006 * tamanho_astro, s);
		// Raios de sol em leque.
		vec3 t = normalize(cross(sd, vec3(0.0, 1.0, 0.001)));
		vec3 b = cross(t, sd);
		float ang = atan(dot(d, b), dot(d, t));
		float raios = smoothstep(0.55, 1.0, sin(ang * 13.0 + sin(ang * 4.0) * 2.5) * 0.5 + 0.5);
		halo += raios * pow(s, 5.0) * 0.45 * forca_raios;
		c += cor_halo * (halo + disco * 1.2) * clamp(LIGHT0_ENERGY, 0.0, 1.5);
	}

	// Estrelas a noite.
	if (estrelas > 0.0 && h > 0.0) {
		vec3 g = floor(d * 220.0);
		float e = step(0.996, hash3(g)) * hash3(g + 3.1);
		c += vec3(e) * estrelas * smoothstep(0.0, 0.3, h);
	}
	COLOR = c;
}
