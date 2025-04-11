const std = @import("std");
const zant = @import("../../../../zant.zig");

const Tensor = zant.core.tensor.Tensor;
const TensorError = zant.utils.error_handler.TensorError;
const TensorMathError = zant.utils.error_handler.TensorMathError;

const pkg_allocator = zant.utils.allocator.allocator;

/// Implements https://onnx.ai/onnx/operators/onnx__Unsqueeze.html
/// Insert single-dimensional entries into the shape of the data tensor.
pub fn unsqueeze(comptime T: type, data: *Tensor(T), axes: *Tensor(i64)) !Tensor(T) {

    // Output rank
    const out_rank = data.shape.len + axes.size;
    const conv_out_rank: i64 = @intCast(out_rank);

    for (0..axes.data.len) |i| {

        // Check if axes are within bounds
        if (axes.data[i] < -conv_out_rank or axes.data[i] >= out_rank) {
            return TensorError.AxisOutOfBounds;
        }

        // Check for duplicates
        for (0..i) |j| {
            if (axes.data[i] == axes.data[j]) {
                return TensorError.DuplicateAxis;
            }
        }
    }

    const output_shape = try get_unsqueeze_output_shape(data.shape, axes.data);
    defer pkg_allocator.free(output_shape);

    var output = try Tensor(T).fromShape(data.allocator, output_shape);

    try unsqueeze_lean(T, data, axes, &output);

    return output;
}

/// Lean version of unsqueeze, note that previous information stored in output tensor is lost
pub fn unsqueeze_lean(comptime T: type, input: *Tensor(T), axes: *Tensor(i64), output: *Tensor(T)) !void {
    _ = axes;
    @memcpy(output.data, input.data);
}

/// Calculate the output shape for an ONNX Unsqueeze operation without performing the operation
pub fn get_unsqueeze_output_shape(input_shape: []const usize, axes: []const i64) ![]usize {
    // Output rank
    const out_rank = input_shape.len + axes.len;

    // Convert negative axes to positive
    var actual_axes = try pkg_allocator.alloc(usize, axes.len);
    defer pkg_allocator.free(actual_axes);

    for (axes, 0..) |axis, i| {
        var conv: i64 = axis;
        if (conv < 0) {
            conv += @intCast(out_rank);
        }
        if (conv < 0 or conv >= out_rank) {
            return TensorError.AxisOutOfBounds;
        }
        const new_axis: usize = @intCast(conv);

        // Check for duplicates
        for (0..i) |j| {
            if (actual_axes[j] == new_axis) {
                return TensorError.DuplicateAxis;
            }
        }
        actual_axes[i] = new_axis;
    }

    // Create output shape array
    var output_shape = try pkg_allocator.alloc(usize, out_rank);

    // Create and initialize support array to track unsqueezed dimensions
    var is_unsqueezed = try pkg_allocator.alloc(bool, out_rank);
    defer pkg_allocator.free(is_unsqueezed);
    @memset(is_unsqueezed, false);

    // Mark unsqueezed dimensions and set them to 1
    for (actual_axes) |axis| {
        output_shape[axis] = 1;
        is_unsqueezed[axis] = true;
    }

    // Fill remaining dimensions with input shape values
    var input_idx: usize = 0;
    for (0..out_rank) |i| {
        if (!is_unsqueezed[i]) {
            output_shape[i] = input_shape[input_idx];
            input_idx += 1;
        }
    }

    return output_shape;
}
