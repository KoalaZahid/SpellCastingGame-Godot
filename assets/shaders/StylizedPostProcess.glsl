#[compute]
#version 450

// Compute shader invoke
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16f, set = 0, binding = 0) uniform image2D color_image;

layout(set=0, binding = 1) restrict buffer Params {
    float shade_smoothness; 
    float color_bands;
} params;

// Our push constant
layout(push_constant, std430) uniform PushConstant {
	vec2 raster_size;
	vec2 reserved;
} push_constant;

// only works from with input range (0 - 1)
float custom_smoothstep(float v, float r) {
	float p = 1.0 / (1.0 - r);
	float a = pow(2.0 * v, p);
	float b = 2.0 - pow(2.0 - 2.0 * v, p);
	float c = sign(v - 0.5) + 1.0;
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

void main() {
	ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
	ivec2 size = ivec2(push_constant.raster_size);

	if (uv.x >= size.x || uv.y >= size.y) {
		return;
	}

	// vec4 screen_color = texture(SCREEN_TEXTURE, uv); <--
    vec4 screen_color = imageLoad(color_image, uv);

	// Shader Code
	// CEL-SHADING SHADOW BANDING
	vec3 screen_hsv = rgb2hsv(screen_color.rgb);

	float ev_values = log2(screen_hsv.z);
	float ev_frac = fract(ev_values);
	float ev_int = floor(ev_values);

	float brightness_power = ev_int + custom_smoothstep(ev_frac, params.shade_smoothness);
	float new_color_value = pow(2,brightness_power);

	float _color_bands = params.color_bands * screen_hsv.r;
	float cb_frac = fract(_color_bands);
	float cb_int = floor(_color_bands);
	float new_hue = custom_smoothstep(cb_frac, 0.5) + cb_int;
	new_hue /= params.color_bands;

	// // COLOR
	vec3 new_color = hsv2rgb(vec3(new_hue, screen_hsv.g, new_color_value));

    imageStore(color_image, uv, vec4(new_color, screen_color.a));
}