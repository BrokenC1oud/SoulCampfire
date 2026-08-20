const std = @import("std");
const log = std.log.scoped(.main);

const Zenver = @import("zenver").Zenver;

const SoulCampfire = @import("SoulCampfire");

pub fn main(init: std.process.Init) !void {
    var zenv = Zenver.init(init.gpa, init.io, ".env");
    defer zenv.deinit();

    try zenv.loadFile(null);

    var game: SoulCampfire.game.Game = undefined;
    try game.init(init.gpa, init.io, &zenv);
    defer game.deinit();

    game.registerSignal();
    try game.start();
    game.mainLoop();
}
