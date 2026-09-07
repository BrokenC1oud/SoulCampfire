const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;
const log = std.log.scoped(.db);

const fridge = @import("fridge");

pub const Db = struct {
    io: Io,
    session: fridge.Session,

    pub fn init(allocator: Allocator, io: Io, path: [:0]const u8) !@This() {
        var db: fridge.Session = try .open(fridge.SQLite3, io, allocator, .{ .filename = path });
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

    pub fn registerModel(self: *@This(), allocator: Allocator, comptime T: []const type) !void {
        var arena = std.heap.ArenaAllocator.init(allocator);
        defer arena.deinit();

        var migration: std.ArrayList(u8) = .empty;
        defer migration.deinit(allocator);

        inline for (T) |t| {
            try migration.appendSlice(allocator, "CREATE TABLE ");
            try migration.appendSlice(allocator, getClassName(t));
            try migration.appendSlice(allocator, " (\n");

            var first = true;
            inline for (@typeInfo(t).@"struct".fields) |field| {
                if (!first) try migration.appendSlice(allocator, ",\n");

                if (comptime std.mem.eql(u8, field.name, "id")) {
                    try migration.appendSlice(allocator, "id INTEGER PRIMARY KEY");
                    first = false;
                    continue;
                }

                try migration.appendSlice(allocator, field.name);
                try migration.append(allocator, ' ');
                try migration.appendSlice(allocator, comptime columnType(field.type));

                if (!nullable(field.type)) try migration.appendSlice(allocator, " NOT NULL");

                if (field.default_value_ptr) |default| {
                    const value: field.type = @as(*const field.type, @ptrCast(@alignCast(default))).*;
                    try migration.appendSlice(allocator, " DEFAULT ");
                    try appendDefault(&migration, allocator, arena.allocator(), field.type, value);
                }

                first = false;
            }

            try migration.appendSlice(allocator, ");");
        }

        try fridge.migrate(&self.session, self.io, migration.items);
    }

    fn appendDefault(list: *std.ArrayList(u8), allocator: Allocator, arena: Allocator, comptime T: type, value: T) !void {
        const v = try fridge.Value.from(value, arena);
        switch (v) {
            .null => try list.appendSlice(allocator, "NULL"),
            .int => |i| try list.print(allocator, "{d}", .{i}),
            .float => |f| try list.print(allocator, "{d}", .{f}),
            .string => |s| {
                try list.append(allocator, '\'');
                try appendEscaped(list, allocator, s);
                try list.append(allocator, '\'');
            },
            .blob => |b| {
                try list.appendSlice(allocator, "X'");
                for (b) |byte| try list.print(allocator, "{x:0>2}", .{byte});
                try list.append(allocator, '\'');
            },
        }
    }

    fn appendEscaped(list: *std.ArrayList(u8), allocator: Allocator, s: []const u8) !void {
        for (s) |c| {
            if (c == '\'') try list.append(allocator, '\'');
            try list.append(allocator, c);
        }
    }

    fn columnType(comptime T: type) []const u8 {
        return switch (@typeInfo(T)) {
            .int => |i| if (i.bits > 64) "TEXT" else "INTEGER",
            .float => "REAL",
            .pointer => |p| if (p.child == u8) "TEXT" else @compileError("pointer not supported"),
            .@"struct", .@"enum", .@"union" => "TEXT",
            .optional => |optional| columnType(optional.child),
            else => |e| @compileError(@tagName(e) ++ " unimplemented"),
        };
    }

    inline fn nullable(comptime T: type) bool {
        return switch (@typeInfo(T)) {
            .optional => true,
            else => false,
        };
    }

    fn getClassName(comptime T: type) []const u8 {
        const fullname = @typeName(T);

        if (std.mem.lastIndexOfScalar(u8, fullname, '.')) |idx| {
            return fullname[idx + 1 ..];
        }

        return fullname;
    }
};
