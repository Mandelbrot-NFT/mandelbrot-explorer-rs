struct VertexOutput {
    @builtin(position) pos: vec4<f32>,
};

@vertex
fn main_vs(
    @location(0) particle_pos: vec2<f32>,
    @location(1) particle_vel: vec2<f32>,
    @location(2) position: vec2<f32>,
) -> VertexOutput {
    let angle = -atan2(particle_vel.x, particle_vel.y);
    let pos = vec2<f32>(
        position.x * cos(angle) - position.y * sin(angle),
        position.x * sin(angle) + position.y * cos(angle)
    );
    var out: VertexOutput;
    out.pos = vec4<f32>(pos + particle_pos, 0.0, 1.0);
    return out;
}

@fragment
fn main_fs() -> @location(0) vec4<f32> {
    return vec4<f32>(0.3, 0.2, 0.1, 1.0);
}
