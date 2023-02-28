const std = @import("std");
const c = @import("c.zig");

pub const Bitmap = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    width: i32,
    height: i32,
    components: []u8,
    
    pub fn create(allocator: std.mem.Allocator, width: i32,height: i32) !Self {
        var components = try allocator.alloc(u8, @intCast(usize, width * height * 4));
        //std.mem.set(u8, components, 0);
        @memset(components.ptr, 0, components.len);

        return Self {
            .allocator = allocator,
            .width = width,
            .height = height,
            .components = components,
        };
    }

    pub fn loadImage(allocator: std.mem.Allocator, path: [*]const u8) !Self {
        var width: i32 = 0;
        var height: i32 = 0;
        var channels: i32 = 0;
        c.stbi_flip_vertically_on_load(1);
        var data = c.stbi_load(path, &width,&height,&channels, 4);
        if(data == null) {
            return error.FailedToLoadBitmap;
        }
        defer c.stbi_image_free(data);

        var length: usize = @intCast(usize, width * height * channels);
        var components = try allocator.alloc(u8, length);
        @memcpy(components.ptr, data, length);

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

    pub fn copyPixel(self: *Self, dstX: usize,dstY: usize, srcX: usize,srcY: usize, src: Bitmap) void {
        var dstIndex: usize = (dstX + dstY * @intCast(usize, self.width)) * 4;
        var srcIndex: usize = (srcX + srcY * @intCast(usize, src.width)) * 4;
        self.components[dstIndex] = src.components[srcIndex];
        self.components[dstIndex+1] = src.components[srcIndex+1];
        self.components[dstIndex+2] = src.components[srcIndex+2];
        self.components[dstIndex+3] = src.components[srcIndex+3];
    }
};
