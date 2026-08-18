const std = @import("std");

const ecs = @import("zflecs");

const SoulCampfire = @import("SoulCampfire");

pub fn main(init: std.process.Init) !void {
    _ = init;

    const world = ecs.init();
    defer _ = ecs.fini(world);

    ecs.set_target_fps(world, 1);

    while (ecs.progress(world, 0)) {}
}
