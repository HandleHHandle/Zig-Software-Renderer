const std = @import("std");
const Bitmap = @import("bitmap.zig").Bitmap;
const Vertex = @import("vertex.zig").Vertex;
const Mat4 = @import("mat4.zig").Mat4;

pub const RenderContext = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    bitmap: Bitmap,
    scanbuffer: []usize,

    pub fn create(allocator: std.mem.Allocator, width: i32,height: i32) !Self {
        var bitmap = try Bitmap.create(allocator, width,height);

        var scanbuffer: []usize = try allocator.alloc(usize, @intCast(usize, height * 2));
        std.mem.set(usize, scanbuffer, 0);

        return Self {
            .allocator = allocator,
            .bitmap = bitmap,
            .scanbuffer = scanbuffer,
        };
    }

    pub fn destroy(self: *Self) void {
        self.allocator.free(self.scanbuffer);
        self.bitmap.destroy();
    }

    pub fn drawScanBuffer(self: *Self, ycoord: usize, xmin: usize, xmax: usize) void {
        self.scanbuffer[ycoord * 2] = xmin;
        self.scanbuffer[ycoord * 2 + 1] = xmax;
    }

    pub fn fillShape(self: *Self, ymin: usize,ymax: usize) void {
        var j: usize = ymin;
        while(j < ymax) : (j += 1) {
            var xmin = self.scanbuffer[j * 2];
            var xmax = self.scanbuffer[j * 2 + 1];

            var i: usize = xmin;
            while(i < xmax) : (i += 1) {
                self.bitmap.drawPixel(i,j, 255,255,255,255);
            }
        }
    }

    pub fn fillTriangle(self: *Self, v1: Vertex,v2: Vertex,v3: Vertex) void {
        var screenSpaceTransform = Mat4.initScreenSpaceTransform(@intToFloat(f32, self.bitmap.width) / 2.0, @intToFloat(f32, self.bitmap.height) / 2.0);
        var minY: Vertex = v1.transform(screenSpaceTransform).perspectiveDivide();
        var midY: Vertex = v2.transform(screenSpaceTransform).perspectiveDivide();
        var maxY: Vertex = v3.transform(screenSpaceTransform).perspectiveDivide();

        if(maxY.pos.y < midY.pos.y) {
            var temp = maxY;
            maxY = midY;
            midY = temp;
        }

        if(midY.pos.y < minY.pos.y) {
            var temp = midY;
            midY = minY;
            minY = temp;
        }

        if(maxY.pos.y < midY.pos.y) {
            var temp = maxY;
            maxY = midY;
            midY = temp;
        }

        var area = minY.triArea2(maxY,midY);
        var handedness: usize = if(area >= 0) 1 else 0;

        self.scanConvertTriangle(minY,midY,maxY, handedness);
        self.fillShape(@floatToInt(usize, minY.pos.y), @floatToInt(usize, maxY.pos.y));
    }

    pub fn scanConvertTriangle(self: *Self, minY: Vertex,midY: Vertex,maxY: Vertex, handedness: usize) void {
        self.scanConvertLine(minY,maxY, 0 + handedness);
        self.scanConvertLine(minY,midY, 1 - handedness);
        self.scanConvertLine(midY,maxY, 1 - handedness);
    }

    pub fn scanConvertLine(self: *Self, minY: Vertex,maxY: Vertex, whichSide: usize) void {
        var ystart = @floatToInt(i32, minY.pos.y);
        var yend = @floatToInt(i32, maxY.pos.y);
        var xstart = @floatToInt(i32, minY.pos.x);
        var xend = @floatToInt(i32, maxY.pos.x);

        var ydist = yend - ystart;
        var xdist = xend - xstart;

        if(ydist <= 0){
            return;
        }

        var xstep = @intToFloat(f32, xdist) / @intToFloat(f32, ydist);
        var curx = @intToFloat(f32, xstart);

        var i = ystart;
        while(i < yend) : (i += 1) {
            self.scanbuffer[@intCast(usize, i) * 2 + whichSide] = @floatToInt(usize, curx);
            curx += xstep;
        }
    }
};
