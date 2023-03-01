const std = @import("std");
const Bitmap = @import("bitmap.zig").Bitmap;
const Vertex = @import("vertex.zig").Vertex;
const Edge = @import("edge.zig").Edge;
const Gradients = @import("gradients.zig").Gradients;
const Vec4 = @import("vec4.zig").Vec4;
const Mat4 = @import("mat4.zig").Mat4;
const Mesh = @import("mesh.zig").Mesh;

pub const RenderContext = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    bitmap: Bitmap,
    zBuffer: []f32,

    pub fn create(allocator: std.mem.Allocator, width: i32,height: i32) !Self {
        var bitmap = try Bitmap.create(allocator, width,height);

        var zBuffer = try allocator.alloc(f32, @intCast(usize, width * height));

        return Self {
            .allocator = allocator,
            .bitmap = bitmap,
            .zBuffer = zBuffer,
        };
    }

    pub fn destroy(self: *Self) void {
        self.allocator.free(self.zBuffer);
        self.bitmap.destroy();
    }
    
    pub fn clearDepthBuffer(self: *Self) void {
        std.mem.set(f32, self.zBuffer, std.math.floatMax(f32));
    }

    pub fn drawMesh(self: *Self, mesh: Mesh, transform: Mat4, texture: Bitmap) !void {
        var i: usize = 0;
        while(i < mesh.indices.items.len) : (i += 3) {
            try self.drawTriangle(
                mesh.vertices.items[mesh.indices.items[i]].transform(transform),
                mesh.vertices.items[mesh.indices.items[i+1]].transform(transform),
                mesh.vertices.items[mesh.indices.items[i+2]].transform(transform),
                texture
            );
        }
    }

    pub fn drawTriangle(self: *Self, v1: Vertex,v2: Vertex,v3: Vertex, texture: Bitmap) !void {
        var v1Inside = v1.isInsideViewFrustum();
        var v2Inside = v2.isInsideViewFrustum();
        var v3Inside = v3.isInsideViewFrustum();

        if(v1Inside and v2Inside and v3Inside) {
            self.fillTriangle(v1,v2,v3, texture);
        }

        if(!v1Inside and !v2Inside and !v3Inside) {
            return;
        }

        var vertices = std.ArrayList(Vertex).init(self.allocator);
        defer vertices.deinit();
        var auxillaryList = std.ArrayList(Vertex).init(self.allocator);
        defer auxillaryList.deinit();

        try vertices.append(v1);
        try vertices.append(v2);
        try vertices.append(v3);

        if(try self.clipPolygonAxis(&vertices, &auxillaryList, 0) and
            try self.clipPolygonAxis(&vertices, &auxillaryList, 1) and
            try self.clipPolygonAxis(&vertices, &auxillaryList, 2)) {
            var initialVertex = vertices.items[0];

            var i: usize = 0;
            while(i < vertices.items.len) : (i += 1) {
                self.fillTriangle(initialVertex,vertices.items[i],vertices.items[1+1], texture);
            }
        }
    }

    pub fn clipPolygonAxis(self: *Self, vertices: *std.ArrayList(Vertex),auxillaryList: *std.ArrayList(Vertex), componentIndex: usize) !bool {
        try self.clipPolygonComponent(vertices, componentIndex, 1.0, auxillaryList);
        vertices.clearAndFree();

        if(auxillaryList.items.len == 0) {
            return false;
        }

        try self.clipPolygonComponent(auxillaryList, componentIndex, -1.0, vertices);
        auxillaryList.clearAndFree();

        return vertices.items.len != 0;
    }

    pub fn clipPolygonComponent(_: *Self, vertices: *std.ArrayList(Vertex), componentIndex: usize, componentFactor: f32, result: *std.ArrayList(Vertex)) !void {
        var previousVertex = vertices.items[vertices.items.len - 1];
        var previousComponent = previousVertex.get(componentIndex) * componentFactor;
        var previousInside = previousComponent <= previousVertex.pos.w;

        var i: usize = 0;
        while(i < vertices.items.len) : (i += 1) {
            var currentVertex = vertices.items[i];
            var currentComponent = currentVertex.get(componentIndex) * componentFactor;
            var currentInside = currentComponent <= currentVertex.pos.w;

            if((@boolToInt(currentInside) ^ @boolToInt(previousInside)) != 0) {
                var amount = (previousVertex.pos.w - previousComponent) / ((previousVertex.pos.w - previousComponent) - (currentVertex.pos.w - currentComponent));
                try result.append(previousVertex.lerp(currentVertex, amount));
            }

            if(currentInside) {
                try result.append(currentVertex);
            }

            previousVertex = currentVertex;
            previousComponent = currentComponent;
            previousInside = currentInside;
        }
    }

    pub fn fillTriangle(self: *Self, v1: Vertex,v2: Vertex,v3: Vertex, texture: Bitmap) void {
        var screenSpaceTransform = Mat4.initScreenSpaceTransform(@intToFloat(f32, self.bitmap.width) / 2.0, @intToFloat(f32, self.bitmap.height) / 2.0);
        var minY: Vertex = v1.transform(screenSpaceTransform).perspectiveDivide();
        var midY: Vertex = v2.transform(screenSpaceTransform).perspectiveDivide();
        var maxY: Vertex = v3.transform(screenSpaceTransform).perspectiveDivide();

        if(minY.triArea2(maxY,midY) >= 0) return;

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

        self.scanEdges(&topToBottom,&topToMiddle, handedness, texture);
        self.scanEdges(&topToBottom,&midToBottom, handedness, texture);
    }

    pub fn scanEdges(self: *Self, a: *Edge,b: *Edge, handedness: bool, texture: Bitmap) void {
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
            self.drawScanLine(left,right, i, texture);
            left.step();
            right.step();
        }
    }

    pub fn drawScanLine(self: *Self, left: *Edge,right: *Edge, j: i32, texture: Bitmap) void {
        var xMin = @floatToInt(i32, @ceil(left.x));
        var xMax = @floatToInt(i32, @ceil(right.x));
        var xPrestep = @intToFloat(f32, xMin) - left.x;

        var xDist = right.x - left.x;
        var texCoordXXStep = (right.texCoordX - left.texCoordX) / xDist;
        var texCoordYXStep = (right.texCoordY - left.texCoordY) / xDist;
        var oneOverZXStep = (right.oneOverZ - left.oneOverZ) / xDist;
        var depthXStep = (right.depth - left.depth) / xDist;

        var texCoordX = left.texCoordX + texCoordXXStep * xPrestep;
        var texCoordY = left.texCoordY + texCoordYXStep * xPrestep;
        var oneOverZ = left.oneOverZ + oneOverZXStep * xPrestep;
        var depth = left.depth + depthXStep * xPrestep;

        var i: i32 = xMin;
        while(i < xMax) : (i += 1) {
            var index: usize = @intCast(usize, i + j * self.bitmap.width);
            if(depth < self.zBuffer[index]) {
                self.zBuffer[index] = depth;
                var z = 1.0 / oneOverZ;
                var srcX = @floatToInt(usize, (texCoordX * z) * @intToFloat(f32, texture.width - 1) + 0.5);
                var srcY = @floatToInt(usize, (texCoordY * z) * @intToFloat(f32, texture.height - 1) + 0.5);

                self.bitmap.copyPixel(@intCast(usize, i),@intCast(usize, j), srcX,srcY, texture);
            }

            oneOverZ += oneOverZXStep;
            texCoordX += texCoordXXStep;
            texCoordY += texCoordYXStep;
            depth += depthXStep;
        }
    }
};
