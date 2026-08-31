const std = @import("std");
const Io = std.Io;
const log = std.log.scoped(.game);

const ecs = @import("zflecs");

const SoulCampfire = @import("SoulCampfire");
const models = SoulCampfire.models;

pub fn init(command: *SoulCampfire.command.Command) !void {
    log.debug("loading base module", .{});

    try command.register("检测灵根", "踏入仙途", inspectSoulCommand);
    try command.register("我的灵根", "查询自己的灵根信息", mySoulCommand);
    try command.register("改名", "更改道号", changeNameCommand);
    try command.register("修仙签到", "每日签到", checkInCommand);
    try command.register("闭关修炼", "进行一次修炼 提升修为", retreatCommand);
    try command.register("深度闭关", "进行8小时的多次闭关", retreatInDepthCommand);
    try command.register("查看闭关", "查看闭关状态", queryRetreatInDepthCommand);
    try command.register("强行出关", "强行出关 并进行修炼结算", quitRetreatInDepthCommand);
    try command.register("突破", "突破至下一境界", breakOutCommand);
    try command.register("直接突破", "直接突破，不消耗特殊物品", directBreakOutCommand);
    try command.register("送灵石", "数量 @somebody", giveStoneCommand);
    try command.register("偷灵石", "@somebody 消耗灵石偷其他道友的灵石", stoleStoneCommand);
    try command.register("修仙排行榜", "根据境界修为排名所有玩家", rankCommand);
    try command.register("灵石排行榜", "根据灵石排名所有玩家", rankStoneCommand);
    try command.register("帮助", "展示此帮助", helpCommand);
}

fn inspectSoulCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
    _ = arguments;

    const new_player_name = std.fmt.allocPrintSentinel(ctx.game.allocator, "Player_{}", .{ctx.event.value.sender.user_id}, 0) catch unreachable;
    defer ctx.game.allocator.free(new_player_name);

    if (ecs.lookup(ctx.game.world.?, new_player_name.ptr) != 0) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你已经进入修仙世界了！") catch {
            log.warn("failed sending messages", .{});
            return;
        };
        return;
    }

    const player = ecs.new_entity(ctx.game.world.?, new_player_name);
    const new_info = models.Player.random(&ctx.game.random_source, &ctx.game.registry, ctx.event.value.sender.user_id);
    _ = ecs.set(ctx.game.world.?, player, models.Player, new_info);

    const reply_message = std.fmt.allocPrint(ctx.game.allocator, "[CQ:reply,id={}]欢迎踏入仙途，你的灵根是：{s}, 你将从炼气一层开始", .{ ctx.event.value.message_id, new_info.trait.toDisplay() }) catch unreachable;
    defer ctx.game.allocator.free(reply_message);
    _ = ctx.game.client.sendGroupMsg(ctx.event.value.group_id, reply_message, .{}) catch {
        log.warn("failed sending messages", .{});
        return;
    };
}

fn mySoulCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
    _ = arguments;

    const player = SoulCampfire.game.Game.getPlayer(ctx.game.allocator, ctx.game.world.?, ctx.event.value.sender.user_id);
    if (player == 0) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还未加入仙界！") catch {
            log.warn("failed sending message", .{});
            return;
        };
        return;
    }

    const info = ecs.get(ctx.game.world.?, player, models.Player);
    if (info == null) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "请稍后重试") catch {
            log.warn("failed sending message", .{});
            return;
        };
        return;
    }

    const reply_msg = std.fmt.allocPrint(ctx.game.allocator,
        \\{s} 的天命玉牒：
        \\宗门：{s}
        \\灵根：{s}
        \\修为：{}
        \\灵石：{}
    , .{
        if (info.?.name) |na| na else ctx.event.value.sender.nickname.?,
        if (info.?.school) |school| SoulCampfire.game.Game.getPlayerSect(ctx.game.allocator, ctx.game.world.?, school).name else "散修",
        info.?.trait.toDisplay(),
        info.?.cultivation.inner,
        info.?.stone,
    }) catch unreachable;
    defer ctx.game.allocator.free(reply_msg);

    ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, reply_msg) catch {
        log.warn("failed sending messages", .{});
        return;
    };
}

