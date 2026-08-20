const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;
const log = std.log.scoped(.game);
const posix = std.posix;

const ecs = @import("zflecs");
const Zenver = @import("zenver").Zenver;

const SoulCampfire = @import("SoulCampfire");

var signal_game: ?*Game = null;

pub const Game = struct {
    allocator: Allocator,
    io: Io,
    env: *Zenver,

    client: SoulCampfire.onebot.Client,
    server: SoulCampfire.onebot.Server,

    event_queue_buffer: []SoulCampfire.GroupMessageEvent,
    event_queue: Io.Queue(SoulCampfire.GroupMessageEvent),

    command_parser: SoulCampfire.command.Command,

    should_exit: bool = false,

    world: ?*ecs.world_t = null,

    random_source: std.Random.IoSource,

    pub fn init(self: *@This(), allocator: Allocator, io: Io, env: *Zenver) !void {
        self.* = undefined;
        self.allocator = allocator;
        self.io = io;
        self.env = env;
        self.should_exit = false;
        self.world = null;

        self.event_queue_buffer = try allocator.alloc(SoulCampfire.GroupMessageEvent, 256);
        errdefer allocator.free(self.event_queue_buffer);
        self.event_queue = .init(self.event_queue_buffer);
        errdefer self.event_queue.close(io);

        self.command_parser = .init(allocator);
        errdefer self.command_parser.deinit();

        self.client = .init(
            allocator,
            io,
            "http://localhost:3000",
            env.getSingleVariable("ONEBOT_TOKEN").?.value,
        );
        errdefer self.client.deinit();

        self.server = try .init(
            allocator,
            io,
            &self.event_queue,
            "127.0.0.1",
            5700,
        );
        errdefer self.server.deinit();

        self.random_source = .{ .io = self.io };
    }

    pub fn deinit(self: *@This()) void {
        if (self.world) |world| {
            _ = ecs.fini(world);
            self.world = null;
        }

        self.client.deinit();
        self.server.deinit();

        self.command_parser.deinit();

        self.event_queue.close(self.io);
        self.allocator.free(self.event_queue_buffer);
        self.* = undefined;
    }

    pub fn start(self: *@This()) !void {
        try self.server.start();

        self.world = ecs.init();

        ecs.set_ctx(self.world.?, self, noFree);

        ecs.set_target_fps(self.world.?, 1);

        ecs.COMPONENT(self.world.?, BasicInfo);
        ecs.COMPONENT(self.world.?, Retreat);

        _ = ecs.ADD_SYSTEM(self.world.?, "event handler system", ecs.OnUpdate, messageEventSystem);

        try self.command_parser.register("检测灵根", inspectSoulCommand);
        try self.command_parser.register("我的灵根", mySoulCommand);

        try self.command_parser.register("闭关修炼", retreatCommand);
        try self.command_parser.register("服用", tookDrugCommand);
        try self.command_parser.register("深度闭关", retreatInDepthCommand);
    }

    pub fn registerSignal(self: *@This()) void {
        signal_game = self;
        var act: posix.Sigaction = .{
            .flags = 0,
            .handler = .{ .handler = posixCtrlHandler },
            .mask = posix.sigemptyset(),
        };
        posix.sigaction(.INT, &act, null);
    }

    pub fn mainLoop(self: *@This()) void {
        var tick: usize = 0;
        while (ecs.progress(self.world.?, 0)) : (tick += 1) {
            log.debug("TICK {} BEGIN", .{tick});

            if (self.should_exit) ecs.quit(self.world.?);
        }
    }

    const BasicInfo = struct {
        user_id: usize,
        cultivation: Cultivation,
        trait: Trait,
        school: School,

        fn random(random_source: *std.Random.IoSource, user_id: usize) @This() {
            const random_interface = random_source.interface();

            return .{
                .user_id = user_id,
                .cultivation = .{ .refining = .{ .level = 1, .minor = 0 } },
                .trait = random_interface.enumValue(Trait),
                .school = .rogue,
            };
        }
    };

    const Cultivation = union(enum) {
        refining: struct { level: usize, minor: usize },

        pub fn modify(self: *@This(), m: isize) void {
            switch (self.*) {
                .refining => |*data| {
                    if (m >= 0) {
                        data.minor += @intCast(m);
                    } else {
                        data.minor += @intCast(-m);
                    }
                },
            }
        }

        pub fn max(self: @This()) usize {
            return switch (self) {
                .refining => 100,
            };
        }

        pub fn level(self: @This()) usize {
            switch (self) {
                inline else => |val| return val.level,
            }
        }

        pub fn minor(self: @This()) usize {
            switch (self) {
                inline else => |val| return val.minor,
            }
        }

        pub fn levelName(self: @This()) []const u8 {
            return switch (self) {
                .refining => "练气",
            };
        }

        pub fn toDisplay(self: @This(), allocator: std.mem.Allocator) []u8 {
            const num_str = SoulCampfire.utils.chineseNumbers[self.level()];
            return std.fmt.allocPrint(allocator, "{s}{s}层", .{ self.levelName(), num_str }) catch unreachable;
        }
    };

    const Trait = enum {
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

    const School = enum {
        star_palace,
        yellow_maple_valley,
        acacia_sect,
        black_demon,
        all_souls_sect,
        supreme_one_sect,
        rogue,

        pub fn toDisplay(self: @This()) []const u8 {
            return switch (self) {
                .star_palace => "星宫",
                .yellow_maple_valley => "黄枫谷",
                .acacia_sect => "合欢宗",
                .black_demon => "黑煞教",
                .all_souls_sect => "万灵宗",
                .supreme_one_sect => "太一宗",
                .rogue => "散修",
            };
        }
    };

    const Retreat = struct {
        endsAt: i96,
        dest: ?struct {
            group_id: usize,
            message_id: isize,
        },
    };

    const RetreatResult = union(enum) {
        success: isize,
        fail: isize,
        deviation: isize,

        fn rollRetreat(random: std.Random) @This() {
            const roll = random.intRangeLessThan(usize, 0, 100);

            return if (roll < 70)
                .{ .success = random.intRangeAtMost(isize, 15, 100) }
            else if (roll < 97)
                .{ .fail = -random.intRangeAtMost(isize, 5, 35) }
            else
                .{ .deviation = -random.intRangeAtMost(isize, 30, 100) };
        }

        fn inner(self: @This()) isize {
            switch (self) {
                inline else => |val| return val,
            }
        }
    };

    fn retreat(world: *ecs.world_t, player: u64, io: Io, random: std.Random) ?RetreatResult {
        const active_retreat = ecs.get(world, player, Retreat);
        if (active_retreat) |r| {
            if (Io.Clock.real.now(io).nanoseconds < r.endsAt) {
                return null;
            }
        }

        const result = RetreatResult.rollRetreat(random);
        return result;
    }

    //--------------------------------
    // SYSTEM
    //--------------------------------

    fn messageEventSystem(it: *ecs.iter_t) void {
        const self: *@This() = @ptrCast(@alignCast(ecs.get_ctx(it.world)));

        var events: [64]SoulCampfire.GroupMessageEvent = undefined;
        const count = self.event_queue.get(self.io, &events, 0) catch return;
        for (events[0..count]) |*event| {
            defer event.deinit();
            log.debug("{s}", .{event.value.raw_message});

            const player_id = std.fmt.allocPrintSentinel(self.allocator, "{}", .{event.value.sender.user_id}, 0) catch unreachable;
            defer self.allocator.free(player_id);
            const player = ecs.lookup(it.world, player_id);

            if (player != 0) {
                const info = ecs.get_mut(it.world, player, BasicInfo);
                if (info) |inner| {
                    inner.cultivation.modify(self.random_source.interface().intRangeAtMost(isize, 0, 5));
                }
            }

            if (std.mem.startsWith(u8, event.value.raw_message, ".")) {
                self.command_parser.execute(event.value.raw_message[1..], event.*, self) catch |err| {
                    log.warn("failed executing command: {t}", .{err});
                };
            }
        }
    }

    //--------------------------------
    // Command
    //--------------------------------
    fn inspectSoulCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
        _ = arguments;

        const new_player_name = std.fmt.allocPrintSentinel(ctx.game.allocator, "{}", .{ctx.event.value.sender.user_id}, 0) catch unreachable;
        defer ctx.game.allocator.free(new_player_name);

        if (ecs.lookup(ctx.game.world.?, new_player_name.ptr) != 0) {
            ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你已经进入修仙世界了！") catch {
                log.warn("failed sending messages", .{});
                return;
            };
            return;
        }

        const player = ecs.new_entity(ctx.game.world.?, new_player_name);
        const new_info = BasicInfo.random(&ctx.game.random_source, ctx.event.value.sender.user_id);
        _ = ecs.set(ctx.game.world.?, player, BasicInfo, new_info);

        const reply_message = std.fmt.allocPrint(ctx.game.allocator, "[CQ:reply,id={}]欢迎踏入仙途，你的灵根是：{s}, 你将从炼气一层开始", .{ ctx.event.value.message_id, new_info.trait.toDisplay() }) catch unreachable;
        defer ctx.game.allocator.free(reply_message);
        _ = ctx.game.client.sendGroupMsg(ctx.event.value.group_id, reply_message, .{}) catch {
            log.warn("failed sending messages", .{});
            return;
        };
    }

    fn mySoulCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
        _ = arguments;

        const player_name = std.fmt.allocPrintSentinel(ctx.game.allocator, "{}", .{ctx.event.value.sender.user_id}, 0) catch unreachable;
        defer ctx.game.allocator.free(player_name);

        const player = ecs.lookup(ctx.game.world.?, player_name.ptr);
        if (player == 0) {
            ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还未加入仙界！") catch {
                log.warn("failed sending message", .{});
                return;
            };
            return;
        }

        const info = ecs.get(ctx.game.world.?, player, BasicInfo);
        if (info == null) {
            ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "请稍后重试") catch {
                log.warn("failed sending message", .{});
                return;
            };
            return;
        }

        const reply_msg = std.fmt.allocPrint(ctx.game.allocator,
            \\{s} 的天命玉牒：
            \\宗门：{s}
            \\灵根：{s}
            \\修为：{}/{}
        , .{
            ctx.event.value.sender.nickname.?,
            info.?.school.toDisplay(),
            info.?.trait.toDisplay(),
            info.?.cultivation.minor(),
            info.?.cultivation.max(),
        }) catch unreachable;
        defer ctx.game.allocator.free(reply_msg);

        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, reply_msg) catch {
            log.warn("failed sending messages", .{});
            return;
        };
    }

    fn retreatCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
        _ = arguments;

        const player_name = std.fmt.allocPrintSentinel(ctx.game.allocator, "{}", .{ctx.event.value.sender.user_id}, 0) catch unreachable;
        defer ctx.game.allocator.free(player_name);

        const player = ecs.lookup(ctx.game.world.?, player_name);
        if (player == 0) {
            ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还未踏上仙途！") catch {
                log.warn("failed sending message", .{});
                return;
            };
        }

        // 检查是否有进行中的修炼
        if (retreat(ctx.game.world.?, player, ctx.game.io, ctx.game.random_source.interface())) |result| {
            const time_took = ctx.game.random_source.interface().intRangeAtMost(usize, 10, 15);
            const r: Retreat = .{
                .endsAt = Io.Clock.real.now(ctx.game.io).nanoseconds + time_took * std.time.ns_per_min,
                .dest = null,
            };
            _ = ecs.set(ctx.game.world.?, player, Retreat, r);

            const info = ecs.get_mut(ctx.game.world.?, player, BasicInfo).?;
            info.cultivation.modify(result.inner());
            const cultivation_level = info.cultivation.toDisplay(ctx.game.allocator);
            defer ctx.game.allocator.free(cultivation_level);

            const reply_message = switch (result) {
                .success => std.fmt.allocPrint(ctx.game.allocator,
                    \\【闭关成功】
                    \\你福至心灵，成功炼化灵气，基础修为增加了{}点。
                    \\本次闭关，你的修为最终增加了{}点。
                    \\
                    \\当前境界：{s}
                    \\当前修为：{}/{}
                    \\
                    \\你感到一阵疲惫，需要打坐休息{}分钟才能再次闭关。
                , .{
                    result.inner(),
                    result.inner(),
                    cultivation_level,
                    info.cultivation.minor(),
                    info.cultivation.max(),
                    time_took,
                }),
                .fail => std.fmt.allocPrint(ctx.game.allocator,
                    \\【闭关失败】
                    \\你心浮气躁，无法凝神，白白浪费了灵气。你的修为减少了{}点。
                    \\
                    \\当前境界：{s}
                    \\当前修为：{}/{}
                    \\
                    \\你感到一阵疲惫，需要打坐休息{}分钟才能再次闭关。
                , .{
                    -result.inner(),
                    cultivation_level,
                    info.cultivation.minor(),
                    info.cultivation.max(),
                    time_took,
                }),
                .deviation => std.fmt.allocPrint(ctx.game.allocator,
                    \\【走火入魔】
                    \\你闭关之时，心魔入侵，道心受损！灵气反噬之下，你的修为倒退了{}点！
                    \\
                    \\当前境界：{s}
                    \\当前修为：{}/{}
                    \\关: 提前结束，但收益会大打折扣 
                    \\你感到一阵疲惫，需要打坐休息{}分钟才能再次闭关。
                , .{
                    -result.inner(),
                    cultivation_level,
                    info.cultivation.minor(),
                    info.cultivation.max(),
                    time_took,
                }),
            } catch unreachable;
            defer ctx.game.allocator.free(reply_message);

            ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, reply_message) catch log.warn("failed sending message", .{});
        } else {
            const active_retreat = ecs.get(ctx.game.world.?, player, Retreat).?;
            const delta = active_retreat.endsAt - Io.Clock.real.now(ctx.game.io).nanoseconds;

            const reply_message = std.fmt.allocPrint(ctx.game.allocator, "修炼还在冷却中！剩余{}h{}min{}s", .{
                @divTrunc(delta, std.time.ns_per_hour),
                @mod(@divTrunc(delta, std.time.ns_per_min), 60),
                @mod(@divTrunc(delta, std.time.ns_per_s), 60),
            }) catch unreachable;
            defer ctx.game.allocator.free(reply_message);

            ctx.game.client.groupReply(
                ctx.event.value.group_id,
                ctx.event.value.message_id,
                reply_message,
            ) catch log.warn("failed sending message", .{});
        }
    }

    fn tookDrugCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
        // TODO
        _ = ctx;
        _ = arguments;
    }

    fn retreatInDepthCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
        _ = ctx;
        _ = arguments;
    }
};

fn posixCtrlHandler(sig: posix.SIG) callconv(.c) void {
    _ = sig;
    if (signal_game) |game| game.should_exit = true;
}

fn noFree(ctx: ?*anyopaque) callconv(.c) void {
    _ = ctx;
}
