const std = @import("std");
const ztroy = @import("zTroy.zig");

test "all" {
    std.testing.refAllDecls(ztroy);
}
