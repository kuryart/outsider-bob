shader_type canvas_item;

// repeat_enable garante que o ruído seja infinito quando rolar
uniform sampler2D noise_texture : repeat_enable; 
uniform vec2 distortion_strength = vec2(0.05, 0.05); // Força da deformação
uniform vec2 scroll_speed = vec2(0.1, 0.1);          // Velocidade e direção da água

void fragment() {
    // 1. Anima o UV exclusivamente para o ruído
    vec2 noise_uv = UV + (scroll_speed * TIME);
    
    // 2. Lê os dados da textura de ruído
    vec4 noise = texture(noise_texture, noise_uv);
    
    // 3. O pulo do gato matemático: centralizar o ruído
    vec2 offset = (noise.rg - 0.5) * 2.0;
    
    // 4. Aplica a distorção no UV da imagem principal
    vec2 distorted_uv = UV + (offset * distortion_strength);
    
    // 5. Renderiza o sprite com o UV bagunçado
    COLOR = texture(TEXTURE, distorted_uv);
}