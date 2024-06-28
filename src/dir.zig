const std = @import("std");
const file = @import("file.zig");
const Dir = std.fs.Dir;

/// config for copyDirConent
pub const CopyConfig = struct {
    /// whether cover file
    if_cover: bool,
};

/// copy the source dir content to dest dir
pub fn copyDirConent(source: Dir, dest: Dir, opt: CopyConfig) !void {
    var source_iterate = source.iterate();
    while (try source_iterate.next()) |entry| {
        const entry_name = entry.name;
        switch (entry.kind) {
            .directory => {
                var source_sub_dir = try source.openDir(entry_name, .{ .iterate = true });
                defer source_sub_dir.close();
                var dest_sub_dir = try dest.makeOpenPath(entry_name, .{ .iterate = true });
                defer dest_sub_dir.close();
                try copyDirConent(source_sub_dir, dest_sub_dir, opt);
            },
            .file => {
                if (try file.fileExist(dest, entry_name)) {
                    if (opt.if_cover)
                        try dest.deleteFile(entry_name);
                    continue;
                }
                _ = try source.updateFile(entry_name, dest, entry_name, .{});
            },
            else => {},
        }
    }
}

test "copyDirConent" {
    const testing = std.testing;

    const file_name = "test.txt";
    var tmp = testing.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();

    var tmp_dir = tmp.dir;
    var tmp_file = try tmp_dir.createFile(file_name, .{ .read = true });
    _ = try tmp_file.write("hello, world!");
    tmp_file.close();

    var tmp2 = testing.tmpDir(.{ .iterate = true });
    defer tmp2.cleanup();

    var tmp2_dir = tmp2.dir;
    try copyDirConent(tmp_dir, tmp2_dir, .{ .if_cover = true });

    try tmp2_dir.access(file_name, .{});
}
