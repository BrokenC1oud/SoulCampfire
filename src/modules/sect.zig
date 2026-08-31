const std = @import("std");
const log = std.log.scoped(.game);

const ecs = @import("zflecs");

const SoulCampfire = @import("SoulCampfire");
const models = SoulCampfire.models;

pub fn init(command: *SoulCampfire.command.Command) !void {
    log.debug("loading sect module", .{});

    try command.register("拜入宗门", "<宗门名称>", joinSectCommand);
    try command.register("我的宗门", "查看当前加入的宗门", mySectCommand);
}

fn joinSectCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
    const player_entity = SoulCampfire.game.Game.getPlayer(ctx.game.allocator, ctx.game.world.?, ctx.event.value.sender.user_id);
    if (player_entity == 0) {
        _ = ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还未踏上仙途！") catch log.warn("failed sending message", .{});
        return;
    }

    const player = ecs.get_mut(ctx.game.world.?, player_entity, models.Player).?;
    if (player.school) |_| {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你已经加入了其他宗门，叛出已有宗门才能加入新的宗门！") catch log.warn("failed sending message", .{});
        return;
    }

    if (arguments.len < 1) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "叽里咕噜说什么呢") catch log.warn("failed sending message", .{});
        return;
    }

    const school = ctx.game.db.session.query(models.School).where("name", arguments[0]).findOne() catch {
        log.warn("db error", .{});
        return;
    };

    if (school) |s| {
        player.school = .{ .id = s.id, .role = .outer, .contribution = 0 };

        const msg = std.fmt.allocPrint(ctx.game.allocator, "欢迎师弟加入了宗门【{s}】，共参天道。", .{s.name}) catch unreachable;
        defer ctx.game.allocator.free(msg);

        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, msg) catch log.warn("failed sending message", .{});
        return;
    } else {
        const msg = std.fmt.allocPrint(ctx.game.allocator, "你要加入的宗门【{s}】不存在", .{arguments[0]}) catch unreachable;
        defer ctx.game.allocator.free(msg);

        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, msg) catch log.warn("failed sending message", .{});
        return;
    }
}

fn mySectCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
    _ = arguments;

    const player_entity = SoulCampfire.game.Game.getPlayer(ctx.game.allocator, ctx.game.world.?, ctx.event.value.sender.user_id);
    if (player_entity == 0) {
        _ = ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还未踏上仙途！") catch log.warn("failed sending message", .{});
        return;
    }

    const player = ecs.get(ctx.game.world.?, player_entity, models.Player).?;
    if (player.school) |school_r| {
        const school = SoulCampfire.game.Game.getPlayerSect(ctx.game.allocator, ctx.game.world.?, school_r);

        const school_rank = ctx.game.db.session.raw(
            \\WITH RankedSchool AS (
            \\    SELECT
            \\        id,
            \\        scale,
            \\        row_number() over (ORDER BY scale) AS rank_num
            \\    FROM School
            \\)
            \\SELECT rank_num
            \\FROM RankedSchool
            \\WHERE id = ?
        , .{school.id}).get(usize) catch {
            log.warn("db error", .{});
            return;
        };

        const msg = std.fmt.allocPrint(ctx.game.allocator,
            \\你所在的宗门：
            \\宗门名讳：{s}
            \\道友职位：{s}
            \\宗门建设度：{}
            \\宗门排名：{}
        , .{ school.name, school_r.role.toDisplay(), school.scale, school_rank.? }) catch unreachable;
        defer ctx.game.allocator.free(msg);

        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, msg) catch log.warn("failed sending message", .{});
    } else {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "一介散修，莫要再问") catch log.warn("failed sending message", .{});
    }
}
