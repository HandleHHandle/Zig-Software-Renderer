const std = @import("std");
const Vec4 = @import("vec4.zig").Vec4;
const Vertex = @import("vertex.zig").Vertex;

const OBJIndex = struct {
    const Self = @This();

    vertexIndex: u32,
    texcoordIndex: u32,
    normalIndex: u32,

    pub fn equals(self: *const Self, r: Self) bool {
        return (
            self.vertexIndex == r.vertexIndex and
            self.texcoordIndex == r.texcoordIndex and
            self.normalIndex == r.normalIndex
        );
    }
};

fn parseOBJIndex(allocator: std.mem.Allocator, token: []const u8) !OBJIndex {
    var items = std.ArrayList([]const u8).init(allocator);
    defer items.deinit();

    var splits = std.mem.split(u8, token, "/");
    while(splits.next()) |tok| {
        try items.append(tok);
    }

    var res = OBJIndex {
        .vertexIndex = try std.fmt.parseInt(u32, items.items[0], 0) - 1,
        .texcoordIndex = 0,
        .normalIndex = 0,
    };

    if(items.items.len > 1) {
        if(items.items[1].len != 0) {
            res.texcoordIndex = try std.fmt.parseInt(u32, items.items[1], 0) - 1;
        }

        if(items.items.len > 2) {
            res.normalIndex = try std.fmt.parseInt(u32, items.items[2], 0) - 1;
        }
    }

    return res;
}

pub const Mesh = struct {
    const Self = @This();

    vertices: std.ArrayList(Vertex),
    indices: std.ArrayList(u32),

    pub fn create(allocator: std.mem.Allocator, filename: []const u8) !Self {
        var positions = std.ArrayList(Vec4).init(allocator);
        var texcoords = std.ArrayList(Vec4).init(allocator);
        var normals = std.ArrayList(Vec4).init(allocator);
        var indices = std.ArrayList(OBJIndex).init(allocator);

        var file = try std.fs.cwd().openFile(filename, .{});
        defer file.close();

        var bufReader = std.io.bufferedReader(file.reader());
        var inStream = bufReader.reader();
        var buf: [1024]u8 = undefined;
        while(try inStream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
            var tokens = std.ArrayList([]const u8).init(allocator);
            defer tokens.deinit();

            var splits = std.mem.split(u8, line, " ");
            while(splits.next()) |token| {
                if(!std.mem.eql(u8, token, "")) {
                    try tokens.append(token);
                }
            }

            if(tokens.items.len == 0 or std.mem.eql(u8, tokens.items[0], "#")) {
                continue;
            } else if(std.mem.eql(u8, tokens.items[0], "v")) {
                try positions.append(Vec4.create(
                    try std.fmt.parseFloat(f32, tokens.items[1]),
                    try std.fmt.parseFloat(f32, tokens.items[2]),
                    try std.fmt.parseFloat(f32, tokens.items[3][0..tokens.items[3].len-1]),
                    1.0
                ));
            } else if(std.mem.eql(u8, tokens.items[0], "vt")) {
                try texcoords.append(Vec4.create(
                    try std.fmt.parseFloat(f32, tokens.items[1]),
                    try std.fmt.parseFloat(f32, tokens.items[2][0..tokens.items[2].len-1]),
                    0.0,0.0
                ));
            } else if(std.mem.eql(u8, tokens.items[0], "vn")) {
                try normals.append(Vec4.create(
                    try std.fmt.parseFloat(f32, tokens.items[1]),
                    try std.fmt.parseFloat(f32, tokens.items[2]),
                    try std.fmt.parseFloat(f32, tokens.items[3][0..tokens.items[3].len-1]),
                    0.0
                ));
            } else if(std.mem.eql(u8, tokens.items[0], "f")) {
                try indices.appendSlice(&[3]OBJIndex {
                    try parseOBJIndex(allocator, tokens.items[1]),
                    try parseOBJIndex(allocator, tokens.items[2]),
                    try parseOBJIndex(allocator, tokens.items[3][0..tokens.items[3].len-1])
                });
            }
        }

        var mVertices = std.ArrayList(Vertex).init(allocator);
        var mIndices = std.ArrayList(u32).init(allocator);

        var i: usize = 0;
        while(i < indices.items.len) : (i += 1) {
            var currentIndex = indices.items[i];

            var currentPosition = positions.items[currentIndex.vertexIndex];
            var currentTexcoord: Vec4 = Vec4.create(0,0,0,0);
            var currentNormal: Vec4 = Vec4.create(0,0,0,0);

            if(texcoords.items.len > 0) {
                currentTexcoord = texcoords.items[currentIndex.texcoordIndex];
            }
            if(normals.items.len > 0) {
                currentNormal = normals.items[currentIndex.normalIndex];
            }

            try mVertices.append(Vertex.create(
                currentPosition,
                currentTexcoord,
                currentNormal
            ));

            try mIndices.append(@intCast(u32, i));
        }

        i = 0;
        while(i < mVertices.items.len) : (i += 1) {
            mVertices.items[i].texCoords.print();
        }

        positions.deinit();
        texcoords.deinit();
        normals.deinit();
        indices.deinit();

        return Self {
            .vertices = mVertices,
            .indices = mIndices,
        };
    }

    pub fn destroy(self: *Self) void {
        self.vertices.deinit();
        self.indices.deinit();
    }
};
