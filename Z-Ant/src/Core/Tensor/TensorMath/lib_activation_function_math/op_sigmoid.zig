const std = @import("std");
const zant = @import("../../../../zant.zig");

const Tensor = zant.core.tensor.Tensor; // Import Tensor type
const pkg_allocator = zant.utils.allocator.allocator;
const error_handler = zant.utils.error_handler;
const TensorMathError = error_handler.TensorMathError;
const TensorError = error_handler.TensorError;
const ArchitectureError = error_handler.ArchitectureError;
const Converter = zant.utils.type_converter;

/// The Sigmoid activation function is a smooth, S-shaped function that maps any input
/// to a value between 0 and 1.
/// it can suffer from vanishing gradients, especially for large positive or negative
/// inputs, slowing down training in deep networks.
pub inline fn sigmoid(comptime T: anytype, tensor: *Tensor(T)) !Tensor(T) {
    //checks
    if (tensor.size <= 0) return TensorError.ZeroSizeTensor;

    var output_tensor = try Tensor(T).fromShape(&pkg_allocator, tensor.shape);
    errdefer output_tensor.deinit();

    try sigmoid_lean(T, tensor, &output_tensor);

    return output_tensor;
}

pub inline fn sigmoid_lean(comptime T: anytype, input_tensor: *Tensor(T), output_tensor: *Tensor(T)) !void {
    @setEvalBranchQuota(100000);
    //std.debug.print("\n[DEBUG] sigmoid_lean:", .{});
    //std.debug.print("\n  Input shape: ", .{});
    //for (input_tensor.shape) |s| std.debug.print("{d} ", .{s});

    //std.debug.print("\n  Output shape: ", .{});
    //for (output_tensor.shape) |s| std.debug.print("{d} ", .{s});

    //apply Sigmoid
    for (0..input_tensor.size) |i| {
        const input_val = input_tensor.data[i];
        output_tensor.data[i] = 1.0 / (1.0 + @exp(-input_val));
        //std.debug.print("\n  sigmoid({d:.6}) = {d:.6}", .{ input_val, output_tensor.data[i] });
    }
    //std.debug.print("\n[DEBUG] sigmoid_lean completed\n", .{});
}

pub fn sigmoid_backward(comptime T: anytype, gradient: *Tensor(T), act_forward_out: *Tensor(T)) !void {
    //checks
    if (gradient.size <= 0 or act_forward_out.size <= 0) return TensorError.ZeroSizeTensor;
    if (gradient.size != act_forward_out.size) return TensorMathError.InputTensorDifferentSize;

    //apply Sigmoid derivative: f'(x) = f(x) * (1 - f(x))
    for (0..gradient.size) |i| {
        const sigmoid_output = act_forward_out.data[i];
        gradient.data[i] *= sigmoid_output * (1 - sigmoid_output);
    }
}
