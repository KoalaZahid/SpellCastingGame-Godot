shader_type spatial;

uniform vec4 rim_color : source_color = vec4(1.0);
uniform float rim_brightness = 5.0;
uniform float rim_size = 1.3;
uniform float rim_transparency = 1.;

float fresnel(float amount, vec3 normal, vec3 view)
{
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

void fragment()
{
	vec3 base_color = rim_color.rgb;
	float basic_fresnel = round(fresnel(rim_size, NORMAL, VIEW));
	ALBEDO = base_color + basic_fresnel * rim_brightness;
}

void light()
{
	float light_influence = dot(LIGHT, NORMAL) * 0.5 + 0.5;
	//vec3 light_influence = mix(vec3(1.0), vec3(0.0), 1.0-ATTENUATION);
	float basic_fresnel = fresnel(rim_size, NORMAL, VIEW);
	float attenuation = clamp(ATTENUATION, 0, 1);
	vec3 light_color = LIGHT_COLOR;
	if (LIGHT_IS_DIRECTIONAL) {
		//attenuation = 0.;
		ALPHA = pow(basic_fresnel*ATTENUATION,5)*0.6 * rim_transparency;
		//light_color *= 0.2;
	} else {
		ALPHA += pow(basic_fresnel*ATTENUATION*light_influence,5) * rim_transparency;
		light_color*=attenuation;
	}
	//float alpha = attenuation*light_influence*basic_fresnel;
	//ALPHA = pow(basic_fresnel*attenuation,5);
	//ALPHA = attenuation;
	//DIFFUSE_LIGHT += LIGHT_COLOR; //* vec3(1.);
	//ALPHA = attenuation*basic_fresnel*light_influence;
	DIFFUSE_LIGHT += light_color*0.2;
}
