shader_type canvas_item;

uniform float wave_amplitude : hint_range(0.0, 0.1) = 0.02; // Força/tamanho da distorção
uniform float wave_frequency : hint_range(0.0, 50.0) = 10.0; // Quantidade de "curvas"
uniform float wave_speed : hint_range(0.0, 10.0) = 4.0;      // Velocidade do movimento

void fragment() {
    vec2 distorted_uv = UV;
    
    // Calcula a deformação no eixo X usando o eixo Y e o tempo
    float wave = sin(UV.y * wave_frequency + TIME * wave_speed);
    
    // Aplica a amplitude para que a imagem não saia da tela
    distorted_uv.x += wave * wave_amplitude;
    
    // Renderiza a textura com o UV distorcido
    COLOR = texture(TEXTURE, distorted_uv);
}