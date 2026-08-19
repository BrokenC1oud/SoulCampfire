const std = @import("std");
const log = std.log.scoped(.main);
const posix = std.posix;

const ecs = @import("zflecs");

const SoulCampfire = @import("SoulCampfire");

var should_exit = false;

var event_queue_buffer: []SoulCampfire.GroupMessageEvent = undefined;
var event_queue: std.Io.Queue(SoulCampfire.GroupMessageEvent) = undefined;

pub fn main(init: std.process.Init) !void {
    var act: posix.Sigaction = .{
        .flags = 0,
        .handler = .{ .handler = posixCtrlHandler },
        .mask = posix.sigemptyset(),
    };
    posix.sigaction(.INT, &act, null);

    var gpa = std.heap.DebugAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("Memory leaked");
    }

    event_queue_buffer = try allocator.alloc(SoulCampfire.GroupMessageEvent, 256);
    defer allocator.free(event_queue_buffer);
    event_queue = .init(event_queue_buffer);
    defer event_queue.close(init.io);

    var client: SoulCampfire.onebot.Client = .init(
        allocator,
        init.io,
        "http://localhost:3000",
        init.environ_map.get("ONEBOT_TOKEN").?,
    );
    defer client.deinit();

    var server: SoulCampfire.onebot.Server = try .init(allocator, init.io, &event_queue, "127.0.0.1", 5700);
    defer server.deinit();

    try server.start();

    const world = ecs.init();
    defer _ = ecs.fini(world);

    ecs.set_target_fps(world, 1);

    var tick: usize = 0;
    while (ecs.progress(world, 0)) : (tick += 1) {
        log.debug("TICK {} BEGIN", .{tick});

        var events: [64]SoulCampfire.GroupMessageEvent = undefined;
        const count = event_queue.get(init.io, &events, 0) catch 0;

        for (events[0..count]) |*event| {
            log.debug("{s}", .{event.value.raw_message});
            event.deinit();
        }

        if (should_exit) ecs.quit(world);
    }
}

fn posixCtrlHandler(sig: posix.SIG) callconv(.c) void {
    _ = sig;
    should_exit = true;
}
