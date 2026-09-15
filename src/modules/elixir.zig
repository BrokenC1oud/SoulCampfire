const std = @import("std");
const Io = std.Io;
const log = std.log.scoped(.game);

const ecs = @import("zflecs");

const SoulCampfire = @import("SoulCampfire");
const models = SoulCampfire.models;
const registry = SoulCampfire.registry;

const Contribution = struct {
    trait: registry.Identifier,
    amount: usize,
};

const Usage = struct {
    indexes: [3]usize = .{ 0, 0, 0 },
    counts: [3]usize = .{ 0, 0, 0 },
    len: usize = 0,

    fn add(self: *Usage, index: usize, amount: usize) void {
        if (amount == 0) return;

        for (0..self.len) |i| {
            if (self.indexes[i] == index) {
                self.counts[i] += amount;
                return;
            }
        }

        self.indexes[self.len] = index;
        self.counts[self.len] = amount;
        self.len += 1;
    }

    fn fits(self: *const Usage, herbs: []const models.InventoryItem) bool {
        for (0..self.len) |i| {
            if (self.counts[i] > herbs[self.indexes[i]].count) return false;
        }
        return true;
    }
};

pub fn init(command: *SoulCampfire.command.Command) !void {
    log.debug("loading elixir module", .{});

    try command.register("炼丹", "发现背包中药材可用的配方", discoverCommand);
}

fn addContribution(contributions: *[3]Contribution, len: *usize, trait: registry.Identifier, amount: usize) void {
    if (amount == 0) return;

    const id_ctx = registry.IdentifierCtx{};
    for (0..len.*) |i| {
        if (id_ctx.eql(contributions[i].trait, trait)) {
            contributions[i].amount += amount;
            return;
        }
    }

    contributions[len.*] = .{ .trait = trait, .amount = amount };
    len.* += 1;
}

