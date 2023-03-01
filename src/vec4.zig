const math = @import("std").math;
const std = @import("std");

pub const Vec4 = struct {
    const Self = @This();

    x: f32,
    y: f32,
    z: f32,
    w: f32,

    pub fn create(x: f32,y: f32,z: f32,w: f32) Self {
        return Self {
            .x = x,
            .y = y,
            .z = z,
            .w = w,
        };
    }

    pub fn length(self: *const Self) f32 {
        return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z + self.w * self.w);
    }

    pub fn max(self: *const Self) f32 {
        return math.max(math.max(self.x,self.y), math.max(self.z,self.w));
    }

    pub fn dot(self: *const Self, r: Self) f32 {
        return self.x * r.x + self.y * r.y + self.z * r.z + self.w * r.w;
    }

    pub fn cross(self: *const Self, r: Self) Self {
        var x = self.y * r.z - self.z * r.y;
        var y = self.z * r.x - self.x * r.z;
        var z = self.x * r.y - self.y * r.x;

        return Self.create(x,y,z, 0.0);
    }

    pub fn normalized(self: *const Self) Self {
        var len = self.length();

        return Self.create(self.x / len,self.y / len,self.z / len,self.w / len);
    }

    pub fn rotate(self: *const Self, axis: Self,angle: f32) Self {
        var sinAngle: f32 = math.sin(-angle);
        var cosAngle: f32 = math.cos(-angle);

        return self.cross(axis.scale(sinAngle)).add(
            (self.scale(cosAngle)).add(
                axis.scale(self.dot(axis.scale(1.0 - cosAngle)))));
    }

    pub fn lerp(self: *const Self, dest: Self, lerpFactor: f32) Self {
        return dest.sub(self.*).scale(lerpFactor).add(self.*);
    }

    pub fn add(self: *const Self, r: Self) Self {
        return Self.create(self.x + r.x,self.y + r.y,self.z + r.z,self.w + r.w);
    }

    pub fn addScalar(self: *const Self, r: f32) Self {
        return Self.create(self.x + r,self.y + r,self.z + r,self.w + r);
    }

    pub fn sub(self: *const Self, r: Self) Self {
        return Self.create(self.x - r.x,self.y - r.y,self.z - r.z,self.w - r.w);
    }

    pub fn subScalar(self: *const Self, r: f32) Self {
        return Self.create(self.x - r,self.y - r,self.z - r,self.w - r);
    }

    pub fn mul(self: *const Self, r: Self) Self {
        return Self.create(self.x * r.x,self.y * r.y,self.z * r.z,self.w * r.w);
    }

    pub fn scale(self: *const Self, r: f32) Self {
        return Self.create(self.x * r,self.y * r,self.z * r,self.w * r);
    }

    pub fn div(self: *const Self, r: Self) Self {
        return Self.create(self.x / r.x,self.y / r.y,self.z / r.z,self.w / r.w);
    }

    pub fn abs(self: *const Self) Self {
        return Self.create(math.fabs(self.x),math.fabs(self.y),math.fabs(self.z),math.fabs(self.w));
    }

    pub fn equals(self: *const Self, r: Self) bool {
        return self.x == r.x and self.y == r.y and self.z == r.z and self.w == r.w;
    }

    pub fn print(self: *const Self) void {
        std.debug.print(
            "{d:.2},{d:.2},{d:.2},{d:.2}\n",
            .{self.x,self.y,self.z,self.w}
        );
    }
};
