const std = @import("std");
const log = std.log.scoped(.game);

const ecs = @import("zflecs");

const SoulCampfire = @import("SoulCampfire");
const models = SoulCampfire.models;

pub fn init(command: *SoulCampfire.command.Command) !void {
    try command.register("炼丹", "发现背包中药材可用的配方", discoverCommand);
}

fn discoverCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
    _ = arguments;

    const player_entity = SoulCampfire.game.Game.getPlayer(ctx.game.allocator, ctx.game.world.?, ctx.event.value.sender.user_id);
    if (player_entity == 0) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还未踏上仙途，.检测灵根 以注册") catch log.warn("failed sending message", .{});
        return;
    }
    const player = ecs.get(ctx.game.world.?, player_entity, models.Player).?;

    const items = ctx.game.db.session.query(models.InventoryItem).where("user_id", player.id).findAll() catch {
        log.warn("db error", .{});
        return;
    };

    var herbs = std.ArrayList(models.InventoryItem).initCapacity(ctx.game.allocator, 0) catch unreachable;
    defer herbs.deinit(ctx.game.allocator);

    for (items) |inv_item| {
        const item = SoulCampfire.registry.Registries.ITEMS.?.get(inv_item.item_id).?;
        if (item.type == .herb) {
            herbs.append(ctx.game.allocator, inv_item) catch unreachable;
        }
    }

    if (herbs.items.len == 0) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你的背包中还没有药材") catch log.warn("failed sending message", .{});
        return;
    }

    for (0..herbs.items.len) |i| {
        const main_herb = SoulCampfire.registry.Registries.ITEMS.?.get(herbs.items[i].item_id).?;
        for (0..herbs.items.len) |j| {
            const guiding_herb = SoulCampfire.registry.Registries.ITEMS.?.get(herbs.items[j].item_id).?;

            const balance: ?struct { usize, usize } = blk: {
                if (main_herb.type.herb.main.temp == guiding_herb.type.herb.guiding.temp and main_herb.type.herb.main.temp == 0) {
                    break :blk .{ 1, 0 };
                }

                var x: isize = 0;
                while (x <= @min(herbs.items[i].count, 5)) : (x += 1) {
                    const numerator = main_herb.type.herb.main.temp * x;

                    if (@rem(numerator, guiding_herb.type.herb.guiding.temp) == 0) {
                        const y = -@divExact(numerator, guiding_herb.type.herb.guiding.temp);
                        if (y > herbs.items[j].count) {
                            break :blk null;
                        }
                        break :blk .{ @intCast(x), @intCast(y) };
                    }
                }

                break :blk null;
            };

            if (balance == null) {
                continue;
            }

            // TODO
        }
    }
}
