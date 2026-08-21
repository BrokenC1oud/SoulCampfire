const std = @import("std");

pub const command = @import("command.zig");
pub const db = @import("db.zig");
pub const game = @import("game.zig");
pub const onebot = @import("onebot.zig");
pub const utils = @import("utils.zig");

pub const GroupMessageEvent = struct {
    value: onebot.Server.GroupMessageEvent,
    arena: *std.heap.ArenaAllocator,

    pub fn deinit(self: @This()) void {
        const allocator = self.arena.child_allocator;
        self.arena.deinit();
        allocator.destroy(self.arena);
    }
};
