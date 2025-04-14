const std = @import("std");
const zap = @import("zap");
const Runner = @import("../runner.zig");
const Constants = @import("../constants.zig");
pub const CodeGen = @This();

const cg = @import("codegen");

allocator: std.mem.Allocator = undefined,
path: []const u8,
error_strategy: zap.Endpoint.ErrorStrategy = .log_to_response,

pub fn init(
    allocator: std.mem.Allocator,
    path: []const u8,
) CodeGen {
    return .{
        .allocator = allocator,
        .path = path,
    };
}

pub fn deinit(_: *CodeGen) void {}

pub fn put(_: *CodeGen, _: zap.Request) !void {}
pub fn get(_: *CodeGen, _: zap.Request) !void {}
pub fn patch(_: *CodeGen, _: zap.Request) !void {}
pub fn delete(_: *CodeGen, _: zap.Request) !void {}
pub fn post(self: *CodeGen, r: zap.Request) !void {
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

                const zip_path = try Runner.runZantCodeGen(self.allocator, filename, data);
                std.debug.print("{s}", .{zip_path});

                const zip_file = try std.fs.cwd().openFile(zip_path, .{});
                defer zip_file.close();

                const stat = try zip_file.stat();
                const zip_data = try self.allocator.alloc(u8, stat.size);
                _ = try zip_file.readAll(zip_data);

                try r.setHeader("Content-Type", "application/zip");
                try r.setHeader("Access-Control-Allow-Origin", Constants.WEBSITE_URL);
                try r.setHeader("Content-Disposition", "attachment; filename=\"codegen.zip\"");
                try r.sendBody(zip_data);
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

pub fn options(_: *CodeGen, r: zap.Request) !void {
    try r.setHeader("Access-Control-Allow-Origin", "http://localhost:8000");
    try r.setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS");
    r.setStatus(zap.http.StatusCode.no_content);
    r.markAsFinished(true);
}
