const Vec4 = @import("vec4.zig").Vec4;
const Vertex = @import("vertex.zig").Vertex;

pub const Gradients = struct {
    const Self = @This();

    texCoordX: [3]f32,
    texCoordY: [3]f32,
    texCoordXXStep: f32,
    texCoordXYStep: f32,
    texCoordYXStep: f32,
    texCoordYYStep: f32,

    pub fn create(minY: Vertex,midY: Vertex,maxY: Vertex) Self {
        var oneOverDx: f32 = 1.0 / (
            ((midY.pos.x - maxY.pos.x) * (minY.pos.y - maxY.pos.y)) -
            ((minY.pos.x - maxY.pos.x) * (midY.pos.y - maxY.pos.y))
        );

        var oneOverDy = -oneOverDx;

        var texCoordX = [3]f32 {
            minY.texCoords.x,
            midY.texCoords.x,
            maxY.texCoords.x
        };
        var texCoordY = [3]f32 {
            minY.texCoords.y,
            midY.texCoords.y,
            maxY.texCoords.y
        };

        var texCoordXXStep = (
            ((texCoordX[1] - texCoordX[2]) * (minY.pos.y - maxY.pos.y)) -
            ((texCoordX[0] - texCoordX[2]) * (midY.pos.y - maxY.pos.y))
        ) * oneOverDx;

        var texCoordXYStep = (
            ((texCoordX[1] - texCoordX[2]) * (minY.pos.x - maxY.pos.x)) -
            ((texCoordX[0] - texCoordX[2]) * (midY.pos.x - maxY.pos.x))
        ) * oneOverDy;

        var texCoordYXStep = (
            ((texCoordY[1] - texCoordY[2]) * (minY.pos.y - maxY.pos.y)) -
            ((texCoordY[0] - texCoordY[2]) * (midY.pos.y - maxY.pos.y))
        ) * oneOverDx;

        var texCoordYYStep = (
            ((texCoordY[1] - texCoordY[2]) * (minY.pos.x - maxY.pos.x)) -
            ((texCoordY[0] - texCoordY[2]) * (midY.pos.x - maxY.pos.x))
        ) * oneOverDy;

        return Self {
            .texCoordX = texCoordX,
            .texCoordY = texCoordY,
            .texCoordXXStep = texCoordXXStep,
            .texCoordXYStep = texCoordXYStep,
            .texCoordYXStep = texCoordYXStep,
            .texCoordYYStep = texCoordYYStep,
        };
    }
};
