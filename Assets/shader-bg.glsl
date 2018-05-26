#ifdef GL_ES
#extension GL_OES_standard_derivatives : enable
precision mediump float;
#endif

#define M_PI 3.1415926535897932384626433832795
#define formula(s) (pixel.x - (s) < square.x && pixel.x + (s)> square.x && pixel.y - (s)< square.y && pixel.y + (s) > square.y)

uniform float u_time;
uniform vec2 mouse;
uniform vec2 u_resolution;


// 2D Random
float random (in vec2 st) {
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))
                 * 43758.5453123);
}

// 2D Noise based on Morgan McGuire @morgan3d   
// https://www.shadertoy.com/view/4dS3Wd
float noise (in vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    // Smooth Interpolation

    // Cubic Hermine Curve.  Same as SmoothStep()
    vec2 u = f*f*(3.0-2.0*f);
    // u = smoothstep(0.,1.,f);

    // Mix 4 coorners porcentages
    return mix(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}


float getBump (in vec2 p) {
    float scale = 20.;
    float bump = noise((p * scale)) * 0.1;
    return bump;
}

vec3 palette( in float t, in vec3 a, in vec3 b, in vec3 c, in vec3 d )
{
    return a + b*cos( 2.0*M_PI*(c*t+d) );
}   


vec3 paletteA (in float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(2.0, 1.0, 0.0);
    vec3 d = vec3(0.50, 0.20, 0.25);
    return palette(t, a, b, c, d);
}

vec3 paletteB (in float t) {
    vec3 a = vec3(0.93,0.43,0.76);
    vec3 b = vec3(0.90,0.31,0.24);
    vec3 c = vec3(0.41,0.93,0.17);
    vec3 d = vec3(0.64,0.44,0.2);
    return palette(t, a, b, c, d);
}

vec3 paletteD (in float t) {
    vec3 a = vec3(0.93,0.43,0.76);
    vec3 b = vec3(0.90,0.31,0.24);
    vec3 c = vec3(0.41,0.93,1.0);
    vec3 d = vec3(0,0.44,0.32);
    return palette(t, a, b, c, d);
}


vec3 paletteC (in float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.00, 0.33, 0.67);
    return palette(t, vec3(0.63,0.87,0.87),vec3(0.53,0.41,0.64),vec3(0.70,0.51,0.58),vec3(0.94,0.34,0.52));
}



vec3 drawSquare(in vec2 pixel, in vec2 square, in vec3 setting) {
	if(formula(setting.x) && !(formula(setting.x - setting.y))) return paletteD(setting.z / 70.0 + u_time * 0.1);
	return vec3(0.0);
}


void main( void ) {
	
    vec2 uv = (gl_FragCoord.xy / u_resolution.xy);
	vec2 pos = uv - vec2(0.5,0.5);	
    float horizon = 0.03*cos(u_time); 
    float fov = 0.5; 
	
	vec3 p = vec3(pos.x, fov, pos.y - horizon);
	float a = 0.;


	vec3 q = vec3(p.x*cos(a)+(p.y)*sin(a), p.x*sin(a)-p.y*cos(a),p.z);
    float scroll = (u_time * -sign(q.z));
    float bump = getBump(q.xy);

	vec2 s = vec2(q.x/q.z, q.y/q.z + bump + scroll) * 0.1;

    float checker = 0.;
    float width = 0.96;
    float size = 0.02;
    bool grid = (fract(s.x / size) > width || fract(s.y / size) > width);
    checker = float(grid);
    
    //horizon "fog"

    vec3 gridColor = (mix(paletteD(s.y + bump * 0.5), vec3(1.0), checker));
    gridColor = mix(gridColor, vec3(1.0), 0.3); //slight desaturate
    float horizonFog = pow(sin(uv.y * M_PI), 2.);
    vec3 color = mix(gridColor, vec3(1.0), horizonFog);


    //now draw the box
    float ang = sin(u_time) * 0.6;
	mat2 rotation = mat2(cos(ang), -sin(ang), sin(ang), cos(ang)); // this is a 2D rotation matrix
	vec2 aspect = u_resolution.xy / min(u_resolution.x, u_resolution.y); // for squared tiles, we calculate aspect
	vec2 position = (gl_FragCoord.xy / u_resolution.xy) * aspect; // position of pixel we need to multiply it with aspect, so we get squared tiles
	vec2 center = vec2(0.5) * aspect; // 0.5 is center but we need to multiply it with aspect (0.5 isn't center for squared tiles)
	
	position *= rotation;
	center *= rotation;
	
	for(int i = 0; i < 50; i++) {
		vec3 d = drawSquare(position, center + vec2(sin(float(i) / 10.0 + u_time) / 4.0, 0.0), vec3(0.0 + sin(float(i) / 200.0), 0.01 , float(i)));
		if(length(d) != 0.0) color = mix(d, vec3(1.0), 0.3); //slight desaturate


	}

	gl_FragColor = vec4( color, 1.0 );
}

