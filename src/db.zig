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

    pub fn registerModel(self: *@This(), comptime T: []const type) !void {
        comptime var full_migration: []const u8 = "";
        inline for (T) |t| {
            comptime var migration: []const u8 = "CREATE TABLE " ++ getClassName(t) ++ " (\n";

            comptime var first = true;
            inline for (@typeInfo(t).@"struct".fields) |field| {
                if (!first) migration = migration ++ ",\n";

                if (comptime std.mem.eql(u8, field.name, "id")) {
                    migration = migration ++ "id INTEGER PRIMARY KEY";
                    first = false;
                    continue;
                }

                migration = migration ++ field.name ++ " " ++ comptime columnType(field.type);

                if (!nullable(field.type)) migration = migration ++ " NOT NULL";

                first = false;
            }

            migration = migration ++ ");";

            full_migration = full_migration ++ migration;
        }

        try fridge.migrate(&self.session, self.io, full_migration);
    }

    fn columnType(comptime T: type) []const u8 {
        return switch (@typeInfo(T)) {
            .int => |i| if (i.bits > 64) "TEXT" else "INTEGER",
            .float => "REAL",
            .array => |array| if (array.child == u8) "TEXT" else @compileError("array not yet implemented"),
            .@"struct", .@"enum", .@"union" => "TEXT",
            .optional => |optional| columnType(optional.child),
            else => |e| @compileError(@typeName(e) ++ "unimplemented"),
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
