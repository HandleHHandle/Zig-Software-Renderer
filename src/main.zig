const std = @import("std");
const c = @import("c.zig");

const Display = @import("display.zig").Display;
const Bitmap = @import("bitmap.zig").Bitmap;
const Stars3D = @import("stars3d.zig").Stars3D;
const Vertex = @import("vertex.zig").Vertex;
const Mesh = @import("mesh.zig").Mesh;
const Vec4 = @import("vec4.zig").Vec4;
const Mat4 = @import("mat4.zig").Mat4;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const leaked = gpa.deinit();
        if(leaked) {
            @panic("MEMORY LEAK");
        }
    }

    var display = try Display.create(allocator, "Software Renderer", 800,600);
    defer display.destroy();

    var stars = try Stars3D.create(allocator, 4096, 64.0,20.0);
    defer stars.destroy();

    var texture = try Bitmap.loadImage(allocator, "resources/brick.png");
    defer texture.destroy();

    var mesh = try Mesh.create(allocator, "resources/icosphere.obj");
    defer mesh.destroy();

    var projection = Mat4.initPerspective(
        std.math.degreesToRadians(f32, 70.0),
        @intToFloat(f32, display.width) / @intToFloat(f32, display.height),
        0.1,1000.0
    );
    var rotCounter: f32 = 0.0;

    var previousTime = std.time.milliTimestamp();
    var currentTime = std.time.milliTimestamp();
    var deltaTime: f32 = 0.0;
    while(display.isOpen()) {
        previousTime = currentTime;
        currentTime = std.time.milliTimestamp();
        deltaTime = @intToFloat(f32, currentTime - previousTime) / 1000.0;

        //std.debug.print("Frame rate: {d}\n", .{1.0 / deltaTime});

        display.input();
    
        stars.updateAndRender(&display.framebuffer.bitmap, deltaTime);

        rotCounter += deltaTime;
        var translation = Mat4.initTranslation(0.0,0.0,3.0);
        var rotation = Mat4.initRotation(0.0,rotCounter,0.0);
        var transform = projection.mul(translation.mul(rotation));

        display.framebuffer.drawMesh(mesh, transform, texture);

        display.swap();
    }
}
