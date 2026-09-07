const std = @import("std");
const log = std.log.scoped(.game);

const SoulCampfire = @import("SoulCampfire");
const Identifier = SoulCampfire.registry.Identifier;

pub const @"江湖好手" = Identifier.fromDefaultNamespace("江湖好手");
pub const @"搬血境" = Identifier.fromDefaultNamespace("搬血境");
pub const @"洞天境" = Identifier.fromDefaultNamespace("洞天境");
pub const @"化灵境" = Identifier.fromDefaultNamespace("化灵境");
pub const @"铭纹境" = Identifier.fromDefaultNamespace("铭纹境");
pub const @"列阵境" = Identifier.fromDefaultNamespace("列阵境");
pub const @"尊者境" = Identifier.fromDefaultNamespace("尊者境");
pub const @"神火境" = Identifier.fromDefaultNamespace("神火境");
pub const @"真一境" = Identifier.fromDefaultNamespace("真一境");
pub const @"圣祭境" = Identifier.fromDefaultNamespace("圣祭境");
pub const @"天神境" = Identifier.fromDefaultNamespace("天神境");
pub const @"虚道境" = Identifier.fromDefaultNamespace("虚道境");
pub const @"斩我境" = Identifier.fromDefaultNamespace("斩我境");
pub const @"遁一境" = Identifier.fromDefaultNamespace("遁一境");
pub const @"至尊境" = Identifier.fromDefaultNamespace("至尊境");
pub const @"真仙境" = Identifier.fromDefaultNamespace("真仙境");
pub const @"仙王境" = Identifier.fromDefaultNamespace("仙王境");
pub const @"准帝境" = Identifier.fromDefaultNamespace("准帝境");
pub const @"仙帝境" = Identifier.fromDefaultNamespace("仙帝境");
pub const @"祭道之上" = Identifier.fromDefaultNamespace("祭道之上");

pub const @"恒心草" = Identifier.fromDefaultNamespace("恒心草");

pub const @"黄级" = Identifier.fromDefaultNamespace("黄级");
pub const @"玄级" = Identifier.fromDefaultNamespace("玄级");
pub const @"地级" = Identifier.fromDefaultNamespace("地级");
pub const @"天级" = Identifier.fromDefaultNamespace("天级");
pub const @"仙级" = Identifier.fromDefaultNamespace("仙级");

