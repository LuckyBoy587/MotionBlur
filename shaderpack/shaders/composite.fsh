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

/*
    ========================================================================
    CONFIGURATION SETTINGS
    You can easily modify these parameters to change the blur effect.
    ========================================================================
*/

// The maximum offset distance of the blur in texture coordinates.
// A value of 0.01 means the blur extends 1% of the screen width/height.
// Increase this to make the blur stronger, or decrease it for a subtler effect.
#define BLUR_STRENGTH 0.01 // [0.001 0.002 0.005 0.01 0.015 0.02 0.03 0.05 0.1]

// The number of samples to take.
// - Must be an odd integer (so the center pixel is sampled perfectly).
// - Higher values make the blur look smoother (fewer "ghost" bands) but cost more GPU performance.
// - Try 5, 9, 15, or 21.
#define BLUR_SAMPLES 11 // [5 7 9 11 13 15 17 19 21]

// The direction of the blur in screen space.
// - vec2(1.0, 0.0) is a horizontal blur.
// - vec2(0.0, 1.0) is a vertical blur.
// - vec2(1.0, 1.0) is a 45-degree diagonal blur.
// - vec2(1.0, 0.5) is a shallow diagonal blur.
#define BLUR_DIRECTION vec2(1.0, 1.0)

/*
    ========================================================================
    MAIN BLUR KERNEL
    ========================================================================
*/
void main() {
    // 1. Normalize the direction vector so that the direction angle does not
    //    unintentionally scale the blur strength (e.g. diagonal vectors are longer).
    vec2 normalizedDir = normalize(BLUR_DIRECTION);

    // 2. Adjust for screen aspect ratio if we want the blur direction to map
    //    identically in visual angles. Since screens are wider than they are tall,
    //    unadjusted diagonal blurs will stretch slightly differently.
    //    We correct the Y component using (viewWidth / viewHeight).
    vec2 aspectCorrection = vec2(1.0, viewWidth / viewHeight);
    vec2 correctDir = normalizedDir / aspectCorrection;

    // 3. Compute the step vector representing the maximum blur spread.
    vec2 blurStep = correctDir * BLUR_STRENGTH;

    // 4. Initialize color accumulation variables.
    vec4 colorSum = vec4(0.0);
    float totalWeight = 0.0;

    // 5. Sample symmetrically along the blur line.
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

    // 6. Write the final averaged color to the screen.
    //    In the composite pass, gl_FragColor writes directly back to the active
    //    color attachment (usually colortex0), updating the screen.
    gl_FragColor = colorSum / totalWeight;
}
