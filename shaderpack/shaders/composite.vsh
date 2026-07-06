#version 330 compatibility

/*
    Basic Motion Blur - composite.vsh
    ---------------------------------------------------------
    This is the vertex shader for the composite post-processing pass.
    The composite pass runs as a fullscreen quad, covering the entire screen.
    Its job here is to pass along the vertex positions and texture coordinates (texcoord)
    to the fragment shader, which performs the actual screen-space blur.
*/

// Output texture coordinate to be interpolated across the screen and read in the fragment shader.
out vec2 texcoord;

void main() {
    // Transform the vertex position using Minecraft's model-view-projection matrix.
    // This projects the fullscreen quad vertices into normalized device coordinates (clip space).
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;

    // Retrieve the texture coordinates for the screen texture.
    // Minecraft uses the first texture unit (Texture 0) for the screen framebuffer.
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
}