pub fn init(_: *SoulCampfire.command.Command) !void {
    log.debug("loading content module", .{});

    const registries = SoulCampfire.registry.Registries;

    try registries.LEVELS.?.entries.put(@"江湖好手", .{
        .level = 0,
        .extensible = false,
        .requirement = 0,
        .ratio = 1,
        .breakout_rate = 100,
        .name = "江湖好手",
    });
    try registries.LEVELS.?.entries.put(@"搬血境", .{
        .level = 1,
        .extensible = true,
        .requirement = 2000,
        .ratio = 1.2,
        .breakout_rate = 40,
        .name = "搬血境",
    });
    try registries.LEVELS.?.entries.put(@"洞天境", .{
        .level = 2,
        .extensible = true,
        .requirement = 8000,
        .ratio = 2.2,
        .breakout_rate = 36,
        .name = "洞天境",
    });
    try registries.LEVELS.?.entries.put(@"化灵境", .{
        .level = 3,
        .extensible = true,
        .requirement = 60000,
        .ratio = 3.2,
        .breakout_rate = 32,
        .name = "化灵境",
    });
    try registries.LEVELS.?.entries.put(@"铭纹境", .{
        .level = 4,
        .extensible = true,
        .requirement = 160000,
        .ratio = 4.2,
        .breakout_rate = 30,
        .name = "铭纹境",
    });
    try registries.LEVELS.?.entries.put(@"列阵境", .{
        .level = 5,
        .extensible = true,
        .requirement = 384000,
        .ratio = 5.2,
        .breakout_rate = 26,
        .name = "列阵境",
    });
    try registries.LEVELS.?.entries.put(@"尊者境", .{
        .level = 6,
        .extensible = true,
        .requirement = 896000,
        .ratio = 6.2,
        .breakout_rate = 25,
        .name = "尊者境",
    });
    try registries.LEVELS.?.entries.put(@"神火境", .{
        .level = 7,
        .extensible = true,
        .requirement = 2048000,
        .ratio = 7.2,
        .breakout_rate = 20,
        .name = "神火境",
    });
    try registries.LEVELS.?.entries.put(@"真一境", .{
        .level = 8,
        .extensible = true,
        .requirement = 4608000,
        .ratio = 8.2,
        .breakout_rate = 18,
        .name = "真一境",
    });
    try registries.LEVELS.?.entries.put(@"圣祭境", .{
        .level = 9,
        .extensible = true,
        .requirement = 12348000,
        .ratio = 9.2,
        .breakout_rate = 15,
        .name = "圣祭境",
    });
    try registries.LEVELS.?.entries.put(@"天神境", .{
        .level = 10,
        .extensible = true,
        .requirement = 35968000,
        .ratio = 13,
        .breakout_rate = 12,
        .name = "天神境",
    });
    try registries.LEVELS.?.entries.put(@"虚道境", .{
        .level = 11,
        .extensible = true,
        .requirement = 70968000,
        .ratio = 16,
        .breakout_rate = 10,
        .name = "虚道境",
    });
    try registries.LEVELS.?.entries.put(@"斩我境", .{
        .level = 12,
        .extensible = true,
        .requirement = 140968000,
        .ratio = 19,
        .breakout_rate = 5,
        .name = "斩我境",
    });
    try registries.LEVELS.?.entries.put(@"遁一境", .{
        .level = 13,
        .extensible = true,
        .requirement = 450710400,
        .ratio = 22,
        .breakout_rate = 3,
        .name = "遁一境",
    });
    try registries.LEVELS.?.entries.put(@"至尊境", .{
        .level = 14,
        .extensible = true,
        .requirement = 1622557440,
        .ratio = 25,
        .breakout_rate = 1,
        .name = "至尊境",
    });
    try registries.LEVELS.?.entries.put(@"真仙境", .{
        .level = 15,
        .extensible = true,
        .requirement = 5841206784,
        .ratio = 28,
        .breakout_rate = 0,
        .name = "真仙境",
    });
    try registries.LEVELS.?.entries.put(@"仙王境", .{
        .level = 16,
        .extensible = true,
        .requirement = 21028344422,
        .ratio = 31,
        .breakout_rate = 0,
        .name = "仙王境",
    });
    try registries.LEVELS.?.entries.put(@"准帝境", .{
        .level = 17,
        .extensible = true,
        .requirement = 75702039920,
        .ratio = 34,
        .breakout_rate = 0,
        .name = "准帝境",
    });
    try registries.LEVELS.?.entries.put(@"仙帝境", .{
        .level = 18,
        .extensible = true,
        .requirement = 272527343704,
        .ratio = 37,
        .breakout_rate = 0,
        .name = "仙帝境",
    });
    try registries.LEVELS.?.entries.put(@"祭道之上", .{
        .level = 19,
        .extensible = false,
        .requirement = 999999999999,
        .ratio = 38,
        .breakout_rate = 0,
        .name = "祭道之上",
    });

    try registries.ITEMS.?.entries.put(@"恒心草", .{ .name = "恒心草" });

    try registries.ALCHEMIST_ATELIER_LEVEL.?.entries.put(@"黄级", .{ .name = "黄级", .level = 1, .cost_scale = 50000000, .cost_stone = 200000 });
    try registries.ALCHEMIST_ATELIER_LEVEL.?.entries.put(@"玄级", .{ .name = "玄级", .level = 2, .cost_scale = 60000000, .cost_stone = 400000 });
    try registries.ALCHEMIST_ATELIER_LEVEL.?.entries.put(@"地级", .{ .name = "地级", .level = 3, .cost_scale = 70000000, .cost_stone = 800000 });
    try registries.ALCHEMIST_ATELIER_LEVEL.?.entries.put(@"天级", .{ .name = "天级", .level = 4, .cost_scale = 80000000, .cost_stone = 1600000 });
    try registries.ALCHEMIST_ATELIER_LEVEL.?.entries.put(@"仙级", .{ .name = "仙级", .level = 5, .cost_scale = 100000000, .cost_stone = 3200000 });
}
