const Vec4 = @import("vec4.zig").Vec4;
const Mat4 = @import("mat4.zig").Mat4;
const math = @import("std").math;

pub const Vertex = struct {
    const Self = @This();

    pos: Vec4,
    texCoords: Vec4,
    normal: Vec4,

    pub fn create(pos: Vec4,texCoords: Vec4,normal: Vec4) Self {
        return Self {
            .pos = pos,
            .texCoords = texCoords,
            .normal = normal,
        };
    }

    pub fn transform(self: *const Self, trans: Mat4) Self {
        return Self.create(trans.transform(self.pos), self.texCoords,self.normal);
    }

    pub fn perspectiveDivide(self: *const Self) Self {
        return Self.create(Vec4.create(
            self.pos.x / self.pos.w,
            self.pos.y / self.pos.w,
            self.pos.z / self.pos.w,
            self.pos.w
        ), self.texCoords,self.normal);
    }

    pub fn triArea2(self: *Self, b: Vertex,c: Vertex) f32 {
        var x1 = b.pos.x - self.pos.x;
        var y1 = b.pos.y - self.pos.y;

        var x2 = c.pos.x - self.pos.x;
        var y2 = c.pos.y - self.pos.y;

        return (x1 * y2 - x2 * y1);
    }

    pub fn lerp(self: *const Self, other: Self, amount: f32) Self {
        return Self.create(
            self.pos.lerp(other.pos, amount),
            self.texCoords.lerp(other.texCoords, amount),
            self.normal.lerp(other.normal, amount)
        );
    }

    pub fn isInsideViewFrustum(self: *const Self) bool {
        return math.fabs(self.pos.x) <= math.fabs(self.pos.w) and
            math.fabs(self.pos.y) <= math.fabs(self.pos.w) and
            math.fabs(self.pos.z) <= math.fabs(self.pos.w);
    }

    pub fn get(self: *const Self, index: usize) f32 {
        switch(index) {
            0 => return self.pos.x,
            1 => return self.pos.y,
            2 => return self.pos.z,
            3 => return self.pos.w,
            else => return math.floatMax(f32),
        }
    }
};
