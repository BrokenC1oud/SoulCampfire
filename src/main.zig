const std = @import("std");
const posix = std.posix;

const ecs = @import("zflecs");

const SoulCampfire = @import("SoulCampfire");

var should_exit = false;

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

    var client: SoulCampfire.onebot.Client = .init(
        allocator,
        init.io,
        "http://localhost:3000",
        init.environ_map.get("ONEBOT_TOKEN").?,
    );
    defer client.deinit();

    var server: SoulCampfire.onebot.Server = try .init(allocator, init.io, "127.0.0.1", 5700);
    defer server.deinit();

    try server.start();

    const world = ecs.init();
    defer _ = ecs.fini(world);

    ecs.set_target_fps(world, 1);

    while (ecs.progress(world, 0)) {
        std.log.debug("tick", .{});

        if (should_exit) ecs.quit(world);
    }
}

fn posixCtrlHandler(sig: posix.SIG) callconv(.c) void {
    _ = sig;
    should_exit = true;
}
