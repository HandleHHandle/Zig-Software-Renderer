const std = @import("std");

pub const Bitmap = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    width: i32,
    height: i32,
    components: []u8,
    
    pub fn create(allocator: std.mem.Allocator, width: i32,height: i32) !Self {
        var components = try allocator.alloc(u8, @intCast(usize, width * height * 4));
        std.mem.set(u8, components, 0);

        return Self {
            .allocator = allocator,
            .width = width,
            .height = height,
            .components = components,
        };
    }

    pub fn destroy(self: *Self) void {
        self.allocator.free(self.components);
    }

    pub fn clear(self: *Self, value: u8) void {
        // std.mem.set IS REALLY SLOW FOR SOME REASON?????
        //std.mem.set(u8, self.components, value);
        @memset(self.components.ptr, value, self.components.len);
    }

    pub fn drawPixel(self: *Self, x: usize,y: usize, a: u8,r: u8,g: u8,b: u8) void {
        var index: usize = (x + y * @intCast(usize, self.width)) * 4;
        self.components.ptr[index] = a;
        self.components.ptr[index + 1] = r;
        self.components.ptr[index + 2] = g;
        self.components.ptr[index + 3] = b;
    }

    pub fn getPixelInt(self: *Self, x: usize,y: usize) u32 {
        var index: usize = (x + y * @intCast(usize, self.width)) * 4;
        var a = @intCast(u32, self.components.ptr[index]) << 24;
        var r = @intCast(u32, self.components.ptr[index+1]) << 16;
        var g = @intCast(u32, self.components.ptr[index+2]) << 8;
        var b = @intCast(u32, self.components.ptr[index+3]);

        return a | r | g | b;
    }

    // Not quite sure yet if slices are passed by reference so if there are any errors check here
    pub fn copyTo(self: *Self, dest: []u8) void {
        std.mem.copy(u8, dest, self.components);
    }
};