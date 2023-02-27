const std = @import("std");
const c = @import("c.zig");
const Bitmap = @import("bitmap.zig").Bitmap;

pub const Display = struct {
    const Self = @This();

    width: c_int,
    height: c_int,
    window: *c.SDL_Window,
    surface: *c.SDL_Surface,
    framebuffer: Bitmap,
    open: bool,

    pub fn create(allocator: std.mem.Allocator, title: [*]const u8, width: c_int,height: c_int) !Self {
        if(c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
            c.SDL_Log("Unable to initialize SDL: %s\n", c.SDL_GetError());
            return error.SDLInitializationFailed;
        }

        var window = c.SDL_CreateWindow(
            title,
            c.SDL_WINDOWPOS_UNDEFINED,c.SDL_WINDOWPOS_UNDEFINED,
            width,height,
            c.SDL_WINDOW_SHOWN,
        ) orelse {
            c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
            return error.SDLWindowCreationFailed;
        };

        var surface = c.SDL_GetWindowSurface(window) orelse {
            c.SDL_Log("Failed to obtain window surface: %s", c.SDL_GetError());
            return error.SDLSurfaceNull;
        };

        var bitmap = try Bitmap.create(allocator, width,height);

        return Self {
            .width = width,
            .height = height,
            .window = window,
            .surface = surface,
            .framebuffer = bitmap,
            .open = true
        };
    }

    pub fn destroy(self: *Self) void {
        self.framebuffer.destroy();
        c.SDL_DestroyWindow(self.window);
        c.SDL_Quit();
    }

    pub fn isOpen(self: *Self) bool {
        return self.open;
    }

    pub fn input(self: *Self) void {
        var event: c.SDL_Event = undefined;
        while(c.SDL_PollEvent(&event) != 0) {
            switch(event.@"type") {
                c.SDL_QUIT => {
                    self.open = false;
                },
                else => {},
            }
        }
    }

    pub fn swap(self: *Self) void {
        _ = c.SDL_LockSurface(self.surface);

        var y: usize = 0;
        while(y < self.height) : (y += 1) {
            var x: usize = 0;
            while(x < self.width) : (x += 1) {
                var target_pixel = @ptrCast(*c.Uint32, @alignCast(4, &@ptrCast([*c]u8, self.surface.pixels.?)[
                    y * @intCast(usize, self.surface.pitch) + x * self.surface.format.*.BytesPerPixel
                ]));

                target_pixel.* = self.framebuffer.getPixelInt(x,y);
            }
        }

        _ = c.SDL_UnlockSurface(self.surface);

        _ = c.SDL_UpdateWindowSurface(self.window);
    }
};
