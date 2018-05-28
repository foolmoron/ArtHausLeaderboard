#ifdef GL_ES
#endif

#define M_PI 3.1415926535897932384626433832795
// #define formula(s) (pixel.x - (s) < square.x && pixel.x + (s)> square.x && pixel.y - (s)< square.y && pixel.y + (s) > square.y)

// 2D Random
float random (float2 st) {
    return frac(sin(dot(st.xy,
                         float2(12.9898,78.233)))
                 * 43758.5453123);
}

// 2D Noise based on Morgan McGuire @morgan3d   
// https://www.shadertoy.com/view/4dS3Wd
float noise (float2 st) {
    float2 i = floor(st);
    float2 f = frac(st);

    // Four corners 2D of a tile
    float a = random(i);
    float b = random(i + float2(1.0, 0.0));
    float c = random(i + float2(0.0, 1.0));
    float d = random(i + float2(1.0, 1.0));

    // Smooth Interpolation

    // Cubic Hermine Curve.  Same as SmoothStep()
    float2 u = f*f*(3.0-2.0*f);
    // u = smoothstep(0.,1.,f);

    // lerp 4 coorners porcentages
    return lerp(a, b, u.x) +
            (c - a)* u.y * (1.0 - u.x) +
            (d - b) * u.x * u.y;
}

float getBump (float2 p) {
    float scale = 20.;
    float bump = noise((p * scale)) * 0.1;
    return bump;
}

float3 palette(float3 t, float3 a, float3 b, float3 c, float3 d) {
    return a + b * cos(2.0 * M_PI * (c * t  + d));
}
float3 paletteA (float t) {
    float3 a = float3(0.93,0.43,0.76);
    float3 b = float3(0.90,0.31,0.24);
    float3 c = float3(0.41,0.93,1.0);
    float3 d = float3(0,0.44,0.32);
    return a + b*cos( 2.0*M_PI*(c*t+d));
}

float3 paletteB (float t) {
    float3 a = float3(0.40,0.99,0.60);
    float3 b = float3(0.59,0.98,0.39);
    float3 c = float3(0.56,0.19,0.84);
    float3 d = float3(0.42,0.50,0.15);
    return a + b*cos( 2.0*M_PI*(c*t+d));
}

float3 paletteC (float t) {
    float3 a = float3(1.00,0.20,1.00);
    float3 b = float3(0.81,1.00,0.68);
    float3 c = float3(0.66,0.36,0.03);
    float3 d = float3(0.31,0.56,0.58);
    return palette(t,float3(0.56,0.98,0.66),float3(0.96,0.67,0.21),float3(0.51,0.16,0.49),float3(0.70,0.47,0.95));
}
bool formula (in float2 pixel, in float2 square, in float s) {
    return pixel.x - (s) < square.x && pixel.x + (s) > square.x && pixel.y - (s) < square.y && pixel.y + (s) > square.y;
}


float3 drawSquare(float2 pixel, float2 square, float3 setting, float time) {
	if(formula(pixel, square, setting.x) && !(formula(pixel, square, setting.x - setting.y))) return paletteA(setting.z / 70.0 + time * 0.1);
	return float3(0.0, 0.0, 0.0);
}


float4 drawEffectA(float2 fragCoord, float time, float2 resolution) {
    time *= 2.0;

    float2 uv = fragCoord;

	float2 pos = uv - float2(0.5,0.5);	
    float horizon = 0.03*cos(time); 
    float fov = 0.5; 
	
	float3 p = float3(pos.x, fov, pos.y - horizon);
	float a = 0.;


	float3 q = float3(p.x*cos(a)+(p.y)*sin(a), p.x*sin(a)-p.y*cos(a),p.z);
    float scroll = (time * -sign(q.z));
    float bump = getBump(q.xy);

	float2 s = float2(q.x/q.z, q.y/q.z + bump + scroll) * 0.1;

    float checker = 0.;
    float width = 0.96;
    float size = 0.02;
    bool grid = (frac(s.x / size) > width || frac(s.y / size) > width);
    checker = float(grid);
    
    //horizon "fog"

    float3 gridColor = (lerp(paletteA(s.y + bump * 0.5), float3(1.0, 1.0, 1.0), checker));
    gridColor = lerp(gridColor, float3(1.0, 1.0, 1.0), 0.3); //slight desaturate
    float horizonFog = pow(sin(uv.y * M_PI), 2.);
    float3 color = lerp(gridColor, float3(1.0, 1.0, 1.0), horizonFog);


    //now draw the box
    float ang = sin(time) * 0.6;
	float2x2 rotation = float2x2(cos(ang), -sin(ang), sin(ang), cos(ang)); // this is a 2D rotation matrix
    float2 aspect = resolution.xy / min(resolution.x, resolution.y); // for squared tiles, we calculate aspect
	float2 position = (fragCoord.xy) * aspect; // position of pixel we need to multiply it with aspect, so we get squared tiles
	float2 center = float2(0.7, 0.5) * aspect;
	
	position = mul(rotation, position);
	center = mul(rotation, center);
	
	for(int i = 0; i < 50; i++) {
		float3 d = drawSquare(position, center + float2(sin(float(i) / 10.0 + time) / 4.0, 0.0), float3(0.0 + sin(float(i) / 200.0), 0.01 , float(i)), time);
		if(length(d) != 0.0) color = lerp(d, float3(1.0, 1.0, 1.0), 0.3); //slight desaturate


	}

	return float4(color, 1.0);
}

float2 hash( float2 p ) { p=float2(dot(p,float2(127.1,311.7)),dot(p,float2(269.5,183.3))); return frac(sin(p)*18.5453); }

// return distance, and cell id
float2 voronoi( in float2 x, float time) {
    float2 n = floor( x );
    float2 f = frac( x );

	float3 m = float3(8.0, 8.0, 8.0);
    for( int j=-1; j<=1; j++ )
    for( int i=-1; i<=1; i++ )
    {
        float2  g = float2( float(i), float(j) );
        float2  o = hash( n + g );
        float2  r = g - f + (0.5+0.5*sin(time+6.2831*o));
	float d = dot( r, r );
        if( d<m.x )
            m = float3( d, o );
    }

    return float2( sqrt(m.x), m.y+m.z );
}

float4 drawEffectB(float2 fragCoord, float time, float2 resolution) {
    float2 p = fragCoord;// / min(resolution.x, resolution.y);
    
    // computer voronoi patterm
    float2 c = voronoi( (14.0+6.0*sin(0.2))*p, time );

    // colorize
    float3 col = 0.5 + 0.5*cos( c.y*6.2831 + float3(0.0,1.0,2.0) );	

    
	
    return float4((paletteC(col.r * 0.2) * 0.8) + 0.5, 1.0);
}
