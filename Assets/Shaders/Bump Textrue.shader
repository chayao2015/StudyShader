//Shader模块定义
Shader "xiaolezi/Bump Texture"
{
	//属性设置
	Properties
	{
		//定义一个物体表面颜色,格式：[属性名]([Inspector面板显示名字],属性类型)=[初始值]
		_DiffuseColor("Main Color", Color) = (1, 1, 1, 1)
		_MainTex("Albedo(RGB)", 2D) = "white"{}
		_BumpMap("Normal Map", 2D) = "bump"{}
		_BumpScale("Bump Scale",Float)= 1.0
		_Glossness("Glossness", Range(8, 256)) = 20
		_SpecularColor("Specular Color", Color) = (1, 1, 1, 1)
	}
	//第一个SubShader块
	SubShader
		{
			//第一个Pass块
			Pass
			{
				//指定灯光渲染模式
				Tags{ "LightMode" = "ForwardBase" }

				//开启CG着色器编辑模块
				CGPROGRAM
				//定义顶点着手器函数名
#pragma vertex vert
				//定义片段着色器函数名
#pragma fragment frag

				//包含相关头文件
#include "UnityCG.cginc"	
#include "Lighting.cginc"

				//定义一个从应用程序到顶点数据的结构体
				struct appdata
				{
					float4 vertex : POSITION;//POSITION语义:表示从该模型中获取到顶点数据
					float3 normal : NORMAL;  //NORMAL语义:获取该模型法线
					float2 texcoord : TEXCOORD0;//TEXCOORD0语义:获取该模型纹理信息
					float4 tangent : TANGENT;//TANGENT语义:获取该模型切线坐标
				};
				//定义一个从顶点数据到片段数据的结构体
				struct v2f
				{
					float4 pos : SV_POSITION;//SV_POSITION语义:从顶点输出数据中获取到顶点数据
					float4 uv : TEXCOORD0;//TEXCOORD0语义:定义纹理贴图变量
					float3 lightDir : TEXCOORD1;//TEXCOORD1语义:定义灯光方向变量
					float3 viewDir : TEXCOORD2;//TEXCOORD2语义:定义观察方向变量
				};
				//从属性模块中取得该变量
				fixed4 _DiffuseColor;
				float _Glossness;
				fixed4 _SpecularColor;
				sampler2D _MainTex;
				float4 _MainTex_ST;
				sampler2D _BumpMap;
				float4 _BumpMap_ST;
				float _BumpScale;

				//顶点着色器函数实现
				v2f vert(appdata v)
				{
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);//让模型顶点数据坐标从本地坐标转化为屏幕剪裁坐标
					//计算纹理坐标
					o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
					o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);

					//计算切线矩阵
					//float3 binormal = cross(normalize(v.normal), normalize(v.tangent.xyz)) * v.tangent.w;
					//	float3x3 rotation = float3x3(v.tangent.xyz, binormal, v.normal);
					//这里直接使用内置宏 TANGENT_SPACE_ROTATION
					TANGENT_SPACE_ROTATION;

					//计算切线空间下的灯光方向
					o.lightDir = normalize(mul(rotation, ObjSpaceLightDir(v.vertex)));
					//计算切线空间下的观察方向
					o.viewDir = normalize(mul(rotation, ObjSpaceViewDir(v.vertex)));

					return o;
				}
				//片段着色器函数实现
				fixed4 frag(v2f f) : SV_Target//SV_Target语义:输出片元着色器值，可直接认为是输出到屏幕颜色
				{
					fixed4 normalAlbedo = tex2D(_BumpMap, f.uv.zw);
					fixed3 tangentNormal = UnpackNormal(normalAlbedo);
					tangentNormal.xy *= _BumpScale;

					//漫反色
					fixed3 albedo = tex2D(_MainTex, f.uv).rgb;
					float Lambert = 0.5 * dot(tangentNormal, f.lightDir) + 0.5;//兰伯特值
					fixed3 diffuse = _LightColor0.rgb * _DiffuseColor.rgb * Lambert * albedo;	//计算漫反色

					//环境光
					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

					//高光
					fixed3 halfDir = normalize(f.lightDir + f.viewDir);//根据物体表面法线计算光的反射光方向
					fixed3 specular = _LightColor0.rgb * _SpecularColor.rgb * pow(max(0, dot(halfDir, tangentNormal)), _Glossness);//Phong氏高光计算

					return fixed4(ambient + diffuse + specular, 1.0);
				}
					//结束CG着色器编辑模块
					ENDCG
			}
		}
		Fallback "Bumped Diffuse"//默认着色器,这里选择高光
}