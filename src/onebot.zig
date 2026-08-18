const std = @import("std");
const Allocator = std.mem.Allocator;
const http = std.http;
const Io = std.Io;
const json = std.json;

const OnebotError = error{
    Somehow,
};

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

        var stringifier: json.Stringify = .{
            .writer = &body.writer,
        };
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

    pub fn canSendImage(self: *@This()) json.Parsed(struct { yes: bool }) {
        return try self.call("can_send_image", .{}, struct { yes: bool });
    }

    pub fn canSendRecord(self: *@This()) json.Parsed(struct { yes: bool }) {
        return try self.call("can_send_record", .{}, struct { yes: bool });
    }

    const LoginInfo = struct {
        user_id: usize,
        nickname: []u8,
    };
    pub fn getLoginInfo(self: *@This()) json.Parsed(LoginInfo) {
        return try self.call("get_login_info", .{}, LoginInfo);
    }
};
