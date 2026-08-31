const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;
const log = std.log.scoped(.game);
const posix = std.posix;

const ecs = @import("zflecs");
const Zenver = @import("zenver").Zenver;

const SoulCampfire = @import("SoulCampfire");
const models = SoulCampfire.models;

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
        try self.db.registerModel(&.{ models.Player, models.CheckIn, models.Retreat, models.School, models.InventoryItem });

        try self.registry.load();

        try self.server.start();

        self.world = ecs.init();

        ecs.set_ctx(self.world.?, self, noFree);

        ecs.set_target_fps(self.world.?, 1);

        ecs.COMPONENT(self.world.?, models.Player);
        ecs.COMPONENT(self.world.?, models.Retreat);

        ecs.COMPONENT(self.world.?, models.School);

        try self.loadData();

        _ = ecs.ADD_SYSTEM(self.world.?, "event handler system", ecs.OnUpdate, messageEventSystem);
        _ = ecs.ADD_SYSTEM(self.world.?, "retreat in depth system", ecs.OnUpdate, depthRetreatSystem);

        _ = ecs.ADD_SYSTEM(self.world.?, "save system", ecs.OnStore, saveSystem);

        try SoulCampfire.modules.base.init(&self.command_parser);
        try SoulCampfire.modules.sect.init(&self.command_parser);
        try SoulCampfire.modules.items.init(&self.command_parser);

        try self.command_parser.register("避世", "", quitWorldCommand);
        try self.command_parser.register("入世", "", joinWorldCommand);
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

        pub fn inner(self: @This()) isize {
            switch (self) {
                inline else => |val| return val,
            }
        }
    };

    pub fn retreat(world: *ecs.world_t, player: u64, io: Io, random: std.Random) ?RetreatResult {
        const active_retreat = ecs.get(world, player, models.Retreat);
        if (active_retreat) |r| {
            if (Io.Clock.real.now(io).nanoseconds < r.endsAt) {
                return null;
            }
        }

        const result = RetreatResult.rollRetreat(random);
        return result;
    }

    pub fn getPlayer(allocator: Allocator, world: *ecs.world_t, user_id: usize) u64 {
        const player_name = std.fmt.allocPrintSentinel(allocator, "Player_{}", .{user_id}, 0) catch unreachable;
        defer allocator.free(player_name);

        const player = ecs.lookup(world, player_name);
        return player;
    }

    pub fn getPlayerSect(allocator: Allocator, world: *ecs.world_t, school_rel: models.SchoolRelation) *models.School {
        const school_name = std.fmt.allocPrintSentinel(allocator, "School_{}", .{school_rel.id}, 0) catch unreachable;
        defer allocator.free(school_name);

        const school_entity = ecs.lookup(world, school_name);
        const school = ecs.get_mut(world, school_entity, models.School).?;

        return school;
    }

    pub fn nextSectId(world: *ecs.world_t) usize {
        var max_id: usize = 0;
        var schools = ecs.each(world, models.School);
        while (ecs.each_next(&schools)) {
            for (schools.entities()) |entity| {
                const school = ecs.get(world, entity, models.School).?;
                max_id = @max(max_id, school.id);
            }
        }
        return max_id + 1;
    }

    pub fn hasSectName(world: *ecs.world_t, name: []const u8) bool {
        var schools = ecs.each(world, models.School);
        while (ecs.each_next(&schools)) {
            for (schools.entities()) |entity| {
                const school = ecs.get(world, entity, models.School).?;
                if (std.mem.eql(u8, school.name, name)) {
                    return true;
                }
            }
        }
        return false;
    }

    fn loadData(self: *@This()) !void {
        const players = try self.db.session.query(models.Player).findAll();
        for (players) |player| {
            const new_entity_name = std.fmt.allocPrintSentinel(self.allocator, "Player_{}", .{player.id}, 0) catch unreachable;
            defer self.allocator.free(new_entity_name);

            const entity = ecs.new_entity(self.world.?, new_entity_name);

            _ = ecs.set(self.world.?, entity, models.Player, player);

            if (try self.db.session.find(models.Retreat, player.id)) |r| {
                _ = ecs.set(self.world.?, entity, models.Retreat, r);
            }
        }

        const schools = try self.db.session.query(models.School).findAll();
        for (schools) |school| {
            const new_entity_name = std.fmt.allocPrintSentinel(self.allocator, "School_{}", .{school.id}, 0) catch unreachable;
            defer self.allocator.free(new_entity_name);

            const entity = ecs.new_entity(self.world.?, new_entity_name);

            _ = ecs.set(self.world.?, entity, models.School, school);
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
                const info = ecs.get_mut(it.world, player, models.Player);
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

    fn depthRetreatSystem(it: *ecs.iter_t, retreats: []const models.Retreat) void {
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

                    _ = ecs.set(it.world, entity, models.Retreat, .{ .id = r.id, .endsAt = Io.Clock.real.now(self.io).nanoseconds + 22 * std.time.ns_per_hour, .depth = null });
                }
            }
        }
    }

    fn saveSystem(it: *ecs.iter_t) void {
        const self: *@This() = @ptrCast(@alignCast(ecs.get_ctx(it.world)));

        var players = ecs.each(it.world, models.Player);
        while (ecs.each_next(&players)) {
            for (players.entities()) |entity| {
                const user_id = ecs.get(it.world, entity, models.Player).?.id;

                const info_persisted = self.db.session.query(models.Player).where("id", user_id).findOne() catch {
                    log.warn("db error", .{});
                    continue;
                };
                const info_mem = ecs.get(it.world, entity, models.Player).?;
                if (info_persisted == null or !std.meta.eql(info_persisted.?, info_mem.*)) {
                    if (info_persisted) |_| {
                        self.db.session.update(models.Player, user_id, info_mem.*) catch log.warn("db error", .{});
                    } else {
                        _ = self.db.session.insert(models.Player, info_mem.*) catch log.warn("db error", .{});
                    }
                }

                const retreat_persisted = self.db.session.query(models.Retreat).where("id", user_id).findOne() catch {
                    log.warn("db error", .{});
                    continue;
                };
                const retreat_mem = ecs.get(it.world, entity, models.Retreat);
                if (retreat_mem) |r| {
                    if (retreat_persisted == null or !std.meta.eql(retreat_persisted.?, r.*)) {
                        if (retreat_persisted) |r_p| {
                            self.db.session.update(models.Retreat, r_p.id, r.*) catch log.warn("db error", .{});
                        } else {
                            _ = self.db.session.insert(models.Retreat, r.*) catch log.warn("db error", .{});
                        }
                    }
                }
            }
        }

        var schools = ecs.each(it.world, models.School);
        while (ecs.each_next(&schools)) {
            for (schools.entities()) |entity| {
                const school_mem = ecs.get(self.world.?, entity, models.School).?;
                const school_persisted = self.db.session.find(models.School, school_mem.id) catch {
                    log.warn("db error", .{});
                    continue;
                };

                if (school_persisted == null or !std.meta.eql(school_mem.*, school_persisted.?)) {
                    if (school_persisted) |p| {
                        self.db.session.update(models.School, p.id, school_mem.*) catch log.warn("db error", .{});
                    } else {
                        _ = self.db.session.insert(models.School, school_mem.*) catch log.warn("db error", .{});
                    }
                }
            }
        }
    }

    //--------------------------------
    // Command
    //--------------------------------

    fn quitWorldCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
        _ = ctx;
        _ = arguments;
    }

    fn joinWorldCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
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
