const std = @import("std");
const string = @import("string.zig");
const expect = std.testing.expect;
const eql = std.mem.eql;
const File = std.fs.File;
const Allocator = std.mem.Allocator;

pub const KeyValueHashMap = std.StringHashMap([]const u8);
pub const SectionHashMap = std.StringHashMap(Section);

pub const INI = struct {
    content: SectionHashMap,
    allocator: Allocator,

    pub fn init(allocator: Allocator) INI {
        return INI{
            .content = SectionHashMap.init(allocator),
            .allocator = allocator,
        };
    }

    /// deinit the ini struct
    pub fn deinit(self: *INI) void {
        defer self.content.deinit();
        var itera = self.iterate();
        while (itera.next()) |section|
            section.value_ptr.deinit();
    }

    pub fn sectionExist(self: *INI, name: []const u8) bool {
        return self.content.getKey(name) != null;
    }

    pub fn getSectionKeyValue(self: *INI, name: []const u8, key: []const u8) ?[]const u8 {
        const section_ptr = self.content.getPtr(name) orelse return null;
        return section_ptr.getValue(key);
    }

    pub fn getSection(self: *INI, name: []const u8) ?*Section {
        return self.content.getPtr(name);
    }

    pub fn setSectionKeyValue(self: *INI, name: []const u8, key: []const u8, value: []const u8) !void {
        const result = try self.content.getOrPut(name);
        if (!result.found_existing)
            result.value_ptr.* = Section.init(name, self.allocator);

        const section_ptr = result.value_ptr;
        try section_ptr.setValue(key, value);
    }

    pub fn setSectionWithKeyValue(self: *INI, name: []const u8, key_value: KeyValue) !void {
        const result = try self.content.getOrPut(name);
        if (!result.found_existing)
            result.value_ptr.* = Section.init(name, self.allocator);

        const section_ptr = result.value_ptr;
        try section_ptr.setWithKeyValue(key_value);
    }

    pub fn deleteSection(self: *INI, name: []const u8) void {
        if (self.content.getPtr(name)) |section| {
            section.deinit();
            _ = self.content.remove(name);
        }
    }

    pub fn iterate(self: *INI) SectionHashMap.Iterator {
        return self.content.iterator();
    }
};

test "INI test" {
    var ini = INI.init(std.testing.allocator);
    defer ini.deinit();

    try expect(!ini.sectionExist("general"));

    try ini.setSectionKeyValue("general", "name", "jinzhongjia");
    try expect(eql(u8, ini.getSectionKeyValue("general", "name").?, "jinzhongjia"));

    try ini.setSectionWithKeyValue("general", KeyValue.init("mail", "mail@nvimer.org"));
    try expect(eql(u8, ini.getSectionKeyValue("general", "mail").?, "mail@nvimer.org"));

    ini.getSection("general").?.deleteKey("name");
    try expect(ini.getSectionKeyValue("general", "name") == null);

    var itera = ini.iterate();
    while (itera.next()) |entry| {
        try expect(eql(u8, entry.key_ptr.*, "general"));
    }

    try expect(ini.sectionExist("general"));

    ini.deleteSection("general");

    try expect(!ini.sectionExist("general"));
}

