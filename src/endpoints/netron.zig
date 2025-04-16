const std = @import("std");
const zap = @import("zap");
const Runner = @import("../runner.zig");
const Constants = @import("../constants.zig");
pub const Netron = @This();

allocator: std.mem.Allocator = undefined,
path: []const u8,
error_strategy: zap.Endpoint.ErrorStrategy = .log_to_response,

pub fn init(
    allocator: std.mem.Allocator,
    path: []const u8,
) Netron {
    return .{
        .allocator = allocator,
        .path = path,
    };
}

pub fn deinit(_: *Netron) void {}

pub fn put(_: *Netron, _: zap.Request) !void {}
pub fn get(_: *Netron, _: zap.Request) !void {
    
}
pub fn patch(_: *Netron, _: zap.Request) !void {}
pub fn delete(_: *Netron, _: zap.Request) !void {}
pub fn post(_: *Netron, _: zap.Request) !void {}

pub fn options(_: *Netron, r: zap.Request) !void {
    try r.setHeader("Access-Control-Allow-Origin", Constants.WEBSITE_URL);
    try r.setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS");
    r.setStatus(zap.http.StatusCode.no_content);
    r.markAsFinished(true);
}
