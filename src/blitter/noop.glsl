#if defined(VERTEX)

uniform vec2 TextureSize;
uniform vec2 OutputSize;
uniform mat4 MVPMatrix;

#if __VERSION__ >= 130
#define IN  in
#define OUT out
#else
#define IN attribute
#define OUT varying
#endif

IN vec2 VertexCoord;
IN vec2 TexCoord;

OUT vec2 v_tex_coord;

void main() {
    gl_Position = MVPMatrix * vec4(VertexCoord, 0.0, 1.0);
    v_tex_coord = TexCoord;
}


#elif defined(FRAGMENT)

#ifdef GL_ES
precision highp float;
#endif

#if __VERSION__ >= 130
#define IN in
#define tex2D texture
out vec4 FragColor;
#else
#define IN varying
#define FragColor gl_FragColor
#define tex2D texture2D
#endif

uniform sampler2D Texture;
uniform vec2 TextureSize;

IN vec2 v_tex_coord;

void main() {
    vec4 col = tex2D(Texture, v_tex_coord);
    FragColor = col;
}

#endif
