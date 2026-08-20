const std = @import("std");
const log = std.log.scoped(.main);

const Zenver = @import("zenver").Zenver;

const SoulCampfire = @import("SoulCampfire");

pub fn main(init: std.process.Init) !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status == .leak) @panic("Memory leaked");
    }

    var zenv = Zenver.init(allocator, init.io, ".env");
    defer zenv.deinit();

    try zenv.loadFile(null);

    var game: SoulCampfire.game.Game = undefined;
    try game.init(allocator, init.io, &zenv);
    defer game.deinit();

    game.registerSignal();
    try game.start();
    game.mainLoop();
}
