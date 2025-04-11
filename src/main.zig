const std = @import("std");
const zap = @import("zap");
const allocator = std.heap.page_allocator;
pub fn main() !void {
    var listener = zap.HttpListener.init(.{
        .port = 3000,
        .on_request = handleRequest,
    });
    try listener.listen();

    zap.start(.{
        .threads = 1,
        .workers = 1,
    });
}

fn handleRequest(r: zap.Request) !void {
    if (r.method) |method| {
        if (r.path) |path| {
            if (std.mem.eql(u8, method, "POST") and std.mem.eql(u8, path, "/codegen")) {
                try r.parseBody();

                const params = try r.parametersToOwnedList(allocator);
                defer params.deinit();

                const file = params.items[0].value.?.Hash_Binfile;
                const data = file.data.?;

                const dot_index = std.mem.lastIndexOf(u8, file.filename.?, ".") orelse file.filename.?.len;
                const file_name = file.filename.?[0..dot_index];

                const zip_path = try runCodegen(file_name, data);
                std.debug.print("{s}", .{zip_path});

                const zip_file = try std.fs.cwd().openFile(zip_path, .{});
                defer zip_file.close();

                const stat = try zip_file.stat();
                const zip_data = try allocator.alloc(u8, stat.size);
                _ = try zip_file.readAll(zip_data);

                try r.setHeader("Content-Type", "application/zip");
                try r.setHeader("Content-Disposition", "attachment; filename=\"codegen.zip\"");
                try r.setHeader("Access-Control-Allow-Origin", "*");
                try r.sendBody(zip_data);
            }
        }
    } else {
        try r.sendBody("Not Found\n");
    }
}

fn runCodegen(file_name: []const u8, data: []const u8) ![]const u8 {

    // Write the file in datasets
    const dir_path = try std.fmt.allocPrint(allocator, "Z-Ant/datasets/models/{s}", .{file_name});
    defer allocator.free(dir_path);
    try std.fs.cwd().makePath(dir_path);
    const file_path = try std.fmt.allocPrint(allocator, "{s}/{s}.onnx", .{ dir_path, file_name });
    defer allocator.free(file_path);
    const file = try std.fs.cwd().createFile(file_path, .{ .truncate = true });
    defer file.close();
    try file.writeAll(data);

    // Run codegen
    const model_flag = try std.fmt.allocPrint(allocator, "-Dmodel={s}", .{file_name});
    defer allocator.free(model_flag);
    var codegen_args = [_][]const u8{ "zig", "build", "codegen", model_flag };
    var codegen_child = std.process.Child.init(&codegen_args, allocator);
    codegen_child.cwd = "Z-Ant";
    try codegen_child.spawn();
    const codegen_result = try codegen_child.wait();
    if (codegen_result.Exited != 0) return error.CodegenFailed;

    // Zip the folder
    const zip_name = try std.fmt.allocPrint(allocator, "{s}.zip", .{file_name});
    const zip_path = try std.fmt.allocPrint(allocator, "Z-Ant/generated/{s}", .{file_name});
    defer allocator.free(zip_name);
    defer allocator.free(zip_path);
    var zip_args = [_][]const u8{
        "zip",
        "-r",
        zip_name,
        file_name,
    };
    var zip_child = std.process.Child.init(&zip_args, allocator);
    zip_child.cwd = "Z-Ant/generated";
    try zip_child.spawn();
    const zip_result = try zip_child.wait();
    if (zip_result.Exited != 0) return error.ZipFailed;

    return try std.fmt.allocPrint(allocator, "Z-Ant/generated/{s}", .{zip_name});
}
