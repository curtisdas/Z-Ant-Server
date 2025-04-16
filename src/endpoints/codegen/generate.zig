const std = @import("std");
const zap = @import("zap");
const Runner = @import("../../runner.zig");
const Constants = @import("../../constants.zig");
pub const Generate = @This();

allocator: std.mem.Allocator = undefined,
path: []const u8,
error_strategy: zap.Endpoint.ErrorStrategy = .log_to_response,

pub fn init(
    allocator: std.mem.Allocator,
    path: []const u8,
) Generate {
    return .{
        .allocator = allocator,
        .path = path,
    };
}

pub fn deinit(_: *Generate) void {}

pub fn put(_: *Generate, _: zap.Request) !void {}
pub fn get(_: *Generate, _: zap.Request) !void {}
pub fn patch(_: *Generate, _: zap.Request) !void {}
pub fn delete(_: *Generate, _: zap.Request) !void {}
pub fn post(self: *Generate, r: zap.Request) !void {
    //try self.options(r);
    try r.parseBody();

    const params = try r.parametersToOwnedList(self.allocator);
    defer params.deinit();

    if (params.items[0].value) |value| {
        const file = value.Hash_Binfile;
        if (file.data) |data| {
            if (file.filename) |fname| {
                const dot_index = std.mem.lastIndexOf(u8, fname, ".") orelse fname.len;
                const filename = fname[0..dot_index];

                // Generate a random ID (e.g., UUID v4)
                var random_bytes: [16]u8 = undefined;
                std.crypto.random.bytes(&random_bytes);

                // Format as hex string
                const random_id = std.fmt.bytesToHex(random_bytes, std.fmt.Case.lower);

                try Runner.runZantCodeGen(self.allocator, filename, data, &random_id);
                // If id is binary data, convert it to hex or base64

                const response = .{
                    .message = "Code generation completed successfully",
                    .id = &random_id,
                };

                const json_str = try std.json.stringifyAlloc(self.allocator, response, .{});
                try r.setHeader("Content-Type", "application/json");
                try r.setHeader("Access-Control-Allow-Origin", Constants.WEBSITE_URL);
                try r.sendBody(json_str);
            } else {
                try r.sendBody("File name not found\n");
            }
        } else {
            try r.sendBody("File data not found\n");
        }
    } else {
        try r.sendBody("Parameters not found\n");
    }
}

pub fn options(_: *Generate, r: zap.Request) !void {
    try r.setHeader("Access-Control-Allow-Origin", "http://localhost:8000");
    try r.setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS");
    r.setStatus(zap.http.StatusCode.no_content);
    r.markAsFinished(true);
}
