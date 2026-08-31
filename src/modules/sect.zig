const std = @import("std");
const log = std.log.scoped(.game);

const ecs = @import("zflecs");

const SoulCampfire = @import("SoulCampfire");
const models = SoulCampfire.models;

pub fn init(command: *SoulCampfire.command.Command) !void {
    log.debug("loading sect module", .{});

    try command.register("我的宗门", "查看当前加入的宗门", mySectCommand);
    try command.register("拜入宗门", "<宗门名称>", joinSectCommand);
    try command.register("创建宗门", "<宗门名称>", createSectCommand);
    try command.register("赐予法印", "@somebody {宗主,长老,亲传,内门,外门} 更改宗门弟子的地位", grantPermissionCommand);
    try command.register("宗门捐献", "为宗门建设捐献灵石", donateCommand);
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

fn createSectCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
    const player_entity = SoulCampfire.game.Game.getPlayer(ctx.game.allocator, ctx.game.world.?, ctx.event.value.sender.user_id);
    if (player_entity == 0) {
        _ = ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还未踏上仙途！") catch log.warn("failed sending message", .{});
        return;
    }

    const player = ecs.get_mut(ctx.game.world.?, player_entity, models.Player).?;

    if (ctx.game.registry.levels.?.get(player.cultivation.level_id).?.level < 1) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你的等级还没有达到列阵境，无法创建宗门") catch log.warn("failed sending message", .{});
        return;
    }

    if (player.stone < 5000000) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你没有足够的灵石以创建宗门，需要5000000") catch log.warn("failed sending message", .{});
        return;
    }

    if (player.school) |_| {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你当前加入了其他宗门，无法创建新的宗门") catch log.warn("failed sending message", .{});
        return;
    }

    if (arguments.len < 1) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "道友确定要创建无名之宗门？还请三思") catch log.warn("failed sending message", .{});
        return;
    }

    const new_sect_id = ctx.game.db.session.insert(models.School, .{ .name = arguments[0] }) catch {
        log.warn("db error", .{});
        return;
    };
    player.school = .{ .id = new_sect_id, .role = .owner, .contribution = 0 };
    player.stone -= 5000000;

    const user_id_str = std.fmt.allocPrint(ctx.game.allocator, "{}", .{player.id}) catch unreachable;
    defer ctx.game.allocator.free(user_id_str);
    const msg = std.fmt.allocPrint(ctx.game.allocator, "恭喜道友 {s} 创建了宗门 {s}，为道友贺，为仙道贺！", .{ player.name orelse user_id_str, arguments[0] }) catch unreachable;
    defer ctx.game.allocator.free(msg);

    ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, msg) catch log.warn("failed sending message", .{});
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

fn grantPermissionCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
    const player_entity = SoulCampfire.game.Game.getPlayer(ctx.game.allocator, ctx.game.world.?, ctx.event.value.sender.user_id);
    if (player_entity == 0) {
        _ = ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还未踏上仙途！") catch log.warn("failed sending message", .{});
        return;
    }
    const player = ecs.get(ctx.game.world.?, player_entity, models.Player).?;

    if (player.school == null) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还没有加入宗门") catch log.warn("failed sending message", .{});
        return;
    }

    if (ctx.event.value.message.len < 3 or arguments.len < 2) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "叽里咕噜说什么呢") catch log.warn("failed sending message", .{});
        return;
    }

    if (ctx.event.value.message[1] != .at) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "不是有效的at") catch log.warn("failed sending message", .{});
        return;
    }

    const target_permission = models.SchoolRelation.Role.fromStr(arguments[1]);
    if (target_permission == null) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "目标权限无效") catch log.warn("failed sending message", .{});
        return;
    }

    const target_user_id = std.fmt.parseInt(usize, ctx.event.value.message[1].at.data.object.get("qq").?.string, 10) catch unreachable;
    const target_entity = SoulCampfire.game.Game.getPlayer(ctx.game.allocator, ctx.game.world.?, target_user_id);
    if (target_entity == 0) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "对方还未踏入仙途，快去邀请吧") catch log.warn("failed sending message", .{});
        return;
    }
    const target_player = ecs.get_mut(ctx.game.world.?, target_entity, models.Player).?;
    if (target_player.school == null or target_player.school.?.id != player.school.?.id) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你和对方不在同一宗门，无法操作") catch log.warn("failed sending message", .{});
        return;
    }
    if (@intFromEnum(target_player.school.?.role) <= @intFromEnum(player.school.?.role) or @intFromEnum(target_permission.?) <= @intFromEnum(player.school.?.role)) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你目前的职位无法完成这个操作") catch log.warn("failed sending message", .{});
        return;
    }
    target_player.school.?.role = target_permission.?;
    const user_id_str = std.fmt.allocPrint(ctx.game.allocator, "{}", .{target_player.id}) catch unreachable;
    defer ctx.game.allocator.free(user_id_str);
    const msg = std.fmt.allocPrint(ctx.game.allocator, "成功将道友 {s} 的地位变更到了 {s}", .{ target_player.name orelse user_id_str, target_permission.?.toDisplay() }) catch unreachable;
    defer ctx.game.allocator.free(msg);
    ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, msg) catch log.warn("failed sending message", .{});
}

fn donateCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
    const player_entity = SoulCampfire.game.Game.getPlayer(ctx.game.allocator, ctx.game.world.?, ctx.event.value.sender.user_id);
    if (player_entity == 0) {
        _ = ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还未踏上仙途！") catch log.warn("failed sending message", .{});
        return;
    }
    const player = ecs.get_mut(ctx.game.world.?, player_entity, models.Player).?;

    if (player.school == null) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "道友还未加入一方宗门") catch log.warn("failed sending message", .{});
        return;
    }

    if (arguments.len < 1) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "叽里咕噜说什么呢") catch log.warn("failed sending message", .{});
        return;
    }

    const amount = std.fmt.parseInt(usize, arguments[0], 10) catch {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "输入的数量有误") catch log.warn("failed sending message", .{});
        return;
    };

    if (player.stone < amount) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "道友的资金不足以捐献制定数量的灵石") catch log.warn("failed sending message", .{});
        return;
    }

    const sect = SoulCampfire.game.Game.getPlayerSect(ctx.game.allocator, ctx.game.world.?, player.school.?);
    player.stone -= amount;
    sect.scale += amount;
    sect.stone += amount;
    player.school.?.contribution += amount;

    const user_id_str = std.fmt.allocPrint(ctx.game.allocator, "{}", .{player.id}) catch unreachable;
    defer ctx.game.allocator.free(user_id_str);
    const msg = std.fmt.allocPrint(ctx.game.allocator, "道友 {s} 为宗门 {s} 捐献了灵石 {} 枚，增加宗门建设度 {}，增加宗门贡献度 {}，蒸蒸日上!", .{ player.name orelse user_id_str, sect.name, amount, amount, amount }) catch unreachable;
    defer ctx.game.allocator.free(msg);

    ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, msg) catch log.warn("failed sending message", .{});
}
