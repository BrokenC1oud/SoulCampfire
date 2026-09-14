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

pub const @"黄级" = Identifier.fromDefaultNamespace("黄级");
pub const @"玄级" = Identifier.fromDefaultNamespace("玄级");
pub const @"地级" = Identifier.fromDefaultNamespace("地级");
pub const @"天级" = Identifier.fromDefaultNamespace("天级");
pub const @"仙级" = Identifier.fromDefaultNamespace("仙级");

pub const @"生息" = Identifier.fromDefaultNamespace("生息");
pub const @"养气" = Identifier.fromDefaultNamespace("养气");
pub const @"炼气" = Identifier.fromDefaultNamespace("练气");
pub const @"聚元" = Identifier.fromDefaultNamespace("聚元");
pub const @"凝神" = Identifier.fromDefaultNamespace("凝神");

pub const @"恒心草" = Identifier.fromDefaultNamespace("恒心草");
pub const @"红绫草" = Identifier.fromDefaultNamespace("红绫草");
pub const @"罗犀草" = Identifier.fromDefaultNamespace("罗犀草");
pub const @"天青花" = Identifier.fromDefaultNamespace("天青花");
pub const @"五柳根" = Identifier.fromDefaultNamespace("五柳根");
pub const @"天元果" = Identifier.fromDefaultNamespace("天元果");
pub const @"何首乌" = Identifier.fromDefaultNamespace("何首乌");
pub const @"夜交藤" = Identifier.fromDefaultNamespace("夜交藤");
pub const @"紫猴花" = Identifier.fromDefaultNamespace("紫猴花");
pub const @"九叶芝" = Identifier.fromDefaultNamespace("九叶芝");
pub const @"幻心草" = Identifier.fromDefaultNamespace("幻心草");
pub const @"鬼臼草" = Identifier.fromDefaultNamespace("鬼臼草");
pub const @"血莲精" = Identifier.fromDefaultNamespace("血莲精");
pub const @"鸡冠草" = Identifier.fromDefaultNamespace("鸡冠草");
pub const @"银精芝" = Identifier.fromDefaultNamespace("银精芝");
pub const @"玉髓芝" = Identifier.fromDefaultNamespace("玉髓芝");
pub const @"地心火芝" = Identifier.fromDefaultNamespace("地心火芝");
pub const @"天蝉灵叶" = Identifier.fromDefaultNamespace("天蝉灵叶");
pub const @"雪玉骨参" = Identifier.fromDefaultNamespace("雪玉骨参");
pub const @"腐骨灵花" = Identifier.fromDefaultNamespace("腐骨灵花");
pub const @"三叶青芝" = Identifier.fromDefaultNamespace("三叶青芝");
pub const @"七彩月兰" = Identifier.fromDefaultNamespace("七彩月兰");
pub const @"三尾风叶" = Identifier.fromDefaultNamespace("三尾风叶");
pub const @"冰灵焰草" = Identifier.fromDefaultNamespace("冰灵焰草");
pub const @"地心淬灵乳" = Identifier.fromDefaultNamespace("地心淬灵乳");
pub const @"天麻翡石精" = Identifier.fromDefaultNamespace("天麻翡石精");
pub const @"八角玄冰草" = Identifier.fromDefaultNamespace("八角玄冰草");
pub const @"奇茸通天菊" = Identifier.fromDefaultNamespace("奇茸通天菊");
pub const @"木灵三针花" = Identifier.fromDefaultNamespace("木灵三针花");
pub const @"鎏鑫天晶草" = Identifier.fromDefaultNamespace("鎏鑫天晶草");
pub const @"檀芒九叶花" = Identifier.fromDefaultNamespace("檀芒九叶花");
pub const @"坎水玄冰果" = Identifier.fromDefaultNamespace("坎水玄冰果");
pub const @"离火梧桐芝" = Identifier.fromDefaultNamespace("离火梧桐芝");
pub const @"尘磊岩麟果" = Identifier.fromDefaultNamespace("尘磊岩麟果");
pub const @"剑魄竹笋" = Identifier.fromDefaultNamespace("剑魄竹笋");
pub const @"明心问道果" = Identifier.fromDefaultNamespace("明心问道果");
pub const @"宁心草" = Identifier.fromDefaultNamespace("宁心草");
pub const @"凝血草" = Identifier.fromDefaultNamespace("凝血草");
pub const @"银月花" = Identifier.fromDefaultNamespace("银月花");
pub const @"宁神花" = Identifier.fromDefaultNamespace("宁神花");
pub const @"流莹草" = Identifier.fromDefaultNamespace("流莹草");
pub const @"蛇涎果" = Identifier.fromDefaultNamespace("蛇涎果");
pub const @"夏枯草" = Identifier.fromDefaultNamespace("夏枯草");
pub const @"百草露" = Identifier.fromDefaultNamespace("百草露");
pub const @"轻灵草" = Identifier.fromDefaultNamespace("轻灵草");
pub const @"龙葵" = Identifier.fromDefaultNamespace("龙葵");
pub const @"弗兰草" = Identifier.fromDefaultNamespace("弗兰草");
pub const @"玄参" = Identifier.fromDefaultNamespace("玄参");
pub const @"菩提花" = Identifier.fromDefaultNamespace("菩提花");
pub const @"乌稠木" = Identifier.fromDefaultNamespace("乌稠木");
pub const @"雪凝花" = Identifier.fromDefaultNamespace("雪凝花");
pub const @"龙纹草" = Identifier.fromDefaultNamespace("龙纹草");
pub const @"天灵果" = Identifier.fromDefaultNamespace("天灵果");
pub const @"灯心草" = Identifier.fromDefaultNamespace("灯心草");
pub const @"穿心莲" = Identifier.fromDefaultNamespace("穿心莲");
pub const @"龙鳞果" = Identifier.fromDefaultNamespace("龙鳞果");
pub const @"白沉脂" = Identifier.fromDefaultNamespace("白沉脂");
pub const @"苦曼藤" = Identifier.fromDefaultNamespace("苦曼藤");
pub const @"血菩提" = Identifier.fromDefaultNamespace("血菩提");
pub const @"诱妖草" = Identifier.fromDefaultNamespace("诱妖草");
pub const @"天问花" = Identifier.fromDefaultNamespace("天问花");
pub const @"渊血冥花" = Identifier.fromDefaultNamespace("渊血冥花");
pub const @"芒焰果" = Identifier.fromDefaultNamespace("芒焰果");
pub const @"问道花" = Identifier.fromDefaultNamespace("问道花");
pub const @"阴阳黄泉花" = Identifier.fromDefaultNamespace("阴阳黄泉花");
pub const @"厉魂血珀" = Identifier.fromDefaultNamespace("厉魂血珀");
pub const @"浩淼水藤" = Identifier.fromDefaultNamespace("浩淼水藤");
pub const @"道蕴花" = Identifier.fromDefaultNamespace("道蕴花");
pub const @"太乙碧莹花" = Identifier.fromDefaultNamespace("太乙碧莹花");
pub const @"森檀木" = Identifier.fromDefaultNamespace("森檀木");
pub const @"炼心芝" = Identifier.fromDefaultNamespace("炼心芝");
pub const @"重元换血草" = Identifier.fromDefaultNamespace("重元换血草");
pub const @"地黄参" = Identifier.fromDefaultNamespace("地黄参");
pub const @"火精枣" = Identifier.fromDefaultNamespace("火精枣");
pub const @"剑芦" = Identifier.fromDefaultNamespace("剑芦");
pub const @"七星草" = Identifier.fromDefaultNamespace("七星草");
pub const @"风灵花" = Identifier.fromDefaultNamespace("风灵花");
pub const @"伏龙参" = Identifier.fromDefaultNamespace("伏龙参");
pub const @"凌风花" = Identifier.fromDefaultNamespace("凌风花");
pub const @"补天芝" = Identifier.fromDefaultNamespace("补天芝");
pub const @"枫香脂" = Identifier.fromDefaultNamespace("枫香脂");
pub const @"炼魂珠" = Identifier.fromDefaultNamespace("炼魂珠");
pub const @"玄冰花" = Identifier.fromDefaultNamespace("玄冰花");
pub const @"炼血珠" = Identifier.fromDefaultNamespace("炼血珠");
pub const @"石龙芮" = Identifier.fromDefaultNamespace("石龙芮");
pub const @"锦地罗" = Identifier.fromDefaultNamespace("锦地罗");
pub const @"冰灵果" = Identifier.fromDefaultNamespace("冰灵果");
pub const @"玉龙参" = Identifier.fromDefaultNamespace("玉龙参");
pub const @"伴妖草" = Identifier.fromDefaultNamespace("伴妖草");
pub const @"剑心竹" = Identifier.fromDefaultNamespace("剑心竹");
pub const @"绝魂草" = Identifier.fromDefaultNamespace("绝魂草");
pub const @"月灵花" = Identifier.fromDefaultNamespace("月灵花");
pub const @"混元果" = Identifier.fromDefaultNamespace("混元果");
pub const @"皇龙花" = Identifier.fromDefaultNamespace("皇龙花");
pub const @"天剑笋" = Identifier.fromDefaultNamespace("天剑笋");
pub const @"黑天麻" = Identifier.fromDefaultNamespace("黑天麻");
pub const @"血玉竹" = Identifier.fromDefaultNamespace("血玉竹");
pub const @"肠蚀草" = Identifier.fromDefaultNamespace("肠蚀草");
pub const @"凤血果" = Identifier.fromDefaultNamespace("凤血果");
pub const @"冰精芝" = Identifier.fromDefaultNamespace("冰精芝");
pub const @"狼桃" = Identifier.fromDefaultNamespace("狼桃");
pub const @"霸王花" = Identifier.fromDefaultNamespace("霸王花");
pub const @"太清玄灵草" = Identifier.fromDefaultNamespace("太清玄灵草");
pub const @"冥胎骨" = Identifier.fromDefaultNamespace("冥胎骨");
pub const @"地龙干" = Identifier.fromDefaultNamespace("地龙干");
pub const @"龙须藤" = Identifier.fromDefaultNamespace("龙须藤");
pub const @"鬼面花" = Identifier.fromDefaultNamespace("鬼面花");
pub const @"梧桐木" = Identifier.fromDefaultNamespace("梧桐木");

