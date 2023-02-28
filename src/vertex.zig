const Vec4 = @import("vec4.zig").Vec4;
const Mat4 = @import("mat4.zig").Mat4;

pub const Vertex = struct {
    const Self = @This();

    pos: Vec4,

    pub fn create(x: f32,y: f32,z: f32) Self {
        return Self {
            .pos = Vec4.create(x,y,z, 1.0),
        };
    }

    pub fn fromVec(vec: Vec4) Self {
        return Self {
            .pos = vec,
        };
    }

    pub fn transform(self: *const Self, trans: Mat4) Self {
        return Self.fromVec(trans.transform(self.pos));
    }

    pub fn perspectiveDivide(self: *const Self) Self {
        return Self.fromVec(Vec4.create(
            self.pos.x / self.pos.w,
            self.pos.y / self.pos.w,
            self.pos.z / self.pos.w,
            self.pos.w
        ));
    }

    pub fn triArea2(self: *Self, b: Vertex,c: Vertex) f32 {
        var x1 = b.pos.x - self.pos.x;
        var y1 = b.pos.y - self.pos.y;

        var x2 = c.pos.x - self.pos.x;
        var y2 = c.pos.y - self.pos.y;

        return (x1 * y2 - x2 * y1);
    }
};
