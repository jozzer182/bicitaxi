#version 460 core

// Barrel distortion shader for liquid glass effect
// This shader receives the backdrop image and applies radial distortion
// Distortion is stronger at edges, minimal at center

precision highp float;

// Output color
out vec4 fragColor;

// Flutter provides these automatically for ImageFilter shaders:
// - The filtered content as sampler2D at index 0
// - Width at float index 0
// - Height at float index 1

uniform vec2 uSize;            // Size from Flutter (width, height)
uniform sampler2D uTexture;    // Input image (backdrop content)
uniform float uDistortion;     // Distortion strength (0.0-1.0)

void main() {
    // Normalized coordinates (0 to 1)
    vec2 uv = gl_FragCoord.xy / uSize;
    
    // Flip Y coordinate (GLSL has origin at bottom-left, Flutter at top-left)
    uv.y = 1.0 - uv.y;
    
    // Center the coordinates (-0.5 to 0.5)
    vec2 centered = uv - 0.5;
    
    // Calculate distance from center (0 at center, ~0.7 at corners)
    float dist = length(centered);
    
    // Barrel distortion formula: r' = r * (1 + k * r^2)
    // This creates stronger distortion at edges, none at center
    float k = uDistortion * 0.3;
    float distortionFactor = 1.0 + k * dist * dist;
    
    // Apply radial distortion
    vec2 distorted = centered * distortionFactor;
    
    // Convert back to 0-1 range
    vec2 finalUV = distorted + 0.5;
    
    // Check if we're sampling outside the texture bounds
    if (finalUV.x < 0.0 || finalUV.x > 1.0 || finalUV.y < 0.0 || finalUV.y > 1.0) {
        // Outside bounds - use edge color with fade
        finalUV = clamp(finalUV, 0.0, 1.0);
    }
    
    // Sample the backdrop texture
    vec4 color = texture(uTexture, finalUV);
    
    // Add subtle edge highlight for glass effect
    float edgeIntensity = smoothstep(0.3, 0.5, dist);
    color.rgb = mix(color.rgb, color.rgb * 1.05 + vec3(0.02), edgeIntensity * 0.3);
    
    fragColor = color;
}