pub fn init(_: *SoulCampfire.command.Command) !void {
    log.debug("loading content module", .{});

    const registries = SoulCampfire.registry.Registries;

    try registries.LEVELS.?.register(@"江湖好手", &.{
        .level = 0,
        .extensible = false,
        .requirement = 0,
        .ratio = 1,
        .breakout_rate = 100,
        .name = "江湖好手",
    });
    try registries.LEVELS.?.register(@"搬血境", &.{
        .level = 1,
        .extensible = true,
        .requirement = 2000,
        .ratio = 1.2,
        .breakout_rate = 40,
        .name = "搬血境",
    });
    try registries.LEVELS.?.register(@"洞天境", &.{
        .level = 2,
        .extensible = true,
        .requirement = 8000,
        .ratio = 2.2,
        .breakout_rate = 36,
        .name = "洞天境",
    });
    try registries.LEVELS.?.register(@"化灵境", &.{
        .level = 3,
        .extensible = true,
        .requirement = 60000,
        .ratio = 3.2,
        .breakout_rate = 32,
        .name = "化灵境",
    });
    try registries.LEVELS.?.register(@"铭纹境", &.{
        .level = 4,
        .extensible = true,
        .requirement = 160000,
        .ratio = 4.2,
        .breakout_rate = 30,
        .name = "铭纹境",
    });
    try registries.LEVELS.?.register(@"列阵境", &.{
        .level = 5,
        .extensible = true,
        .requirement = 384000,
        .ratio = 5.2,
        .breakout_rate = 26,
        .name = "列阵境",
    });
    try registries.LEVELS.?.register(@"尊者境", &.{
        .level = 6,
        .extensible = true,
        .requirement = 896000,
        .ratio = 6.2,
        .breakout_rate = 25,
        .name = "尊者境",
    });
    try registries.LEVELS.?.register(@"神火境", &.{
        .level = 7,
        .extensible = true,
        .requirement = 2048000,
        .ratio = 7.2,
        .breakout_rate = 20,
        .name = "神火境",
    });
    try registries.LEVELS.?.register(@"真一境", &.{
        .level = 8,
        .extensible = true,
        .requirement = 4608000,
        .ratio = 8.2,
        .breakout_rate = 18,
        .name = "真一境",
    });
    try registries.LEVELS.?.register(@"圣祭境", &.{
        .level = 9,
        .extensible = true,
        .requirement = 12348000,
        .ratio = 9.2,
        .breakout_rate = 15,
        .name = "圣祭境",
    });
    try registries.LEVELS.?.register(@"天神境", &.{
        .level = 10,
        .extensible = true,
        .requirement = 35968000,
        .ratio = 13,
        .breakout_rate = 12,
        .name = "天神境",
    });
    try registries.LEVELS.?.register(@"虚道境", &.{
        .level = 11,
        .extensible = true,
        .requirement = 70968000,
        .ratio = 16,
        .breakout_rate = 10,
        .name = "虚道境",
    });
    try registries.LEVELS.?.register(@"斩我境", &.{
        .level = 12,
        .extensible = true,
        .requirement = 140968000,
        .ratio = 19,
        .breakout_rate = 5,
        .name = "斩我境",
    });
    try registries.LEVELS.?.register(@"遁一境", &.{
        .level = 13,
        .extensible = true,
        .requirement = 450710400,
        .ratio = 22,
        .breakout_rate = 3,
        .name = "遁一境",
    });
    try registries.LEVELS.?.register(@"至尊境", &.{
        .level = 14,
        .extensible = true,
        .requirement = 1622557440,
        .ratio = 25,
        .breakout_rate = 1,
        .name = "至尊境",
    });
    try registries.LEVELS.?.register(@"真仙境", &.{
        .level = 15,
        .extensible = true,
        .requirement = 5841206784,
        .ratio = 28,
        .breakout_rate = 0,
        .name = "真仙境",
    });
    try registries.LEVELS.?.register(@"仙王境", &.{
        .level = 16,
        .extensible = true,
        .requirement = 21028344422,
        .ratio = 31,
        .breakout_rate = 0,
        .name = "仙王境",
    });
    try registries.LEVELS.?.register(@"准帝境", &.{
        .level = 17,
        .extensible = true,
        .requirement = 75702039920,
        .ratio = 34,
        .breakout_rate = 0,
        .name = "准帝境",
    });
    try registries.LEVELS.?.register(@"仙帝境", &.{
        .level = 18,
        .extensible = true,
        .requirement = 272527343704,
        .ratio = 37,
        .breakout_rate = 0,
        .name = "仙帝境",
    });
    try registries.LEVELS.?.register(@"祭道之上", &.{
        .level = 19,
        .extensible = false,
        .requirement = 999999999999,
        .ratio = 38,
        .breakout_rate = 0,
        .name = "祭道之上",
    });

    try registries.ALCHEMIST_ATELIER_LEVEL.?.register(@"黄级", &.{ .name = "黄级", .level = 1, .cost_scale = 50000000, .cost_stone = 200000 });
    try registries.ALCHEMIST_ATELIER_LEVEL.?.register(@"玄级", &.{ .name = "玄级", .level = 2, .cost_scale = 60000000, .cost_stone = 400000 });
    try registries.ALCHEMIST_ATELIER_LEVEL.?.register(@"地级", &.{ .name = "地级", .level = 3, .cost_scale = 70000000, .cost_stone = 800000 });
    try registries.ALCHEMIST_ATELIER_LEVEL.?.register(@"天级", &.{ .name = "天级", .level = 4, .cost_scale = 80000000, .cost_stone = 1600000 });
    try registries.ALCHEMIST_ATELIER_LEVEL.?.register(@"仙级", &.{ .name = "仙级", .level = 5, .cost_scale = 100000000, .cost_stone = 3200000 });

    try registries.HERB_TRAIT.?.register(@"生息", &.{ .name = "生息" });
    try registries.HERB_TRAIT.?.register(@"养气", &.{ .name = "养气" });
    try registries.HERB_TRAIT.?.register(@"炼气", &.{ .name = "炼气" });
    try registries.HERB_TRAIT.?.register(@"聚元", &.{ .name = "聚元" });
    try registries.HERB_TRAIT.?.register(@"凝神", &.{ .name = "凝神" });

    try registries.ITEMS.?.register(@"恒心草", &.{
        .name = "恒心草",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"生息", .power = 2 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 2 },
                .auxiliary = .{ .trait = @"养气", .power = 2 },
            },
        },
    });
    try registries.ITEMS.?.register(@"红绫草", &.{
        .name = "红绫草",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"生息", .power = 2 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 2 },
                .auxiliary = .{ .trait = @"养气", .power = 2 },
            },
        },
    });
    try registries.ITEMS.?.register(@"罗犀草", &.{
        .name = "罗犀草",
        .type = .{
            .herb = .{
                .main = .{ .temp = -1, .trait = @"生息", .power = 2 },
                .guiding = .{ .temp = 1, .trait = @"生息", .power = 2 },
                .auxiliary = .{ .trait = @"养气", .power = 2 },
            },
        },
    });
    try registries.ITEMS.?.register(@"天青花", &.{
        .name = "天青花",
        .type = .{
            .herb = .{
                .main = .{ .temp = 1, .trait = @"生息", .power = 2 },
                .guiding = .{ .temp = -1, .trait = @"生息", .power = 2 },
                .auxiliary = .{ .trait = @"养气", .power = 2 },
            },
        },
    });
    try registries.ITEMS.?.register(@"五柳根", &.{
        .name = "五柳根",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"生息", .power = 4 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 4 },
                .auxiliary = .{ .trait = @"养气", .power = 4 },
            },
        },
    });
    try registries.ITEMS.?.register(@"天元果", &.{
        .name = "天元果",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"生息", .power = 4 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 4 },
                .auxiliary = .{ .trait = @"养气", .power = 4 },
            },
        },
    });
    try registries.ITEMS.?.register(@"何首乌", &.{
        .name = "何首乌",
        .type = .{
            .herb = .{
                .main = .{ .temp = -1, .trait = @"生息", .power = 4 },
                .guiding = .{ .temp = 1, .trait = @"生息", .power = 4 },
                .auxiliary = .{ .trait = @"养气", .power = 4 },
            },
        },
    });
    try registries.ITEMS.?.register(@"夜交藤", &.{
        .name = "夜交藤",
        .type = .{
            .herb = .{
                .main = .{ .temp = 1, .trait = @"生息", .power = 4 },
                .guiding = .{ .temp = -1, .trait = @"生息", .power = 4 },
                .auxiliary = .{ .trait = @"养气", .power = 4 },
            },
        },
    });
    try registries.ITEMS.?.register(@"紫猴花", &.{
        .name = "紫猴花",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"生息", .power = 8 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 8 },
                .auxiliary = .{ .trait = @"养气", .power = 8 },
            },
        },
    });
    try registries.ITEMS.?.register(@"九叶芝", &.{
        .name = "九叶芝",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"生息", .power = 8 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 8 },
                .auxiliary = .{ .trait = @"养气", .power = 8 },
            },
        },
    });
    try registries.ITEMS.?.register(@"幻心草", &.{
        .name = "幻心草",
        .type = .{
            .herb = .{
                .main = .{ .temp = -1, .trait = @"生息", .power = 8 },
                .guiding = .{ .temp = 1, .trait = @"生息", .power = 8 },
                .auxiliary = .{ .trait = @"养气", .power = 8 },
            },
        },
    });
    try registries.ITEMS.?.register(@"鬼臼草", &.{
        .name = "鬼臼草",
        .type = .{
            .herb = .{
                .main = .{ .temp = 1, .trait = @"生息", .power = 8 },
                .guiding = .{ .temp = -1, .trait = @"生息", .power = 8 },
                .auxiliary = .{ .trait = @"养气", .power = 8 },
            },
        },
    });
    try registries.ITEMS.?.register(@"血莲精", &.{
        .name = "血莲精",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"生息", .power = 16 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 16 },
                .auxiliary = .{ .trait = @"养气", .power = 16 },
            },
        },
    });
    try registries.ITEMS.?.register(@"鸡冠草", &.{
        .name = "鸡冠草",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"生息", .power = 16 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 16 },
                .auxiliary = .{ .trait = @"养气", .power = 16 },
            },
        },
    });
    try registries.ITEMS.?.register(@"银精芝", &.{
        .name = "银精芝",
        .type = .{
            .herb = .{
                .main = .{ .temp = -1, .trait = @"生息", .power = 16 },
                .guiding = .{ .temp = 1, .trait = @"生息", .power = 16 },
                .auxiliary = .{ .trait = @"养气", .power = 16 },
            },
        },
    });
    try registries.ITEMS.?.register(@"玉髓芝", &.{
        .name = "玉髓芝",
        .type = .{
            .herb = .{
                .main = .{ .temp = 1, .trait = @"生息", .power = 16 },
                .guiding = .{ .temp = -1, .trait = @"生息", .power = 16 },
                .auxiliary = .{ .trait = @"养气", .power = 16 },
            },
        },
    });
    try registries.ITEMS.?.register(@"地心火芝", &.{
        .name = "地心火芝",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"生息", .power = 32 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 32 },
                .auxiliary = .{ .trait = @"养气", .power = 32 },
            },
        },
    });
    try registries.ITEMS.?.register(@"天蝉灵叶", &.{
        .name = "天蝉灵叶",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"生息", .power = 32 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 32 },
                .auxiliary = .{ .trait = @"养气", .power = 32 },
            },
        },
    });
    try registries.ITEMS.?.register(@"雪玉骨参", &.{
        .name = "雪玉骨参",
        .type = .{
            .herb = .{
                .main = .{ .temp = -1, .trait = @"生息", .power = 32 },
                .guiding = .{ .temp = 1, .trait = @"生息", .power = 32 },
                .auxiliary = .{ .trait = @"养气", .power = 32 },
            },
        },
    });
    try registries.ITEMS.?.register(@"腐骨灵花", &.{
        .name = "腐骨灵花",
        .type = .{
            .herb = .{
                .main = .{ .temp = 1, .trait = @"生息", .power = 32 },
                .guiding = .{ .temp = -1, .trait = @"生息", .power = 32 },
                .auxiliary = .{ .trait = @"养气", .power = 32 },
            },
        },
    });
    try registries.ITEMS.?.register(@"三叶青芝", &.{
        .name = "三叶青芝",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"生息", .power = 64 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 64 },
                .auxiliary = .{ .trait = @"养气", .power = 64 },
            },
        },
    });
    try registries.ITEMS.?.register(@"七彩月兰", &.{
        .name = "七彩月兰",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"生息", .power = 64 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 64 },
                .auxiliary = .{ .trait = @"养气", .power = 64 },
            },
        },
    });
    try registries.ITEMS.?.register(@"三尾风叶", &.{
        .name = "三尾风叶",
        .type = .{
            .herb = .{
                .main = .{ .temp = -1, .trait = @"生息", .power = 64 },
                .guiding = .{ .temp = 1, .trait = @"生息", .power = 64 },
                .auxiliary = .{ .trait = @"养气", .power = 64 },
            },
        },
    });
    try registries.ITEMS.?.register(@"冰灵焰草", &.{
        .name = "冰灵焰草",
        .type = .{
            .herb = .{
                .main = .{ .temp = 1, .trait = @"生息", .power = 64 },
                .guiding = .{ .temp = -1, .trait = @"生息", .power = 64 },
                .auxiliary = .{ .trait = @"养气", .power = 64 },
            },
        },
    });
    try registries.ITEMS.?.register(@"地心淬灵乳", &.{
        .name = "地心淬灵乳",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"生息", .power = 128 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 128 },
                .auxiliary = .{ .trait = @"养气", .power = 128 },
            },
        },
    });
    try registries.ITEMS.?.register(@"天麻翡石精", &.{
        .name = "天麻翡石精",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"生息", .power = 128 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 128 },
                .auxiliary = .{ .trait = @"养气", .power = 128 },
            },
        },
    });
    try registries.ITEMS.?.register(@"八角玄冰草", &.{
        .name = "八角玄冰草",
        .type = .{
            .herb = .{
                .main = .{ .temp = -1, .trait = @"生息", .power = 128 },
                .guiding = .{ .temp = 1, .trait = @"生息", .power = 128 },
                .auxiliary = .{ .trait = @"养气", .power = 128 },
            },
        },
    });
    try registries.ITEMS.?.register(@"奇茸通天菊", &.{
        .name = "奇茸通天菊",
        .type = .{
            .herb = .{
                .main = .{ .temp = 1, .trait = @"生息", .power = 128 },
                .guiding = .{ .temp = -1, .trait = @"生息", .power = 128 },
                .auxiliary = .{ .trait = @"养气", .power = 128 },
            },
        },
    });
    try registries.ITEMS.?.register(@"木灵三针花", &.{
        .name = "木灵三针花",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"生息", .power = 256 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 256 },
                .auxiliary = .{ .trait = @"养气", .power = 256 },
            },
        },
    });
    try registries.ITEMS.?.register(@"鎏鑫天晶草", &.{
        .name = "鎏鑫天晶草",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"生息", .power = 256 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 256 },
                .auxiliary = .{ .trait = @"养气", .power = 256 },
            },
        },
    });
    try registries.ITEMS.?.register(@"檀芒九叶花", &.{
        .name = "檀芒九叶花",
        .type = .{
            .herb = .{
                .main = .{ .temp = -1, .trait = @"生息", .power = 256 },
                .guiding = .{ .temp = 1, .trait = @"生息", .power = 256 },
                .auxiliary = .{ .trait = @"养气", .power = 256 },
            },
        },
    });
    try registries.ITEMS.?.register(@"坎水玄冰果", &.{
        .name = "坎水玄冰果",
        .type = .{
            .herb = .{
                .main = .{ .temp = 1, .trait = @"生息", .power = 256 },
                .guiding = .{ .temp = -1, .trait = @"生息", .power = 256 },
                .auxiliary = .{ .trait = @"养气", .power = 256 },
            },
        },
    });
    try registries.ITEMS.?.register(@"离火梧桐芝", &.{
        .name = "离火梧桐芝",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"生息", .power = 512 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 512 },
                .auxiliary = .{ .trait = @"养气", .power = 512 },
            },
        },
    });
    try registries.ITEMS.?.register(@"尘磊岩麟果", &.{
        .name = "尘磊岩麟果",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"生息", .power = 512 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 512 },
                .auxiliary = .{ .trait = @"养气", .power = 512 },
            },
        },
    });
    try registries.ITEMS.?.register(@"剑魄竹笋", &.{
        .name = "剑魄竹笋",
        .type = .{
            .herb = .{
                .main = .{ .temp = -1, .trait = @"生息", .power = 512 },
                .guiding = .{ .temp = 1, .trait = @"生息", .power = 512 },
                .auxiliary = .{ .trait = @"养气", .power = 512 },
            },
        },
    });
    try registries.ITEMS.?.register(@"明心问道果", &.{
        .name = "明心问道果",
        .type = .{
            .herb = .{
                .main = .{ .temp = 1, .trait = @"生息", .power = 512 },
                .guiding = .{ .temp = -1, .trait = @"生息", .power = 512 },
                .auxiliary = .{ .trait = @"养气", .power = 512 },
            },
        },
    });
    try registries.ITEMS.?.register(@"宁心草", &.{
        .name = "宁心草",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"养气", .power = 2 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 2 },
                .auxiliary = .{ .trait = @"炼气", .power = 2 },
            },
        },
    });
    try registries.ITEMS.?.register(@"凝血草", &.{
        .name = "凝血草",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"养气", .power = 2 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 2 },
                .auxiliary = .{ .trait = @"炼气", .power = 2 },
            },
        },
    });
    try registries.ITEMS.?.register(@"银月花", &.{
        .name = "银月花",
        .type = .{
            .herb = .{
                .main = .{ .temp = -1, .trait = @"养气", .power = 2 },
                .guiding = .{ .temp = 1, .trait = @"生息", .power = 2 },
                .auxiliary = .{ .trait = @"炼气", .power = 2 },
            },
        },
    });
    try registries.ITEMS.?.register(@"宁神花", &.{
        .name = "宁神花",
        .type = .{
            .herb = .{
                .main = .{ .temp = 1, .trait = @"养气", .power = 2 },
                .guiding = .{ .temp = -1, .trait = @"生息", .power = 2 },
                .auxiliary = .{ .trait = @"炼气", .power = 2 },
            },
        },
    });
    try registries.ITEMS.?.register(@"流莹草", &.{
        .name = "流莹草",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"养气", .power = 4 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 4 },
                .auxiliary = .{ .trait = @"炼气", .power = 4 },
            },
        },
    });
    try registries.ITEMS.?.register(@"蛇涎果", &.{
        .name = "蛇涎果",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"养气", .power = 4 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 4 },
                .auxiliary = .{ .trait = @"炼气", .power = 4 },
            },
        },
    });
    try registries.ITEMS.?.register(@"夏枯草", &.{
        .name = "夏枯草",
        .type = .{
            .herb = .{
                .main = .{ .temp = -1, .trait = @"养气", .power = 4 },
                .guiding = .{ .temp = 1, .trait = @"生息", .power = 4 },
                .auxiliary = .{ .trait = @"炼气", .power = 4 },
            },
        },
    });
    try registries.ITEMS.?.register(@"百草露", &.{
        .name = "百草露",
        .type = .{
            .herb = .{
                .main = .{ .temp = 1, .trait = @"养气", .power = 4 },
                .guiding = .{ .temp = -1, .trait = @"生息", .power = 4 },
                .auxiliary = .{ .trait = @"炼气", .power = 4 },
            },
        },
    });
    try registries.ITEMS.?.register(@"轻灵草", &.{
        .name = "轻灵草",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"养气", .power = 8 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 8 },
                .auxiliary = .{ .trait = @"炼气", .power = 8 },
            },
        },
    });
    try registries.ITEMS.?.register(@"龙葵", &.{
        .name = "龙葵",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"养气", .power = 8 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 8 },
                .auxiliary = .{ .trait = @"炼气", .power = 8 },
            },
        },
    });
    try registries.ITEMS.?.register(@"弗兰草", &.{
        .name = "弗兰草",
        .type = .{
            .herb = .{
                .main = .{ .temp = -1, .trait = @"养气", .power = 8 },
                .guiding = .{ .temp = 1, .trait = @"生息", .power = 8 },
                .auxiliary = .{ .trait = @"炼气", .power = 8 },
            },
        },
    });
    try registries.ITEMS.?.register(@"玄参", &.{
        .name = "玄参",
        .type = .{
            .herb = .{
                .main = .{ .temp = 1, .trait = @"养气", .power = 8 },
                .guiding = .{ .temp = -1, .trait = @"生息", .power = 8 },
                .auxiliary = .{ .trait = @"炼气", .power = 8 },
            },
        },
    });
    try registries.ITEMS.?.register(@"菩提花", &.{
        .name = "菩提花",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"养气", .power = 16 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 16 },
                .auxiliary = .{ .trait = @"炼气", .power = 16 },
            },
        },
    });
    try registries.ITEMS.?.register(@"乌稠木", &.{
        .name = "乌稠木",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"养气", .power = 16 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 16 },
                .auxiliary = .{ .trait = @"炼气", .power = 16 },
            },
        },
    });
    try registries.ITEMS.?.register(@"雪凝花", &.{
        .name = "雪凝花",
        .type = .{
            .herb = .{
                .main = .{ .temp = -1, .trait = @"养气", .power = 16 },
                .guiding = .{ .temp = 1, .trait = @"生息", .power = 16 },
                .auxiliary = .{ .trait = @"炼气", .power = 16 },
            },
        },
    });
    try registries.ITEMS.?.register(@"龙纹草", &.{
        .name = "龙纹草",
        .type = .{
            .herb = .{
                .main = .{ .temp = 1, .trait = @"养气", .power = 16 },
                .guiding = .{ .temp = -1, .trait = @"生息", .power = 16 },
                .auxiliary = .{ .trait = @"炼气", .power = 16 },
            },
        },
    });
    try registries.ITEMS.?.register(@"天灵果", &.{
        .name = "天灵果",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"养气", .power = 32 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 32 },
                .auxiliary = .{ .trait = @"炼气", .power = 32 },
            },
        },
    });
    try registries.ITEMS.?.register(@"灯心草", &.{
        .name = "灯心草",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"养气", .power = 32 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 32 },
                .auxiliary = .{ .trait = @"炼气", .power = 32 },
            },
        },
    });
    try registries.ITEMS.?.register(@"穿心莲", &.{
        .name = "穿心莲",
        .type = .{
            .herb = .{
                .main = .{ .temp = -1, .trait = @"养气", .power = 32 },
                .guiding = .{ .temp = 1, .trait = @"生息", .power = 32 },
                .auxiliary = .{ .trait = @"炼气", .power = 32 },
            },
        },
    });
    try registries.ITEMS.?.register(@"龙鳞果", &.{
        .name = "龙鳞果",
        .type = .{
            .herb = .{
                .main = .{ .temp = 1, .trait = @"养气", .power = 32 },
                .guiding = .{ .temp = -1, .trait = @"生息", .power = 32 },
                .auxiliary = .{ .trait = @"炼气", .power = 32 },
            },
        },
    });
    try registries.ITEMS.?.register(@"白沉脂", &.{
        .name = "白沉脂",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"养气", .power = 64 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 64 },
                .auxiliary = .{ .trait = @"炼气", .power = 64 },
            },
        },
    });
    try registries.ITEMS.?.register(@"苦曼藤", &.{
        .name = "苦曼藤",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"养气", .power = 64 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 64 },
                .auxiliary = .{ .trait = @"炼气", .power = 64 },
            },
        },
    });
    try registries.ITEMS.?.register(@"血菩提", &.{
        .name = "血菩提",
        .type = .{
            .herb = .{
                .main = .{ .temp = -1, .trait = @"养气", .power = 64 },
                .guiding = .{ .temp = 1, .trait = @"生息", .power = 64 },
                .auxiliary = .{ .trait = @"炼气", .power = 64 },
            },
        },
    });
    try registries.ITEMS.?.register(@"诱妖草", &.{
        .name = "诱妖草",
        .type = .{
            .herb = .{
                .main = .{ .temp = 1, .trait = @"养气", .power = 64 },
                .guiding = .{ .temp = -1, .trait = @"生息", .power = 64 },
                .auxiliary = .{ .trait = @"炼气", .power = 64 },
            },
        },
    });
    try registries.ITEMS.?.register(@"天问花", &.{
        .name = "天问花",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"养气", .power = 128 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 128 },
                .auxiliary = .{ .trait = @"炼气", .power = 128 },
            },
        },
    });
    try registries.ITEMS.?.register(@"渊血冥花", &.{
        .name = "渊血冥花",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"养气", .power = 128 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 128 },
                .auxiliary = .{ .trait = @"炼气", .power = 128 },
            },
        },
    });
    try registries.ITEMS.?.register(@"芒焰果", &.{
        .name = "芒焰果",
        .type = .{
            .herb = .{
                .main = .{ .temp = -1, .trait = @"养气", .power = 128 },
                .guiding = .{ .temp = 1, .trait = @"生息", .power = 128 },
                .auxiliary = .{ .trait = @"炼气", .power = 128 },
            },
        },
    });
    try registries.ITEMS.?.register(@"问道花", &.{
        .name = "问道花",
        .type = .{
            .herb = .{
                .main = .{ .temp = 1, .trait = @"养气", .power = 128 },
                .guiding = .{ .temp = -1, .trait = @"生息", .power = 128 },
                .auxiliary = .{ .trait = @"炼气", .power = 128 },
            },
        },
    });
    try registries.ITEMS.?.register(@"阴阳黄泉花", &.{
        .name = "阴阳黄泉花",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"养气", .power = 256 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 256 },
                .auxiliary = .{ .trait = @"炼气", .power = 256 },
            },
        },
    });
    try registries.ITEMS.?.register(@"厉魂血珀", &.{
        .name = "厉魂血珀",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"养气", .power = 256 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 256 },
                .auxiliary = .{ .trait = @"炼气", .power = 256 },
            },
        },
    });
    try registries.ITEMS.?.register(@"浩淼水藤", &.{
        .name = "浩淼水藤",
        .type = .{
            .herb = .{
                .main = .{ .temp = -1, .trait = @"养气", .power = 256 },
                .guiding = .{ .temp = 1, .trait = @"生息", .power = 256 },
                .auxiliary = .{ .trait = @"炼气", .power = 256 },
            },
        },
    });
    try registries.ITEMS.?.register(@"道蕴花", &.{
        .name = "道蕴花",
        .type = .{
            .herb = .{
                .main = .{ .temp = 1, .trait = @"养气", .power = 256 },
                .guiding = .{ .temp = -1, .trait = @"生息", .power = 256 },
                .auxiliary = .{ .trait = @"炼气", .power = 256 },
            },
        },
    });
    try registries.ITEMS.?.register(@"太乙碧莹花", &.{
        .name = "太乙碧莹花",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"养气", .power = 512 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 512 },
                .auxiliary = .{ .trait = @"炼气", .power = 512 },
            },
        },
    });
    try registries.ITEMS.?.register(@"森檀木", &.{
        .name = "森檀木",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"养气", .power = 512 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 512 },
                .auxiliary = .{ .trait = @"炼气", .power = 512 },
            },
        },
    });
    try registries.ITEMS.?.register(@"炼心芝", &.{
        .name = "炼心芝",
        .type = .{
            .herb = .{
                .main = .{ .temp = -1, .trait = @"养气", .power = 512 },
                .guiding = .{ .temp = 1, .trait = @"生息", .power = 512 },
                .auxiliary = .{ .trait = @"炼气", .power = 512 },
            },
        },
    });
    try registries.ITEMS.?.register(@"重元换血草", &.{
        .name = "重元换血草",
        .type = .{
            .herb = .{
                .main = .{ .temp = 1, .trait = @"养气", .power = 512 },
                .guiding = .{ .temp = -1, .trait = @"生息", .power = 512 },
                .auxiliary = .{ .trait = @"炼气", .power = 512 },
            },
        },
    });
    try registries.ITEMS.?.register(@"地黄参", &.{
        .name = "地黄参",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"聚元", .power = 2 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 2 },
                .auxiliary = .{ .trait = @"凝神", .power = 2 },
            },
        },
    });
    try registries.ITEMS.?.register(@"火精枣", &.{
        .name = "火精枣",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"聚元", .power = 2 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 2 },
                .auxiliary = .{ .trait = @"凝神", .power = 2 },
            },
        },
    });
    try registries.ITEMS.?.register(@"剑芦", &.{
        .name = "剑芦",
        .type = .{
            .herb = .{
                .main = .{ .temp = -1, .trait = @"聚元", .power = 2 },
                .guiding = .{ .temp = 1, .trait = @"生息", .power = 2 },
                .auxiliary = .{ .trait = @"凝神", .power = 2 },
            },
        },
    });
    try registries.ITEMS.?.register(@"七星草", &.{
        .name = "七星草",
        .type = .{
            .herb = .{
                .main = .{ .temp = 1, .trait = @"聚元", .power = 2 },
                .guiding = .{ .temp = -1, .trait = @"生息", .power = 2 },
                .auxiliary = .{ .trait = @"凝神", .power = 2 },
            },
        },
    });
    try registries.ITEMS.?.register(@"风灵花", &.{
        .name = "风灵花",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"聚元", .power = 4 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 4 },
                .auxiliary = .{ .trait = @"凝神", .power = 4 },
            },
        },
    });
    try registries.ITEMS.?.register(@"伏龙参", &.{
        .name = "伏龙参",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"聚元", .power = 4 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 4 },
                .auxiliary = .{ .trait = @"凝神", .power = 4 },
            },
        },
    });
    try registries.ITEMS.?.register(@"凌风花", &.{
        .name = "凌风花",
        .type = .{
            .herb = .{
                .main = .{ .temp = -1, .trait = @"聚元", .power = 4 },
                .guiding = .{ .temp = 1, .trait = @"生息", .power = 4 },
                .auxiliary = .{ .trait = @"凝神", .power = 4 },
            },
        },
    });
    try registries.ITEMS.?.register(@"补天芝", &.{
        .name = "补天芝",
        .type = .{
            .herb = .{
                .main = .{ .temp = 1, .trait = @"聚元", .power = 4 },
                .guiding = .{ .temp = -1, .trait = @"生息", .power = 4 },
                .auxiliary = .{ .trait = @"凝神", .power = 4 },
            },
        },
    });
    try registries.ITEMS.?.register(@"枫香脂", &.{
        .name = "枫香脂",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"聚元", .power = 8 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 8 },
                .auxiliary = .{ .trait = @"凝神", .power = 8 },
            },
        },
    });
    try registries.ITEMS.?.register(@"炼魂珠", &.{
        .name = "炼魂珠",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"聚元", .power = 8 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 8 },
                .auxiliary = .{ .trait = @"凝神", .power = 8 },
            },
        },
    });
    try registries.ITEMS.?.register(@"玄冰花", &.{
        .name = "玄冰花",
        .type = .{
            .herb = .{
                .main = .{ .temp = -1, .trait = @"聚元", .power = 8 },
                .guiding = .{ .temp = 1, .trait = @"生息", .power = 8 },
                .auxiliary = .{ .trait = @"凝神", .power = 8 },
            },
        },
    });
    try registries.ITEMS.?.register(@"炼血珠", &.{
        .name = "炼血珠",
        .type = .{
            .herb = .{
                .main = .{ .temp = 1, .trait = @"聚元", .power = 8 },
                .guiding = .{ .temp = -1, .trait = @"生息", .power = 8 },
                .auxiliary = .{ .trait = @"凝神", .power = 8 },
            },
        },
    });
    try registries.ITEMS.?.register(@"石龙芮", &.{
        .name = "石龙芮",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"聚元", .power = 16 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 16 },
                .auxiliary = .{ .trait = @"凝神", .power = 16 },
            },
        },
    });
    try registries.ITEMS.?.register(@"锦地罗", &.{
        .name = "锦地罗",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"聚元", .power = 16 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 16 },
                .auxiliary = .{ .trait = @"凝神", .power = 16 },
            },
        },
    });
    try registries.ITEMS.?.register(@"冰灵果", &.{
        .name = "冰灵果",
        .type = .{
            .herb = .{
                .main = .{ .temp = -1, .trait = @"聚元", .power = 16 },
                .guiding = .{ .temp = 1, .trait = @"生息", .power = 16 },
                .auxiliary = .{ .trait = @"凝神", .power = 16 },
            },
        },
    });
    try registries.ITEMS.?.register(@"玉龙参", &.{
        .name = "玉龙参",
        .type = .{
            .herb = .{
                .main = .{ .temp = 1, .trait = @"聚元", .power = 16 },
                .guiding = .{ .temp = -1, .trait = @"生息", .power = 16 },
                .auxiliary = .{ .trait = @"凝神", .power = 16 },
            },
        },
    });
    try registries.ITEMS.?.register(@"伴妖草", &.{
        .name = "伴妖草",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"聚元", .power = 32 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 32 },
                .auxiliary = .{ .trait = @"凝神", .power = 32 },
            },
        },
    });
    try registries.ITEMS.?.register(@"剑心竹", &.{
        .name = "剑心竹",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"聚元", .power = 32 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 32 },
                .auxiliary = .{ .trait = @"凝神", .power = 32 },
            },
        },
    });
    try registries.ITEMS.?.register(@"绝魂草", &.{
        .name = "绝魂草",
        .type = .{
            .herb = .{
                .main = .{ .temp = -1, .trait = @"聚元", .power = 32 },
                .guiding = .{ .temp = 1, .trait = @"生息", .power = 32 },
                .auxiliary = .{ .trait = @"凝神", .power = 32 },
            },
        },
    });
    try registries.ITEMS.?.register(@"月灵花", &.{
        .name = "月灵花",
        .type = .{
            .herb = .{
                .main = .{ .temp = 1, .trait = @"聚元", .power = 32 },
                .guiding = .{ .temp = -1, .trait = @"生息", .power = 32 },
                .auxiliary = .{ .trait = @"凝神", .power = 32 },
            },
        },
    });
    try registries.ITEMS.?.register(@"混元果", &.{
        .name = "混元果",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"聚元", .power = 64 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 64 },
                .auxiliary = .{ .trait = @"凝神", .power = 64 },
            },
        },
    });
    try registries.ITEMS.?.register(@"皇龙花", &.{
        .name = "皇龙花",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"聚元", .power = 64 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 64 },
                .auxiliary = .{ .trait = @"凝神", .power = 64 },
            },
        },
    });
    try registries.ITEMS.?.register(@"天剑笋", &.{
        .name = "天剑笋",
        .type = .{
            .herb = .{
                .main = .{ .temp = -1, .trait = @"聚元", .power = 64 },
                .guiding = .{ .temp = 1, .trait = @"凝神", .power = 64 },
                .auxiliary = .{ .trait = @"养气", .power = 64 },
            },
        },
    });
    try registries.ITEMS.?.register(@"黑天麻", &.{
        .name = "黑天麻",
        .type = .{
            .herb = .{
                .main = .{ .temp = 1, .trait = @"聚元", .power = 64 },
                .guiding = .{ .temp = -1, .trait = @"生息", .power = 64 },
                .auxiliary = .{ .trait = @"凝神", .power = 64 },
            },
        },
    });
    try registries.ITEMS.?.register(@"血玉竹", &.{
        .name = "血玉竹",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"聚元", .power = 128 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 128 },
                .auxiliary = .{ .trait = @"凝神", .power = 128 },
            },
        },
    });
    try registries.ITEMS.?.register(@"肠蚀草", &.{
        .name = "肠蚀草",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"聚元", .power = 128 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 128 },
                .auxiliary = .{ .trait = @"凝神", .power = 128 },
            },
        },
    });
    try registries.ITEMS.?.register(@"凤血果", &.{
        .name = "凤血果",
        .type = .{
            .herb = .{
                .main = .{ .temp = -1, .trait = @"聚元", .power = 128 },
                .guiding = .{ .temp = 1, .trait = @"生息", .power = 128 },
                .auxiliary = .{ .trait = @"凝神", .power = 128 },
            },
        },
    });
    try registries.ITEMS.?.register(@"冰精芝", &.{
        .name = "冰精芝",
        .type = .{
            .herb = .{
                .main = .{ .temp = 1, .trait = @"聚元", .power = 128 },
                .guiding = .{ .temp = -1, .trait = @"生息", .power = 128 },
                .auxiliary = .{ .trait = @"凝神", .power = 128 },
            },
        },
    });
    try registries.ITEMS.?.register(@"狼桃", &.{
        .name = "狼桃",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"聚元", .power = 256 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 256 },
                .auxiliary = .{ .trait = @"凝神", .power = 256 },
            },
        },
    });
    try registries.ITEMS.?.register(@"霸王花", &.{
        .name = "霸王花",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"聚元", .power = 256 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 256 },
                .auxiliary = .{ .trait = @"凝神", .power = 256 },
            },
        },
    });
    try registries.ITEMS.?.register(@"太清玄灵草", &.{
        .name = "太清玄灵草",
        .type = .{
            .herb = .{
                .main = .{ .temp = -1, .trait = @"聚元", .power = 256 },
                .guiding = .{ .temp = 1, .trait = @"生息", .power = 256 },
                .auxiliary = .{ .trait = @"凝神", .power = 256 },
            },
        },
    });
    try registries.ITEMS.?.register(@"冥胎骨", &.{
        .name = "冥胎骨",
        .type = .{
            .herb = .{
                .main = .{ .temp = 1, .trait = @"聚元", .power = 256 },
                .guiding = .{ .temp = -1, .trait = @"生息", .power = 256 },
                .auxiliary = .{ .trait = @"凝神", .power = 256 },
            },
        },
    });
    try registries.ITEMS.?.register(@"地龙干", &.{
        .name = "地龙干",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"聚元", .power = 512 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 512 },
                .auxiliary = .{ .trait = @"凝神", .power = 512 },
            },
        },
    });
    try registries.ITEMS.?.register(@"龙须藤", &.{
        .name = "龙须藤",
        .type = .{
            .herb = .{
                .main = .{ .temp = 0, .trait = @"聚元", .power = 512 },
                .guiding = .{ .temp = 0, .trait = @"生息", .power = 512 },
                .auxiliary = .{ .trait = @"凝神", .power = 512 },
            },
        },
    });
    try registries.ITEMS.?.register(@"鬼面花", &.{
        .name = "鬼面花",
        .type = .{
            .herb = .{
                .main = .{ .temp = -1, .trait = @"聚元", .power = 512 },
                .guiding = .{ .temp = 1, .trait = @"生息", .power = 512 },
                .auxiliary = .{ .trait = @"凝神", .power = 512 },
            },
        },
    });
    try registries.ITEMS.?.register(@"梧桐木", &.{
        .name = "梧桐木",
        .type = .{
            .herb = .{
                .main = .{ .temp = 1, .trait = @"聚元", .power = 512 },
                .guiding = .{ .temp = -1, .trait = @"生息", .power = 512 },
                .auxiliary = .{ .trait = @"凝神", .power = 512 },
            },
        },
    });
}
