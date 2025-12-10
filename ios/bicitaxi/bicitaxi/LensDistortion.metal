//
//  LensDistortion.metal
//  bicitaxi
//
//  Metal shader for REAL optical lens distortion - creates visible refraction effect
//

#include <metal_stdlib>
using namespace metal;

/// Lens distortion shader - creates optical refraction like looking through a water droplet
/// This distorts/magnifies the background content within the lens area
/// 
/// Parameters:
/// - position: Current pixel position
/// - lensCenter: Center point of the lens effect
/// - lensRadius: Radius of the lens area
/// - refractionStrength: How much distortion (0.0 = none, 0.5 = strong, 1.0 = extreme)
[[ stitchable ]] float2 lensDistortion(
    float2 position,
    float2 lensCenter,
    float lensRadius,
    float refractionStrength
) {
    // Calculate vector from lens center to current pixel
    float2 delta = position - lensCenter;
    float distance = length(delta);
    
    // Only distort pixels inside the lens radius
    if (distance < lensRadius && lensRadius > 0.0) {
        // Normalized distance from center (0 at center, 1 at edge)
        float normalizedDist = distance / lensRadius;
        
        // Create smooth lens distortion curve (stronger at center, fading at edges)
        // Using a quadratic falloff for natural lens-like appearance
        float distortionFactor = 1.0 - normalizedDist * normalizedDist;
        
        // Apply refraction - push pixels toward the center (magnification effect)
        float2 offset = delta * distortionFactor * refractionStrength;
        
        // CLAMP the offset to prevent sampling outside view bounds
        // This prevents icons from disappearing when lens is directly over them
        float maxOffset = 15.0;  // Maximum pixel offset
        offset = clamp(offset, float2(-maxOffset), float2(maxOffset));
        
        // Calculate new position
        float2 newPos = position - offset;
        
        // Ensure the new position doesn't go negative (out of view bounds)
        newPos = max(newPos, float2(0.0, 0.0));
        
        return newPos;
    }
    
    // Outside the lens, no distortion
    return position;
}


/// Barrel distortion for a more dramatic "fisheye" glass effect
[[ stitchable ]] float2 barrelLens(
    float2 position,
    float2 lensCenter,
    float lensRadius,
    float distortionK
) {
    float2 delta = position - lensCenter;
    float distance = length(delta);
    
    if (distance < lensRadius && lensRadius > 0.0) {
        float normalizedDist = distance / lensRadius;
        
        // Barrel distortion: r' = r * (1 + k * r^2)
        // Creates the classic fisheye/lens bulge effect
        float distortedDist = normalizedDist * (1.0 + distortionK * normalizedDist * normalizedDist);
        
        // Scale back to coordinate space, clamping to prevent extreme distortion
        float2 direction = delta / distance;
        float2 distortedPos = lensCenter + direction * min(distortedDist, 1.5) * lensRadius;
        
        return distortedPos;
    }
    
    return position;
}

/// Water droplet refraction - spherical lens effect with edge darkening
[[ stitchable ]] float2 waterDroplet(
    float2 position,
    float2 dropCenter,
    float dropRadius,
    float refractionIndex  // 1.0 = no refraction, 1.33 = water, 1.5 = glass
) {
    float2 delta = position - dropCenter;
    float distance = length(delta);
    
    if (distance < dropRadius && dropRadius > 0.0) {
        float normalizedDist = distance / dropRadius;
        
        // Simulate spherical refraction using Snell's law approximation
        // The refraction is stronger at the edges of the sphere
        float theta = asin(normalizedDist);  // Angle of incidence
        float refractedTheta = asin(sin(theta) / refractionIndex);  // Snell's law
        
        // Calculate the apparent position shift
        float shift = (theta - refractedTheta) / theta;
        shift = isnan(shift) ? 0.0 : shift;  // Handle edge case at center
        
        // Apply the refraction effect
        float2 offset = delta * shift * 0.5;
        
        return position - offset;
    }
    
    return position;
}
