const std = @import("std");
const c = @import("c.zig");

pub fn main() !void {
    if(c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
        return error.SDLInitializationFailed;
    }
    defer c.SDL_Quit();

    var window = c.SDL_CreateWindow(
        "Software Renderer",
        c.SDL_WINDOWPOS_UNDEFINED,c.SDL_WINDOWPOS_UNDEFINED,
        1280,720,
        0
    ) orelse {
        c.SDL_Log("Unable to create window: %s", c.SDL_GetError());
        return error.SDLWindowCreationFailed;
    };
    defer c.SDL_DestroyWindow(window);

    var running: bool = true;
    while(running) {
        var event: c.SDL_Event = undefined;
        while(c.SDL_PollEvent(&event) != 0) {
            switch(event.@"type") {
                c.SDL_QUIT => {
                    running = false;
                },
                else => {},
            }
        }
    }
}
