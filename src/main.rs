use bytemuck::{Pod, Zeroable};
use nanorand::{Rng, WyRand};
use std::{borrow::Cow, mem};
use wgpu::util::DeviceExt;

use computer::{Computer, SampleLocation};
use renderer::Renderer;
use math::UVec2;

mod framework;
mod computer;
mod renderer;
mod math;


#[repr(C)]
#[derive(Copy, Clone, Debug, Pod, Zeroable)]
struct Vertex {
    position: [f32; 2],
}

struct Mandelbrot {
    computer: Computer,
    renderer: Renderer,
    sample_location: SampleLocation,
    // frame_num: usize,
    clicking: bool,
    mouse_x: i32,
    mouse_y: i32,
}

impl framework::App for Mandelbrot {
    fn required_limits() -> wgpu::Limits {
        wgpu::Limits::downlevel_defaults()
    }

    fn required_downlevel_capabilities() -> wgpu::DownlevelCapabilities {
        wgpu::DownlevelCapabilities {
            flags: wgpu::DownlevelFlags::COMPUTE_SHADERS,
            ..Default::default()
        }
    }

    fn init(
        config: &wgpu::SurfaceConfiguration,
        _adapter: &wgpu::Adapter,
        device: &wgpu::Device,
        _queue: &wgpu::Queue,
    ) -> Self {
        let size = UVec2::new(config.width, config.height);
        let computer = Computer::new(size, device);
        let renderer = Renderer::new(config, device, size);

        Mandelbrot {
            computer,
            renderer,
            sample_location: SampleLocation::new(config.width as f32, config.height as f32),
            clicking: false,
            mouse_x: 0,
            mouse_y: 0,
        }
    }

    /// update is called for any WindowEvent not handled by the framework
    fn update(&mut self, event: winit::event::WindowEvent) -> bool {
        match event {
            winit::event::WindowEvent::MouseWheel {
                device_id: _,
                delta,
                phase: _,
                modifiers: _
            } => match delta {
                winit::event::MouseScrollDelta::LineDelta(_, y) => {
                    if y > 0.0 {
                        self.sample_location.zoom(y / 12.0);
                    } else {
                        self.sample_location.zoom(y / 12.0);
                    }
                },
                winit::event::MouseScrollDelta::PixelDelta(winit::dpi::PhysicalPosition { x: _, y }) => {
                    if y > 0.0 {
                        self.sample_location.zoom(y as f32 / 32.0);
                    } else {
                        self.sample_location.zoom(y as f32 / 32.0);
                    }
                }
            },
            winit::event::WindowEvent::KeyboardInput {
                device_id: _,
                input,
                is_synthetic: _,
            } => match input.state {
                winit::event::ElementState::Pressed => {
                    if input.virtual_keycode == Some(winit::event::VirtualKeyCode::A) {
                        self.sample_location.left();
                    }
                    if input.virtual_keycode == Some(winit::event::VirtualKeyCode::D) {
                        self.sample_location.right();
                    }

                    if input.virtual_keycode == Some(winit::event::VirtualKeyCode::W) {
                        self.sample_location.up();
                    }

                    if input.virtual_keycode == Some(winit::event::VirtualKeyCode::S) {
                        self.sample_location.down();
                    }

                    if input.virtual_keycode == Some(winit::event::VirtualKeyCode::Q) {
                        self.sample_location.zoom(-2.0);
                    }

                    if input.virtual_keycode == Some(winit::event::VirtualKeyCode::E) {
                        self.sample_location.zoom(2.0);
                    }
                }
                winit::event::ElementState::Released => {},
            },
            winit::event::WindowEvent::MouseInput { button: winit::event::MouseButton::Left, state: button_state, .. } => {
                match button_state {
                    winit::event::ElementState::Pressed  => { self.clicking = true  },
                    winit::event::ElementState::Released => { self.clicking = false }
                }
            },
            winit::event::WindowEvent::CursorMoved { position, .. } => {
                let (x, y): (i32, i32) = position.into();
                if self.clicking {
                    let delta_x = x - self.mouse_x;
                    let delta_y = y - self.mouse_y;
                    self.sample_location.move_(delta_x as f32, delta_y as f32);
                }
                self.mouse_x = x as i32;
                self.mouse_y = y as i32;
            },
            _ => {return false}
        }
        return true
    }

    /// resize is called on WindowEvent::Resized events
    fn resize(
        &mut self,
        sc_desc: &wgpu::SurfaceConfiguration,
        _device: &wgpu::Device,
        _queue: &wgpu::Queue,
    ) {
        self.renderer.resize(sc_desc.width, sc_desc.height);
        self.sample_location.resize(sc_desc.width as f32, sc_desc.height as f32);
    }

    fn render(
        &mut self,
        view: &wgpu::TextureView,
        device: &wgpu::Device,
        queue: &wgpu::Queue,
        _spawner: &framework::Spawner,
    ) {
        let mandelbrot = self.computer.run(device, queue, &self.sample_location.to_mandlebrot_params(1360));
        match self.renderer.render(view, device, queue, mandelbrot) {
            Ok(_) => {}
            // Reconfigure the surface if lost
            // Err(wgpu::SurfaceError::Lost) => {
            //     self.renderer.resize(app.gpu.size, &mut app.gpu)
            // }
            // The system is out of memory, we should probably quit
            // Err(wgpu::SurfaceError::OutOfMemory) => *control_flow = ControlFlow::Exit,
            // All other errors (Outdated, Timeout) should be resolved by the next frame
            Err(e) => eprintln!("{:?}", e),
        }

    }
}

fn main() {
    framework::run::<Mandelbrot>("boids");
}
