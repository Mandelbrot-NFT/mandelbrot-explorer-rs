struct MandelbrotParams {
    x_min: f32,
    x_max: f32,
    y_min: f32,
    y_max: f32,
    max_iterations: i32
};

fn complex_mult(a: vec2<f32>, b: vec2<f32>) -> vec2<f32> {
    let x = a.x;
    let y = a.y;
    let u = b.x;
    let v = b.y;
    let r = x * u - y * v;
    let i = x * v + y * u;
    return vec2<f32>(r, i);
}

fn complex_abs(a: vec2<f32>) -> f32 {
    return sqrt(pow(a.x, 2.0) + pow(a.y, 2.0));
}

fn lerp(input: f32, in_min: f32, in_max: f32, out_min: f32, out_max: f32) -> f32 {
    let in_range = in_max - in_min;
    let in_normal = (input - in_min) / in_range;
    let out_range = out_max - out_min;
    return in_normal * out_range + out_min;
}

fn hsv2rgb(c: vec3<f32>) -> vec4<f32>
{
    let k = vec4<f32>(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    let p: vec3<f32> = abs(fract(c.xxx + k.xyz) * 6.0 - k.www);
    let cx = clamp(p.x - k.x, 0.0, 1.0);
    let cy = clamp(p.y - k.x, 0.0, 1.0);
    let cz = clamp(p.z - k.x, 0.0, 1.0);
    let col = c.z * mix(k.xxx, vec3<f32>(cx, cy, cz), c.y);
    return vec4<f32>(col.r, col.g, col.b, 1.0);
}

fn is_within_the_cardioid_or_a_p2bulb(x: f32, y: f32) -> bool {
    let q = pow(x - 0.25, 2.0) + pow(y, 2.0);
    return (q * (q + (x - 0.25)) <= 0.25 * pow(y, 2.0)) || (pow((x + 1.0), 2.0) + pow(y, 2.0) <= 0.0625);
}

fn mandelbrot(x: f32, y: f32, max_iter: i32) -> i32 {
    let c = vec2<f32>(x, y);
    var z = vec2<f32>(0.0, 0.0);
    var n:i32 = 0;
    while (complex_abs(z) <= 2.0) && (n < max_iter) {
        z = complex_mult(z, z) + c;
        n += 1;
    }
    return n;
}

fn mandelbrot_optimized(x0: f32, y0: f32, max_iter: i32) -> i32 {
    var x = 0.0;
    var y = 0.0;
    var x2 = 0.0;
    var y2 = 0.0;
    var n:i32 = 0;
    while (x2 + y2 <= 4.0) && n < max_iter {
        y = 2.0 * x * y + y0;
        x = x2 - y2 + x0;
        x2 = pow(x, 2.0);
        y2 = pow(y, 2.0);
        n += 1;
    }
    return n;
}


@group(0) @binding(0) var output_texture : texture_storage_2d<rgba8unorm, write>;
@group(0) @binding(1) var<uniform> params : MandelbrotParams;

@compute @workgroup_size(16, 16)
fn main(
    @builtin(global_invocation_id) global_id : vec3<u32>,
) {
    let dimensions = vec2<i32>(textureDimensions(output_texture).xy);
    let coords = vec2<i32>(global_id.xy);
    if (coords.x >= dimensions.x) || (coords.y >= dimensions.y) {
        return;
    }

    let xnorm = f32(coords.x) / f32(dimensions.x);
    let ynorm = f32(coords.y) / f32(dimensions.y);
    let x = lerp(xnorm, 0.0, 1.0, params.x_min, params.x_max);
    let y = lerp(ynorm, 0.0, 1.0, params.y_min, params.y_max);

    var val: f32 = 1.0;
    if is_within_the_cardioid_or_a_p2bulb(x, y) {
        val = 0.0;
    } else {
        // let i = mandelbrot(x, y, params.max_iterations);
        let i = mandelbrot_optimized(x, y, params.max_iterations);
        let i_norm = f32(i) / f32(params.max_iterations);
        
        val = i_norm; 
        val = sqrt(val);
        var bright = 1.0;
        if (i >= params.max_iterations) {
            bright = 0.0;
            val = 0.0;
        }
    }

    // let rgb = hsv2rgb(vec3<f32>(val,1.0,bright));
    let color = vec4<f32>(val, val, val, 1.0);

    textureStore(output_texture, coords.xy, color);
}
