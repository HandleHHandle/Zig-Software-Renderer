const std = @import("std");
const Vec4 = @import("vec4.zig").Vec4;

pub const Mat4 = struct {
    const Self = @This();

    values: [16]f32,

    pub fn create() Self {
        // Was this what fixed it?????
        var values = [16]f32 {
            0.0,0.0,0.0,0.0,
            0.0,0.0,0.0,0.0,
            0.0,0.0,0.0,0.0,
            0.0,0.0,0.0,0.0
        };

        return Self {
            .values = values,
        };
    }

    pub fn identity() Self {
        var values = [16]f32 {
            1.0,0.0,0.0,0.0,
            0.0,1.0,0.0,0.0,
            0.0,0.0,1.0,0.0,
            0.0,0.0,0.0,1.0
        };

        return Self {
            .values = values,
        };
    }

    pub fn initScreenSpaceTransform(halfWidth: f32,halfHeight: f32) Self {
        var values = [16]f32 {
            halfWidth, 0.0, 0.0, halfWidth,
            0.0, -halfHeight, 0.0, halfHeight,
            0.0,0.0,1.0,0.0,
            0.0,0.0,0.0,1.0
        };

        return Self {
            .values = values,
        };
    }

    pub fn initTranslation(x: f32,y: f32,z: f32) Self {
        var values = [16]f32 {
            1.0,0.0,0.0,x,
            0.0,1.0,0.0,y,
            0.0,0.0,1.0,z,
            0.0,0.0,0.0,1.0
        };

        return Self {
            .values = values,
        };
    }

    pub fn initRotation(x: f32,y: f32,z: f32) Self {
        var rx = Mat4.create();
        var ry = Mat4.create();
        var rz = Mat4.create();

        rz.set(0,0, std.math.cos(z)); rz.set(0,1, -std.math.sin(z));
        rz.set(1,0, std.math.sin(z)); rz.set(1,1, std.math.cos(z));
        rz.set(2,2, 1.0);
        rz.set(3,3, 1.0);

        rx.set(0,0, 1.0);
        rx.set(1,1, std.math.cos(x)); rx.set(1,2, -std.math.sin(x));
        rx.set(2,1, std.math.sin(x)); rx.set(2,2, std.math.cos(x));
        rx.set(3,3, 1.0);

        ry.set(0,0, std.math.cos(y)); ry.set(0,2, -std.math.sin(y));
        ry.set(1,1, 1.0);
        ry.set(2,0, std.math.sin(y)); ry.set(2,2, std.math.cos(y));
        ry.set(3,3, 1.0);

        var res = rz.mul(ry.mul(rx));

        return res;
    }

    pub fn initScale(x: f32,y: f32,z: f32) Self {
        var values = [16]f32 {
            x,0.0,0.0,0.0,
            0.0,y,0.0,0.0,
            0.0,0.0,z,0.0,
            0.0,0.0,0.0,1.0
        };

        return Self {
            .values = values,
        };
    }

    pub fn initPerspective(fov: f32,aspectRatio: f32,zNear: f32,zFar: f32) Self {
        var tanHalfFOV: f32 = std.math.tan(fov / 2.0);
        var zRange = zNear - zFar;

        var values = [16]f32 {
            1.0 / (tanHalfFOV * aspectRatio), 0.0,0.0,0.0,
            0.0, 1.0 / tanHalfFOV, 0.0,0.0,
            0.0,0.0, (-zNear - zFar) / zRange, 2.0 * zFar * zNear / zRange,
            0.0,0.0,1.0,0.0
        };

        return Self {
            .values = values,
        };
    }

    pub fn transform(self: *const Self, r: Vec4) Vec4 {
        return Vec4.create(
            self.get(0,0) * r.x + self.get(0,1) * r.y + self.get(0,2) * r.z + self.get(0,3) * r.w,
            self.get(1,0) * r.x + self.get(1,1) * r.y + self.get(1,2) * r.z + self.get(1,3) * r.w,
            self.get(2,0) * r.x + self.get(2,1) * r.y + self.get(2,2) * r.z + self.get(2,3) * r.w,
            self.get(3,0) * r.x + self.get(3,1) * r.y + self.get(3,2) * r.z + self.get(3,3) * r.w
        );
    }

    pub fn mul(self: *Self, r: Self) Self {
        var res = Self.create();

        var i: usize = 0;
        while(i < 4) : (i += 1) {
            var j: usize = 0;
            while(j < 4) : (j += 1) {
                res.set(i, j,
                    self.get(i,0) * r.get(0, j) +
                    self.get(i,1) * r.get(1, j) +
		    self.get(i,2) * r.get(2, j) +
		    self.get(i,3) * r.get(3, j));
            }
        }

        return res;
    }

    pub fn get(self: *const Self, x: usize,y: usize) f32 {
        return self.values[x * 4 + y];
    }

    pub fn set(self: *Self, x: usize,y: usize, value: f32) void {
        self.values[x * 4 + y] = value;
    }

    pub fn print(self: *Self) void {
        std.debug.print(
            "{d:.2}, {d:.2}, {d:.2}, {d:.2}\n{d:.2}, {d:.2}, {d:.2}, {d:.2}\n{d:.2}, {d:.2}, {d:.2}, {d:.2}\n{d:.2}, {d:.2}, {d:.2}, {d:.2}\n",
            .{
                self.values[0],self.values[1],self.values[2],self.values[3],
                self.values[4],self.values[5],self.values[6],self.values[7],
                self.values[8],self.values[9],self.values[10],self.values[11],
                self.values[12],self.values[13],self.values[14],self.values[15],
            }
        );
    }
};
