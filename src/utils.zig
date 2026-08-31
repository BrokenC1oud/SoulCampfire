const std = @import("std");

const SoulCampfire = @import("SoulCampfire");

pub const chineseNumbers = [_][]const u8{ "零", "一", "二", "三", "四", "五", "六", "七", "八", "九" };

pub fn parseAtTarget(event: *const SoulCampfire.GroupMessageEvent, idx: usize) ?usize {
    if (idx >= event.value.message.len) return null;
    const seg = event.value.message[idx];
    if (seg != .at) return null;
    const data = seg.at.data;
    if (data != .object) return null;
    const qq = data.object.get("qq") orelse return null;
    if (qq != .string) return null;
    return std.fmt.parseInt(usize, qq.string, 10) catch null;
}
