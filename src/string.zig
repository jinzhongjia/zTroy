const std = @import("std");
const SPACE = 32;

/// trim the whitespace, when return null, str is whitespace
pub fn trim(str: []const u8) ?[]const u8 {
    var head: usize = 0;
    var head_ok = false;
    var tail: usize = 0;
    var tail_ok = false;

    const str_len = str.len;
    for (0..str_len) |index| {
        if (!head_ok and str[index] != SPACE) {
            head = index;
            head_ok = true;
        }

        if (!tail_ok and str[str_len - 1 - index] != SPACE) {
            tail = str_len - index;
            tail_ok = true;
        }
    }

    if (head == 0 and tail == 0) return null;

    return str[head..tail];
}

test "test trim" {
    try std.testing.expect(' ' == SPACE);
    try std.testing.expect(std.mem.eql(u8, trim("  kk   ").?, "kk"));
    try std.testing.expect(trim("   ") == null);
}
