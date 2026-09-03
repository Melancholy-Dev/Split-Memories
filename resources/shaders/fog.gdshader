shader_type canvas_item;

// Credit for the original shader goes to Gonkee: https://github.com/Gonkee/Gonkees-Shaders/blob/master/fog.shader
// Pixelate by Godot Shaders: https://godotshaders.com/shader/pixelate/

uniform vec4 color : source_color = vec4(0.2, 0.8, 0.2, 1.0);

uniform int OCTAVES = 4;

uniform bool enable_pixelation = true;
uniform int pixelation_amount = 100;

uniform sampler2D fog_mask : hint_default_white;

uniform vec2 fog_direction = vec2(1.0, 1.0);
uniform float fog_speed = 0.05;

uniform bool scroll_noise_tex = false;
uniform vec2 noise_scroll_direction = vec2(1.0, 0.0);
uniform float noise_speed = 0.05;


// Random value
float random_value(vec2 position) {
    return fract(
        sin(dot(position, vec2(12.9898, 78.233)))
        * 43758.5453
    );
}


// Interpolated noise
float value_noise(vec2 position) {
    vec2 cell = floor(position);
    vec2 local_position = fract(position);

    float bottom_left = random_value(cell);
    float bottom_right = random_value(cell + vec2(1.0, 0.0));
    float top_left = random_value(cell + vec2(0.0, 1.0));
    float top_right = random_value(cell + vec2(1.0, 1.0));

    vec2 smooth_position =
        local_position * local_position *
        (3.0 - 2.0 * local_position);

    float bottom = mix(
        bottom_left,
        bottom_right,
        smooth_position.x
    );

    float top = mix(
        top_left,
        top_right,
        smooth_position.x
    );

    return mix(
        bottom,
        top,
        smooth_position.y
    );
}


// Fractal Brownian Motion
float fbm(vec2 position) {
    float result = 0.0;
    float amplitude = 0.5;

    for (int i = 0; i < OCTAVES; i++) {
        result += value_noise(position) * amplitude;
        position *= 2.0;
        amplitude *= 0.5;
    }

    return result;
}


void fragment() {
    // Use TIME directly to avoid a reset every 60 seconds.
    float time_value = TIME;

    vec2 noise_uv = UV;

    if (enable_pixelation) {
        float pixel_amount = max(float(pixelation_amount), 1.0);

        noise_uv = floor(
            UV * pixel_amount
        ) / pixel_amount;
    }

    // Compute noise based on pixelated or non-pixelated coordinates
    vec2 noise_position = noise_uv * 20.0;

    // Scroll the noise texture if enabled
    vec2 fog_offset =
        fog_direction *
        time_value *
        fog_speed;

    vec2 scroll_offset = vec2(0.0);

    if (scroll_noise_tex) {
        scroll_offset =
            noise_scroll_direction *
            time_value *
            noise_speed;
    }

    vec2 final_position =
        noise_position +
        fog_offset +
        scroll_offset;

    // Compute organic motion in two directions
    float motion_x = fbm(final_position);
    float motion_y = fbm(
        final_position + vec2(17.31, 41.73)
    );

    vec2 motion = vec2(
        motion_x,
        motion_y
    ) * 2.0 - 1.0;

    // Compute the final fog density
    float fog_density = fbm(
        final_position + motion * 0.75
    );

    fog_density = clamp(
        fog_density,
        0.0,
        1.0
    );

    // Get the fog density from the texture mask
    float mask_value = texture(
        fog_mask,
        UV
    ).r;

    // Modulate the fog density by the mask value
    fog_density *= mask_value;

    // Use the alpha value of the color to control the overall fog opacity
    float final_alpha =
        fog_density *
        color.a *
        0.5;

    COLOR = vec4(
        color.rgb,
        final_alpha
    );
}
