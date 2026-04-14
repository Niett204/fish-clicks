shader_type canvas_item;

void fragment() {
    // Calculamos la distancia desde el centro (0.5, 0.5)
    float dist = distance(UV, vec2(0.5));
    
    // Obtenemos el color original de la foto
    vec4 color = texture(TEXTURE, UV);
    
    // Si la distancia es mayor a 0.5, hacemos el píxel transparente
    // El 'smoothstep' ayuda a que los bordes no se vean pixelados (anti-aliasing)
    color.a *= smoothstep(0.5, 0.49, dist);
    
    COLOR = color;
}