const Vertex = @import("vertex.zig").Vertex;
const Vec4 = @import("vec4.zig").Vec4;
const Gradients = @import("gradients.zig").Gradients;
const math = @import("std").math;

pub const Edge = struct {
    const Self = @This();

    x: f32,
    xStep: f32,
    yStart: i32,
    yEnd: i32,
    texCoordX: f32,
    texCoordXStep: f32,
    texCoordY: f32,
    texCoordYStep: f32,
    oneOverZ: f32,
    oneOverZStep: f32,
    depth: f32,
    depthStep: f32,
    lightAmount: f32,
    lightAmountStep: f32,

    pub fn create(gradients: Gradients, minY: Vertex,maxY: Vertex, minYIndex: usize) Self {
        var yStart = @floatToInt(i32, @ceil(minY.pos.y));
        var yEnd = @floatToInt(i32, @ceil(maxY.pos.y));

        var yDist = maxY.pos.y - minY.pos.y;
        var xDist = maxY.pos.x - minY.pos.x;

        var yPrestep = @intToFloat(f32, yStart) - minY.pos.y;
        var xStep = xDist / yDist;
        var x = minY.pos.x + yPrestep * xStep;
        var xPrestep = x - minY.pos.x;

        var texCoordX = gradients.texCoordX[minYIndex] + gradients.texCoordXXStep * xPrestep + gradients.texCoordXYStep * yPrestep;
        var texCoordXStep = gradients.texCoordXYStep + gradients.texCoordXXStep * xStep;

        var texCoordY = gradients.texCoordY[minYIndex] + gradients.texCoordYXStep * xPrestep + gradients.texCoordYYStep * yPrestep;
        var texCoordYStep = gradients.texCoordYYStep + gradients.texCoordYXStep * xStep;

        var oneOverZ = gradients.oneOverZ[minYIndex] + gradients.oneOverZXStep * xPrestep + gradients.oneOverZYStep * yPrestep;
        var oneOverZStep = gradients.oneOverZYStep + gradients.oneOverZXStep * xStep;

        var depth = gradients.depth[minYIndex] + gradients.depthXStep * xPrestep + gradients.depthYStep * yPrestep;
        var depthStep = gradients.depthYStep + gradients.depthXStep * xStep;

        var lightAmount = gradients.lightAmount[minYIndex] + gradients.lightAmountXStep * xPrestep + gradients.lightAmountYStep * yPrestep;            
        var lightAmountStep = gradients.lightAmountYStep + gradients.lightAmountXStep * xStep;

        return Self {
            .x = x,
            .xStep = xStep,
            .yStart = yStart,
            .yEnd = yEnd,
            .texCoordX = texCoordX,
            .texCoordXStep = texCoordXStep,
            .texCoordY = texCoordY,
            .texCoordYStep = texCoordYStep,
            .oneOverZ = oneOverZ,
            .oneOverZStep = oneOverZStep,
            .depth = depth,
            .depthStep = depthStep,
            .lightAmount = lightAmount,
            .lightAmountStep = lightAmountStep,
        };
    }

    pub fn step(self: *Self) void {
        self.x += self.xStep;
        self.texCoordX += self.texCoordXStep;
        self.texCoordY += self.texCoordYStep;
        self.oneOverZ += self.oneOverZStep;
        self.depth += self.depthStep;
        self.lightAmount += self.lightAmountStep;
    }
};
