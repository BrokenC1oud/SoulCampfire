const std = @import("std");
const Allocator = std.mem.Allocator;
const http = std.http;
const Io = std.Io;
const json = std.json;
const log = std.log.scoped(.onebot);
const net = std.Io.net;

const SoulCampfire = @import("SoulCampfire");

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

pub const Server = struct {
    allocator: Allocator,
    io: Io,
    event_queue: *Io.Queue(SoulCampfire.GroupMessageEvent),

    listener: Io.net.Server,

    accept_task: ?Io.Future(Io.Cancelable!void) = null,
    active_connections: std.atomic.Value(usize) = .init(0),
    connections: Io.Group = .init,
    listener_closed: bool = false,
    shutting_down: std.atomic.Value(bool) = .init(false),

    pub fn init(allocator: Allocator, io: Io, event_queue: *Io.Queue(SoulCampfire.GroupMessageEvent), host: []const u8, port: u16) !@This() {
        const addr = try net.IpAddress.parseIp4(host, port);
        return .{
            .allocator = allocator,
            .io = io,
            .event_queue = event_queue,
            .listener = try addr.listen(
                io,
                .{ .reuse_address = true },
            ),
        };
    }

    pub fn start(self: *@This()) !void {
        self.shutting_down.store(false, .release);
        self.accept_task = try self.io.concurrent(acceptLoop, .{self});
    }

    fn acceptLoop(self: *@This()) Io.Cancelable!void {
        while (!self.shutting_down.load(.acquire)) {
            const stream = self.listener.accept(self.io) catch |err| switch (err) {
                error.Canceled => return error.Canceled,
                error.SocketNotListening => return,
                else => {
                    log.err("http accept failed: {t}", .{err});
                    return error.Canceled;
                },
            };

            if (self.shutting_down.load(.acquire)) {
                stream.close(self.io);
                return;
            }

            _ = self.active_connections.fetchAdd(1, .acq_rel);
            self.connections.concurrent(self.io, handleConnection, .{ self, stream }) catch {
                _ = self.active_connections.fetchSub(1, .acq_rel);
                stream.close(self.io);
                return error.Canceled;
            };
        }
    }

    fn handleConnection(self: *@This(), stream: Io.net.Stream) Io.Cancelable!void {
        defer stream.close(self.io);
        defer _ = self.active_connections.fetchSub(1, .acq_rel);

        var recv_buffer: [16384]u8 = undefined;
        var connection_reader = stream.reader(self.io, &recv_buffer);
        var connection_writer = stream.writer(self.io, &.{});
        var http_server: http.Server = .init(
            &connection_reader.interface,
            &connection_writer.interface,
        );

        var request = http_server.receiveHead() catch |err| switch (err) {
            error.HttpConnectionClosing => return,
            else => {
                log.err("failed to receive http request: {t}; stream error: {?t}", .{ err, connection_reader.err });
                return;
            },
        };

        if (request.head.method != .POST) {
            log.err("non-post request got, dropped", .{});
            return;
        }

        const body_reader = request.readerExpectContinue(&.{}) catch |err| {
            log.err("failed to initialize request body reader: {t}", .{err});
            return;
        };
        const payload = body_reader.allocRemaining(self.allocator, .limited(1024 * 1024)) catch |err| {
            log.err("failed to read request payload: {t}; stream error: {?t}", .{ err, connection_reader.err });
            return;
        };
        defer self.allocator.free(payload);

        const parsed = parseEvent(self.allocator, payload) catch {
            log.warn("unimplemented onebot event, dropped", .{});
            request.respond("", .{ .status = .ok, .keep_alive = false }) catch {};
            return;
        };

        switch (parsed.value) {
            .group_message => |event| {
                log.debug("{s}", .{event.raw_message});
                self.event_queue.putOne(self.io, .{ .value = event, .arena = parsed.arena }) catch {
                    log.warn("failed putting event into queue", .{});
                };
            },
            else => {
                log.debug("unimplemented event, dropped", .{});
                parsed.deinit();
            },
        }

        request.respond("", .{ .keep_alive = false }) catch |err| {
            log.err("failed to send http response: {t}; stream error: {?t}", .{ err, connection_writer.err });
        };
    }

    pub fn shutdown(self: *@This()) void {
        if (self.shutting_down.swap(true, .acq_rel)) return;

        self.listener.socket.close(self.io);
        self.listener_closed = true;

        if (self.accept_task) |*task| {
            _ = task.await(self.io) catch {};
            self.accept_task = null;
        }

        while (self.active_connections.load(.acquire) != 0) {
            self.io.sleep(.fromMilliseconds(1), .awake) catch break;
        }

        if (self.active_connections.load(.acquire) != 0) {
            self.connections.cancel(self.io);
        } else {
            _ = self.connections.await(self.io) catch {};
        }
    }

    pub fn deinit(self: *@This()) void {
        self.shutdown();
        if (!self.listener_closed) self.listener.deinit(self.io);
        self.* = undefined;
    }

    pub const TextElement = struct {
        type: enum { text },
        data: struct { text: []const u8 },
    };

    pub const ReplyElement = struct {
        type: enum { reply },
        data: struct { id: i64 },
    };

    pub const GenericElement = struct {
        type: []const u8,
        data: json.Value,
    };

    pub const MessageElement = union(enum) {
        text: TextElement,
        reply: ReplyElement,
        face: GenericElement,
        image: GenericElement,
        at: GenericElement,
        file: GenericElement,

        pub fn jsonParse(allocator: Allocator, source: anytype, options: json.ParseOptions) !@This() {
            const value = try json.Value.jsonParse(allocator, source, options);
            return jsonParseFromValue(allocator, value, options);
        }

        pub fn jsonParseFromValue(allocator: Allocator, source: json.Value, options: json.ParseOptions) !@This() {
            if (source != .object) return error.UnexpectedToken;
            const type_value = source.object.get("type") orelse return error.MissingField;
            if (type_value != .string) return error.UnexpectedToken;

            const element_type = type_value.string;
            if (std.mem.eql(u8, element_type, "text")) {
                return .{ .text = try json.innerParseFromValue(TextElement, allocator, source, options) };
            }
            if (std.mem.eql(u8, element_type, "reply")) {
                return .{ .reply = try json.innerParseFromValue(ReplyElement, allocator, source, options) };
            }

            inline for (.{ "face", "image", "at", "file" }) |name| {
                if (std.mem.eql(u8, element_type, name)) {
                    return @unionInit(
                        @This(),
                        name,
                        try json.innerParseFromValue(GenericElement, allocator, source, options),
                    );
                }
            }
            return error.InvalidEnumTag;
        }
    };

    pub const EventSender = struct {
        user_id: i64,
        nickname: ?[]const u8 = null,
        card: ?[]const u8 = "",
        role: ?[]const u8 = null,
    };

    pub const RawData = struct {
        msgId: []const u8,
        msgTime: []const u8,
        elements: []json.Value = &.{},
    };

    pub const FileInfo = struct {
        id: []const u8,
        name: []const u8,
        size: i64,
        busid: i64,
    };

    pub const GroupMessageEvent = struct {
        time: i64,
        self_id: i64,
        post_type: enum { message },
        message_type: []const u8,
        sub_type: []const u8,
        message_id: i64,
        user_id: i64,
        message: []MessageElement,
        raw_message: []const u8,
        sender: EventSender,
        group_id: i64,
    };

    pub const GroupUploadNoticeEvent = struct {
        time: i64,
        self_id: i64,
        post_type: enum { notice },
        notice_type: enum { group_upload },
        group_id: i64,
        user_id: i64,
        file: FileInfo,
    };

    pub const OneBotEvent = union(enum) {
        group_message: GroupMessageEvent,
        group_upload_notice: GroupUploadNoticeEvent,

        pub fn jsonParse(allocator: Allocator, source: anytype, options: json.ParseOptions) !@This() {
            const value = try json.Value.jsonParse(allocator, source, options);
            return jsonParseFromValue(allocator, value, options);
        }

        pub fn jsonParseFromValue(allocator: Allocator, source: json.Value, options: json.ParseOptions) !@This() {
            if (source != .object) return error.UnexpectedToken;
            const post_type_value = source.object.get("post_type") orelse return error.MissingField;
            if (post_type_value != .string) return error.UnexpectedToken;

            if (std.mem.eql(u8, post_type_value.string, "message")) {
                return .{ .group_message = try json.innerParseFromValue(GroupMessageEvent, allocator, source, options) };
            }
            if (std.mem.eql(u8, post_type_value.string, "notice")) {
                const notice_type_value = source.object.get("notice_type") orelse return error.MissingField;
                if (notice_type_value != .string) return error.UnexpectedToken;
                if (std.mem.eql(u8, notice_type_value.string, "group_upload")) {
                    return .{ .group_upload_notice = try json.innerParseFromValue(GroupUploadNoticeEvent, allocator, source, options) };
                }
            }
            return error.InvalidEnumTag;
        }
    };

    pub fn parseEvent(allocator: Allocator, payload: []const u8) !json.Parsed(OneBotEvent) {
        return json.parseFromSlice(
            OneBotEvent,
            allocator,
            payload,
            .{ .ignore_unknown_fields = true },
        );
    }
};
