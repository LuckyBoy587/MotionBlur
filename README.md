# Basic Motion Blur Shader Pack

A minimal, beginner-friendly Minecraft Java shader pack designed to apply a fullscreen directional screen-space blur. This pack is built specifically for **Iris** (and is compatible with OptiFine) and serves as an educational starting point for understanding post-processing shaders in GLSL.

---

## How It Works (High Level)

Instead of modifying how individual blocks or entities are rendered, this shader pack operates as a post-processing filter (the **composite pass**). 

1. Minecraft renders the 3D scene normally onto a screen-sized color texture (`colortex0`).
2. The composite pass draws a flat, fullscreen rectangle (quad) over the screen.
3. For every pixel, the fragment shader (`composite.fsh`) samples the scene texture multiple times in a symmetric line along the specified direction (e.g. horizontally or diagonally) and averages the colors.
4. The averaged result is output to the screen, creating a directional blur effect.

---

## Folder Structure

```text
basic-motion-blur/
├── .github/
│   └── workflows/
│       └── ci-release.yml      # CI/CD validation and release workflow
├── docs/
│   └── development.md          # Technical pipeline guide & learning roadmap
├── shaderpack/                 # The folder to be zipped and installed
│   └── shaders/
│       ├── composite.vsh       # Fullscreen quad vertex shader
│       ├── composite.fsh       # Directional blur fragment shader
│       └── screen.properties   # Settings UI layout configuration
├── .gitignore                  # Git ignore rules
├── LICENSE                     # MIT License
└── README.md                   # You are here
```

> [!IMPORTANT]
> When installing the shader pack, the contents of the `shaderpack/` folder must be zipped so that the `shaders/` directory is at the root level of the zip file. The GitHub Actions workflow automates this structure.

---

## Installation

1. Make sure you have **Iris Shader Mod** (or OptiFine) installed for Minecraft Java Edition.
2. Download the pre-packaged `.zip` file from the **Releases** tab of this repository. (Alternatively, zip the contents of the `shaderpack/` folder yourself).
3. Open Minecraft, go to **Options -> Video Settings -> Shader Packs**.
4. Click **Open Shader Pack Folder**.
5. Drag and drop the `.zip` file (e.g. `basic-motion-blur-v0.1.0.zip`) into that folder.
6. Select **Basic Motion Blur** in-game and apply it.

---

## Tweaking Blur Strength and Direction

You can customize the shader pack in two ways:

### 1. In-Game Settings Menu (Recommended)
This pack uses the standard properties format, which automatically generates a UI menu in Minecraft:
1. Open the Shader Packs settings menu in Minecraft.
2. Click **Shader Pack Settings...** on the right side while the pack is selected.
3. Tweak the **Blur Strength** and **Sample Count** directly using the interactive buttons.

### 2. Editing Code (`shaderpack/shaders/composite.fsh`)
For deeper adjustments, open `composite.fsh` in a text editor:
*   **Blur Strength**: Modify `#define BLUR_STRENGTH 0.01` to make the blur wider or tighter.
*   **Sample Count**: Modify `#define BLUR_SAMPLES 11` (must be an odd integer) to make the blur smoother or more performant.
*   **Blur Direction**: Change `#define BLUR_DIRECTION vec2(1.0, 1.0)`:
    *   Horizontal Blur: `vec2(1.0, 0.0)`
    *   Vertical Blur: `vec2(0.0, 1.0)`
    *   Diagonal Blur: `vec2(1.0, 1.0)` (default)
    *   Custom angles: Modify the x and y values as desired (e.g. `vec2(1.0, 0.5)`).

---

## Limitations

*   **Not True Motion Blur**: This pack does not calculate real camera velocity or velocity vectors of moving objects. It is a static, screen-space directional filter.
*   **Static Blur**: Because it doesn't track camera movement, the blur will remain active even when you stand still. See [development.md](file:///D:/Minecraft%20Shaders/MotionBlur/docs/development.md) for how to upgrade it to dynamic, movement-based motion blur.

---

## GitHub Actions & Releases

This repository includes a continuous integration workflow (`.github/workflows/ci-release.yml`) that runs on every push, pull request, or tag.

### How the Workflow Works:
1. **Validation**: Checks that `composite.vsh`, `composite.fsh`, and `screen.properties` are in the correct directories.
2. **Packaging & Release**: Zips the contents of the `shaderpack/` folder and uploads it as a workflow artifact, then automatically publishes a new GitHub Release:
   - **Branch pushes (e.g., `main`)**: Generates a release tagged `dev-<commit-sha>` (e.g., `dev-abcdef1`) and names it `Development Build dev-<commit-sha>`. The archive is named `basic-motion-blur-dev-<commit-sha>.zip`.
   - **Version tags (e.g., `v*`)**: Generates a release tagged with the version name (e.g., `v0.1.0`) and names it `Release v0.1.0`. The archive is named `basic-motion-blur-v0.1.0.zip`.

### How to Publish a Release:
*   **For Development Builds**: Simply commit and push your changes to the `main` branch. The action will automatically compile the zip, upload the artifact, and create a dev release.
    ```bash
    git add .
    git commit -m "Your commit message"
    git push origin main
    ```
*   **For Version Tag Releases**: Add a version tag to your commit and push it to trigger a formal release:
    ```bash
    # 1. Add version tag
    git tag v0.1.0

    # 2. Push tag to GitHub
    git push origin v0.1.0
    ```

---

## License

This project is licensed under the MIT License - see the [LICENSE](file:///D:/Minecraft%20Shaders/MotionBlur/LICENSE) file for details.
