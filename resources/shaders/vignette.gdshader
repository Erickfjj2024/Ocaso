// vignette.gdshader
// Vinheta crescente: escurece as bordas da tela conforme a intensidade aumenta.
// Usado pelo SanityVFX para reforçar a sensação de sufocamento psicológico.
shader_type canvas_item;
render_mode unshaded;

/// Força da vinheta. 0 = invisível, 2+ = bordas quase pretas.
uniform float strength : hint_range(0.0, 3.0) = 0.0;

/// Cor base da vinheta (preto por padrão; pode ser roxo escuro para sanidade crítica).
uniform vec4 vignette_color : source_color = vec4(0.02, 0.0, 0.06, 1.0);

void fragment() {
	// UV centrado em (0, 0), vai de -0.5 a +0.5
	vec2 uv = UV - vec2(0.5);
	// Produto escalar cria falloff radial natural
	float v = dot(uv * vec2(1.7), uv * vec2(1.7));
	float alpha = clamp(v * strength, 0.0, 1.0);
	COLOR = vec4(vignette_color.rgb, alpha);
}
