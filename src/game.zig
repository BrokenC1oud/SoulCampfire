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

        _ = ecs.ADD_SYSTEM(self.world.?, "event handler system", ecs.OnUpdate, messageEventSystem);

        try self.command_parser.register("检测灵根", inspectSoulCommand);
        try self.command_parser.register("我的灵根", mySoulCommand);
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
        cultivation: usize,
        trait: Trait,
        school: School,

        fn random(random_source: *std.Random.IoSource, user_id: usize) @This() {
            const random_interface = random_source.interface();

            return .{
                .user_id = user_id,
                .cultivation = 0,
                .trait = random_interface.enumValue(Trait),
                .school = .rogue,
            };
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
            \\修为：{}
        , .{
            ctx.event.value.sender.nickname.?,
            info.?.school.toDisplay(),
            info.?.trait.toDisplay(),
            info.?.cultivation,
        }) catch unreachable;
        defer ctx.game.allocator.free(reply_msg);

        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, reply_msg) catch {
            log.err("failed sending messages", .{});
            return;
        };
    }
};

fn posixCtrlHandler(sig: posix.SIG) callconv(.c) void {
    _ = sig;
    if (signal_game) |game| game.should_exit = true;
}

fn noFree(ctx: ?*anyopaque) callconv(.c) void {
    _ = ctx;
}
