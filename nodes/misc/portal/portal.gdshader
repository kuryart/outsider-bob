shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(0.2, 0.8, 1.0, 1.0);
uniform float glow_power : hint_range(0.0, 5.0, 0.1) = 2.0;
uniform float glow_radius : hint_range(0.0, 20.0, 0.5) = 2.0;

void fragment() {
    // 1. Pega a cor original do pixel atual
    vec4 sprite_color = texture(TEXTURE, UV);
    
    // 2. Calcula o tamanho de um pixel da textura para a amostragem
    vec2 pixel_size = TEXTURE_PIXEL_SIZE * glow_radius;
    vec4 glow = vec4(0.0);
    
    // 3. Amostra 8 pixels vizinhos (cima, baixo, lados e diagonais)
    glow += texture(TEXTURE, UV + vec2(-pixel_size.x, 0.0));
    glow += texture(TEXTURE, UV + vec2(pixel_size.x, 0.0));
    glow += texture(TEXTURE, UV + vec2(0.0, -pixel_size.y));
    glow += texture(TEXTURE, UV + vec2(0.0, pixel_size.y));
    glow += texture(TEXTURE, UV + vec2(-pixel_size.x, -pixel_size.y));
    glow += texture(TEXTURE, UV + vec2(pixel_size.x, -pixel_size.y));
    glow += texture(TEXTURE, UV + vec2(-pixel_size.x, pixel_size.y));
    glow += texture(TEXTURE, UV + vec2(pixel_size.x, pixel_size.y));
    
    // 4. Tira a média das amostras para criar um "borrão" da silhueta
    glow /= 8.0;
    
    // 5. Aplica a cor escolhida e a intensidade apenas onde há alpha no borrão
    vec4 final_glow = vec4(glow_color.rgb, glow.a) * glow_power;
    
    // 6. Mescla o sprite original por cima do brilho gerado
    COLOR = mix(final_glow, sprite_color, sprite_color.a);
}