fn changeNameCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
    const player_entity = SoulCampfire.game.Game.getPlayer(ctx.game.allocator, ctx.game.world.?, ctx.event.value.sender.user_id);
    if (player_entity == 0) {
        _ = ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还未踏上仙途！") catch log.warn("failed sending message", .{});
        return;
    }

    if (arguments.len < 1 or arguments[0].len == 0) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "叽里咕噜说什么呢") catch log.warn("failed sending message", .{});
        return;
    }

    const player = ecs.get_mut(ctx.game.world.?, player_entity, models.Player).?;
    player.name = ctx.game.db.session.arena.dupe(u8, arguments[0]) catch {
        log.warn("db error", .{});
        return;
    };

    ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "改名成功!") catch log.warn("failed sending message", .{});
}

fn checkInCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
    _ = arguments;

    const player_entity = SoulCampfire.game.Game.getPlayer(ctx.game.allocator, ctx.game.world.?, ctx.event.value.sender.user_id);
    if (player_entity == 0) {
        _ = ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还未踏上仙途！") catch log.warn("failed sending message", .{});
        return;
    }

    const now = Io.Clock.real.now(ctx.game.io).toSeconds();
    const epoch: std.time.epoch.EpochSeconds = .{ .secs = @intCast(now) };
    const epoch_day = epoch.getEpochDay();

    const check_in_his = ctx.game.db.session.query(models.CheckIn).where("user_id", ctx.event.value.sender.user_id).where("day", epoch_day.day).findOne() catch {
        log.warn("db error", .{});
        return;
    };

    if (check_in_his) |history| {
        const msg = std.fmt.allocPrint(ctx.game.allocator, "你今天已经签到过了 获得了{}灵石", .{history.stone}) catch unreachable;
        defer ctx.game.allocator.free(msg);

        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, msg) catch log.warn("failed sending message", .{});
    } else {
        const check_id = ctx.game.db.session.insert(models.CheckIn, .{
            .user_id = ctx.event.value.sender.user_id,
            .day = epoch_day.day,
            .stone = ctx.game.random_source.interface().intRangeAtMost(usize, 200000, 500000),
        }) catch {
            log.warn("db error", .{});
            return;
        };
        const check = ctx.game.db.session.find(models.CheckIn, check_id) catch {
            log.warn("db error", .{});
            return;
        } orelse unreachable;

        const player = ecs.get_mut(ctx.game.world.?, player_entity, models.Player).?;
        player.stone += check.stone;

        const msg = std.fmt.allocPrint(ctx.game.allocator, "签到成功，获得了{}块灵石", .{check.stone}) catch unreachable;
        defer ctx.game.allocator.free(msg);

        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, msg) catch log.warn("failed sending message", .{});
    }
}

fn retreatCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
    _ = arguments;

    const player = SoulCampfire.game.Game.getPlayer(ctx.game.allocator, ctx.game.world.?, ctx.event.value.sender.user_id);
    if (player == 0) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还未踏上仙途！") catch {
            log.warn("failed sending message", .{});
            return;
        };
        return;
    }

    if (SoulCampfire.game.Game.retreat(ctx.game.world.?, player, ctx.game.io, ctx.game.random_source.interface())) |result| {
        const time_took = ctx.game.random_source.interface().intRangeAtMost(usize, 10, 15);
        const r: models.Retreat = .{
            .id = ctx.event.value.sender.user_id,
            .endsAt = Io.Clock.real.now(ctx.game.io).nanoseconds + time_took * std.time.ns_per_min,
            .depth = null,
        };
        _ = ecs.set(ctx.game.world.?, player, models.Retreat, r);

        const info = ecs.get_mut(ctx.game.world.?, player, models.Player).?;
        info.cultivation.modify(result.inner());
        const cultivation_level = info.cultivation.toDisplay(ctx.game.allocator, &ctx.game.registry);
        defer ctx.game.allocator.free(cultivation_level);

        const reply_message = switch (result) {
            .success => std.fmt.allocPrint(ctx.game.allocator,
                \\【闭关成功】
                \\你福至心灵，成功炼化灵气，基础修为增加了{}点。
                \\本次闭关，你的修为最终增加了{}点。
                \\
                \\当前境界：{s}
                \\当前修为：{}
                \\
                \\你感到一阵疲惫，需要打坐休息{}分钟才能再次闭关。
            , .{
                result.inner(),
                result.inner(),
                cultivation_level,
                info.cultivation.inner,
                time_took,
            }),
            .fail => std.fmt.allocPrint(ctx.game.allocator,
                \\【闭关失败】
                \\你心浮气躁，无法凝神，白白浪费了灵气。你的修为减少了{}点。
                \\
                \\当前境界：{s}
                \\当前修为：{}
                \\
                \\你感到一阵疲惫，需要打坐休息{}分钟才能再次闭关。
            , .{
                -result.inner(),
                cultivation_level,
                info.cultivation.inner,
                time_took,
            }),
            .deviation => std.fmt.allocPrint(ctx.game.allocator,
                \\【走火入魔】
                \\你闭关之时，心魔入侵，道心受损！灵气反噬之下，你的修为倒退了{}点！
                \\
                \\当前境界：{s}
                \\当前修为：{}
                \\
                \\你感到一阵疲惫，需要打坐休息{}分钟才能再次闭关。
            , .{
                -result.inner(),
                cultivation_level,
                info.cultivation.inner,
                time_took,
            }),
        } catch unreachable;
        defer ctx.game.allocator.free(reply_message);

        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, reply_message) catch log.warn("failed sending message", .{});
    } else {
        const active_retreat = ecs.get(ctx.game.world.?, player, models.Retreat).?;
        const delta = active_retreat.endsAt - Io.Clock.real.now(ctx.game.io).nanoseconds;

        const reply_message = std.fmt.allocPrint(ctx.game.allocator, "修炼还在冷却中！剩余{}h{}min{}s", .{
            @divTrunc(delta, std.time.ns_per_hour),
            @mod(@divTrunc(delta, std.time.ns_per_min), 60),
            @mod(@divTrunc(delta, std.time.ns_per_s), 60),
        }) catch unreachable;
        defer ctx.game.allocator.free(reply_message);

        ctx.game.client.groupReply(
            ctx.event.value.group_id,
            ctx.event.value.message_id,
            reply_message,
        ) catch log.warn("failed sending message", .{});
    }
}

