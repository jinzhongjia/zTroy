const std = @import("std");
const Dir = std.fs.Dir;

pub fn fileExist(dir: Dir, sub_path: []const u8) !bool {
    var dest_file = dir.openFile(sub_path, .{}) catch |err| switch (err) {
        error.FileNotFound => return false,
        else => |e| return e,
    };
    defer dest_file.close();
    return true;
}

test "fileExist" {
    const testing = std.testing;

    const file_name = "test.txt";
    var tmp = testing.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();

    var tmp_dir = tmp.dir;
    var tmp_file = try tmp_dir.createFile(file_name, .{ .read = true });
    _ = try tmp_file.write("hello, world!");
    tmp_file.close();

    try tmp_dir.access(file_name, .{});
}
