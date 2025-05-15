shader_type spatial;
render_mode unshaded, fog_disabled;
//#ifndef saturate
#define saturate(v) clamp(v,0.,1.)

uniform sampler2D SCREEN_TEXTURE: source_color, hint_screen_texture;
uniform sampler2D NORMAL_TEXTURE : hint_normal_roughness_texture;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture;

//uniform int shading_bands = 1;
uniform float shade_smoothness : hint_range(0, 0.99, 0.01) = 0;
uniform float color_bands : hint_range(1,24,1) = 12;

// only works from with input range (0 - 1)
float custom_smoothstep(float input, float r) {
	float p = 1.0 / (1.0 - r);
	float a = pow(2.0 * input, p);
	float b = 2.0 - pow(2.0 - 2.0 * input, p);
	float c = sign(input - 0.5) + 1.0;
	float d = (a * (2.0 - c) + b * c) / 4.0;
	return d;
}

vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

//uniform float depth_range:hint_range(0.1, 100.0, 0.1);

void vertex(){
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec2 uv = SCREEN_UV;

	vec4 screen_color = texture(SCREEN_TEXTURE, uv);
	vec3 normal_view_space = texture(NORMAL_TEXTURE, uv).rgb;
	normal_view_space = normal_view_space * 2.0 - 1.0;
	//vec3 normals_world = (INV_VIEW_MATRIX * vec4(normal_view_space, 0.0)).xyz;
	//float roughness = texture(NORMAL_TEXTURE, uv).w;

	float depth = texture(DEPTH_TEXTURE, uv).x;
	vec3 ndc = vec3(uv * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz/=view.w;
	//float linear_depth = -view.z;

	// Shader Code
	// CEL-SHADING SHADOW BANDING
	vec3 screen_hsv = rgb2hsv(screen_color.rgb);

	float ev_values = log2(screen_hsv.z);
	float ev_frac = fract(ev_values);
	float ev_int = floor(ev_values);

	float brightness_power = ev_int + custom_smoothstep(ev_frac, shade_smoothness);
	float new_color_value = pow(2,brightness_power);

	float _color_bands = color_bands * screen_hsv.r;
	float cb_frac = fract(_color_bands);
	float cb_int = floor(_color_bands);
	float new_hue = custom_smoothstep(cb_frac, 0.5) + cb_int;
	new_hue /= color_bands;

	// COLOR
	vec3 new_color = hsv2rgb(vec3(new_hue, screen_hsv.g, new_color_value));

	ALBEDO = new_color;
}