fn retreatInDepthCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
    _ = arguments;

    const player = SoulCampfire.game.Game.getPlayer(ctx.game.allocator, ctx.game.world.?, ctx.event.value.sender.user_id);

    if (player == 0) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还未踏上仙途！") catch {
            log.warn("failed sending message", .{});
            return;
        };
        return;
    }

    _ = SoulCampfire.game.Game.retreat(ctx.game.world.?, player, ctx.game.io, ctx.game.random_source.interface()) orelse {
        const active_retreat = ecs.get(ctx.game.world.?, player, models.Retreat).?;
        const delta = active_retreat.endsAt - Io.Clock.real.now(ctx.game.io).nanoseconds;

        if (active_retreat.depth == null) {
            const reply_message = std.fmt.allocPrint(ctx.game.allocator, "修炼还在冷却中！剩余{}h{}min{}s", .{
                @divTrunc(delta, std.time.ns_per_hour),
                @mod(@divTrunc(delta, std.time.ns_per_min), 60),
                @mod(@divTrunc(delta, std.time.ns_per_s), 60),
            }) catch unreachable;
            defer ctx.game.allocator.free(reply_message);

            ctx.game.client.groupReply(
                ctx.event.value.group_id,
                ctx.event.value.message_id,
                reply_message,
            ) catch log.warn("failed sending message", .{});
        } else {
            ctx.game.client.groupReply(
                ctx.event.value.group_id,
                ctx.event.value.message_id,
                "你已在深度闭关之中",
            ) catch log.warn("failed sending message", .{});
        }

        return;
    };

    _ = ecs.set(ctx.game.world.?, player, models.Retreat, .{
        .id = ctx.event.value.sender.user_id,
        .endsAt = Io.Clock.real.now(ctx.game.io).nanoseconds + 8 * std.time.ns_per_hour,
        .depth = .{
            .group_id = ctx.event.value.group_id,
            .message_id = ctx.event.value.message_id,
            .startsAt = Io.Clock.real.now(ctx.game.io).nanoseconds,
        },
    });

    ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id,
        \\你已进入深度闭关状态，神魂将自行吐纳8小时。
        \\期间你将无法进行大部分操作。到时将自动结算收获。
    ) catch log.warn("failed sending messages", .{});
}

