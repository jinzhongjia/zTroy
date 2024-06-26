const std = @import("std");
const expect = std.testing.expect;
const eql = std.mem.eql;
const File = std.fs.File;
const Allocator = std.mem.Allocator;

pub const Section = struct {
    name: []const u8,
    values: ?[]const KeyValue,

    pub fn cpy(self: Section, allocator: Allocator) !Section {
        var new_name = try allocator.alloc(u8, self.name.len);
        errdefer allocator.free(new_name);
        @memcpy(new_name[0..], self.name[0..]);

        var res: Section = undefined;
        res.name = new_name;
        res.values = null;

        if (self.values) |val| {
            const values = try allocator.alloc(KeyValue, val.len);
            for (0..val.len) |index| {
                values[index] = try val[index].cpy(allocator);
            }

            res.values = values;
        }

        return res;
    }

    pub fn free(self: Section, allocator: Allocator) void {
        allocator.free(self.name);
        if (self.values) |val| {
            for (0..val.len) |index| {
                val[index].free(allocator);
            }
            allocator.free(val);
        }
    }
};

test "section" {
    const n1 = Section{
        .name = "group1",
        .values = &.{.{
            .key = "mail",
            .value = "mail@nvime.org",
        }},
    };

    const n2 = try n1.cpy(std.testing.allocator);
    n2.free(std.testing.allocator);
}

pub const KeyValue = struct {
    key: []const u8,
    value: ?[]const u8,

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

const SPACE = 32;

/// this function will parse a line
/// when return null, that mean current line is whitespace or comment
pub fn parseLine(line: []const u8) ?LineStruct {
    const no_comment_str = trimComment(line) orelse return null;
    const no_whitespace_str = trim(no_comment_str) orelse return null;

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
    const no_whitespace_str = if (white) trim(no_comment_str) orelse return null else no_comment_str;

    const nstr = no_whitespace_str;
    const len = nstr.len;

    for (0..len) |index| {
        if (nstr[index] == '=') {
            if (index == 0)
                return null;
            return KeyValue{
                .key = trim(nstr[0..index]).?,
                .value = if (index + 1 == len) null else trim(nstr[index + 1 ..]),
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
    const no_whitespace_str = if (white) trim(no_comment_str) orelse return null else no_comment_str;

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
