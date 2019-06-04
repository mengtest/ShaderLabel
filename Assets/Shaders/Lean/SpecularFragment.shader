﻿// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// 逐像素高光反射
Shader "Lean/Specular Fragment"
{ 
    Properties{
        _MainTex ("Texture", 2D) = "white" {}
        _BumpTex ("Normal Map", 2D) = "bump" {}
        _Color ("Color", color) = (1,1,1,1)
        _Specular ("Specular", Color) = (1, 1, 1, 1)//高光反射颜色
        _Gloss("Gloss", Range(8,200)) = 10 //高光的参数
    }
    SubShader{
        Pass {
            
            // 只有定义了正确的LightMode才能得到一些Unity的内置光照变量
            Tags{"LightMode" = "ForwardBase"}

            CGPROGRAM

            // 包含unity的内置的文件，才可以使用Unity内置的一些变量
            #include "Lighting.cginc" // 取得第一个直射光的颜色_LightColor0 第一个直射光的位置_WorldSpaceLightPos0（即方向）
            #pragma vertex vert
            #pragma fragment frag
  
			sampler2D _MainTex;
			float4 _MainTex_ST;
            sampler2D _BumpTex;
			float4 _BumpTex_ST;
            fixed4 _Color;
            fixed4 _Specular;
            half _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;    // 告诉Unity把模型空间下的顶点坐标填充给vertex属性
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;      // 告诉Unity把模型空间下的法线方向填充给normal属性
            };

            struct v2f
            {
                float4 vertex : SV_POSITION; // 声明用来存储顶点在裁剪空间下的坐标
                float2 uv : TEXCOORD0;
                float3 worldNomal : TEXCOORD1; 
                float3 worldVertex : TEXCOORD2;
            };

            // 计算顶点坐标从模型坐标系转换到裁剪面坐标系
            v2f vert(a2v v)
            {
                v2f f;
                f.vertex = UnityObjectToClipPos(v.vertex); // UNITY_MATRIX_MVP是内置矩阵。该步骤用来把一个坐标从模型空间转换到剪裁空间
                f.uv = TRANSFORM_TEX(v.uv, _MainTex);
                // 法线方向。把法线方向从模型空间转换到世界空间
                f.worldNomal = UnityObjectToWorldNormal(v.normal);//世界空间法线
                f.worldVertex = mul(unity_ObjectToWorld, v.vertex).xyz;//世界空间坐标
                return f;
            }

            // 计算每个像素点的颜色值
            fixed4 frag(v2f f) : SV_Target 
            {
                fixed4 col = tex2D(_MainTex, f.uv)*_Color;
                // 环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * col;
                // 法线方向。
                fixed3 normalDir = normalize(f.worldNomal); // 单位向量
                // 光照方向。
                //fixed3 lightDir = normalize(_WorldSpaceLightPos0.xyz); //对于每个顶点来说，光的位置就是光的方向，因为光是平行光
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(f.worldVertex));//获取光线方向
                // 漫反射Diffuse颜色 = 直射光颜色 * max(0, cos(光源方向和法线方向夹角)) * 材质自身色彩
                fixed3 diffuse = _LightColor0 * col * max(0, dot(normalDir, lightDir)); // 颜色融合用乘法
                // 反射光的方向
                fixed3 reflectDir = normalize(reflect(-lightDir, normalDir)); // 参数：平行光的入射方向，法线方向。而lightDir光照方向是从模型表面到光源的，所以取负数。
                // 视野方向 = 摄像机的位置 - 当前点的位置
                //fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - f.worldVertex);
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(f.worldVertex));//获取视觉方向
                //高光反射Specular = 直射光 * pow(max(0, cos(反射光方向和视野方向的夹角)), 高光反射参数)
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(dot(reflectDir, viewDir), 0), _Gloss);

                // 最终颜色 = 漫反射 + 环境光 + 高光反射
                return fixed4(diffuse + ambient + specular, 1);// 颜色叠加用加法（亮度通常会增加）
            }

            ENDCG
        }
        
    }
    FallBack "Diffuse"
}