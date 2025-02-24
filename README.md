
# ComputerGraphicsShaderToy

A real-time ray tracing shader implemented in **GLSL**. This project demonstrates fundamental ray tracing techniques such as sphere intersection, material shading (Lambertian, Metal, Dielectric), reflections, and refractions – all rendered in a ShaderToy-like environment.

![Shader Showcase](https://github.com/user-attachments/assets/403a46de-17c5-4fc9-bbae-fca39733865c?raw=true "Shader Showcase" )

## Overview

This shader creates a dynamic scene consisting of:

- **Ground Sphere:** Acts as a plane.
- **Grid of Small Spheres:** Randomly positioned with randomized materials.
- **Three Large Spheres:**
  - **Dielectric (Glass):** Transparent and refractive.
  - **Lambertian (Diffuse):** Matte surfaces with randomized colors.
  - **Metal:** Reflective surfaces.

The camera orbits the scene over time, providing a rotating view with basic anti-aliasing and gamma correction.

## Features

- **Ray-Sphere Intersection:**  
  Uses a simple mathematical model to detect intersections with spheres.

- **Material Types:**
  - **Lambertian:** Diffuse surfaces with randomized albedo.
  - **Metal:** Perfectly reflective surfaces.
  - **Dielectric:** Refractive (glass-like) materials.

- **Randomized Scene Elements:**  
  A grid of small spheres is randomly positioned and assigned materials using a simple RNG.

- **Dynamic Camera Movement:**  
  The camera rotates around the scene based on elapsed time.

- **Basic Anti-Aliasing:**  
  Uses random offsets per pixel for smoother rendering.

- **Gamma Correction:**  
  Applies a square-root function to simulate gamma correction.

## How to Run

This shader is designed for environments like [ShaderToy](https://www.shadertoy.com/) or any WebGL-enabled platform that supports GLSL shaders.

### On ShaderToy

1. **Create a New Shader:**  
   Copy the contents of `rayTracer.glsl` into a new shader on ShaderToy.

2. **Uniforms Required:**  
   Ensure the following uniforms are provided (or adjust the code accordingly):
   - `iResolution` – The viewport resolution.
   - `iTime` – Elapsed time in seconds.

### Local Testing

You can also run this shader locally using a WebGL framework, for example:

- **Using Three.js:**  
  Set up a basic HTML/JavaScript project to compile and render the shader in a `<canvas>` element.

## Customization

- **Materials & Scene:**  
  Modify the parameters in the `hit_scene()` function within `rayTracer.glsl` to change sphere sizes, positions, and material properties.

- **Camera Settings:**  
  Adjust the camera setup in the `mainImage()` function to modify the field-of-view, orbit radius, or other parameters.

- **Sampling:**  
  Increase the number of samples per pixel for improved anti-aliasing (at a potential performance cost).

