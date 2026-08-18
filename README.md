# Soul Campfire

一个群聊修仙小游戏

## OneBot v11

`src/onebot.zig` 提供基于 SnowLuma OneBot v11 HTTP API 的 Zig 客户端和反向 HTTP 事件接收器。

客户端的 `call` 方法覆盖文档中的全部动作。公开接口使用 Zig 参数结构体，响应通过 `Response.parse(T)` 使用 `std.json.parseFromSlice` 反序列化：

```zig
const onebot = @import("SoulCampfire").onebot;
const allocator = std.heap.page_allocator;

var bot = onebot.Client.init(allocator, "http://127.0.0.1:3000", "access-token");
var response = try bot.call("get_status", .{});
defer response.deinit();
const result = try response.parse(struct {
    status: []const u8,
    retcode: i64,
    data: struct { online: bool },
});
defer result.deinit();
if (!std.mem.eql(u8, result.value.status, "ok")) return error.OneBotActionFailed;
```

`src/onebot_actions.zig` 是由 `tools/catalog.json` 生成的完整动作绑定，当前包含 191 个规范动作和 6 个别名。调用方式为 `onebot_actions.actions.getStatus(&bot, .{})`；每个动作对应一个 `XxxParams` 参数结构体。重新生成绑定：

```bash
node tools/generate-onebot-actions.mjs
zig fmt src/onebot_actions.zig
```

例如调用 SnowLuma 的群列表接口：

```zig
var response = try onebot_actions.actions.getGroupList(&bot, .{});
defer response.deinit();
```

流式动作同样已生成绑定并在源码注释中标记为 `stream`。它们使用 SnowLuma 的多帧 HTTP 响应协议，应传入 `onebot.StreamHandler`，由 `Client.callStream` 逐帧回调。

SnowLuma 反向 HTTP 事件客户端通过 `httpClients` 向你的监听器 `POST` 事件。`EventServer` 校验 `X-Signature: sha1=<HMAC-SHA1>`，事件回调返回后响应 `200 OK`：

```zig
fn onEvent(event: onebot.Event, context: ?*anyopaque) void {
    _ = context;
    std.debug.print("event: {s}\n", .{@tagName(event.postType())});
}

var listener = onebot.EventServer{
    .allocator = allocator,
    .address = try std.net.Address.parseIp4("127.0.0.1", 5700),
    .access_token = "access-token",
    .handler = onEvent,
};
try listener.listen();
```

事件体以原始字节保存，可通过 `event.parse(MyEventType)` 使用 `std.json.parseFromSlice` 解析为调用方定义的 Zig 事件结构体。`event.postType()` 只读取通用 `post_type` 字段。
