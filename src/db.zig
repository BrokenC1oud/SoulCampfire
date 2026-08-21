const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const fridge = @import("fridge");

pub const Db = struct {
    io: Io,
    session: fridge.Session,

    pub fn init(allocator: Allocator, io: Io, path: [:0]const u8) !@This() {
        var db: fridge.Session = try .open(fridge.SQLite3, allocator, io, .{ .filename = path });
        errdefer db.deinit();

        return .{
            .io = io,
            .session = db,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.session.deinit();
        self.* = undefined;
    }

    pub fn migrate(self: *@This()) !void {
        try fridge.migrate(&self.session, self.io, @embedFile("./migrations/player.sql"));
    }
};
