const std = @import("std");

const Registry = struct {
    fn init() @This() {
        return .{};
    }

    fn load(self: *@This()) void {
        _ = self;
    }
};
