const std = @import("std");

const relation = enum {
    big,
    eql,
    small,
};

pub fn quickSort(
    comptime T: type,
    slice: []T,
    compare: *const fn (a: T, b: T) relation,
) void {
    const oneSort = struct {
        fn sort(arr: []T, c: *const fn (a: T, b: T) relation) usize {
            var i: usize = 0;
            var j: usize = arr.len - 1;
            const temp: T = arr[i];

            while (i < j) {
                while (i < j and c(arr[j], temp) == .big)
                    j -= 1;
                if (i < j)
                    arr[i] = arr[j];

                while (i < j and (c(arr[i], temp) == .small or c(arr[i], temp) == .eql))
                    i += 1;
                if (i < j)
                    arr[j] = arr[i];
            }

            arr[j] = temp;
            return j;
        }
    };
    if (slice.len < 2)
        return;

    const k = oneSort.sort(slice, compare);
    quickSort(T, slice[0 .. k - 1], compare);
    quickSort(T, slice[k + 1 ..], compare);
}

test "quick sort" {
    const compare = struct {
        fn handle(a: u8, b: u8) relation {
            if (a < b)
                return .small;
            if (a == b)
                return .eql;
            return .big;
        }
    };

    var arr = [_]u8{ 3, 5, 6, 8, 3, 5, 4, 1, 9, 2 };
    const sorted_arr = [_]u8{ 1, 2, 3, 3, 4, 5, 5, 6, 8, 9 };

    quickSort(u8, &arr, compare.handle);
    for (0..arr.len) |i| {
        try std.testing.expect(arr[i] == sorted_arr[i]);
    }
}
