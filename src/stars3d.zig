const std = @import("std");
const c = @import("c.zig");
const Bitmap = @import("bitmap.zig").Bitmap;

pub const Stars3D = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    starsX: []f32,
    starsY: []f32,
    starsZ: []f32,
    spread: f32,
    speed: f32,

    pub fn create(allocator: std.mem.Allocator, numStars: u32, spread: f32,speed: f32) !Self {
        c.srand(@intCast(u32, c.time(0)));

        var starsX = try allocator.alloc(f32, @intCast(usize, numStars));
        std.mem.set(f32, starsX, 0.0);
        var starsY = try allocator.alloc(f32, @intCast(usize, numStars));
        std.mem.set(f32, starsY, 0.0);
        var starsZ = try allocator.alloc(f32, @intCast(usize, numStars));
        std.mem.set(f32, starsZ, 0.0);

        var self = Self {
            .allocator = allocator,
            .starsX = starsX,
            .starsY = starsY,
            .starsZ = starsZ,
            .spread = spread,
            .speed = speed,
        };
        
        var i: usize = 0;
        while(i < numStars) : (i += 1) {
            self.initStar(i);
        }

        return self;
    }

    pub fn destroy(self: *Self) void {
        self.allocator.free(self.starsX);
        self.allocator.free(self.starsY);
        self.allocator.free(self.starsZ);
    }

    pub fn initStar(self: *Self, i: usize) void {
        self.starsX[i] = 2.0 * ((@intToFloat(f32, c.rand()) / @intToFloat(f32, c.RAND_MAX)) - 0.5) * self.spread;
        self.starsY[i] = 2.0 * ((@intToFloat(f32, c.rand()) / @intToFloat(f32, c.RAND_MAX)) - 0.5) * self.spread;
        self.starsZ[i] = ((@intToFloat(f32, c.rand()) / @intToFloat(f32, c.RAND_MAX)) + 0.00001) * self.spread;
    }

    pub fn updateAndRender(self: *Self, target: *Bitmap, delta: f32) void {
        var tanHalfFOV = std.math.tan(std.math.degreesToRadians(f32, 90.0 / 2.0));

        var halfWidth: f32 = @intToFloat(f32, target.width) / 2.0;
        var halfHeight: f32 = @intToFloat(f32, target.height) / 2.0;

        var i: usize = 0;
        while(i < self.starsX.len) : (i += 1) {
            self.starsZ[i] -= delta * self.speed;

            if(self.starsZ[i] <= 0) {
                self.initStar(i);
            }

            var fx = (self.starsX[i] / (self.starsZ[i] * tanHalfFOV)) * halfWidth + halfWidth;
            var fy = (self.starsY[i] / (self.starsZ[i] * tanHalfFOV)) * halfHeight + halfHeight;

            if(fx < 0 or fx >= @intToFloat(f32, target.width) or fy < 0 or fy >= @intToFloat(f32, target.height)) {
                self.initStar(i);
            } else {
                var x: usize = @floatToInt(usize, fx);
                var y: usize = @floatToInt(usize, fy);
                target.drawPixel(x,y, 255,255,255,255);
            }
        }
    }
};
