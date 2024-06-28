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
                // TODO: why the param.type can be null????
                const error_message = std.fmt.comptimePrint(
                    "sorry the params has a element which not has type {any}",
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
