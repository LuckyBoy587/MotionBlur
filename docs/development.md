# Developer Notes & Shader Pipeline Guide

Welcome to the development notes for the **Basic Motion Blur** learning shader pack. This document explains how the shader works under the hood and provides a detailed roadmap for expanding it into a production-ready cinematic motion blur.

---

## The Screen-Space Shader Pipeline

In modern game engines like Minecraft Java (with Iris or OptiFine), rendering is split into multiple passes. This shader pack uses the simplest post-processing structure: the **composite pass**.

```mermaid
graph TD
    A[Minecraft World: gbuffers passes] -->|Renders 3D geometry, sky, particles| B(colortex0 Framebuffer)
    B -->|Passed as sampler2D| C[composite Pass]
    C -->|Run fullscreen quad vertex shader composite.vsh| D[Fragment shader composite.fsh]
    D -->|Perform directional blur on colortex0| E[Output to Screen]
```

### 1. The Fullscreen Quad Flow
During the `gbuffers` stage, Minecraft renders the world, entities, and particles. The result is stored in color framebuffers (primarily `colortex0` for standard colors).

Once the 3D rendering is finished, Minecraft switches to post-processing:
1. It draws a single flat rectangle (a fullscreen quad) covering the entire screen.
2. It runs `composite.vsh` to map the corners of this quad to normalized device coordinates (clip space) and pass texture coordinates to the fragment shader.
3. It runs `composite.fsh` for every pixel on the screen. The texture coordinate (`texcoord`) maps exactly to the screen location from `(0,0)` to `(1,1)`.

### 2. Why is this the Easiest Starting Point?
By using the composite pass, we do not need to modify how blocks or entities look individually. We simply take the completed picture of the game (`colortex0`), apply a mathematical filter (directional blur) centered around each pixel, and output the modified image. This isolates the shader logic from Minecraft's complex rendering engine, making it an ideal environment for learning GLSL.

---

## Current Dynamic Translation-Based Blur
The current implementation tracks the player's translation movement between frames:
1. It compares `cameraPosition` and `previousCameraPosition` to get a world-space movement vector.
2. It rotates this vector into camera space using the `gbufferModelView` matrix to align it with screen coordinates (`X` for horizontal/strafing, `Y` for vertical/jumping, `Z` for forward/backward).
3. The blur direction dynamically aligns with the screen-space movement (falling/jumping blurs vertically, strafing blurs horizontally).
4. The blur strength is scaled by speed, meaning there is **no blur when standing still**.

---

## Roadmap for Later Upgrades

This project is designed to be a learning foundation. Here is how you can evolve it further:

### Phase 1: Camera Rotation Tracking
*   **Concept**: Blur the screen when the player rotates the camera (looking around), even when standing physically still.
*   **Implementation**:
    1.  Reconstruct the camera rotation matrix change between frames.
    2.  Extract the delta yaw and pitch.
    3.  Add the rotational velocity to the screen-space blur vector to combine translation and rotation.

### Phase 2: Velocity-Aware (True) Motion Blur
*   **Concept**: Blur pixels individually based on how fast that specific pixel's world coordinate is moving relative to the screen. This handles both camera translation/rotation and moving entities.
*   **Implementation**:
    1.  Enable depth buffer reading by declaring `uniform sampler2D depthtex0;` to get the depth of each pixel.
    2.  Reconstruct the world position of the current pixel using the depth and the inverse projection-view matrix (`gbufferProjectionInverse` and `gbufferModelViewInverse`).
    3.  Project the previous frame's position of that same world point using the previous frame's projection-view matrix (`previousProjection` and `previousModelView`).
    4.  Calculate the difference between the current screen position and the previous screen position. This difference vector is the **velocity vector** for that pixel.
    5.  Sample along this velocity vector in the fragment shader.

### Phase 3: Better Sampling & Noise
*   **Concept**: Avoid the "ghosting" artifacts that occur when `BLUR_SAMPLES` is low, and improve performance.
*   **Implementation**:
    1.  **Dithering / Jittering**: Add a pseudo-random noise offset (using a blue noise texture or a screen-space hash function) to each sample position. This turns distinct ghosting bands into soft, film-like grain.
    2.  **Gaussian Weights**: Instead of averaging samples equally (box filter), weight the center samples higher using a Gaussian distribution function to produce a smoother blur.
