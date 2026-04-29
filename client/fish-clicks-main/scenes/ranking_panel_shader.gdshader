shader_type canvas_item;

void fragment() {
    // Calculamos la distancia desde el centro (0.5, 0.5)
    float dist = distance(UV, vec2(0.5));
    // Si la distancia es mayor a 0.5 (fuera del círculo), hacemos el pixel transparente
    COLOR.a *= step(dist, 0.5);
}