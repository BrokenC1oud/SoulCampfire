const std = @import("std");
const Io = std.Io;
const log = std.log.scoped(.game);

const SoulCampfire = @import("SoulCampfire");
const models = SoulCampfire.models;

pub fn init(command: *SoulCampfire.command.Command) !void {
    try command.register("服用", "服用背包内的物品，获得加成", tookDrugCommand);
    try command.register("我的背包", "查看背包内物品", myBackpackCommand);
}

fn myBackpackCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
    _ = arguments;

    const player_entity = SoulCampfire.game.Game.getPlayer(ctx.game.allocator, ctx.game.world.?, ctx.event.value.sender.user_id);
    if (player_entity == 0) {
        _ = ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还未踏上仙途！") catch log.warn("failed sending message", .{});
        return;
    }

    const items = ctx.game.db.session.query(models.InventoryItem).where("user_id", ctx.event.value.sender.user_id).findAll() catch {
        log.warn("db error", .{});
        return;
    };

    var msg: Io.Writer.Allocating = .init(ctx.game.allocator);
    defer msg.deinit();

    if (items.len > 0) {
        msg.writer.print("你的背包：\n", .{}) catch unreachable;
        for (items) |inv_item| {
            const item = ctx.game.registry.items.?.get(inv_item.item_id).?;
            msg.writer.print("{s} * {}\n", .{ item.name, inv_item.count }) catch unreachable;
        }
    } else {
        msg.writer.print("道友的背包空空如也！", .{}) catch unreachable;
    }

    ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, msg.written()) catch log.warn("failed sending message", .{});
}

fn tookDrugCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
    // TODO
    _ = ctx;
    _ = arguments;
}
