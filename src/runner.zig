const std = @import("std");
const constants = @import("constants.zig");

pub fn runZantCodeGen(allocator: std.mem.Allocator, file_name: []const u8, data: []const u8, random_id: []const u8) !void {
    try writeFileToDB(allocator, file_name, data);
    try codeGen(allocator, file_name);
    try zipFolder(allocator, file_name, random_id);
}

fn writeFileToDB(allocator: std.mem.Allocator, file_name: []const u8, data: []const u8) !void {
    const dir_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ constants.MODELS_PATH, file_name });
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
fn zipFolder(allocator: std.mem.Allocator, file_name: []const u8, random_id: []const u8) !void {
    const zip_name = try std.fmt.allocPrint(allocator, "{s}.zip", .{random_id});
    const zip_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ constants.GENERATED_PATH, file_name });
    defer allocator.free(zip_name);
    defer allocator.free(zip_path);

    // Here's where we need to change the command to use zip_name instead of a hardcoded name
    var zip_args = [_][]const u8{
        "zip",
        "-r",
        zip_name, // Now using the dynamically generated zip_name
        file_name,
    };

    var zip_child = std.process.Child.init(&zip_args, allocator);
    zip_child.cwd = constants.GENERATED_PATH;
    try zip_child.spawn();
    const zip_result = try zip_child.wait();
    if (zip_result.Exited != 0) return error.ZipFailed;
}
