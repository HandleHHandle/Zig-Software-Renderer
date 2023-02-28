const std = @import("std");
const c = @import("c.zig");
const Bitmap = @import("bitmap.zig").Bitmap;
const RenderContext = @import("rendercontext.zig").RenderContext;

pub const Display = struct {
    const Self = @This();

    width: c_int,
    height: c_int,
    window: *c.SDL_Window,
    renderer: *c.SDL_Renderer,
    texture: *c.SDL_Texture,
    format: u32,
    framebuffer: RenderContext,
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

        var renderer = c.SDL_CreateRenderer(window, -1, c.SDL_RENDERER_ACCELERATED) orelse {
            c.SDL_Log("Unable to create renderer: %s", c.SDL_GetError());
            return error.SDLRendererCreationFailed;
        };

        var texture = c.SDL_CreateTexture(renderer, c.SDL_PIXELFORMAT_RGBA8888, c.SDL_TEXTUREACCESS_STREAMING, width,height) orelse {
            c.SDL_Log("Failed to create texture: %s", c.SDL_GetError());
            return error.SDLTextureNull;
        };

        var format: u32 = undefined;
        _ = c.SDL_QueryTexture(texture, &format, null,null,null);

        var framebuffer = try RenderContext.create(allocator, width,height);

        return Self {
            .width = width,
            .height = height,
            .window = window,
            .renderer = renderer,
            .texture = texture,
            .format = format,
            .framebuffer = framebuffer,
            .open = true
        };
    }

    pub fn destroy(self: *Self) void {
        self.framebuffer.destroy();
        c.SDL_DestroyTexture(self.texture);
        c.SDL_DestroyRenderer(self.renderer);
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
        var pixels: ?*anyopaque = null;
        var pitch: i32 = 0;

        if(c.SDL_LockTexture(self.texture, null, &pixels, &pitch) != 0) {
            c.SDL_Log("Failed to lock texture: %s", c.SDL_GetError());
            return;
        }

        var upixels = @ptrCast([*]u32, @alignCast(4, pixels.?));

        var y: usize = 0;
        while(y < self.height) : (y += 1) {
            var x: usize = 0;
            while(x < self.width) : (x += 1) {
                var index: usize = y * @divExact(@intCast(u32, pitch), @sizeOf(u32)) + x;
                upixels[index] = self.framebuffer.bitmap.getPixelInt(x,y);
            }
        }
        _ = c.SDL_UnlockTexture(self.texture);

        _ = c.SDL_RenderCopy(self.renderer, self.texture, null,null);

        c.SDL_RenderPresent(self.renderer);
    }
};