fn queryRetreatInDepthCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
    _ = arguments;

    const player = SoulCampfire.game.Game.getPlayer(ctx.game.allocator, ctx.game.world.?, ctx.event.value.sender.user_id);

    if (player == 0) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还未踏上仙途！") catch {
            log.warn("failed sending message", .{});
            return;
        };
        return;
    }

    const active_retreat = ecs.get(ctx.game.world.?, player, models.Retreat);
    if (active_retreat == null or active_retreat.?.depth == null) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你并未处于深度闭关之中") catch {
            log.warn("failed sending message", .{});
            return;
        };
        return;
    }

    const delta = active_retreat.?.endsAt - Io.Clock.real.now(ctx.game.io).nanoseconds;
    const message = std.fmt.allocPrint(ctx.game.allocator, "你正在深度闭关，预计需要{}小时{}分钟{}秒即可功成圆满。", .{
        @divTrunc(delta, std.time.ns_per_hour),
        @mod(@divTrunc(delta, std.time.ns_per_min), 60),
        @mod(@divTrunc(delta, std.time.ns_per_s), 60),
    }) catch unreachable;
    defer ctx.game.allocator.free(message);

    ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, message) catch log.warn("failed sending message", .{});
}

fn quitRetreatInDepthCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
    _ = arguments;

    const player = SoulCampfire.game.Game.getPlayer(ctx.game.allocator, ctx.game.world.?, ctx.event.value.sender.user_id);

    if (player == 0) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还未踏上仙途！") catch {
            log.warn("failed sending message", .{});
            return;
        };
        return;
    }

    const active_retreat = ecs.get_mut(ctx.game.world.?, player, models.Retreat);
    if (active_retreat == null or active_retreat.?.depth == null) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你并未处于深度闭关之中") catch {
            log.warn("failed sending message", .{});
            return;
        };
        return;
    }

    active_retreat.?.endsAt = Io.Clock.real.now(ctx.game.io).nanoseconds;

    ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你强行中断了修炼，正在进行结算") catch log.warn("failed sending message", .{});
}

fn breakOutCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
    _ = arguments;

    const player_entity = SoulCampfire.game.Game.getPlayer(ctx.game.allocator, ctx.game.world.?, ctx.event.value.sender.user_id);
    if (player_entity == 0) {
        _ = ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还未踏上仙途！") catch log.warn("failed sending message", .{});
        return;
    }

    const player = ecs.get(ctx.game.world.?, player_entity, models.Player).?;
    const level = ctx.game.registry.levels.?.get(player.cultivation.level_id).?;
    const next_level = if (level.extensible) switch (player.cultivation.minor) {
        0, 1 => level,
        2 => if (ctx.game.registry.getLevelByLevel(level.level + 1)) |ne| ne.value_ptr.* else {
            ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你已经到达了最高境界，无法继续突破") catch log.warn("failed sending message", .{});
            return;
        },
        else => @panic("how did you get there"),
    } else if (ctx.game.registry.getLevelByLevel(level.level + 1)) |ne| ne.value_ptr.* else {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你已经到达了最高境界，无法继续突破") catch log.warn("failed sending message", .{});
        return;
    };
    if (player.cultivation.inner < next_level.requirement) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你的修为还没有达到下一境界的要求，继续修炼") catch log.warn("failed sending message", .{});
        return;
    }
    if (Io.Clock.real.now(ctx.game.io).toSeconds() - player.last_breakout < std.time.s_per_hour) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你的突破还在冷却中，请稍候") catch log.warn("failed sending message", .{});
        return;
    }
    // TODO: 背包物品特殊加成
    const breakout_bonus: usize = @intFromFloat(player.break_out_bonus * 100);
    const success_rate = level.breakout_rate + breakout_bonus;

    const msg = std.fmt.allocPrint(ctx.game.allocator, "你当前突破到 {s} 境界的概率为{}%，输入`.直接突破`进行突破", .{ next_level.name, success_rate }) catch unreachable;
    defer ctx.game.allocator.free(msg);

    ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, msg) catch log.warn("failed sending message", .{});
}

