Shader "NamNH/HalfLambertDissolve" {
	Properties{
		[Header(Main)]
		_MainTex("Texture", 2D) = "white" {}
		_Color("Color", color) = (1,1,1,1)
		_LightIntensity("Light Intensity", Range(0.1,10)) = 1

		[Header(Burn)]
		_SliceGuide("Slice Guide (RGB)", 2D) = "white" {}
		_SliceAmount("Slice Amount", Range(0.0, 1.0)) = 0

		_BurnSize("Burn Size", Range(0.0, 1.0)) = 0.15
		_BurnRamp("Burn Ramp (RGB)", 2D) = "white" {}
		_BurnColor("Burn Color", Color) = (1,1,1,1)

		_EmissionAmount("Emission amount", float) = 2.0
	}

	SubShader{
		Pass {
			Tags { "RenderType" = "Opaque" "LightMode" = "ForwardBase" "PassFlags" = "OnlyDirectional"}
			//Cull Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog

			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"

			struct appdata {
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f {
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
				float3 worldNormal : NORMAL;
				UNITY_FOG_COORDS(1)
				SHADOW_COORDS(2)
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Color;
			half _LightIntensity;

			sampler2D _SliceGuide;
			sampler2D _BumpMap;
			sampler2D _BurnRamp;
			fixed4 _BurnColor;
			float _BurnSize;
			float _SliceAmount;
			float _EmissionAmount;

			v2f vert(appdata v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				UNITY_TRANSFER_FOG(o,o.pos);
				TRANSFER_SHADOW(o)
				return o;
			}

			fixed4 frag(v2f i) : SV_Target {
				half test = tex2D(_SliceGuide, i.uv).rgb - _SliceAmount;
				clip(test);

				fixed4 burn = tex2D(_BurnRamp, float2(test * (1 / _BurnSize), 0)) * _BurnColor * _EmissionAmount;

				float shadow = SHADOW_ATTENUATION(i);
				float NdotL = dot(_WorldSpaceLightPos0, i.worldNormal);
				float lightIntensity = saturate(shadow * NdotL * 0.5 + 0.5);
				fixed4 col = tex2D(_MainTex, i.uv);
				col.rgb *= lightIntensity * _LightColor0.xyz * _Color.rgb * _LightIntensity;

				col = lerp(col, burn, step(test, _BurnSize) * step(0.001, _SliceAmount));

				UNITY_APPLY_FOG(i.fogCoord, col);

				return col;
			}
			ENDCG
		}
		
		Pass {
			Tags {"LightMode"="ShadowCaster"}
			Offset 1,1
			//Cull Off
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag

				#include "UnityCG.cginc"
				#include "Lighting.cginc"
				#pragma multi_compile_shadowcaster
				#pragma multi_compile_fog
				#pragma target 3.0

				struct appdata {
					float4 vertex : POSITION;
					float2 uv : TEXCOORD0;
				};

				struct v2f {
					V2F_SHADOW_CASTER;
					float2 uv : TEXCOORD1;
				};

				sampler2D _SliceGuide;
				float _SliceAmount;

				v2f vert(appdata v) {
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);
					o.uv = v.uv;
					TRANSFER_SHADOW_CASTER(o)
					return o;
				}

				fixed4 frag(v2f i) : SV_Target{
					half test = tex2D(_SliceGuide, i.uv).rgb - _SliceAmount;
					clip(test);
					SHADOW_CASTER_FRAGMENT(i)
				}

			ENDCG

		}
	}
}
