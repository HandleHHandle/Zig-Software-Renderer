const Vec4 = @import("vec4.zig").Vec4;
const Mat4 = @import("mat4.zig").Mat4;

pub const Vertex = struct {
    const Self = @This();

    pos: Vec4,
    texCoords: Vec4,

    pub fn create(pos: Vec4,texCoords: Vec4) Self {
        return Self {
            .pos = pos,
            .texCoords = texCoords,
        };
    }

    pub fn transform(self: *const Self, trans: Mat4) Self {
        return Self.create(trans.transform(self.pos), self.texCoords);
    }

    pub fn perspectiveDivide(self: *const Self) Self {
        return Self.create(Vec4.create(
            self.pos.x / self.pos.w,
            self.pos.y / self.pos.w,
            self.pos.z / self.pos.w,
            self.pos.w
        ), self.texCoords);
    }

    pub fn triArea2(self: *Self, b: Vertex,c: Vertex) f32 {
        var x1 = b.pos.x - self.pos.x;
        var y1 = b.pos.y - self.pos.y;

        var x2 = c.pos.x - self.pos.x;
        var y2 = c.pos.y - self.pos.y;

        return (x1 * y2 - x2 * y1);
    }
};