fn directBreakOutCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
    _ = arguments;

    const player_entity = SoulCampfire.game.Game.getPlayer(ctx.game.allocator, ctx.game.world.?, ctx.event.value.sender.user_id);
    if (player_entity == 0) {
        _ = ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还未踏上仙途！") catch log.warn("failed sending message", .{});
        return;
    }

    const player = ecs.get_mut(ctx.game.world.?, player_entity, models.Player).?;
    const level = ctx.game.registry.levels.?.get(player.cultivation.level_id).?;
    const next_level = if (level.extensible) switch (player.cultivation.minor) {
        0, 1 => level,
        2 => if (ctx.game.registry.getLevelByLevel(level.level + 1)) |ne| ne.value_ptr.* else {
            ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你已经到达了最高境界，无法继续突破") catch log.warn("failed sending message", .{});
            return;
        },
        else => @panic("how did you get there"),
    } else if (ctx.game.registry.getLevelByLevel(level.level + 1)) |ne| ne.value_ptr.* else {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你已经到达了最高境界，无法继续突破") catch log.warn("failed sending message", .{});
        return;
    };

    if (player.cultivation.inner < next_level.requirement) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你的修为还没有达到下一境界的要求，继续修炼") catch log.warn("failed sending message", .{});
        return;
    }
    if (Io.Clock.real.now(ctx.game.io).toSeconds() - player.last_breakout < std.time.s_per_hour) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你的突破还在冷却中，请稍候") catch log.warn("failed sending message", .{});
        return;
    }
    // TODO: 背包物品特殊加成
    const breakout_bonus: usize = @intFromFloat(player.break_out_bonus * 100);
    const success_rate = level.breakout_rate + breakout_bonus;

    const r = ctx.game.random_source.interface().intRangeLessThan(usize, 0, 100);
    const success = r < success_rate;
    const now = Io.Clock.real.now(ctx.game.io).toSeconds();

    player.last_breakout = now;

    if (success) {
        const previous_level = level.name;
        if (level.extensible and player.cultivation.minor < 2) {
            player.cultivation.minor += 1;
        } else {
            player.cultivation.level_id = ctx.game.registry.getLevelByLevel(next_level.level).?.key_ptr.*;
            player.cultivation.minor = 0;
        }
        player.break_out_bonus = 0;

        const cultivation_level = player.cultivation.toDisplay(ctx.game.allocator, &ctx.game.registry);
        defer ctx.game.allocator.free(cultivation_level);

        const message = std.fmt.allocPrint(ctx.game.allocator,
            \\【突破成功】
            \\你成功突破了{s}，踏入{s}！
            \\当前境界：{s}
        , .{ previous_level, next_level.name, cultivation_level }) catch unreachable;
        defer ctx.game.allocator.free(message);

        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, message) catch log.warn("failed sending message", .{});
    } else {
        player.break_out_bonus += 0.3;

        const next_bonus: usize = @intFromFloat(player.break_out_bonus * 100);
        const message = std.fmt.allocPrint(ctx.game.allocator,
            \\【突破失败】
            \\你冲击{s}境界失败了，气血翻涌，境界没有变化。
            \\下次突破成功率额外增加{}%。
            \\突破冷却一小时后方可再次尝试。
        , .{ next_level.name, next_bonus }) catch unreachable;
        defer ctx.game.allocator.free(message);

        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, message) catch log.warn("failed sending message", .{});
    }
}

fn giveStoneCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
    const player_entity = SoulCampfire.game.Game.getPlayer(ctx.game.allocator, ctx.game.world.?, ctx.event.value.sender.user_id);
    if (player_entity == 0) {
        _ = ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还未踏上仙途！") catch log.warn("failed sending message", .{});
        return;
    }

    const player = ecs.get_mut(ctx.game.world.?, player_entity, models.Player).?;

    if (arguments.len < 2 or ctx.event.value.message.len < 2) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "叽里咕噜说什么呢") catch log.warn("failed sending message", .{});
        return;
    }

    if (ctx.event.value.message[1] != .at) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "不是有效的at") catch log.warn("failed sending message", .{});
        return;
    }

    const amount = std.fmt.parseInt(usize, arguments[0], 10) catch {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "输入的灵石数量无效") catch log.warn("failed sending message", .{});
        return;
    };

    if (player.stone < amount) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你的灵石余额不足") catch log.warn("failed sending message", .{});
        return;
    }

    const target_user_id = SoulCampfire.utils.parseAtTarget(&ctx.event, 1) orelse {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "无效的@目标，请指定具体的群友") catch log.warn("failed sending message", .{});
        return;
    };

    if (player.id == target_user_id) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "请不要将灵石赠送给自己") catch log.warn("failed sending message", .{});
        return;
    }

    const target_player_entity = SoulCampfire.game.Game.getPlayer(ctx.game.allocator, ctx.game.world.?, target_user_id);

    if (target_player_entity == 0) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "对方还没有踏入仙界，快去邀请吧") catch log.warn("failed sending message", .{});
        return;
    }

    const target_player = ecs.get_mut(ctx.game.world.?, target_player_entity, models.Player).?;

    target_player.stone += amount;
    player.stone -= amount;

    const user_id_str = std.fmt.allocPrint(ctx.game.allocator, "{}", .{target_player.id}) catch unreachable;
    defer ctx.game.allocator.free(user_id_str);
    const msg = std.fmt.allocPrint(ctx.game.allocator, "成功赠送了 {} 灵石给 {s}", .{ amount, target_player.name orelse user_id_str }) catch unreachable;
    defer ctx.game.allocator.free(msg);

    ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, msg) catch log.warn("failed sending message", .{});
}