pub const Section = struct {
    name: []const u8,
    content: KeyValueHashMap,
    allocator: Allocator,

    /// init the section, note the name will not owner by section
    /// but section will use param name
    pub fn init(name: []const u8, allocator: Allocator) Section {
        return .{
            .name = name,
            .content = KeyValueHashMap.init(allocator),
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Section) void {
        self.content.deinit();
    }

    pub fn getValue(self: *Section, key: []const u8) ?[]const u8 {
        if (self.content.getEntry(key)) |entry|
            return entry.value_ptr.*;
        return null;
    }

    pub fn keyExist(self: *Section, key: []const u8) bool {
        return self.content.getKey(key) != null;
    }

    pub fn setValue(self: *Section, key: []const u8, value: []const u8) !void {
        try self.content.put(key, value);
    }

    pub fn setWithKeyValue(self: *Section, key_value: KeyValue) !void {
        if (key_value.value) |value|
            try self.setValue(key_value.key, value);
    }

    pub fn deleteKey(self: *Section, key: []const u8) void {
        _ = self.content.remove(key);
    }

    pub fn iterate(self: *Section) KeyValueHashMap.Iterator {
        return self.content.iterator();
    }
};

test "section" {
    var section1 = Section.init("general", std.testing.allocator);
    defer section1.deinit();

    try section1.setValue("name", "jinzhongjia");
    try expect(eql(u8, section1.getValue("name").?, "jinzhongjia"));

    try section1.setWithKeyValue(KeyValue.init("mail", "mail@nvimer.org"));
    try expect(eql(u8, section1.getValue("mail").?, "mail@nvimer.org"));

    try expect(section1.keyExist("name"));
    section1.deleteKey("name");
    try expect(!section1.keyExist("name"));
}

pub const KeyValue = struct {
    key: []const u8,
    value: ?[]const u8,

    pub fn init(key: []const u8, value: ?[]const u8) KeyValue {
        return .{ .key = key, .value = value };
    }

    pub fn cpy(self: KeyValue, allocator: Allocator) !KeyValue {
        var new_key = try allocator.alloc(u8, self.key.len);
        errdefer allocator.free(new_key);
        @memcpy(new_key[0..], self.key[0..]);

        var res: KeyValue = undefined;
        res.key = new_key;
        res.value = null;

        if (self.value) |val| {
            var new_value = try allocator.alloc(u8, val.len);
            @memcpy(new_value[0..], val[0..]);
            res.value = new_value;
        }

        return res;
    }

    pub fn free(self: KeyValue, allocator: Allocator) void {
        allocator.free(self.key);
        if (self.value) |val|
            allocator.free(val);
    }
};

test "key value" {
    const n1 = KeyValue{
        .key = "name",
        .value = "jinzhongjia",
    };

    const n2 = try n1.cpy(std.testing.allocator);
    n2.free(std.testing.allocator);
}

pub const LineStruct = union(enum) {
    section: []const u8,
    key_value: KeyValue,
};

/// this function will parse a line
/// when return null, that mean current line is whitespace or comment
pub fn parseLine(line: []const u8) ?LineStruct {
    const no_comment_str = trimComment(line) orelse return null;
    const no_whitespace_str = string.trim(no_comment_str) orelse return null;

    if (checkSection(no_whitespace_str, false, false)) |section_name| {
        return LineStruct{
            .section = section_name,
        };
    } else if (getKeyValue(no_whitespace_str, false, false)) |key_value| {
        return LineStruct{
            .key_value = key_value,
        };
    }

    return null;
}

test "parse line" {
    const v1 = parseLine(" [name] ;kk").?;
    try expect(eql(u8, v1.section, "name"));

    const v2 = parseLine(" mail=mail@nvimer.org ;99  ").?;
    try expect(eql(u8, v2.key_value.key, "mail"));
    try expect(eql(u8, v2.key_value.value.?, "mail@nvimer.org"));

    const v3 = parseLine("passwd =    ##kk;").?;
    try expect(eql(u8, v3.key_value.key, "passwd"));
    try expect(v3.key_value.value == null);

    const v4 = parseLine(" = =;");
    try expect(v4 == null);
}

/// get key and value
/// when return null, str is not key = value pair
/// both key can not be null, that mean this is an error
pub fn getKeyValue(str: []const u8, comment: bool, white: bool) ?KeyValue {
    const no_comment_str = if (comment) trimComment(str) orelse return null else str;
    const no_whitespace_str = if (white) string.trim(no_comment_str) orelse return null else no_comment_str;

    const nstr = no_whitespace_str;
    const len = nstr.len;

    for (0..len) |index| {
        if (nstr[index] == '=') {
            if (index == 0)
                return null;
            return KeyValue{
                .key = string.trim(nstr[0..index]).?,
                .value = if (index + 1 == len) null else string.trim(nstr[index + 1 ..]),
            };
        }
    }
    return null;
}

test "get key value" {
    const key_value = getKeyValue("name=jinzhongjia", false, false).?;
    try expect(eql(u8, key_value.key, "name"));
    try expect(eql(u8, key_value.value.?, "jinzhongjia"));
}

/// check section, when return null, that mean this str is not section
/// comment is whether trim comment
/// white is whether trim whitespace
pub fn checkSection(str: []const u8, comment: bool, white: bool) ?[]const u8 {
    const no_comment_str = if (comment) trimComment(str) orelse return null else str;
    const no_whitespace_str = if (white) string.trim(no_comment_str) orelse return null else no_comment_str;

    if (no_whitespace_str.len < 3)
        return null;

    if (no_whitespace_str[0] == '[' and no_whitespace_str[no_whitespace_str.len - 1] == ']')
        return no_whitespace_str[1 .. no_whitespace_str.len - 1];

    return null;
}

test "check section" {
    try std.testing.expect(eql(u8, checkSection(" [kk]; ", true, true).?, "kk"));
    try std.testing.expect(eql(u8, checkSection(" [kk] ", false, true).?, "kk"));
    try std.testing.expect(eql(u8, checkSection("[kk]", false, false).?, "kk"));
    try expect(checkSection("[]", false, false) == null);
}

/// trim the comment, when return null, str is comment
pub fn trimComment(str: []const u8) ?[]const u8 {
    for (0..str.len) |index| {
        if (str[index] == ';' or str[index] == '#') {
            if (index == 0)
                return null;
            return str[0..index];
        }
    }
    return str;
}

test "trim comment" {
    try expect(std.mem.eql(u8, trimComment("ll#kkk").?, "ll"));
    try expect(std.mem.eql(u8, trimComment("ll;kkk").?, "ll"));
    try expect(trimComment("#kk") == null);
    try expect(trimComment(";kk") == null);
}
