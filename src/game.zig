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
    random_source: std.Random.IoSource,

    env: *Zenver,

    client: SoulCampfire.onebot.Client,
    server: SoulCampfire.onebot.Server,

    event_queue_buffer: []SoulCampfire.GroupMessageEvent,
    event_queue: Io.Queue(SoulCampfire.GroupMessageEvent),

    command_parser: SoulCampfire.command.Command,

    should_exit: bool = false,

    world: ?*ecs.world_t = null,

    db: SoulCampfire.db.Db,

    registry: SoulCampfire.registry.Registry,

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

        self.db = try .init(self.allocator, self.io, "soul_campfire.db");
        errdefer self.db.deinit();

        self.registry = .init(self.allocator, self.io);
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

        self.db.deinit();
        self.registry.deinit();

        self.* = undefined;
    }

    pub fn start(self: *@This()) !void {
        try self.db.registerModel(&.{ Player, CheckIn, Retreat, School, InventoryItem });

        try self.registry.load();

        try self.server.start();

        self.world = ecs.init();

        ecs.set_ctx(self.world.?, self, noFree);

        ecs.set_target_fps(self.world.?, 1);

        ecs.COMPONENT(self.world.?, Player);
        ecs.COMPONENT(self.world.?, Retreat);

        ecs.COMPONENT(self.world.?, School);

        try self.loadData();

        _ = ecs.ADD_SYSTEM(self.world.?, "event handler system", ecs.OnUpdate, messageEventSystem);
        _ = ecs.ADD_SYSTEM(self.world.?, "retreat in depth system", ecs.OnUpdate, depthRetreatSystem);

        _ = ecs.ADD_SYSTEM(self.world.?, "save system", ecs.OnStore, saveSystem);

        try self.command_parser.register("检测灵根", inspectSoulCommand);
        try self.command_parser.register("我的灵根", mySoulCommand);
        try self.command_parser.register("修仙排行榜", rankCommand);
        try self.command_parser.register("改名", changeNameCommand);
        try self.command_parser.register("突破", breakOutCommand);
        try self.command_parser.register("直接突破", directBreakOutCommand);

        try self.command_parser.register("修仙签到", checkInCommand);
        try self.command_parser.register("闭关修炼", retreatCommand);
        try self.command_parser.register("服用", tookDrugCommand);
        try self.command_parser.register("深度闭关", retreatInDepthCommand);
        try self.command_parser.register("查看闭关", queryRetreatInDepthCommand);
        try self.command_parser.register("强行出关", quitRetreatInDepthCommand);
        try self.command_parser.register("避世", quitWorldCommand);
        try self.command_parser.register("入世", joinWorldCommand);

        try self.command_parser.register("拜入宗门", joinSchoolCommand);
        try self.command_parser.register("我的宗门", mySchoolCommand);

        try self.command_parser.register("我的背包", myBackpackCommand);
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

    const Player = struct {
        id: usize,
        cultivation: Cultivation,
        trait: Trait,
        school: ?SchoolRelation,
        stone: usize = 0,
        name: ?[]const u8,
        break_out_bonus: f64 = 0,
        last_breakout: i64 = 0,

        fn random(random_source: *std.Random.IoSource, registry: *SoulCampfire.registry.Registry, user_id: usize) @This() {
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

    const Cultivation = struct {
        level_id: []const u8,
        minor: u2,
        inner: usize,

        fn modify(self: *@This(), m: isize) void {
            if (m > 0) {
                self.inner +|= @intCast(m);
            } else {
                self.inner -|= @intCast(-m);
            }
        }

        fn toDisplay(self: *@This(), allocator: Allocator, registry: *SoulCampfire.registry.Registry) []const u8 {
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

    const SchoolRelation = struct {
        id: usize,
        role: enum {
            /// 宗主
            owner,
            /// 长老
            elder,
            /// 亲传
            disciple,
            /// 内门
            inner,
            /// 外门
            outer,

            fn toDisplay(self: @This()) []const u8 {
                return switch (self) {
                    .owner => "宗主",
                    .elder => "长老",
                    .disciple => "亲传",
                    .inner => "内门",
                    .outer => "外门",
                };
            }
        },
        contribution: usize,
    };

    const Retreat = struct {
        id: usize,
        endsAt: i96,
        depth: ?struct {
            group_id: usize,
            message_id: isize,
            startsAt: i96,
        },
    };

    const RetreatResult = union(enum(u8)) {
        success: isize = 0,
        fail: isize = 1,
        deviation: isize = 2,

        fn rollRetreat(random: std.Random) @This() {
            const roll = random.intRangeLessThan(usize, 0, 100);

            return if (roll < 70)
                .{ .success = random.intRangeAtMost(isize, 300, 500) }
            else if (roll < 97)
                .{ .fail = -random.intRangeAtMost(isize, 75, 200) }
            else
                .{ .deviation = -random.intRangeAtMost(isize, 100, 400) };
        }

        fn inner(self: @This()) isize {
            switch (self) {
                inline else => |val| return val,
            }
        }
    };

    const School = struct {
        id: usize,
        name: []const u8,
        scale: usize,
        stone: usize,
    };

    const InventoryItem = struct {
        id: usize,
        user_id: usize,
        item_id: []const u8,
        count: usize,
    };

    const CheckIn = struct {
        id: usize,
        user_id: usize,
        day: u47,
        stone: usize,
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

    fn getPlayer(allocator: Allocator, world: *ecs.world_t, user_id: usize) u64 {
        const player_name = std.fmt.allocPrintSentinel(allocator, "Player_{}", .{user_id}, 0) catch unreachable;
        defer allocator.free(player_name);

        const player = ecs.lookup(world, player_name);
        return player;
    }

    fn getPlayerSchool(allocator: Allocator, world: *ecs.world_t, school_rel: SchoolRelation) *const School {
        const school_name = std.fmt.allocPrintSentinel(allocator, "School_{}", .{school_rel.id}, 0) catch unreachable;
        defer allocator.free(school_name);

        const school_entity = ecs.lookup(world, school_name);
        const school = ecs.get(world, school_entity, School).?;

        return school;
    }

    fn loadData(self: *@This()) !void {
        const players = try self.db.session.query(Player).findAll();
        for (players) |player| {
            const new_entity_name = std.fmt.allocPrintSentinel(self.allocator, "Player_{}", .{player.id}, 0) catch unreachable;
            defer self.allocator.free(new_entity_name);

            const entity = ecs.new_entity(self.world.?, new_entity_name);

            _ = ecs.set(self.world.?, entity, Player, player);

            if (try self.db.session.find(Retreat, player.id)) |r| {
                _ = ecs.set(self.world.?, entity, Retreat, r);
            }
        }

        const schools = try self.db.session.query(School).findAll();
        for (schools) |school| {
            const new_entity_name = std.fmt.allocPrintSentinel(self.allocator, "School_{}", .{school.id}, 0) catch unreachable;
            defer self.allocator.free(new_entity_name);

            const entity = ecs.new_entity(self.world.?, new_entity_name);

            _ = ecs.set(self.world.?, entity, School, school);
        }
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

            const player = getPlayer(self.allocator, it.world, event.value.sender.user_id);

            if (player != 0) {
                const info = ecs.get_mut(it.world, player, Player);
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

    fn depthRetreatSystem(it: *ecs.iter_t, retreats: []const Retreat) void {
        const self: *@This() = @ptrCast(@alignCast(ecs.get_ctx(it.world)));

        for (it.entities(), retreats) |entity, r| {
            if (r.depth) |d| {
                if (Io.Clock.real.now(self.io).nanoseconds > r.endsAt) {
                    const now: f128 = @floatFromInt(Io.Clock.real.now(self.io).nanoseconds - d.startsAt);
                    const ns_per_hour: f128 = @floatFromInt(std.time.ns_per_hour);
                    const time_consumed: f64 = @floatCast(now / ns_per_hour);

                    var i: usize = 0;
                    var result = [3]u8{ 0, 0, 0 };
                    var sum: isize = 0;
                    const rolls: usize = @intFromFloat(@trunc(time_consumed * 4.0));
                    while (i < rolls) : (i += 1) {
                        const r_r = retreat(it.world, entity, self.io, self.random_source.interface()).?;
                        result[@intFromEnum(r_r)] += 1;
                        sum += r_r.inner();
                    }

                    const interrupted = time_consumed < 7.5;
                    if (interrupted) sum = @divTrunc(sum * 4, 5);

                    var message: std.Io.Writer.Allocating = .init(self.allocator);
                    defer message.deinit();

                    message.writer.print(
                        \\【深度闭关总结】
                        \\本次结算时长：{d:.1} (上限8小时)
                        \\
                        \\- 修行有成：{}次
                        \\- 心神不宁：{}次
                        \\- 走火入魔：{}次
                        \\
                        \\本次深度闭关，你的修为最终变化了{}点！
                        \\
                    , .{ time_consumed, result[0], result[1], result[2], sum }) catch unreachable;

                    if (interrupted) message.writer.print(
                        \\【强行出关惩罚】：因为你强行中断修行，所得感悟流失大半，所幸天道垂怜修为变化为{}
                    , .{sum}) catch unreachable;
                    message.writer.flush() catch unreachable;

                    self.client.groupReply(d.group_id, d.message_id, message.written()) catch log.warn("failed sending message", .{});

                    _ = ecs.set(it.world, entity, Retreat, .{ .id = r.id, .endsAt = Io.Clock.real.now(self.io).nanoseconds + 22 * std.time.ns_per_hour, .depth = null });
                }
            }
        }
    }

    fn saveSystem(it: *ecs.iter_t) void {
        const self: *@This() = @ptrCast(@alignCast(ecs.get_ctx(it.world)));

        var players = ecs.each(it.world, Player);
        while (ecs.each_next(&players)) {
            for (players.entities()) |entity| {
                const user_id = ecs.get(it.world, entity, Player).?.id;

                const info_persisted = self.db.session.query(Player).where("id", user_id).findOne() catch {
                    log.warn("db error", .{});
                    continue;
                };
                const info_mem = ecs.get(it.world, entity, Player).?;
                if (info_persisted == null or !std.meta.eql(info_persisted.?, info_mem.*)) {
                    if (info_persisted) |_| {
                        self.db.session.update(Player, user_id, info_mem.*) catch log.warn("db error", .{});
                    } else {
                        _ = self.db.session.insert(Player, info_mem.*) catch log.warn("db error", .{});
                    }
                }

                const retreat_persisted = self.db.session.query(Retreat).where("id", user_id).findOne() catch {
                    log.warn("db error", .{});
                    continue;
                };
                const retreat_mem = ecs.get(it.world, entity, Retreat);
                if (retreat_mem) |r| {
                    if (retreat_persisted == null or !std.meta.eql(retreat_persisted.?, r.*)) {
                        if (retreat_persisted) |r_p| {
                            self.db.session.update(Retreat, r_p.id, r.*) catch log.warn("db error", .{});
                        } else {
                            _ = self.db.session.insert(Retreat, r.*) catch log.warn("db error", .{});
                        }
                    }
                }
            }
        }

        var schools = ecs.each(it.world, School);
        while (ecs.each_next(&schools)) {
            for (schools.entities()) |entity| {
                const school_mem = ecs.get(self.world.?, entity, School).?;
                const school_persisted = self.db.session.find(School, school_mem.id) catch {
                    log.warn("db error", .{});
                    continue;
                };

                if (school_persisted == null or !std.meta.eql(school_mem.*, school_persisted.?)) {
                    if (school_persisted) |p| {
                        self.db.session.update(School, p.id, school_mem.*) catch log.warn("db error", .{});
                    } else {
                        _ = self.db.session.insert(School, school_mem.*) catch log.warn("db error", .{});
                    }
                }
            }
        }
    }

    //--------------------------------
    // Command
    //--------------------------------
    fn inspectSoulCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
        _ = arguments;

        const new_player_name = std.fmt.allocPrintSentinel(ctx.game.allocator, "Player_{}", .{ctx.event.value.sender.user_id}, 0) catch unreachable;
        defer ctx.game.allocator.free(new_player_name);

        if (ecs.lookup(ctx.game.world.?, new_player_name.ptr) != 0) {
            ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你已经进入修仙世界了！") catch {
                log.warn("failed sending messages", .{});
                return;
            };
            return;
        }

        const player = ecs.new_entity(ctx.game.world.?, new_player_name);
        const new_info = Player.random(&ctx.game.random_source, &ctx.game.registry, ctx.event.value.sender.user_id);
        _ = ecs.set(ctx.game.world.?, player, Player, new_info);

        const reply_message = std.fmt.allocPrint(ctx.game.allocator, "[CQ:reply,id={}]欢迎踏入仙途，你的灵根是：{s}, 你将从炼气一层开始", .{ ctx.event.value.message_id, new_info.trait.toDisplay() }) catch unreachable;
        defer ctx.game.allocator.free(reply_message);
        _ = ctx.game.client.sendGroupMsg(ctx.event.value.group_id, reply_message, .{}) catch {
            log.warn("failed sending messages", .{});
            return;
        };
    }

    fn mySoulCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
        _ = arguments;

        const player = getPlayer(ctx.game.allocator, ctx.game.world.?, ctx.event.value.sender.user_id);
        if (player == 0) {
            ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还未加入仙界！") catch {
                log.warn("failed sending message", .{});
                return;
            };
            return;
        }

        const info = ecs.get(ctx.game.world.?, player, Player);
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
            \\修为：{}
            \\灵石：{}
        , .{
            if (info.?.name) |na| na else ctx.event.value.sender.nickname.?,
            if (info.?.school) |school| getPlayerSchool(ctx.game.allocator, ctx.game.world.?, school).name else "散修",
            info.?.trait.toDisplay(),
            info.?.cultivation.inner,
            info.?.stone,
        }) catch unreachable;
        defer ctx.game.allocator.free(reply_msg);

        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, reply_msg) catch {
            log.warn("failed sending messages", .{});
            return;
        };
    }

    fn checkInCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
        _ = arguments;

        const player_entity = getPlayer(ctx.game.allocator, ctx.game.world.?, ctx.event.value.sender.user_id);
        if (player_entity == 0) {
            _ = ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还未踏上仙途！") catch log.warn("failed sending message", .{});
            return;
        }

        const now = Io.Clock.real.now(ctx.game.io).toSeconds();
        const epoch: std.time.epoch.EpochSeconds = .{ .secs = @intCast(now) };
        const epoch_day = epoch.getEpochDay();

        const check_in_his = ctx.game.db.session.query(CheckIn).where("user_id", ctx.event.value.sender.user_id).where("day", epoch_day.day).findOne() catch {
            log.warn("db error", .{});
            return;
        };

        if (check_in_his) |history| {
            const msg = std.fmt.allocPrint(ctx.game.allocator, "你今天已经签到过了 获得了{}灵石", .{history.stone}) catch unreachable;
            defer ctx.game.allocator.free(msg);

            ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, msg) catch log.warn("failed sending message", .{});
        } else {
            const check_id = ctx.game.db.session.insert(CheckIn, .{
                .user_id = ctx.event.value.sender.user_id,
                .day = epoch_day.day,
                .stone = ctx.game.random_source.interface().intRangeAtMost(usize, 200000, 500000),
            }) catch {
                log.warn("db error", .{});
                return;
            };
            const check = ctx.game.db.session.find(CheckIn, check_id) catch {
                log.warn("db error", .{});
                return;
            } orelse unreachable;

            const player = ecs.get_mut(ctx.game.world.?, player_entity, Player).?;
            player.stone += check.stone;

            const msg = std.fmt.allocPrint(ctx.game.allocator, "签到成功，获得了{}块灵石", .{check.stone}) catch unreachable;
            defer ctx.game.allocator.free(msg);

            ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, msg) catch log.warn("failed sending message", .{});
        }
    }

    fn retreatCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
        _ = arguments;

        const player = getPlayer(ctx.game.allocator, ctx.game.world.?, ctx.event.value.sender.user_id);
        if (player == 0) {
            ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还未踏上仙途！") catch {
                log.warn("failed sending message", .{});
                return;
            };
            return;
        }

        if (retreat(ctx.game.world.?, player, ctx.game.io, ctx.game.random_source.interface())) |result| {
            const time_took = ctx.game.random_source.interface().intRangeAtMost(usize, 10, 15);
            const r: Retreat = .{
                .id = ctx.event.value.sender.user_id,
                .endsAt = Io.Clock.real.now(ctx.game.io).nanoseconds + time_took * std.time.ns_per_min,
                .depth = null,
            };
            _ = ecs.set(ctx.game.world.?, player, Retreat, r);

            const info = ecs.get_mut(ctx.game.world.?, player, Player).?;
            info.cultivation.modify(result.inner());
            const cultivation_level = info.cultivation.toDisplay(ctx.game.allocator, &ctx.game.registry);
            defer ctx.game.allocator.free(cultivation_level);

            const reply_message = switch (result) {
                .success => std.fmt.allocPrint(ctx.game.allocator,
                    \\【闭关成功】
                    \\你福至心灵，成功炼化灵气，基础修为增加了{}点。
                    \\本次闭关，你的修为最终增加了{}点。
                    \\
                    \\当前境界：{s}
                    \\当前修为：{}
                    \\
                    \\你感到一阵疲惫，需要打坐休息{}分钟才能再次闭关。
                , .{
                    result.inner(),
                    result.inner(),
                    cultivation_level,
                    info.cultivation.inner,
                    time_took,
                }),
                .fail => std.fmt.allocPrint(ctx.game.allocator,
                    \\【闭关失败】
                    \\你心浮气躁，无法凝神，白白浪费了灵气。你的修为减少了{}点。
                    \\
                    \\当前境界：{s}
                    \\当前修为：{}
                    \\
                    \\你感到一阵疲惫，需要打坐休息{}分钟才能再次闭关。
                , .{
                    -result.inner(),
                    cultivation_level,
                    info.cultivation.inner,
                    time_took,
                }),
                .deviation => std.fmt.allocPrint(ctx.game.allocator,
                    \\【走火入魔】
                    \\你闭关之时，心魔入侵，道心受损！灵气反噬之下，你的修为倒退了{}点！
                    \\
                    \\当前境界：{s}
                    \\当前修为：{}
                    \\关: 提前结束，但收益会大打折扣 
                    \\你感到一阵疲惫，需要打坐休息{}分钟才能再次闭关。
                , .{
                    -result.inner(),
                    cultivation_level,
                    info.cultivation.inner,
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
        _ = arguments;

        const player = getPlayer(ctx.game.allocator, ctx.game.world.?, ctx.event.value.sender.user_id);

        if (player == 0) {
            ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还未踏上仙途！") catch {
                log.warn("failed sending message", .{});
                return;
            };
            return;
        }

        _ = retreat(ctx.game.world.?, player, ctx.game.io, ctx.game.random_source.interface()) orelse {
            const active_retreat = ecs.get(ctx.game.world.?, player, Retreat).?;
            const delta = active_retreat.endsAt - Io.Clock.real.now(ctx.game.io).nanoseconds;

            if (active_retreat.depth == null) {
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
            } else {
                ctx.game.client.groupReply(
                    ctx.event.value.group_id,
                    ctx.event.value.message_id,
                    "你已在深度闭关之中",
                ) catch log.warn("failed sending message", .{});
            }

            return;
        };

        _ = ecs.set(ctx.game.world.?, player, Retreat, .{
            .id = ctx.event.value.sender.user_id,
            .endsAt = Io.Clock.real.now(ctx.game.io).nanoseconds + 8 * std.time.ns_per_hour,
            .depth = .{
                .group_id = ctx.event.value.group_id,
                .message_id = ctx.event.value.message_id,
                .startsAt = Io.Clock.real.now(ctx.game.io).nanoseconds,
            },
        });

        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id,
            \\你已进入深度闭关状态，神魂将自行吐纳8小时。
            \\期间你将无法进行大部分操作。到时将自动结算收获。
        ) catch log.warn("failed sending messages", .{});
    }

    fn queryRetreatInDepthCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
        _ = arguments;

        const player = getPlayer(ctx.game.allocator, ctx.game.world.?, ctx.event.value.sender.user_id);

        if (player == 0) {
            ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还未踏上仙途！") catch {
                log.warn("failed sending message", .{});
                return;
            };
            return;
        }

        const active_retreat = ecs.get(ctx.game.world.?, player, Retreat);
        if (active_retreat == null or active_retreat.?.depth == null) {
            ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你并未处于深度闭关之中") catch {
                log.warn("failed sending message", .{});
                return;
            };
            return;
        }

        const delta = active_retreat.?.endsAt - Io.Clock.real.now(ctx.game.io).nanoseconds;
        const message = std.fmt.allocPrint(ctx.game.allocator, "你正在深度闭关，预计需要{}小时{}分钟{}秒即可功成圆满。", .{
            @divTrunc(delta, std.time.ns_per_hour),
            @mod(@divTrunc(delta, std.time.ns_per_min), 60),
            @mod(@divTrunc(delta, std.time.ns_per_s), 60),
        }) catch unreachable;
        defer ctx.game.allocator.free(message);

        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, message) catch log.warn("failed sending message", .{});
    }

    fn quitRetreatInDepthCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
        _ = arguments;

        const player = getPlayer(ctx.game.allocator, ctx.game.world.?, ctx.event.value.sender.user_id);

        if (player == 0) {
            ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还未踏上仙途！") catch {
                log.warn("failed sending message", .{});
                return;
            };
            return;
        }

        const active_retreat = ecs.get_mut(ctx.game.world.?, player, Retreat);
        if (active_retreat == null or active_retreat.?.depth == null) {
            ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你并未处于深度闭关之中") catch {
                log.warn("failed sending message", .{});
                return;
            };
            return;
        }

        active_retreat.?.endsAt = Io.Clock.real.now(ctx.game.io).nanoseconds;

        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你强行中断了修炼，正在进行结算") catch log.warn("failed sending message", .{});
    }

    fn quitWorldCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
        _ = ctx;
        _ = arguments;
    }

    fn joinWorldCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
        _ = ctx;
        _ = arguments;
    }

    fn joinSchoolCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
        const player_entity = getPlayer(ctx.game.allocator, ctx.game.world.?, ctx.event.value.sender.user_id);
        if (player_entity == 0) {
            _ = ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还未踏上仙途！") catch log.warn("failed sending message", .{});
            return;
        }

        const player = ecs.get_mut(ctx.game.world.?, player_entity, Player).?;
        if (player.school) |_| {
            ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你已经加入了其他宗门，叛出已有宗门才能加入新的宗门！") catch log.warn("failed sending message", .{});
            return;
        }

        if (arguments.len < 1) {
            ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "叽里咕噜说什么呢") catch log.warn("failed sending message", .{});
            return;
        }

        const school = ctx.game.db.session.query(School).where("name", arguments[0]).findOne() catch {
            log.warn("db error", .{});
            return;
        };

        if (school) |s| {
            player.school = .{ .id = s.id, .role = .outer, .contribution = 0 };

            const msg = std.fmt.allocPrint(ctx.game.allocator, "欢迎师弟加入了宗门【{s}】，共参天道。", .{s.name}) catch unreachable;
            defer ctx.game.allocator.free(msg);

            ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, msg) catch log.warn("failed sending message", .{});
            return;
        } else {
            const msg = std.fmt.allocPrint(ctx.game.allocator, "你要加入的宗门【{s}】不存在", .{arguments[0]}) catch unreachable;
            defer ctx.game.allocator.free(msg);

            ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, msg) catch log.warn("failed sending message", .{});
            return;
        }
    }

    fn mySchoolCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
        _ = arguments;

        const player_entity = getPlayer(ctx.game.allocator, ctx.game.world.?, ctx.event.value.sender.user_id);
        if (player_entity == 0) {
            _ = ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还未踏上仙途！") catch log.warn("failed sending message", .{});
            return;
        }

        const player = ecs.get(ctx.game.world.?, player_entity, Player).?;
        if (player.school) |school_r| {
            const school = getPlayerSchool(ctx.game.allocator, ctx.game.world.?, school_r);

            const school_rank = ctx.game.db.session.raw(
                \\WITH RankedSchool AS (
                \\    SELECT
                \\        id,
                \\        scale,
                \\        row_number() over (ORDER BY scale) AS rank_num
                \\    FROM School
                \\)
                \\SELECT rank_num
                \\FROM RankedSchool
                \\WHERE id = ?
            , .{school.id}).get(usize) catch {
                log.warn("db error", .{});
                return;
            };

            const msg = std.fmt.allocPrint(ctx.game.allocator,
                \\你所在的宗门：
                \\宗门名讳：{s}
                \\道友职位：{s}
                \\宗门建设度：{}
                \\宗门排名：{}
            , .{ school.name, school_r.role.toDisplay(), school.scale, school_rank.? }) catch unreachable;
            defer ctx.game.allocator.free(msg);

            ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, msg) catch log.warn("failed sending message", .{});
        } else {
            ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "一介散修，莫要再问") catch log.warn("failed sending message", .{});
        }
    }

    fn myBackpackCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
        _ = arguments;

        const player_entity = getPlayer(ctx.game.allocator, ctx.game.world.?, ctx.event.value.sender.user_id);
        if (player_entity == 0) {
            _ = ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还未踏上仙途！") catch log.warn("failed sending message", .{});
            return;
        }

        const items = ctx.game.db.session.query(InventoryItem).where("user_id", ctx.event.value.sender.user_id).findAll() catch {
            log.warn("db error", .{});
            return;
        };

        var msg: Io.Writer.Allocating = .init(ctx.game.allocator);
        defer msg.deinit();

        if (items.len > 0) {
            msg.writer.print("你的背包：\n", .{}) catch unreachable;
            for (items) |inv_item| {
                const item = ctx.game.registry.items.?.get(inv_item.item_id).?;
                msg.writer.print("{s} * {}\n", .{ item.name, inv_item.count }) catch unreachable;
            }
        } else {
            msg.writer.print("道友的背包空空如也！", .{}) catch unreachable;
        }

        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, msg.written()) catch log.warn("failed sending message", .{});
    }

    fn rankCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
        _ = arguments;

        const RankEntry = struct {
            player: Player,
            level: usize,

            fn lessThan(_: void, lhs: @This(), rhs: @This()) bool {
                if (lhs.level != rhs.level) return lhs.level > rhs.level;
                if (lhs.player.cultivation.inner != rhs.player.cultivation.inner) {
                    return lhs.player.cultivation.inner > rhs.player.cultivation.inner;
                }
                return lhs.player.id < rhs.player.id;
            }
        };

        var entries = std.ArrayList(RankEntry).initCapacity(ctx.game.allocator, 0) catch unreachable;
        defer entries.deinit(ctx.game.allocator);

        var players = ecs.each(ctx.game.world.?, Player);
        while (ecs.each_next(&players)) {
            for (players.entities()) |entity| {
                const player = ecs.get(ctx.game.world.?, entity, Player).?;
                const level = ctx.game.registry.levels.?.get(player.cultivation.level_id) orelse continue;
                entries.append(ctx.game.allocator, .{
                    .player = player.*,
                    .level = level.level,
                }) catch unreachable;
            }
        }

        std.sort.block(RankEntry, entries.items, void{}, RankEntry.lessThan);

        var message: Io.Writer.Allocating = .init(ctx.game.allocator);
        defer message.deinit();

        message.writer.print("【修仙排行榜】\n", .{}) catch unreachable;
        const count = @min(entries.items.len, 10);
        for (entries.items[0..count], 0..) |entry, index| {
            const level = ctx.game.registry.levels.?.get(entry.player.cultivation.level_id).?;
            const user_id = std.fmt.allocPrint(ctx.game.allocator, "{}", .{entry.player.id}) catch unreachable;
            defer ctx.game.allocator.free(user_id);

            message.writer.print("{}. {s} {s} 修为：{}\n", .{
                index + 1,
                if (entry.player.name) |na| na else user_id,
                level.name,
                entry.player.cultivation.inner,
            }) catch unreachable;
        }

        if (count == 0) message.writer.print("暂无修士上榜\n", .{}) catch unreachable;

        ctx.game.client.groupReply(
            ctx.event.value.group_id,
            ctx.event.value.message_id,
            message.written(),
        ) catch log.warn("failed sending messages", .{});
    }

    fn changeNameCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
        const player_entity = getPlayer(ctx.game.allocator, ctx.game.world.?, ctx.event.value.sender.user_id);
        if (player_entity == 0) {
            _ = ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还未踏上仙途！") catch log.warn("failed sending message", .{});
            return;
        }

        if (arguments.len < 1 or arguments[0].len == 0) {
            ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "叽里咕噜说什么呢") catch log.warn("failed sending message", .{});
            return;
        }

        const player = ecs.get_mut(ctx.game.world.?, player_entity, Player).?;
        player.name = ctx.game.db.session.arena.dupe(u8, arguments[0]) catch {
            log.warn("db error", .{});
            return;
        };

        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "改名成功!") catch log.warn("failed sending message", .{});
    }

    fn breakOutCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
        _ = arguments;

        const player_entity = getPlayer(ctx.game.allocator, ctx.game.world.?, ctx.event.value.sender.user_id);
        if (player_entity == 0) {
            _ = ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还未踏上仙途！") catch log.warn("failed sending message", .{});
            return;
        }

        const player = ecs.get(ctx.game.world.?, player_entity, Player).?;
        const level = ctx.game.registry.levels.?.get(player.cultivation.level_id).?;
        const next_level = if (level.extensible) switch (player.cultivation.minor) {
            0, 1 => level,
            2 => if (ctx.game.registry.getLevelByLevel(level.level + 1)) |ne| ne.value_ptr.* else {
                ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你已经到达了最高境界，无法继续突破") catch log.warn("failed sending message", .{});
                return;
            },
            else => @panic("how did you get there"),
        } else if (ctx.game.registry.getLevelByLevel(level.level + 1)) |ne| ne.value_ptr.* else {
            ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你已经到达了最高境界，无法继续突破") catch log.warn("failed sending message", .{});
            return;
        };
        if (player.cultivation.inner < next_level.requirement) {
            ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你的修为还没有达到下一境界的要求，继续修炼") catch log.warn("failed sending message", .{});
            return;
        }
        if (Io.Clock.real.now(ctx.game.io).toSeconds() - player.last_breakout < std.time.s_per_hour) {
            ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你的突破还在冷却中，请稍候") catch log.warn("failed sending message", .{});
            return;
        }
        // TODO: 背包物品特殊加成
        const breakout_bonus: usize = @intFromFloat(player.break_out_bonus * 100);
        const success_rate = level.breakout_rate + breakout_bonus;

        const msg = std.fmt.allocPrint(ctx.game.allocator, "你当前突破到 {s} 境界的概率为{}%，输入`.直接突破`进行突破", .{ next_level.name, success_rate }) catch unreachable;
        defer ctx.game.allocator.free(msg);

        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, msg) catch log.warn("failed sending message", .{});
    }

    fn directBreakOutCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
        _ = arguments;

        const player_entity = getPlayer(ctx.game.allocator, ctx.game.world.?, ctx.event.value.sender.user_id);
        if (player_entity == 0) {
            _ = ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还未踏上仙途！") catch log.warn("failed sending message", .{});
            return;
        }

        const player = ecs.get_mut(ctx.game.world.?, player_entity, Player).?;
        const level = ctx.game.registry.levels.?.get(player.cultivation.level_id).?;
        const next_level = if (level.extensible) switch (player.cultivation.minor) {
            0, 1 => level,
            2 => if (ctx.game.registry.getLevelByLevel(level.level + 1)) |ne| ne.value_ptr.* else {
                ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你已经到达了最高境界，无法继续突破") catch log.warn("failed sending message", .{});
                return;
            },
            else => @panic("how did you get there"),
        } else if (ctx.game.registry.getLevelByLevel(level.level + 1)) |ne| ne.value_ptr.* else {
            ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你已经到达了最高境界，无法继续突破") catch log.warn("failed sending message", .{});
            return;
        };

        if (player.cultivation.inner < next_level.requirement) {
            ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你的修为还没有达到下一境界的要求，继续修炼") catch log.warn("failed sending message", .{});
            return;
        }
        if (Io.Clock.real.now(ctx.game.io).toSeconds() - player.last_breakout < std.time.s_per_hour) {
            ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你的突破还在冷却中，请稍候") catch log.warn("failed sending message", .{});
            return;
        }
        // TODO: 背包物品特殊加成
        const breakout_bonus: usize = @intFromFloat(player.break_out_bonus * 100);
        const success_rate = level.breakout_rate + breakout_bonus;

        const r = ctx.game.random_source.interface().intRangeLessThan(usize, 0, 100);
        const success = r < success_rate;
        const now = Io.Clock.real.now(ctx.game.io).toSeconds();

        player.last_breakout = now;

        if (success) {
            const previous_level = level.name;
            if (level.extensible and player.cultivation.minor < 2) {
                player.cultivation.minor += 1;
            } else {
                player.cultivation.level_id = ctx.game.registry.getLevelByLevel(next_level.level).?.key_ptr.*;
                player.cultivation.minor = 0;
            }
            player.break_out_bonus = 0;

            const cultivation_level = player.cultivation.toDisplay(ctx.game.allocator, &ctx.game.registry);
            defer ctx.game.allocator.free(cultivation_level);

            const message = std.fmt.allocPrint(ctx.game.allocator,
                \\【突破成功】
                \\你成功突破了{s}，踏入{s}！
                \\当前境界：{s}
                \\当前修为：{}
            , .{ previous_level, next_level.name, cultivation_level, player.cultivation.inner }) catch unreachable;
            defer ctx.game.allocator.free(message);

            ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, message) catch log.warn("failed sending message", .{});
        } else {
            player.break_out_bonus += 0.3;

            const next_bonus: usize = @intFromFloat(player.break_out_bonus * 100);
            const message = std.fmt.allocPrint(ctx.game.allocator,
                \\【突破失败】
                \\你冲击{s}境界失败了，气血翻涌，境界没有变化。
                \\下次突破成功率额外增加{}%。
                \\突破冷却一小时后方可再次尝试。
            , .{ next_level.name, next_bonus }) catch unreachable;
            defer ctx.game.allocator.free(message);

            ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, message) catch log.warn("failed sending message", .{});
        }
    }
};

fn posixCtrlHandler(sig: posix.SIG) callconv(.c) void {
    _ = sig;
    if (signal_game) |game| game.should_exit = true;
}

fn noFree(ctx: ?*anyopaque) callconv(.c) void {
    _ = ctx;
}
