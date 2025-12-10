#version 460 core

// Shader de distorsión radial con punto rojo de debug en el centro

precision highp float;

layout(location = 0) out vec4 fragColor;

// === UNIFORMS ===
// Los índices en Dart setFloat() son:
// 0 = uWidgetSize.x, 1 = uWidgetSize.y (vec2 = 2 floats)
// 2 = uDistortionStrength (float = 1 float)
// 3 = uWidgetOffset.x, 4 = uWidgetOffset.y (vec2 = 2 floats)
// uBackdropTexture es manejado automáticamente por BackdropFilter

uniform vec2 uWidgetSize;         // Tamaño del widget en píxeles físicos
uniform float uDistortionStrength;// Fuerza de distorsión (0.0 a 2.0)
uniform vec2 uWidgetOffset;       // Offset del widget (no usado actualmente)
uniform sampler2D uBackdropTexture;// Textura del backdrop

void main() {
    // Coordenadas normalizadas del fragmento (0.0 a 1.0)
    vec2 normalizedCoord = gl_FragCoord.xy / uWidgetSize;
    //normalizedCoord.y = 1.0 - normalizedCoord.y;  // Voltear Y para Flutter
   // normalizedCoord.x = 1.0 - normalizedCoord.x;  // Voltear X para Flutter 
    
    // Coordenadas centradas en el widget (-0.5 a 0.5)
    vec2 centeredCoord = normalizedCoord / 3.0 ;
    
    // Distancia desde el centro (0 en centro, ~0.7 en esquinas)
    float distanceFromCenter = length(centeredCoord);
    
    // Calcular distorsión: aumenta desde el centro hacia los bordes
    float distortionFactor = uDistortionStrength * 0.05 * distanceFromCenter;
    
    // Aplicar distorsión a las coordenadas de muestreo
    //vec2 samplingCoord = normalizedCoord + centeredCoord * distortionFactor;
    //samplingCoord = clamp(samplingCoord, 0.0, 1.0);
    
    // Muestrear el backdrop con las coordenadas distorsionadas
    //vec4 backdropColor = texture(uBackdropTexture, samplingCoord);
    
    // DEBUG: Punto rojo en el centro exacto (5 píxeles de radio)
    float distanceInPixels = length(centeredCoord * uWidgetSize);
    if (distanceInPixels < 60.0) {
        backdropColor = vec4(1.0, 0.0, 0.0, 1.0);  // 1Rojo puro
    }
    
    fragColor = backdropColor;
}
