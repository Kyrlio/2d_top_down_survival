shader_type canvas_item;
uniform float pixelation:hint_range(1.0,16.0)=1.0;
uniform bool controlEdges=false;
varying vec2 p_world;
void vertex(){
	p_world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}
void fragment(){
	vec2 p_snapped=floor(p_world/pixelation)*pixelation+pixelation/2.0;
	vec2 delta=p_snapped-p_world;
	mat2 M_p=mat2(dFdx(p_world),dFdy(p_world));
	mat2 M_uv=mat2(dFdx(UV),dFdy(UV));
	mat2 J=M_uv*inverse(M_p);
	vec2 delta_uv=J*delta;
	vec2 uv=UV+delta_uv;
	vec4 color=texture(TEXTURE,uv);
	if(controlEdges){
		float margin_x=(abs(J[0].x)+abs(J[1].x))*pixelation*0.5;
		float margin_y=(abs(J[0].y)+abs(J[1].y))*pixelation*0.5;
		if(uv.x<margin_x||uv.x>1.0-margin_x||uv.y<margin_y||uv.y>1.0-margin_y){
			color.a=0.0;
		}else{
			color.a=step(0.5,color.a);
		}
	}else{
		color.a=step(0.5,color.a);
	}
	COLOR=color;
}
