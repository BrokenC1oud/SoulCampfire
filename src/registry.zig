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

pub const Registry = struct {
    allocator: Allocator,
    io: Io,

    items: ?std.StringHashMap(ItemDefinition) = null,

    pub fn init(allocator: Allocator, io: Io) @This() {
        return .{
            .allocator = allocator,
            .io = io,
        };
    }

    pub fn load(self: *@This()) !void {
        self.items = .init(self.allocator);

        var dir = try Io.Dir.cwd().openDir(self.io, "assets", .{ .iterate = true });
        defer dir.close(self.io);

        var ns_walker = dir.iterate();

        while (try ns_walker.next(self.io)) |ns| {
            log.debug("loading namespace: {s}", .{ns.name});
            var ns_dir = try dir.openDir(self.io, ns.name, .{ .iterate = true });
            defer ns_dir.close(self.io);

            try self.load_items(ns.name, ns_dir);
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
                try self.items.?.put(item_id, parsed);

                log.debug("loaded item {s}: {any}", .{ item_id, parsed });
            }
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
        self.* = undefined;
    }
};
