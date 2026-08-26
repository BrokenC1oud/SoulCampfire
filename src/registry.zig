const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;
const log = std.log.scoped(.registry);
const zon = std.zon;

const ItemKind = enum {
    herb,

    fn fromStr(str: []const u8) @This() {
        return if (std.mem.eql(u8, str, "herb"))
            .herb
        else
            @panic("unknow item kind");
    }
};

const ItemDefinition = struct {
    stackable: bool,

    kind: ?ItemKind = null,
    name: []const u8 = "",
};

const LevelDefinition = struct {
    level: usize,
    extensible: bool,
    requirement: usize,
    ratio: f64,
    breakout_rate: usize,

    name: []const u8 = "",
};

pub const Registry = struct {
    allocator: Allocator,
    io: Io,

    items: ?std.StringHashMap(ItemDefinition) = null,
    levels: ?std.StringHashMap(LevelDefinition) = null,

    pub fn init(allocator: Allocator, io: Io) @This() {
        return .{
            .allocator = allocator,
            .io = io,
        };
    }

    pub fn load(self: *@This()) !void {
        self.items = .init(self.allocator);
        self.levels = .init(self.allocator);

        var dir = try Io.Dir.cwd().openDir(self.io, "assets", .{ .iterate = true });
        defer dir.close(self.io);

        var ns_walker = dir.iterate();

        while (try ns_walker.next(self.io)) |ns| {
            log.debug("loading namespace: {s}", .{ns.name});
            var ns_dir = try dir.openDir(self.io, ns.name, .{ .iterate = true });
            defer ns_dir.close(self.io);

            try self.load_items(ns.name, ns_dir);
            try self.load_levels(ns.name, ns_dir);
        }
    }

    pub fn load_items(self: *@This(), ns: []const u8, ns_dir: Io.Dir) !void {
        var item_dir = try ns_dir.openDir(self.io, "items", .{ .iterate = true });
        defer item_dir.close(self.io);

        var kind_walker = item_dir.iterate();
        while (try kind_walker.next(self.io)) |kind_entry| {
            const kind = ItemKind.fromStr(kind_entry.name);

            var kind_dir = try item_dir.openDir(self.io, kind_entry.name, .{ .iterate = true });
            defer kind_dir.close(self.io);

            var item_walker = kind_dir.iterate();
            while (try item_walker.next(self.io)) |item_entry| {
                const item_buffer = try kind_dir.readFileAllocOptions(self.io, item_entry.name, self.allocator, .unlimited, .@"8", 0);
                defer self.allocator.free(item_buffer);

                var diag: zon.parse.Diagnostics = .{};
                defer diag.deinit(self.allocator);

                var parsed = try zon.parse.fromSliceAlloc(ItemDefinition, self.allocator, item_buffer, &diag, .{ .free_on_error = true });
                errdefer zon.parse.free(self.allocator, parsed);
                parsed.kind = kind;
                parsed.name = try self.allocator.dupe(u8, std.fs.path.stem(item_entry.name));

                const item_id = try std.fmt.allocPrint(self.allocator, "{s}:{s}", .{ ns, std.fs.path.stem(item_entry.name) });
                errdefer self.allocator.free(item_id);
                try self.items.?.put(item_id, parsed);

                log.debug("loaded item {s}", .{item_id});
            }
        }
    }

    pub fn load_levels(self: *@This(), ns: []const u8, ns_dir: Io.Dir) !void {
        var levels_dir = try ns_dir.openDir(self.io, "levels", .{ .iterate = true });
        defer levels_dir.close(self.io);

        var levels_iter = levels_dir.iterate();
        while (try levels_iter.next(self.io)) |level_entry| {
            const level_buffer = try levels_dir.readFileAllocOptions(self.io, level_entry.name, self.allocator, .unlimited, .@"8", 0);
            defer self.allocator.free(level_buffer);

            var diag: zon.parse.Diagnostics = .{};
            defer diag.deinit(self.allocator);

            var parsed = try zon.parse.fromSliceAlloc(LevelDefinition, self.allocator, level_buffer, &diag, .{ .free_on_error = true });
            errdefer zon.parse.free(self.allocator, parsed);

            parsed.name = try self.allocator.dupe(u8, std.fs.path.stem(level_entry.name));

            const level_id = try std.fmt.allocPrint(self.allocator, "{s}:{s}", .{ ns, parsed.name });
            errdefer self.allocator.free(level_id);

            try self.levels.?.put(level_id, parsed);

            log.debug("loaded level: {s}", .{level_id});
        }
    }

    pub fn deinit(self: *@This()) void {
        if (self.items) |*items| {
            var iter = items.iterator();
            while (iter.next()) |entry| {
                self.allocator.free(entry.key_ptr.*);
                zon.parse.free(self.allocator, entry.value_ptr.*);
            }
            items.deinit();
        }
        if (self.levels) |*levels| {
            var iter = levels.iterator();
            while (iter.next()) |entry| {
                self.allocator.free(entry.key_ptr.*);
                zon.parse.free(self.allocator, entry.value_ptr.*);
            }
            levels.deinit();
        }
        self.* = undefined;
    }

    pub fn getLevelByLevel(self: *@This(), level: usize) ?std.StringHashMap(LevelDefinition).Entry {
        var level_iter = self.levels.?.iterator();
        return while (level_iter.next()) |entry| {
            if (entry.value_ptr.level == level) break entry;
        } else null;
    }
};
