//Shader模块定义
Shader "xiaolezi/Lambert Lighting Model Per-Vertex Shader"
{
	//属性设置
	Properties
	{
		//定义一个物体表面颜色,格式：[属性名]([Inspector面板显示名字],属性类型)=[初始值]
		_DiffuseColor("Diffuse Color", Color) = (1, 1, 1, 1)
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
				};
				//定义一个从顶点数据到片段数据的结构体
				struct v2f
				{
					float4 pos : SV_POSITION;//SV_POSITION语义:从顶点输出数据中获取到顶点数据
					fixed3 diffuse : COLOR0;//COLOR0语义:定义颜色信息
				};
				//从属性模块中取得该变量
				fixed4 _DiffuseColor;
				//顶点着色器函数实现
				v2f vert(appdata v)
				{
					v2f o;
					o.pos = UnityObjectToClipPos(v.vertex);//让模型顶点数据坐标从本地坐标转化为屏幕剪裁坐标
					fixed3 normalDir = normalize(UnityObjectToWorldNormal(v.normal));	//计算世界法线方向
					fixed3 lightDir = normalize(ObjSpaceLightDir(v.vertex));			//计算灯光方向

					float Lambert = max(dot(normalDir, lightDir), 0);//兰伯特值
					o.diffuse = _LightColor0.rgb * _DiffuseColor.rgb * Lambert;	//计算漫反色
					return o;
				}
				//片段着色器函数实现
				fixed4 frag(v2f f) : SV_Target//SV_Target语义:输出片元着色器值，可直接认为是输出到屏幕颜色
				{
					return fixed4(f.diffuse, 1.0);
				}
					//结束CG着色器编辑模块
					ENDCG
			}
		}

		Fallback "Diffuse"//默认着色器
}