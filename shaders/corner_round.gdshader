shader_type canvas_item;

uniform vec2 size = vec2(600,60);
uniform float radius = 20.0;
uniform float ratio = 0;
uniform vec4 color = vec4(1,1,1,1);

float rounded_box_sdf(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + vec2(r);
	return length(max(q,0))-r;
}
void fragment() {
	vec2 p = UV * size - size * 0.5;
	float dist = rounded_box_sdf(p,size*0.5,radius);
	float left = -size.x * 0.5;
	float visible_edge = mix(left,size.x*0.5,ratio);
	float visible = step(p.x,visible_edge);
	float aa = fwidth(dist);
	float alpha = smoothstep(aa,0.0,dist) * visible;
	
	COLOR = vec4(color.rgb, color.a * alpha);
}