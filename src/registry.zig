const std = @import("std");

const ItemDefinition = struct {};

const Registry = struct {
    items: std.StringHashMap(ItemDefinition),

    fn init() @This() {
        return .{};
    }

    fn load(self: *@This()) void {
        _ = self;
    }
};
