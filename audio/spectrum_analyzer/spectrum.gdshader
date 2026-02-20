shader_type canvas_item;
render_mode blend_mix;

uniform sampler2D audiosample : filter_nearest;
uniform float mfac = 2.0;
const float mdisp = 0.166667;
const float mthick = 0.01;

void fragment() {
	COLOR = vec4(0.0,0.0,0.0,1.0);
	vec4 a = texture(audiosample, UV);
	float dr = abs(1.0 - UV.y - a.r*mfac);
	float dg = abs(1.0 - UV.y - a.g*mfac);
	if (dg < mthick) {
		COLOR.r = 1.0;
	}
	if (dr < mthick) {
		COLOR.gb = vec2(1.0,1.0);
	}
}
