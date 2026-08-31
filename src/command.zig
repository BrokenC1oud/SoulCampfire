const std = @import("std");
const Allocator = std.mem.Allocator;

const SoulCampfire = @import("SoulCampfire");

const CommandError = error{ InvalidName, EmptyName, UnknownCommand };

pub const Command = struct {
    allocator: Allocator,
    commands: std.array_hash_map.String(CommandEntry),

    const CommandEntry = struct {
        callback: Callback,
        description: []const u8,
    };

    const Callback = *const fn (CommandContext, []const []const u8) void;

    pub const CommandContext = struct {
        event: SoulCampfire.GroupMessageEvent,
        game: *SoulCampfire.game.Game,
    };

    pub fn init(allocator: Allocator) @This() {
        return .{
            .allocator = allocator,
            .commands = std.array_hash_map.String(CommandEntry).init(allocator, &.{}, &.{}) catch unreachable,
        };
    }

    pub fn deinit(self: *@This()) void {
        for (self.commands.keys()) |key| {
            self.allocator.free(key);
        }
        self.commands.deinit(self.allocator);
        self.* = undefined;
    }

    pub fn register(self: *@This(), name: []const u8, description: []const u8, callback: Callback) !void {
        if (std.mem.indexOf(u8, name, " ") != null) {
            return CommandError.InvalidName;
        }
        const owned_name = try self.allocator.dupe(u8, name);
        errdefer self.allocator.free(owned_name);

        try self.commands.put(self.allocator, owned_name, .{ .callback = callback, .description = description });
    }

    pub fn execute(self: *@This(), input: []const u8, event: SoulCampfire.GroupMessageEvent, game: *SoulCampfire.game.Game) !void {
        var arguments: std.ArrayList([]const u8) = try .initCapacity(self.allocator, 0);
        defer arguments.deinit(self.allocator);
        var iterator = std.mem.tokenizeScalar(u8, input, ' ');

        const command_name = iterator.next() orelse return CommandError.EmptyName;
        while (iterator.next()) |argument| {
            try arguments.append(self.allocator, argument);
        }

        const command = self.commands.get(command_name) orelse return CommandError.UnknownCommand;
        command.callback(.{ .event = event, .game = game }, arguments.items);
    }
};