fn stoleStoneCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
    const player_entity = SoulCampfire.game.Game.getPlayer(ctx.game.allocator, ctx.game.world.?, ctx.event.value.sender.user_id);
    if (player_entity == 0) {
        _ = ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你还未踏上仙途！") catch log.warn("failed sending message", .{});
        return;
    }

    const player = ecs.get_mut(ctx.game.world.?, player_entity, models.Player).?;

    if (arguments.len < 1 or ctx.event.value.message.len < 2) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "叽里咕噜说什么呢") catch log.warn("failed sending message", .{});
        return;
    }

    if (ctx.event.value.message[1] != .at) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "不是有效的at") catch log.warn("failed sending message", .{});
        return;
    }

    if (player.stone < 1000000) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "道友的偷窃准备不足，需要至少1000000灵石才能进行切格瓦拉") catch log.warn("failed sending message", .{});
        return;
    }

    const now = Io.Clock.real.now(ctx.game.io).toSeconds();
    if (now - player.last_stole < 600) {
        const msg = std.fmt.allocPrint(ctx.game.allocator, "偷灵石还在冷却中，剩余{}s", .{600 - (now - player.last_stole)}) catch unreachable;
        defer ctx.game.allocator.free(msg);

        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, msg) catch log.warn("failed sending message", .{});
        return;
    }

    const target_user_id = SoulCampfire.utils.parseAtTarget(&ctx.event, 1) orelse {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "无效的@目标，请指定具体的群友") catch log.warn("failed sending message", .{});
        return;
    };
    if (player.id == target_user_id) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "道友请不要偷自己刷成就") catch log.warn("failed sending message", .{});
        return;
    }

    const target_entity = SoulCampfire.game.Game.getPlayer(ctx.game.allocator, ctx.game.world.?, target_user_id);
    if (target_entity == 0) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "你at的群友还没有加入仙界， 快去邀请吧") catch log.warn("failed sending message", .{});
        return;
    }

    const target_player = ecs.get_mut(ctx.game.world.?, target_entity, models.Player).?;

    const strength_ratio: f64 = @as(f64, @floatFromInt(player.cultivation.inner)) / @as(f64, @floatFromInt(player.cultivation.inner + target_player.cultivation.inner));
    if (strength_ratio >= 0.8) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "道友偷窃小辈，实属天道所不齿") catch log.warn("failed sending message", .{});
        return;
    } else if (strength_ratio <= 0.05) {
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "道友请不要不自量力") catch log.warn("failed sending message", .{});
        return;
    }

    player.last_stole = now;

    const verdiction = ctx.game.random_source.interface().float(f64);
    if (verdiction < strength_ratio) {
        const stone_stolen: usize = @divFloor(ctx.game.random_source.interface().intRangeLessThan(usize, 1, 20) * target_player.stone, 100);
        player.stone += stone_stolen;
        target_player.stone -= stone_stolen;
        const user_id_str = std.fmt.allocPrint(ctx.game.allocator, "{}", .{target_player.id}) catch unreachable;
        defer ctx.game.allocator.free(user_id_str);
        const msg = std.fmt.allocPrint(ctx.game.allocator, "成功偷取了 {s} 道友的 {} 灵石", .{ target_player.name orelse user_id_str, stone_stolen }) catch unreachable;
        defer ctx.game.allocator.free(msg);
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, msg) catch log.warn("failed sending message", .{});
        return;
    } else {
        player.stone -= 1000000;
        target_player.stone += 1000000;
        ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, "道友偷窃失手了，被对方发现并被送到了老八厕所义务劳动，赔款灵石*1000000") catch log.warn("failed sending message", .{});
        return;
    }
}

