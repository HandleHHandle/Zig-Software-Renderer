const std = @import("std");
const c = @import("c.zig");

const Display = @import("display.zig").Display;
const Bitmap = @import("bitmap.zig").Bitmap;
const Stars3D = @import("stars3d.zig").Stars3D;

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

    display.framebuffer.drawPixel(100,100, 255,255,0,0);

    var previousTime = std.time.milliTimestamp();
    var currentTime = std.time.milliTimestamp();
    var deltaTime: f32 = 0.0;
    while(display.isOpen()) {
        previousTime = currentTime;
        currentTime = std.time.milliTimestamp();
        deltaTime = @intToFloat(f32, currentTime - previousTime) / 1000.0;

        std.debug.print("Frame rate: {d}\n", .{1.0 / deltaTime});

        display.input();
    
        stars.updateAndRender(&display.framebuffer, deltaTime);

        display.swap();
    }
}
