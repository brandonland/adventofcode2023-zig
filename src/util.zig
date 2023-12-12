const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

pub var gpa_impl = std.heap.GeneralPurposeAllocator(.{}){};
pub const gpa = gpa_impl.allocator();

// Add utility functions here

// Useful stdlib functions
const eql = std.mem.eql;
const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSeq = std.mem.tokenizeSequence;
const tokenizeSca = std.mem.tokenizeScalar;
const splitAny = std.mem.splitAny;
const splitSeq = std.mem.splitSequence;
const splitSca = std.mem.splitScalar;
const indexOf = std.mem.indexOfScalar;
const indexOfAny = std.mem.indexOfAny;
const indexOfStr = std.mem.indexOfPosLinear;
const lastIndexOf = std.mem.lastIndexOfScalar;
const lastIndexOfAny = std.mem.lastIndexOfAny;
const lastIndexOfStr = std.mem.lastIndexOfLinear;
const trim = std.mem.trim;
const trimLeft = std.mem.trimLeft;
const trimRight = std.mem.trimRight;
const sliceMin = std.mem.min;
const sliceMax = std.mem.max;

const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.block;
const asc = std.sort.asc;
const desc = std.sort.desc;

/// Removes all spaces from a slice
pub fn removeSpaces(string: []const u8) []const u8 {
    var it = splitAny(u8, string, " ");
    // Until I find a better way, initial container holds only 100 slots.
    var new_slice = [_]u8{0} ** 100;

    var i: usize = 0;
    var char_count: usize = 0;
    while (it.next()) |num| {
        if (eql(u8, "", num)) continue;
        for (num[0..]) |c| {
            new_slice[char_count] = c;
            char_count += 1;
        }
        i += 1;
    }

    const result: []const u8 = &new_slice;
    return trimRight(u8, result, &[_]u8{0});
}