fn rankCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
    _ = arguments;

    const RankEntry = struct {
        player: models.Player,
        level: usize,

        fn lessThan(_: void, lhs: @This(), rhs: @This()) bool {
            if (lhs.level != rhs.level) return lhs.level > rhs.level;
            if (lhs.player.cultivation.inner != rhs.player.cultivation.inner) {
                return lhs.player.cultivation.inner > rhs.player.cultivation.inner;
            }
            return lhs.player.id < rhs.player.id;
        }
    };

    var entries = std.ArrayList(RankEntry).initCapacity(ctx.game.allocator, 0) catch unreachable;
    defer entries.deinit(ctx.game.allocator);

    var players = ecs.each(ctx.game.world.?, models.Player);
    while (ecs.each_next(&players)) {
        for (players.entities()) |entity| {
            const player = ecs.get(ctx.game.world.?, entity, models.Player).?;
            const level = ctx.game.registry.levels.?.get(player.cultivation.level_id) orelse continue;
            entries.append(ctx.game.allocator, .{
                .player = player.*,
                .level = level.level,
            }) catch unreachable;
        }
    }

    std.sort.block(RankEntry, entries.items, void{}, RankEntry.lessThan);

    var message: Io.Writer.Allocating = .init(ctx.game.allocator);
    defer message.deinit();

    message.writer.print("【修仙排行榜】\n", .{}) catch unreachable;
    const count = @min(entries.items.len, 10);
    for (entries.items[0..count], 0..) |entry, index| {
        const level = ctx.game.registry.levels.?.get(entry.player.cultivation.level_id).?;
        const user_id = std.fmt.allocPrint(ctx.game.allocator, "{}", .{entry.player.id}) catch unreachable;
        defer ctx.game.allocator.free(user_id);

        message.writer.print("{}. {s} {s} 修为：{}\n", .{
            index + 1,
            if (entry.player.name) |na| na else user_id,
            level.name,
            entry.player.cultivation.inner,
        }) catch unreachable;
    }

    if (count == 0) message.writer.print("暂无修士上榜\n", .{}) catch unreachable;

    ctx.game.client.groupReply(
        ctx.event.value.group_id,
        ctx.event.value.message_id,
        message.written(),
    ) catch log.warn("failed sending messages", .{});
}

fn rankStoneCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
    _ = arguments;

    const RankEntry = struct {
        player: *const models.Player,

        fn lessThan(_: void, lhs: @This(), rhs: @This()) bool {
            return lhs.player.stone > rhs.player.stone;
        }
    };

    var entries = std.ArrayList(RankEntry).initCapacity(ctx.game.allocator, 0) catch unreachable;
    defer entries.deinit(ctx.game.allocator);

    var players = ecs.each(ctx.game.world.?, models.Player);
    while (ecs.each_next(&players)) {
        for (players.entities()) |entity| {
            const player = ecs.get(ctx.game.world.?, entity, models.Player).?;
            entries.append(ctx.game.allocator, .{ .player = player }) catch unreachable;
        }
    }

    std.sort.block(RankEntry, entries.items, void{}, RankEntry.lessThan);

    var msg: Io.Writer.Allocating = .init(ctx.game.allocator);
    defer msg.deinit();

    msg.writer.print("【灵石排行榜】\n", .{}) catch unreachable;
    const count = @min(entries.items.len, 10);
    for (entries.items[0..count], 0..) |entry, idx| {
        const user_id_str = std.fmt.allocPrint(ctx.game.allocator, "{}", .{entry.player.id}) catch unreachable;
        defer ctx.game.allocator.free(user_id_str);

        msg.writer.print("{}. {s} {}\n", .{ idx + 1, entry.player.name orelse user_id_str, entry.player.stone }) catch unreachable;
    }

    if (count == 0) {
        msg.writer.print("暂无道友上榜", .{}) catch unreachable;
    }

    ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, msg.written()) catch log.warn("failed sending message", .{});
}

fn helpCommand(ctx: SoulCampfire.command.Command.CommandContext, arguments: []const []const u8) void {
    _ = arguments;

    var msg: Io.Writer.Allocating = .init(ctx.game.allocator);
    defer msg.deinit();

    msg.writer.print("【修仙帮助】\n", .{}) catch unreachable;

    var command_iter = ctx.game.command_parser.commands.iterator();
    while (command_iter.next()) |entry| {
        msg.writer.print(".{s}: {s}\n", .{ entry.key_ptr.*, entry.value_ptr.description }) catch unreachable;
    }

    ctx.game.client.groupReply(ctx.event.value.group_id, ctx.event.value.message_id, msg.written()) catch log.warn("failed sending message", .{});
}
