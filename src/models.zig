const std = @import("std");
const Allocator = std.mem.Allocator;

const SoulCampfire = @import("SoulCampfire");

pub const Player = struct {
    id: usize,
    cultivation: Cultivation,
    trait: Trait,
    school: ?SchoolRelation,
    stone: usize = 0,
    name: ?[]const u8,
    break_out_bonus: f64 = 0,
    last_breakout: i64 = 0,
    last_stole: i64 = 0,

    pub fn random(random_source: *std.Random.IoSource, registry: *SoulCampfire.registry.Registry, user_id: usize) @This() {
        const random_interface = random_source.interface();

        return .{
            .id = user_id,
            .cultivation = .{ .level_id = registry.getLevelByLevel(0).?.key_ptr.*, .minor = 0, .inner = 100 },
            .trait = random_interface.enumValue(Trait),
            .school = null,
            .name = null,
        };
    }
};

pub const Cultivation = struct {
    level_id: []const u8,
    minor: u2,
    inner: usize,

    pub fn modify(self: *@This(), m: isize) void {
        if (m > 0) {
            self.inner +|= @intCast(m);
        } else {
            self.inner -|= @intCast(-m);
        }
    }

    pub fn toDisplay(self: *@This(), allocator: Allocator, registry: *SoulCampfire.registry.Registry) []const u8 {
        const major = registry.levels.?.get(self.level_id).?;
        const minor = switch (self.minor) {
            0 => "初期",
            1 => "中期",
            2 => "圆满",
            else => @panic("you shouldn't be there"),
        };
        const result = if (major.extensible)
            std.fmt.allocPrint(allocator, "{s}{s}", .{ major.name, minor }) catch unreachable
        else
            std.fmt.allocPrint(allocator, "{s}", .{major.name}) catch unreachable;
        return result;
    }
};

pub const Trait = enum {
    metal,
    wood,
    water,
    fire,
    dust,

    pub fn toDisplay(self: @This()) []const u8 {
        return switch (self) {
            .metal => "金",
            .wood => "木",
            .water => "水",
            .fire => "火",
            .dust => "土",
        };
    }
};

pub const SchoolRelation = struct {
    id: usize,
    role: Role,
    contribution: usize,

    pub const Role = enum(u8) {
        /// 宗主
        owner = 0,
        /// 长老
        elder = 1,
        /// 亲传
        disciple = 2,
        /// 内门
        inner = 3,
        /// 外门
        outer = 4,

        pub fn toDisplay(self: @This()) []const u8 {
            return switch (self) {
                .owner => "宗主",
                .elder => "长老",
                .disciple => "亲传",
                .inner => "内门",
                .outer => "外门",
            };
        }

        pub fn fromStr(str: []const u8) ?@This() {
            return if (std.mem.eql(u8, str, "宗主"))
                .owner
            else if (std.mem.eql(u8, str, "长老"))
                .elder
            else if (std.mem.eql(u8, str, "亲传"))
                .disciple
            else if (std.mem.eql(u8, str, "内门"))
                .inner
            else if (std.mem.eql(u8, str, "外门"))
                .outer
            else
                null;
        }
    };
};

pub const CheckIn = struct {
    id: usize,
    user_id: usize,
    day: u47,
    stone: usize,
};

pub const Retreat = struct {
    id: usize,
    endsAt: i96,
    depth: ?struct {
        group_id: usize,
        message_id: isize,
        startsAt: i96,
    },
};

pub const School = struct {
    id: usize,
    name: []const u8,
    scale: usize = 0,
    stone: usize = 0,
};

pub const InventoryItem = struct {
    id: usize,
    user_id: usize,
    item_id: []const u8,
    count: usize,
};
