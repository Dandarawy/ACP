Shader "CustomUI/ColorWheel"
{
	Properties
	{
		[PerRendererData] _MainTex("Sprite Texture", 2D) = "white" {}
		_Hue("Hue", Float) = 0
		_Sat("Saturation", Float) = 0
		_Val("Value", Float) = 0
		_ColorsCount("Colors Segments", int) = 40
		_WheelsCount("Number of Wheels", int) = 2
		_StartingAngle("Starting Angle",Range(0,360))=0
		_StencilComp("Stencil Comparison", Float) = 8
		_Stencil("Stencil ID", Float) = 0
		_StencilOp("Stencil Operation", Float) = 0
		_StencilWriteMask("Stencil Write Mask", Float) = 255
		_StencilReadMask("Stencil Read Mask", Float) = 255

		_ColorMask("Color Mask", Float) = 15

		[Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip("Use Alpha Clip", Float) = 0
	}

		SubShader
		{
			Tags
			{
				"Queue" = "Transparent"
				"IgnoreProjector" = "True"
				"RenderType" = "Transparent"
				"PreviewType" = "Plane"
				"CanUseSpriteAtlas" = "True"
			}

			Stencil
			{
				Ref[_Stencil]
				Comp[_StencilComp]
				Pass[_StencilOp]
				ReadMask[_StencilReadMask]
				WriteMask[_StencilWriteMask]
			}

			Cull Off
			Lighting Off
			ZWrite Off
			ZTest[unity_GUIZTestMode]
			Blend SrcAlpha OneMinusSrcAlpha
			ColorMask[_ColorMask]

			Pass
			{
				Name "Default"
			CGPROGRAM
				#pragma vertex vert
				#pragma fragment frag
				#pragma target 2.0

				#include "UnityCG.cginc"
				#include "UnityUI.cginc"

				#pragma multi_compile_local _ UNITY_UI_CLIP_RECT
				#pragma multi_compile_local _ UNITY_UI_ALPHACLIP

				struct appdata_t
				{
					float4 vertex   : POSITION;
					float4 color    : COLOR;
					float2 texcoord : TEXCOORD0;
					UNITY_VERTEX_INPUT_INSTANCE_ID
				};

				struct v2f
				{
					float4 vertex   : SV_POSITION;
					fixed4 color : COLOR;
					float2 texcoord  : TEXCOORD0;
					float4 worldPosition : TEXCOORD1;
					UNITY_VERTEX_OUTPUT_STEREO
				};

				sampler2D _MainTex;
				fixed4 _TextureSampleAdd;
				float4 _ClipRect;
				float4 _MainTex_ST;
				float _Hue;
				float _Sat;
				float _Val;
				float _ColorsCount;
				float _WheelsCount;
				float _StartingAngle;
				v2f vert(appdata_t v)
				{
					v2f OUT;
					UNITY_SETUP_INSTANCE_ID(v);
					UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
					OUT.worldPosition = v.vertex;
					OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);
					OUT.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
					OUT.color = v.color;
					return OUT;
				}
				float3 HSV2RGB(float3 c)
				{
					float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
					float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
					return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
				}
				fixed4 frag(v2f IN) : SV_Target
				{
					half4 color = (tex2D(_MainTex, IN.texcoord) + _TextureSampleAdd) * IN.color;
					//Saturation = the distance from the center
					float s = distance(IN.texcoord, half2(0.5, 0.5))/0.5;
					//Hue = angle
					float h = atan2(IN.texcoord.y - 0.5,IN.texcoord.x - 0.5);
					//add starting angle shift to control the starting angle of the wheel
					h= h + UNITY_PI * 2 * _StartingAngle / 360.0;
					//convert h from (0-2*Pi) range to (0-1) range
					h = (h > 0 ? h : (2 * UNITY_PI + h)) / (2 * UNITY_PI);
					//add the value of Hue coming from the rotation of the wheel by the user
					//and divide by wheelsCount to distribute colors over "WheelCount" wheels
					float shiftedH = (h + _Hue )/_WheelsCount;
					shiftedH=fmod(shiftedH,1);
					//assign a single color for the whole portion instead of applying gradient value of H
					float discretedH = float(floor(shiftedH*(_ColorsCount))) / (_ColorsCount);
					//a slight shift of h value to distribute all the (0-1) h range on "_ColorsCount-1" portions and leave the last portion for the gray color
					discretedH=discretedH*(_ColorsCount)/(_ColorsCount-1);
					if (shiftedH > 1.0-1.0/(_ColorsCount) && shiftedH<=1)
						color = half4(HSV2RGB(float3(0, 0, (_Val-_Sat +0.75)/1.5)), color.a);
					else
						color = half4(HSV2RGB(float3(discretedH, _Sat, _Val)), color.a);
					#ifdef UNITY_UI_CLIP_RECT
					color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
					#endif

					#ifdef UNITY_UI_ALPHACLIP
					clip(color.a - 0.001);
					#endif

					return color;
				}

				
			ENDCG
			}
		}
}
