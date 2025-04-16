const std = @import("std");
const zap = @import("zap");
const Runner = @import("../../runner.zig");
const Constants = @import("../../constants.zig");
pub const Download = @This();

allocator: std.mem.Allocator = undefined,
path: []const u8,
error_strategy: zap.Endpoint.ErrorStrategy = .log_to_response,

pub fn init(
    allocator: std.mem.Allocator,
    path: []const u8,
) Download {
    return .{
        .allocator = allocator,
        .path = path,
    };
}

pub fn deinit(_: *Download) void {}

pub fn put(_: *Download, _: zap.Request) !void {}
pub fn get(self: *Download, r: zap.Request) !void {
    r.parseQuery();
    const params = try r.parametersToOwnedList(self.allocator);
    defer params.deinit();

    for (params.items) |param| {
        if (std.mem.eql(u8, param.key, "id")) {
            std.debug.print("Download ID: {s}\n", .{param.value.?.String});
            const id = param.value;
            if (id) |filename| {
                std.debug.print("Download ID: {s}\n", .{filename.String});
                const zip_path = try std.fmt.allocPrint(self.allocator, "{s}/{s}.zip", .{ Constants.GENERATED_PATH, filename.String });
                defer self.allocator.free(zip_path);
                const file = try std.fs.cwd().openFile(zip_path, .{});
                defer file.close();

                const stat = try file.stat();
                const zip_data = try self.allocator.alloc(u8, stat.size);
                _ = try file.readAll(zip_data);

                try r.setHeader("Content-Type", "application/zip");
                try r.setHeader("Access-Control-Allow-Origin", Constants.WEBSITE_URL);
                try r.setHeader("Content-Disposition", "attachment; filename=\"codegen.zip\"");
                try r.sendBody(zip_data);
            } else {
                try r.sendBody("File name not found\n");
            }
        }
    }
}
pub fn patch(_: *Download, _: zap.Request) !void {}
pub fn delete(_: *Download, _: zap.Request) !void {}
pub fn post(_: *Download, _: zap.Request) !void {}

pub fn options(_: *Download, r: zap.Request) !void {
    try r.setHeader("Access-Control-Allow-Origin", Constants.WEBSITE_URL);
    try r.setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS");
    r.setStatus(zap.http.StatusCode.no_content);
    r.markAsFinished(true);
}
