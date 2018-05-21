Shader "Depth Mask Cutoff" { 
	Properties {
		_MainTex ("Font Texture", 2D) = "white" {}
		_Color ("Text Color", Color) = (1,1,1,1)
		_Cutoff ("Cutoff", Range(0, 1)) = 0.9
	}
 
	SubShader {
		Tags {"Queue" = "Geometry+50" "LightMode" = "ShadowCaster" }

		Lighting Off Cull Off ZWrite On Fog { Mode Off }

		Blend SrcAlpha OneMinusSrcAlpha

		Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float _Cutoff;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 world : TEXCOORD0;
				float4 screen : TEXCOORD1;
				float2 uv : TEXCOORD2;
			};
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
                o.world = mul(unity_ObjectToWorld, v.vertex);
				o.screen = ComputeScreenPos(o.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 c = tex2D(_MainTex, i.uv);
				if (c.a < _Cutoff) {
					discard;
				}
				return c;
			}
			ENDCG
		}
	}
}