Shader "Effect"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Color1 ("Color 1", Color) = (0.0, 0.8, 0.5, 1)
		_Color2 ("Color 2", Color) = (0.8, 0.0, 0.2, 1)
		_DepthMaskMin ("Depth Mask Min", Range(-2, 2)) = 0
	}
	SubShader
	{
		Tags { "Queue" = "Geometry+40" "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			sampler2D _CameraDepthTexture;

			sampler2D _MainTex;
			float4 _MainTex_ST;
            fixed4 _Color1;
            fixed4 _Color2;
			float _DepthMaskMin;

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

				float depth = Linear01Depth(tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(i.screen)).x);
                fixed4 finalColor = lerp(_Color1, _Color2, step(1 - depth, _DepthMaskMin));

				return finalColor;
			}
			ENDCG
		}
	}
}
