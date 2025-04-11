const std = @import("std");

pub fn runZantCodeGen(allocator: std.mem.Allocator, file_name: []const u8, data: []const u8) ![]const u8 {
    try writeFileToDB(allocator, file_name, data);
    try codeGen(allocator, file_name);
    return try zipFolder(allocator, file_name);
}

fn writeFileToDB(allocator: std.mem.Allocator, file_name: []const u8, data: []const u8) !void {
    const dir_path = try std.fmt.allocPrint(allocator, "vendor/Z-Ant/datasets/models/{s}", .{file_name});
    defer allocator.free(dir_path);
    try std.fs.cwd().makePath(dir_path);
    const file_path = try std.fmt.allocPrint(allocator, "{s}/{s}.onnx", .{ dir_path, file_name });
    defer allocator.free(file_path);
    const file = try std.fs.cwd().createFile(file_path, .{ .truncate = true });
    defer file.close();
    try file.writeAll(data);
}

fn codeGen(allocator: std.mem.Allocator, file_name: []const u8) !void {
    const model_flag = try std.fmt.allocPrint(allocator, "-Dmodel={s}", .{file_name});
    defer allocator.free(model_flag);
    var codegen_args = [_][]const u8{ "zig", "build", "codegen", model_flag };
    var codegen_child = std.process.Child.init(&codegen_args, allocator);
    codegen_child.cwd = "vendor/Z-Ant";
    try codegen_child.spawn();
    const codegen_result = try codegen_child.wait();
    if (codegen_result.Exited != 0) return error.CodegenFailed;
}

fn zipFolder(allocator: std.mem.Allocator, file_name: []const u8) ![]const u8 {
    // Zip the folder
    const zip_name = try std.fmt.allocPrint(allocator, "{s}.zip", .{file_name});
    const zip_path = try std.fmt.allocPrint(allocator, "vendor/Z-Ant/generated/{s}", .{file_name});
    defer allocator.free(zip_name);
    defer allocator.free(zip_path);
    var zip_args = [_][]const u8{
        "zip",
        "-r",
        zip_name,
        file_name,
    };
    var zip_child = std.process.Child.init(&zip_args, allocator);
    zip_child.cwd = "vendor/Z-Ant/generated";
    try zip_child.spawn();
    const zip_result = try zip_child.wait();
    if (zip_result.Exited != 0) return error.ZipFailed;

    return try std.fmt.allocPrint(allocator, "vendor/Z-Ant/generated/{s}", .{zip_name});
}
