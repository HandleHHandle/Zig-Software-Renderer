const std = @import("std");
const Bitmap = @import("bitmap.zig").Bitmap;
const Vertex = @import("vertex.zig").Vertex;
const Edge = @import("edge.zig").Edge;
const Gradients = @import("gradients.zig").Gradients;
const Vec4 = @import("vec4.zig").Vec4;
const Mat4 = @import("mat4.zig").Mat4;

pub const RenderContext = struct {
    const Self = @This();

    bitmap: Bitmap,

    pub fn create(allocator: std.mem.Allocator, width: i32,height: i32) !Self {
        var bitmap = try Bitmap.create(allocator, width,height);

        return Self {
            .bitmap = bitmap,
        };
    }

    pub fn destroy(self: *Self) void {
        self.bitmap.destroy();
    }

    pub fn fillTriangle(self: *Self, v1: Vertex,v2: Vertex,v3: Vertex, texture: Bitmap) void {
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

        self.scanTriangle(minY,midY,maxY, minY.triArea2(maxY,midY) >= 0, texture);
    }

    pub fn scanTriangle(self: *Self, minY: Vertex,midY: Vertex,maxY: Vertex, handedness: bool, texture: Bitmap) void {
        var gradients = Gradients.create(minY,midY,maxY);
        var topToBottom: Edge = Edge.create(gradients, minY,maxY, 0);
        var topToMiddle: Edge = Edge.create(gradients, minY,midY, 0);
        var midToBottom: Edge = Edge.create(gradients, midY,maxY, 1);

        self.scanEdges(&gradients, &topToBottom,&topToMiddle, handedness, texture);
        self.scanEdges(&gradients, &topToBottom,&midToBottom, handedness, texture);
    }

    pub fn scanEdges(self: *Self, gradients: *Gradients, a: *Edge,b: *Edge, handedness: bool, texture: Bitmap) void {
        var left = a;
        var right = b;
        if(handedness) {
            left = b;
            right = a;
        }

        var yStart = b.yStart;
        var yEnd = b.yEnd;
        var i: i32 = yStart;
        while(i < yEnd) : (i += 1) {
            self.drawScanLine(gradients, left,right, i, texture);
            left.step();
            right.step();
        }
    }

    pub fn drawScanLine(self: *Self, gradients: *Gradients, left: *Edge,right: *Edge, j: i32, texture: Bitmap) void {
        var xMin = @floatToInt(i32, @ceil(left.x));
        var xMax = @floatToInt(i32, @ceil(right.x));
        var xPrestep = @intToFloat(f32, xMin) - left.x;

        var texCoordX = left.texCoordX + gradients.texCoordXXStep * xPrestep;
        var texCoordY = left.texCoordY + gradients.texCoordYXStep * xPrestep;

        var i: i32 = xMin;
        while(i < xMax) : (i += 1) {
            var srcX: usize = @floatToInt(usize, texCoordX * @intToFloat(f32, texture.width - 1) + 0.5);
            var srcY: usize = @floatToInt(usize, texCoordY * @intToFloat(f32, texture.height - 1) + 0.5);

            self.bitmap.copyPixel(@intCast(usize, i),@intCast(usize, j), srcX,srcY, texture);
            texCoordX += gradients.texCoordXXStep;
            texCoordY += gradients.texCoordYXStep;
        }
    }
};