fn recipeMatches(recipe: *const registry.Recipe, contributions: []const Contribution) bool {
    const id_ctx = registry.IdentifierCtx{};

    for (recipe.ingredients, 0..) |ingredient, index| {
        var already_counted = false;
        for (recipe.ingredients[0..index]) |previous| {
            if (id_ctx.eql(previous.item, ingredient.item)) {
                already_counted = true;
                break;
            }
        }
        if (already_counted) continue;

        var required: usize = 0;
        for (recipe.ingredients) |other| {
            if (id_ctx.eql(other.item, ingredient.item)) {
                required += other.amount;
            }
        }

        var supplied: usize = 0;
        for (contributions) |contribution| {
            if (id_ctx.eql(contribution.trait, ingredient.item)) {
                supplied = contribution.amount;
                break;
            }
        }

        if (supplied < required) return false;
    }

    return true;
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
        const item = registry.Registries.ITEMS.?.get(inv_item.item_id).?;
        if (item.type == .herb) {
            herbs.append(ctx.game.allocator, inv_item) catch unreachable;
        }
    }

    if (herbs.items.len == 0) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你的背包中还没有药材") catch log.warn("failed sending message", .{});
        return;
    }

    const recipes = if (registry.Registries.RECIPE) |*value| value else return;
    if (recipes.entries.count() == 0) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "未曾从背包药材中参悟出任何配方") catch log.warn("failed sending message", .{});
        return;
    }
    const id_ctx = registry.IdentifierCtx{};

    var discovered = std.ArrayList(registry.Identifier).initCapacity(ctx.game.allocator, 0) catch unreachable;
    defer discovered.deinit(ctx.game.allocator);

    var names = std.ArrayList(struct { product: registry.Identifier, x_id: registry.Identifier, x: usize, y_id: registry.Identifier, y: usize, z_id: registry.Identifier, z: usize }).initCapacity(ctx.game.allocator, 0) catch unreachable;
    defer names.deinit(ctx.game.allocator);

    var remaining = recipes.entries.count();

    outer: for (0..herbs.items.len) |i| {
        const main_herb = registry.Registries.ITEMS.?.get(herbs.items[i].item_id).?;
        const main_stats = main_herb.type.herb.main;
        const main_count = herbs.items[i].count;

        for (0..herbs.items.len) |j| {
            const guiding_herb = registry.Registries.ITEMS.?.get(herbs.items[j].item_id).?;
            const guiding_stats = guiding_herb.type.herb.guiding;
            const guiding_count = herbs.items[j].count;

            const max_guiding_scale = @min(main_count, 5);
            var x: usize = 1;
            while (x <= max_guiding_scale) : (x += 1) {
                const maybe_y: ?usize = blk: {
                    if (main_stats.temp == 0) break :blk 0;
                    if (guiding_stats.temp == 0) break :blk null;

                    const numerator = main_stats.temp * @as(isize, @intCast(x));
                    if (@rem(numerator, guiding_stats.temp) != 0) continue;

                    const y_signed = -@divExact(numerator, guiding_stats.temp);
                    if (y_signed < 0) break :blk null;
                    if (y_signed > @as(isize, @intCast(@min(guiding_count, 5)))) break :blk null;
                    break :blk @intCast(y_signed);
                };
                const y = maybe_y orelse break;

                for (0..herbs.items.len) |k| {
                    const auxiliary_herb = registry.Registries.ITEMS.?.get(herbs.items[k].item_id).?;
                    const auxiliary_stats = auxiliary_herb.type.herb.auxiliary;

                    const max_aux_scale = @min(herbs.items[k].count, 5);
                    var z: usize = 1;
                    while (z <= max_aux_scale) : (z += 1) {
                        var usage = Usage{};
                        usage.add(i, x);
                        usage.add(j, y);
                        usage.add(k, z);
                        if (!usage.fits(herbs.items)) continue;

                        var contributions: [3]Contribution = undefined;
                        var contributions_len: usize = 0;
                        addContribution(&contributions, &contributions_len, main_stats.trait, main_stats.power * x);
                        addContribution(&contributions, &contributions_len, guiding_stats.trait, guiding_stats.power * y);
                        addContribution(&contributions, &contributions_len, auxiliary_stats.trait, auxiliary_stats.power * z);

                        var recipe_iterator = recipes.entries.iterator();
                        while (recipe_iterator.next()) |entry| {
                            const recipe_key = entry.key_ptr.*;
                            const recipe = entry.value_ptr.*;

                            if (!recipeMatches(recipe, contributions[0..contributions_len])) continue;

                            var already_discovered = false;
                            for (discovered.items) |found| {
                                if (id_ctx.eql(found, recipe_key)) {
                                    already_discovered = true;
                                    break;
                                }
                            }
                            if (already_discovered) continue;

                            discovered.append(ctx.game.allocator, recipe_key) catch unreachable;
                            names.append(ctx.game.allocator, .{ .product = recipe.product, .x_id = herbs.items[i].item_id, .x = x, .y_id = herbs.items[j].item_id, .y = y, .z_id = herbs.items[k].item_id, .z = z }) catch unreachable;
                            remaining -= 1;
                            if (remaining == 0) break :outer;
                        }
                    }
                }
            }
        }
    }

    var msg: Io.Writer.Allocating = .init(ctx.game.allocator);
    defer msg.deinit();

    if (names.items.len == 0) {
        msg.writer.print("未曾从背包药材中参悟出任何配方", .{}) catch unreachable;
    } else {
        msg.writer.print("你从背包药材中参悟出以下配方：\n", .{}) catch unreachable;
        for (names.items) |rec| {
            msg.writer.print("- {s}: ", .{registry.Registries.ITEMS.?.get(rec.product).?.name}) catch unreachable;
            msg.writer.print("主药{s}*{}", .{ registry.Registries.ITEMS.?.get(rec.x_id).?.name, rec.x }) catch unreachable;
            msg.writer.print("药引{s}*{}", .{ registry.Registries.ITEMS.?.get(rec.y_id).?.name, rec.y }) catch unreachable;
            msg.writer.print("副药{s}*{}", .{ registry.Registries.ITEMS.?.get(rec.z_id).?.name, rec.z }) catch unreachable;

            msg.writer.print("\n", .{}) catch unreachable;
        }
    }

    ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, msg.written()) catch log.warn("failed sending message", .{});
}
