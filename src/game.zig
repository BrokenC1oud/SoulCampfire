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

        _ = ecs.ADD_SYSTEM(self.world.?, "event handler system", ecs.OnUpdate, messageEventSystem);

        try self.command_parser.register("检测灵根", inspectSoulCommand);
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
                self.command_parser.execute(event.value.raw_message[1..], event.*) catch |err| {
                    log.warn("failed executing command: {t}", .{err});
                };
            }
        }
    }

    //--------------------------------
    // Command
    //--------------------------------
    fn inspectSoulCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
        _ = ctx;
        _ = arguments;

        log.debug("command handler called", .{});
    }
};

fn posixCtrlHandler(sig: posix.SIG) callconv(.c) void {
    _ = sig;
    if (signal_game) |game| game.should_exit = true;
}

fn noFree(ctx: ?*anyopaque) callconv(.c) void {
    _ = ctx;
}
