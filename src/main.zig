const std = @import("std");
const zap = @import("zap");

const Codegen = @import("endpoints/codegen.zig");
const Netron = @import("endpoints/netron.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};
    const allocator = gpa.allocator();

    {
        // setup listener
        var listener = zap.Endpoint.Listener.init(
            allocator,
            .{
                .on_request = null,
                .port = 3000,
                .log = true,
                .max_clients = 100000,
                .max_body_size = 100 * 1024 * 1024,
            },
        );
        defer listener.deinit();

        // /users endpoint
        var codegen = Codegen.init(allocator, "/codegen");
        defer codegen.deinit();

        var netron = Netron.init(allocator, "/netron");
        defer netron.deinit();

        // register endpoints with the listener
        try listener.register(&codegen);
        try listener.register(&netron);

        try listener.listen();

        std.debug.print("Listening on 0.0.0.0:3000\n", .{});

        // and run
        zap.start(.{
            .threads = 2,
            // IMPORTANT! It is crucial to only have a single worker for this example to work!
            // Multiple workers would have multiple copies of the users hashmap.
            //
            // Since zap is quite fast, you can do A LOT with a single worker.
            // Try it with `zig build run-endpoint -Drelease-fast`
            .workers = 1,
        });
    }

    // show potential memory leaks when ZAP is shut down
    const has_leaked = gpa.detectLeaks();
    std.log.debug("Has leaked: {}\n", .{has_leaked});
}
