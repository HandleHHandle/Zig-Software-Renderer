const Vec4 = @import("vec4.zig").Vec4;
const Vertex = @import("vertex.zig").Vertex;

pub const Gradients = struct {
    const Self = @This();

    texCoordX: [3]f32,
    texCoordY: [3]f32,
    oneOverZ: [3]f32,
    depth: [3]f32,
    lightAmount: [3]f32,
    texCoordXXStep: f32,
    texCoordXYStep: f32,
    texCoordYXStep: f32,
    texCoordYYStep: f32,
    oneOverZXStep: f32,
    oneOverZYStep: f32,
    depthXStep: f32,
    depthYStep: f32,
    lightAmountXStep: f32,
    lightAmountYStep: f32,

    fn calcXStep(values: [3]f32, minY: Vertex,midY: Vertex,maxY: Vertex, dv: f32) f32 {
        return (
            ((values[1] - values[2]) * (minY.pos.y - maxY.pos.y)) -
            ((values[0] - values[2]) * (midY.pos.y - maxY.pos.y))
        ) * dv;
    }

    fn calcYStep(values: [3]f32, minY: Vertex,midY: Vertex,maxY: Vertex, dv: f32) f32 {
        return (
            ((values[1] - values[2]) * (minY.pos.x - maxY.pos.x)) -
            ((values[0] - values[2]) * (midY.pos.x - maxY.pos.x))
        ) * dv;
    }

    fn saturate(val: f32) f32 {
        if(val > 1.0) {
            return 1.0;
        }
        if(val < 0.0) {
            return 0.0;
        }
        return val;
    }

    pub fn create(minY: Vertex,midY: Vertex,maxY: Vertex) Self {
        var oneOverDx: f32 = 1.0 / (
            ((midY.pos.x - maxY.pos.x) * (minY.pos.y - maxY.pos.y)) -
            ((minY.pos.x - maxY.pos.x) * (midY.pos.y - maxY.pos.y))
        );

        var oneOverDy = -oneOverDx;

        var oneOverZ = [3]f32 {
            1.0 / minY.pos.w,
            1.0 / midY.pos.w,
            1.0 / maxY.pos.w
        };
        var texCoordX = [3]f32 {
            minY.texCoords.x * oneOverZ[0],
            midY.texCoords.x * oneOverZ[1],
            maxY.texCoords.x * oneOverZ[2]
        };
        var texCoordY = [3]f32 {
            minY.texCoords.y * oneOverZ[0],
            midY.texCoords.y * oneOverZ[1],
            maxY.texCoords.y * oneOverZ[2]
        };
        var depth = [3]f32 {
            minY.pos.z,
            midY.pos.z,
            maxY.pos.z
        };

        var lightDir = Vec4.create(0,0,1,1);
        var lightAmount = [3]f32 {
            Self.saturate(minY.normal.dot(lightDir)) * 0.9 + 0.1,
            Self.saturate(midY.normal.dot(lightDir)) * 0.9 + 0.1,
            Self.saturate(maxY.normal.dot(lightDir)) * 0.9 + 0.1
        };

        var texCoordXXStep = Self.calcXStep(texCoordX,minY,midY,maxY, oneOverDx);
        var texCoordXYStep = Self.calcYStep(texCoordX,minY,midY,maxY, oneOverDy);
        var texCoordYXStep = Self.calcXStep(texCoordY,minY,midY,maxY, oneOverDx);
        var texCoordYYStep = Self.calcYStep(texCoordY,minY,midY,maxY, oneOverDy);
        var oneOverZXStep = Self.calcXStep(oneOverZ,minY,midY,maxY, oneOverDx);
        var oneOverZYStep = Self.calcYStep(oneOverZ,minY,midY,maxY, oneOverDy);
        var depthXStep = Self.calcXStep(depth,minY,midY,maxY, oneOverDx);
        var depthYStep = Self.calcYStep(depth,minY,midY,maxY, oneOverDy);
        var lightAmountXStep = Self.calcXStep(lightAmount,minY,midY,maxY, oneOverDx);
        var lightAmountYStep = Self.calcYStep(lightAmount,minY,midY,maxY, oneOverDx);

        return Self {
            .texCoordX = texCoordX,
            .texCoordY = texCoordY,
            .oneOverZ = oneOverZ,
            .depth = depth,
            .lightAmount = lightAmount,
            .texCoordXXStep = texCoordXXStep,
            .texCoordXYStep = texCoordXYStep,
            .texCoordYXStep = texCoordYXStep,
            .texCoordYYStep = texCoordYYStep,
            .oneOverZXStep = oneOverZXStep,
            .oneOverZYStep = oneOverZYStep,
            .depthXStep = depthXStep,
            .depthYStep = depthYStep,
            .lightAmountXStep = lightAmountXStep,
            .lightAmountYStep = lightAmountYStep,
        };
    }
};
