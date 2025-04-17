const std = @import("std");
const zap = @import("zap");
const Runner = @import("../runner.zig");
const Constants = @import("../constants.zig");
pub const Codegen = @This();

allocator: std.mem.Allocator = undefined,
path: []const u8,
error_strategy: zap.Endpoint.ErrorStrategy = .log_to_response,

pub fn init(
    allocator: std.mem.Allocator,
    path: []const u8,
) Codegen {
    return .{
        .allocator = allocator,
        .path = path,
    };
}

pub fn deinit(_: *Codegen) void {}

pub fn put(_: *Codegen, _: zap.Request) !void {}
pub fn get(self: *Codegen, r: zap.Request) !void {
    r.parseQuery();
    const params = try r.parametersToOwnedList(self.allocator);
    defer params.deinit();

    for (params.items) |param| {
        if (std.mem.eql(u8, param.key, "id")) {
            const id = param.value;
            if (id) |filename| {
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

pub fn patch(_: *Codegen, _: zap.Request) !void {}
pub fn delete(_: *Codegen, _: zap.Request) !void {}

pub fn post(self: *Codegen, r: zap.Request) !void {
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

pub fn options(_: *Codegen, r: zap.Request) !void {
    try r.setHeader("Access-Control-Allow-Origin", "http://localhost:8000");
    try r.setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS");
    r.setStatus(zap.http.StatusCode.no_content);
    r.markAsFinished(true);
}
