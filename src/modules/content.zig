const std = @import("std");
const log = std.log.scoped(.game);

const SoulCampfire = @import("SoulCampfire");
const Identifier = SoulCampfire.registry.Identifier;

pub fn init(_: *SoulCampfire.command.Command) !void {
    log.debug("loading content module", .{});

    const registries = SoulCampfire.registry.Registries;

    try registries.LEVELS.?.entries.put(.fromDefaultNamespace("江湖好手"), .{
        .level = 0,
        .extensible = false,
        .requirement = 0,
        .ratio = 1,
        .breakout_rate = 100,
        .name = "江湖好手",
    });
    try registries.LEVELS.?.entries.put(.fromDefaultNamespace("搬血境"), .{
        .level = 1,
        .extensible = true,
        .requirement = 2000,
        .ratio = 1.2,
        .breakout_rate = 40,
        .name = "搬血境",
    });
    try registries.LEVELS.?.entries.put(.fromDefaultNamespace("洞天境"), .{
        .level = 2,
        .extensible = true,
        .requirement = 8000,
        .ratio = 2.2,
        .breakout_rate = 36,
        .name = "洞天境",
    });
    try registries.LEVELS.?.entries.put(.fromDefaultNamespace("化灵境"), .{
        .level = 3,
        .extensible = true,
        .requirement = 60000,
        .ratio = 3.2,
        .breakout_rate = 32,
        .name = "化灵境",
    });
    try registries.LEVELS.?.entries.put(.fromDefaultNamespace("铭纹境"), .{
        .level = 4,
        .extensible = true,
        .requirement = 160000,
        .ratio = 4.2,
        .breakout_rate = 30,
        .name = "铭纹境",
    });
    try registries.LEVELS.?.entries.put(.fromDefaultNamespace("列阵境"), .{
        .level = 5,
        .extensible = true,
        .requirement = 384000,
        .ratio = 5.2,
        .breakout_rate = 26,
        .name = "列阵境",
    });
    try registries.LEVELS.?.entries.put(.fromDefaultNamespace("尊者境"), .{
        .level = 6,
        .extensible = true,
        .requirement = 896000,
        .ratio = 6.2,
        .breakout_rate = 25,
        .name = "尊者境",
    });
    try registries.LEVELS.?.entries.put(.fromDefaultNamespace("神火境"), .{
        .level = 7,
        .extensible = true,
        .requirement = 2048000,
        .ratio = 7.2,
        .breakout_rate = 20,
        .name = "神火境",
    });
    try registries.LEVELS.?.entries.put(.fromDefaultNamespace("真一境"), .{
        .level = 8,
        .extensible = true,
        .requirement = 4608000,
        .ratio = 8.2,
        .breakout_rate = 18,
        .name = "真一境",
    });
    try registries.LEVELS.?.entries.put(.fromDefaultNamespace("圣祭境"), .{
        .level = 9,
        .extensible = true,
        .requirement = 12348000,
        .ratio = 9.2,
        .breakout_rate = 15,
        .name = "圣祭境",
    });
    try registries.LEVELS.?.entries.put(.fromDefaultNamespace("天神境"), .{
        .level = 10,
        .extensible = true,
        .requirement = 35968000,
        .ratio = 13,
        .breakout_rate = 12,
        .name = "天神境",
    });
    try registries.LEVELS.?.entries.put(.fromDefaultNamespace("虚道境"), .{
        .level = 11,
        .extensible = true,
        .requirement = 70968000,
        .ratio = 16,
        .breakout_rate = 10,
        .name = "虚道境",
    });
    try registries.LEVELS.?.entries.put(.fromDefaultNamespace("斩我境"), .{
        .level = 12,
        .extensible = true,
        .requirement = 140968000,
        .ratio = 19,
        .breakout_rate = 5,
        .name = "斩我境",
    });
    try registries.LEVELS.?.entries.put(.fromDefaultNamespace("遁一境"), .{
        .level = 13,
        .extensible = true,
        .requirement = 450710400,
        .ratio = 22,
        .breakout_rate = 3,
        .name = "遁一境",
    });
    try registries.LEVELS.?.entries.put(.fromDefaultNamespace("至尊境"), .{
        .level = 14,
        .extensible = true,
        .requirement = 1622557440,
        .ratio = 25,
        .breakout_rate = 1,
        .name = "至尊境",
    });
    try registries.LEVELS.?.entries.put(.fromDefaultNamespace("真仙境"), .{
        .level = 15,
        .extensible = true,
        .requirement = 5841206784,
        .ratio = 28,
        .breakout_rate = 0,
        .name = "真仙境",
    });
    try registries.LEVELS.?.entries.put(.fromDefaultNamespace("仙王境"), .{
        .level = 16,
        .extensible = true,
        .requirement = 21028344422,
        .ratio = 31,
        .breakout_rate = 0,
        .name = "仙王境",
    });
    try registries.LEVELS.?.entries.put(.fromDefaultNamespace("准帝境"), .{
        .level = 17,
        .extensible = true,
        .requirement = 75702039920,
        .ratio = 34,
        .breakout_rate = 0,
        .name = "准帝境",
    });
    try registries.LEVELS.?.entries.put(.fromDefaultNamespace("仙帝境"), .{
        .level = 18,
        .extensible = true,
        .requirement = 272527343704,
        .ratio = 37,
        .breakout_rate = 0,
        .name = "仙帝境",
    });
    try registries.LEVELS.?.entries.put(.fromDefaultNamespace("祭道之上"), .{
        .level = 19,
        .extensible = false,
        .requirement = 999999999999,
        .ratio = 38,
        .breakout_rate = 0,
        .name = "祭道之上",
    });

    try registries.ITEMS.?.entries.put(.fromDefaultNamespace("恒心草"), .{ .name = "恒心草" });
}
