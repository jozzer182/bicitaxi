#version 460 core

#include <flutter/runtime_effect.glsl>

// Uniforms from Dart
uniform vec2 uSize;           // Widget size (width, height)
uniform vec2 uScreenSize;     // Full screen size
uniform vec2 uWidgetPos;      // Widget position on screen (x, y from top-left)
uniform sampler2D uTexture;   // Background image (full screen capture)
uniform float uRefraction;    // Refraction strength (0.0-0.1)
uniform float uTime;          // Animation time for subtle wave

out vec4 fragColor;

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    
    // Local UV within widget (0-1)
    vec2 localUV = fragCoord / uSize;
    
    // Calculate where this pixel is on the full screen
    // Widget position + local position = screen position
    vec2 screenPos = uWidgetPos + fragCoord;
    
    // Convert to UV in the full background texture
    // Note: Flutter Y=0 is top, but texture Y=0 is bottom, so we flip Y
    vec2 bgUV = vec2(screenPos.x / uScreenSize.x, 1.0 - (screenPos.y / uScreenSize.y));
    
    // Distance from center for lens-like effects (local to widget)
    vec2 center = vec2(0.5);
    vec2 fromCenter = localUV - center;
    float dist = length(fromCenter);
    
    // Refraction: create lens-like distortion
    float angle = atan(fromCenter.y, fromCenter.x);
    float wave = sin(angle * 4.0 + uTime * 0.8) * 0.008;
    
    // Lens distortion offset (in background UV space)
    float lensStrength = smoothstep(0.0, 0.5, dist) * uRefraction;
    vec2 refractOffset = fromCenter * (lensStrength + wave) * (uSize / uScreenSize);
    
    // Sample background with displacement
    vec2 sampledUV = bgUV + refractOffset;
    
    // Clamp to valid range
    sampledUV = clamp(sampledUV, vec2(0.001), vec2(0.999));
    
    vec4 bgColor = texture(uTexture, sampledUV);
    
    // Fresnel effect: brighter at edges (like real glass)
    float fresnel = pow(dist * 1.2, 2.0) * 0.1;
    
    // White glass tint
    vec3 glassTint = vec3(1.0);
    float tintStrength = 0.05;
    
    // Combine: background + tint + fresnel edge glow
    vec3 finalColor = mix(bgColor.rgb, glassTint, tintStrength + fresnel);
    
    // Slight transparency
    fragColor = vec4(finalColor, 0.95);
}
