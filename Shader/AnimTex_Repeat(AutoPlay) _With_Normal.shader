Shader "VertexAnim/Repeat(AutoPlay)_With_Normal" 
{ 
	Properties {
		_MainTex ("Base (RGB) Gloss (A)", 2D) = "white" {}
        _Color ("Color", Color) = (1,1,1,1)
		
		_AnimTex ("PosTex", 2D) = "white" {} 
        _AnimTex_NormalTex ("Normal Tex", 2D) = "white" {}
		_AnimTex_Scale ("Scale", Vector) = (1,1,1,1)
		_AnimTex_Offset ("Offset", Vector) = (0,0,0,0)
		_AnimTex_AnimEnd ("End (Time, Frame)", Vector) = (0, 0, 0, 0)
		_AnimTex_T ("Time", float) = 0
		_AnimTex_FPS ("Frame per Sec(FPS)", Float) = 30

        _NormalLength("NormalLength", Range(0,1)) = 0.1
	}


    CGINCLUDE
    #include "UnityCG.cginc"
    #include "AnimTexture.cginc"

    struct vsin {
        uint vid: SV_VertexID;
        float2 texcoord : TEXCOORD0;
    };


    void getWorldPosNormal(uint vid, out float3 pos, out float3 normal)
    {
        float t = _AnimTex_T + _Time.y;
        t = clamp(t % _AnimTex_AnimEnd.x, 0, _AnimTex_AnimEnd.x);
        pos = AnimTexVertexPos(vid, t);
        normal = AnimTexNormal(vid, t);
    }

    ENDCG


	SubShader { 
		Tags { "RenderType"="Opaque" }
		LOD 700 Cull Off
		
        Pass {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            sampler2D _MainTex;
            float4 _Color;

            struct vsout {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            vsout vert(vsin v) 
            {
                float3 pos, normal;
                getWorldPosNormal(v.vid, pos, normal);

                vsout OUT;
                OUT.vertex = UnityObjectToClipPos(pos);
                OUT.uv = v.texcoord;
                return OUT;
            }

            float4 frag(vsout IN) : COLOR {
                return tex2D(_MainTex, IN.uv) * _Color;
            }

            ENDCG
        }

        Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag

            struct vsout {
                float4 vertex : SV_POSITION;
                float4 normal : NORMAL;
            };

            vsout vert(vsin v) 
            {
                float3 pos, normal;
                getWorldPosNormal(v.vid, pos, normal);

                vsout OUT;
                OUT.vertex = float4(pos,1);
                OUT.normal = float4(normalize(normal),1);
                return OUT;
            }

            float _NormalLength;

            struct geom2ps {
                float4 pos : SV_POSITION;
            };

            geom2ps createOutput(float3 wPos){
                geom2ps o;
                o.pos = UnityObjectToClipPos(wPos);
                return o;
            }

            [maxvertexcount(6)]
            void geom(triangle vsout input[3], inout LineStream<geom2ps> output)
            {
                for(int i=0; i<3; ++i)
                {
                    vsout In = input[i];
                    float3 wPos = In.vertex.xyz;
                    float3 normal = (In.normal.xyz / In.normal.w) * _NormalLength;
                    //float3 normal = float3(0,1,0);

                    output.Append(createOutput(wPos));
                    output.Append(createOutput(wPos + normal));
                    output.RestartStrip();
                }
            }

			float4 frag(geom2ps IN) : COLOR {
				return float4(1,0,0,1);
			}
			ENDCG
		}
    }
}
