const std = @import("std");
const FnParam = std.builtin.Type.Fn.Param;

/// generate a fuction's param tuple
pub fn FnParamsToTuple(comptime params: []const FnParam) type {
    const Type = std.builtin.Type;
    const fields: [params.len]Type.StructField = blk: {
        var res: [params.len]Type.StructField = undefined;

        for (params, 0..params.len) |param, i| {
            if (param.type) |t| {
                res[i] = Type.StructField{
                    .type = t,
                    .alignment = @alignOf(t),
                    .default_value = null,
                    .is_comptime = false,
                    .name = std.fmt.comptimePrint("{}", .{i}),
                };
            } else {
                // when param type is anytype, the type is null
                const error_message = std.fmt.comptimePrint(
                    "sorry the param is anytype!",
                    .{param},
                );
                @compileError(error_message);
            }
        }
        break :blk res;
    };
    return @Type(.{
        .Struct = std.builtin.Type.Struct{
            .layout = .Auto,
            .is_tuple = true,
            .decls = &.{},
            .fields = &fields,
        },
    });
}
