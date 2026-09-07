const std = @import("std");
const Allocator = std.mem.Allocator;
const log = std.log.scoped(.registry);

const Value = @import("fridge").Value;

pub const Identifier = struct {
    namespace: []const u8,
    path: []const u8,

    pub fn fromDefaultNamespace(name: []const u8) @This() {
        return .{
            .namespace = "soul_campfire",
            .path = name,
        };
    }

    pub fn fromStr(id: []const u8) @This() {
        const needle = std.mem.indexOf(u8, id, ":").?;
        return .{
            .namespace = id[0..needle],
            .path = id[needle + 1 ..],
        };
    }

    fn hash(self: @This()) u64 {
        var hasher = std.hash.Wyhash.init(0);
        hasher.update(self.namespace);
        hasher.update(":");
        hasher.update(self.path);
        return hasher.final();
    }

    fn eql(self: @This(), other: @This()) bool {
        return std.mem.eql(u8, self.namespace, other.namespace) and std.mem.eql(u8, self.path, other.path);
    }

    pub fn jsonStringify(self: Identifier, stream: anytype) !void {
        try stream.print("\"{s}:{s}\"", .{ self.namespace, self.path });
    }

    pub fn jsonParse(allocator: std.mem.Allocator, source: anytype, _: std.json.ParseOptions) !Identifier {
        const token = try source.next();
        if (token != .string) return error.UnexpectedToken;

        const str = token.string;
        const allocated_str = try allocator.dupe(u8, str);

        return Identifier.fromStr(allocated_str);
    }

    pub fn toValue(self: Identifier, arena: Allocator) Value {
        return .{ .string = std.fmt.allocPrint(arena, "{s}:{s}", .{ self.namespace, self.path }) catch unreachable };
    }

    pub fn fromValue(val: Value, arena: Allocator) !Identifier {
        return Identifier.fromStr(try arena.dupe(u8, val.string));
    }
};

const IdentifierCtx = struct {
    pub fn hash(self: @This(), id: Identifier) u64 {
        _ = self;
        return id.hash();
    }

    pub fn eql(self: @This(), a: Identifier, b: Identifier) bool {
        _ = self;
        return a.eql(b);
    }
};

fn Registry(T: type) type {
    return struct {
        entries: std.HashMap(Identifier, T, IdentifierCtx, 80),

        fn init(allocator: Allocator) @This() {
            return .{
                .entries = .init(allocator),
            };
        }

        fn register(self: *@This(), id: Identifier, entry: T) !void {
            try self.entries.put(id, entry);
        }

        fn deinit(self: *@This()) void {
            self.entries.deinit();
        }
    };
}

const Item = struct {
    name: []const u8,
};

const Level = struct {
    level: usize,
    extensible: bool,
    requirement: usize,
    ratio: f64,
    breakout_rate: usize,

    name: []const u8,
};

const AlchemistAtelierLevel = struct {
    name: []const u8,
    level: usize,
    cost_scale: usize,
    cost_stone: usize,
};

pub const Registries = struct {
    pub var ITEMS: ?Registry(Item) = null;
    pub var LEVELS: ?Registry(Level) = null;
    pub var ALCHEMIST_ATELIER_LEVEL: ?Registry(AlchemistAtelierLevel) = null;

    pub fn init(allocator: Allocator) !void {
        ITEMS = Registry(Item).init(allocator);
        LEVELS = Registry(Level).init(allocator);
        ALCHEMIST_ATELIER_LEVEL = Registry(AlchemistAtelierLevel).init(allocator);
    }

    pub fn deinit() void {
        if (ITEMS) |*sth| {
            sth.deinit();
        }
        if (LEVELS) |*sth| {
            sth.deinit();
        }
        if (ALCHEMIST_ATELIER_LEVEL) |*sth| {
            sth.deinit();
        }
    }

    pub fn getLevelByLevel(level: usize) ?std.HashMap(Identifier, Level, IdentifierCtx, 80).Entry {
        if (LEVELS) |*levels| {
            var iter = levels.entries.iterator();
            return while (iter.next()) |entry| {
                if (entry.value_ptr.level == level) break entry;
            } else null;
        } else {
            return null;
        }
    }

    pub fn getAtelierByLevel(level: usize) ?std.HashMap(Identifier, AlchemistAtelierLevel, IdentifierCtx, 80).Entry {
        if (ALCHEMIST_ATELIER_LEVEL) |*levels| {
            var iter = levels.entries.iterator();
            return while (iter.next()) |entry| {
                if (entry.value_ptr.level == level) break entry;
            } else null;
        } else {
            return null;
        }
    }
};
