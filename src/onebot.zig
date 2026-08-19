const std = @import("std");
const Allocator = std.mem.Allocator;
const http = std.http;
const Io = std.Io;
const json = std.json;
const log = std.log.scoped(.onebot);

const OnebotError = error{
    Somehow,
};

const Sender = struct {
    user_id: i64,
    nickname: []const u8,

    pub fn deinit(self: *@This(), allocator: Allocator) void {
        allocator.free(self.nickname);
    }
};

const MessageSegment = struct {
    type: []const u8,
    data: json.Value,
};

const Message = []MessageSegment;

pub const Client = struct {
    allocator: Allocator,
    endpoint: []const u8,
    token: []const u8,

    httpClient: http.Client,

    pub fn init(allocator: Allocator, io: Io, endpoint: []const u8, token: []const u8) @This() {
        const client: http.Client = .{ .allocator = allocator, .io = io };

        const clean_endpoint = std.mem.trimEnd(u8, endpoint, "/");

        return .{
            .allocator = allocator,
            .endpoint = clean_endpoint,
            .token = token,

            .httpClient = client,
        };
    }

    pub fn deinit(self: *@This()) void {
        self.httpClient.deinit();
    }

    fn Response(T: type) type {
        return struct {
            status: []u8,
            retcode: usize,
            data: T,
        };
    }

    fn call(self: *@This(), action: []const u8, params: anytype, R: type) !json.Parsed(R) {
        const url = try std.fmt.allocPrint(self.allocator, "{s}/{s}", .{ self.endpoint, action });
        defer self.allocator.free(url);

        const auth_header = try std.fmt.allocPrint(self.allocator, "Bearer {s}", .{self.token});
        defer self.allocator.free(auth_header);

        var body: std.Io.Writer.Allocating = .init(self.allocator);
        defer body.deinit();

        var stringifier: json.Stringify = .{ .writer = &body.writer, .options = .{
            .emit_null_optional_fields = true,
        } };
        try stringifier.write(params);

        var resp: std.Io.Writer.Allocating = .init(self.allocator);
        defer resp.deinit();

        var res = try self.httpClient.fetch(.{
            .location = .{ .url = url },
            .method = .POST,
            .headers = .{ .authorization = .{ .override = auth_header } },
            .payload = body.written(),
            .response_writer = &resp.writer,
        });
        if (res.status.class() != .success) {
            return OnebotError.Somehow;
        }

        log.debug("{s}", .{resp.written()});

        const parsed = try json.parseFromSlice(
            Response(R),
            self.allocator,
            resp.written(),
            .{ .ignore_unknown_fields = true },
        );

        const result: json.Parsed(R) = .{
            .arena = parsed.arena,
            .value = parsed.value.data,
        };
        return result;
    }

    pub fn canSendImage(self: *@This()) !bool {
        const result = try self.call("can_send_image", .{}, struct { yes: bool });
        defer result.deinit();

        return result.value.yes;
    }

    pub fn canSendRecord(self: *@This()) !bool {
        const result = try self.call("can_send_record", .{}, struct { yes: bool });
        defer result.deinit();

        return result.value.yes;
    }

    const LoginInfo = struct {
        user_id: usize,
        nickname: []u8,

        pub fn deinit(self: *@This(), allocator: Allocator) void {
            allocator.free(self.nickname);
        }
    };
    pub fn getLoginInfo(self: *@This()) !LoginInfo {
        const result = try self.call("get_login_info", .{}, LoginInfo);
        defer result.deinit();

        return .{
            .user_id = result.value.user_id,
            .nickname = try self.allocator.dupe(u8, result.value.nickname),
        };
    }

    const Status = struct {
        online: bool,
        good: bool,
    };
    pub fn getStatus(self: *@This()) !Status {
        const result = try self.call("get_status", .{}, Status);
        defer result.deinit();

        const owned = result.value;
        return owned;
    }

    const VersionInfo = struct {
        app_name: []u8,
        app_version: []u8,
        protocol_version: []u8,

        pub fn deinit(self: *@This(), allocator: Allocator) void {
            allocator.free(self.app_name);
            allocator.free(self.app_version);
            allocator.free(self.protocol_version);
        }
    };
    pub fn getVersionInfo(self: *@This()) !VersionInfo {
        const result = try self.call("get_version_info", .{}, VersionInfo);
        defer result.deinit();

        return .{
            .app_name = try self.allocator.dupe(u8, result.value.app_name),
            .app_version = try self.allocator.dupe(u8, result.value.app_version),
            .protocol_version = try self.allocator.dupe(u8, result.value.protocol_version),
        };
    }

    pub fn deleteMsg(self: *@This(), message_id: isize) !void {
        const result = try self.call("delete_msg", .{ .message_id = message_id }, ?struct {});
        defer result.deinit();
    }

    const MessageType = enum {
        group,
        private,
    };
    const GetMsgResp = struct {
        time: i64,
        message_type: MessageType,
        message_id: i64,
        real_id: i64,
        sender: Sender,
        message: Message,
    };
    // TODO
    pub fn getMsg(self: *@This(), message_id: isize) !json.Parsed(GetMsgResp) {
        const result = try self.call("get_msg", .{ .message_id = message_id }, GetMsgResp);

        return result;
    }

    pub fn sendGroupMsg(self: *@This(), group_id: usize, message: []const u8, options: struct { auto_escape: bool = false }) !isize {
        const result = try self.call(
            "send_group_msg",
            .{
                .group_id = group_id,
                .message = message,
                .auto_escape = options.auto_escape,
            },
            struct { message_id: isize },
        );
        defer result.deinit();

        return result.value.message_id;
    }

    pub fn sendPrivateMsg(self: *@This(), user_id: usize, message: []const u8, options: struct { group_id: ?usize = null, auto_escape: bool = false }) !isize {
        const result = try self.call(
            "send_private_msg",
            .{
                .user_id = user_id,
                .message = message,
                .group_id = options.group_id,
                .auto_escape = options.auto_escape,
            },
            struct { message_id: isize },
        );
        defer result.deinit();

        return result.value.message_id;
    }

    pub fn sendMsg(
        self: *@This(),
        message: []const u8,
        destination: union(enum) { group: usize, private: usize },
        options: struct { auto_escape: bool = false },
    ) !isize {
        const res_ty = struct { message_id: isize };
        const result = try self.call(
            "send_msg",
            .{
                .message = message,
                .message_type = @tagName(destination),
                .group_id = if (destination == .group) destination.group else null,
                .user_id = if (destination == .private) destination.private else null,
                .auto_escape = options.auto_escape,
            },
            res_ty,
        );
        defer result.deinit();

        return result.value.message_id;
    }
};
