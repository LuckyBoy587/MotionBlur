#version 330 compatibility

/*
    Basic Motion Blur - composite.fsh
    ---------------------------------------------------------
    This is the fragment shader for the composite post-processing pass.
    It reads from colortex0 (the main scene color texture rendered by Minecraft)
    and applies a symmetric directional blur to simulate a simple motion blur.
*/

// Input texture coordinates interpolated from the vertex shader.
in vec2 texcoord;

// The main color framebuffer from Minecraft (contains the fully rendered 3D scene).
uniform sampler2D colortex0;

// Screen dimensions provided by Iris, helpful for resolution-independent styling.
uniform float viewWidth;
uniform float viewHeight;

// Camera tracking uniforms provided by Iris / OptiFine.
// - cameraPosition is the current world position of the camera.
// - previousCameraPosition is the world position from the previous frame.
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

// Model-view matrix, used to rotate world-space translation into camera space.
uniform mat4 gbufferModelView;

/*
    ========================================================================
    CONFIGURATION SETTINGS
    You can easily modify these parameters to change the blur effect.
    ========================================================================
*/

// The base offset distance of the blur in texture coordinates.
// A value of 0.01 means the blur extends 1% of the screen width/height.
#define BLUR_STRENGTH 0.01 // [0.001 0.002 0.005 0.01 0.015 0.02 0.03 0.05 0.1]

// Sensitivity of the blur to movement speed.
// Higher values make the blur more pronounced at lower speeds.
#define SPEED_MULTIPLIER 15.0 // [5.0 10.0 15.0 20.0 25.0 30.0 40.0 50.0]

// The number of samples to take.
// - Must be an odd integer (so the center pixel is sampled perfectly).
// - Higher values make the blur look smoother (fewer "ghost" bands) but cost more GPU performance.
#define BLUR_SAMPLES 11 // [5 7 9 11 13 15 17 19 21]

/*
    ========================================================================
    MAIN BLUR KERNEL
    ========================================================================
*/
void main() {
    // 1. Calculate translation vector in world space.
    vec3 cameraOffset = cameraPosition - previousCameraPosition;

    // 2. Rotate the world-space offset vector into camera space.
    //    Multiplying by gbufferModelView transforms the direction vector to match
    //    the camera's orientation (X = right/left, Y = up/down, Z = forward/backward).
    vec3 viewSpaceOffset = (gbufferModelView * vec4(cameraOffset, 0.0)).xyz;

    // 3. Compute current translation speed and apply a small deadzone to prevent
    //    precision jitter or floating errors from causing blur when standing still.
    float speed = length(cameraOffset);
    if (speed < 0.0005) {
        speed = 0.0;
    }

    // 4. Determine screen-space motion direction from the view-space translation.
    //    - Strafe left/right moves X.
    //    - Jump/fall moves Y.
    vec2 motionDir = viewSpaceOffset.xy;

    // If moving forward/backward (Z translation only), fallback to a diagonal blur direction.
    if (abs(viewSpaceOffset.z) > 0.0005 && length(motionDir) < 0.0005) {
        motionDir = vec2(1.0, 1.0);
    }

    // 5. Normalize the motion direction vector. If there is no movement, the direction is zero.
    vec2 blurDir = vec2(0.0);
    float motionLen = length(motionDir);
    if (motionLen > 0.0001) {
        blurDir = motionDir / motionLen;
    }

    // 6. Adjust for screen aspect ratio so that diagonal/vertical blurs
    //    have isotropic mapping (uniform visual blur angles).
    vec2 aspectCorrection = vec2(1.0, viewWidth / viewHeight);
    vec2 correctDir = blurDir / aspectCorrection;

    // 7. Compute the dynamic blur step vector.
    //    Blur strength is scaled proportionally to movement speed and sensitivity.
    float dynamicStrength = BLUR_STRENGTH * speed * SPEED_MULTIPLIER;
    vec2 blurStep = correctDir * dynamicStrength;

    // 8. Initialize color accumulation variables.
    vec4 colorSum = vec4(0.0);
    float totalWeight = 0.0;

    // 9. Sample symmetrically along the blur line.
    //    By sampling from -halfSamples to +halfSamples, the blur is centered
    //    directly on the pixel, preventing the screen from looking "shifted".
    int halfSamples = BLUR_SAMPLES / 2;
    for (int i = -halfSamples; i <= halfSamples; i++) {
        // Calculate where along the blur line this sample lies (from -1.0 to 1.0).
        float offsetFraction = float(i) / float(halfSamples);
        
        // Offset coordinate to sample from.
        vec2 sampleOffset = blurStep * offsetFraction;
        
        // Accumulate sample color.
        colorSum += texture(colortex0, texcoord + sampleOffset);
        totalWeight += 1.0;
    }

    // 10. Write the final averaged color to the screen.
    gl_FragColor = colorSum / totalWeight;
}
