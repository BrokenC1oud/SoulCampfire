const std = @import("std");

const ecs = @import("zflecs");

const SoulCampfire = @import("SoulCampfire");

pub fn main(init: std.process.Init) !void {
    var client: SoulCampfire.onebot.Client = .init(
        init.gpa,
        init.io,
        "http://localhost:3000",
        init.environ_map.get("ONEBOT_TOKEN").?,
    );
    defer client.deinit();

    const world = ecs.init();
    defer _ = ecs.fini(world);

    ecs.set_target_fps(world, 1);

    while (ecs.progress(world, 0)) {
        std.log.debug("tick", .{});
    }
}
