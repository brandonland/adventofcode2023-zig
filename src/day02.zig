const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

// Useful stdlib functions
const eql = std.mem.eql;
const tokenize = std.mem.tokenize;
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
const sliceMin = std.mem.min;
const sliceMax = std.mem.max;

const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.block;
const asc = std.sort.asc;
const desc = std.sort.desc;

const data = @embedFile("data/day02.txt");

const max_red: u8 = 12;
const max_green: u8 = 13;
const max_blue: u8 = 14;

fn part1() !u32 {
    var lines = tokenize(u8, data, "\n");

    var total: u32 = 0;
    game_loop: while (lines.next()) |line| {
        var line_split = splitAny(u8, line, ":;");
        const game_id = line_split.first()[5..];
        const game_contents = line_split.rest();

        var handfuls = splitSeq(u8, game_contents, "; ");
        while (handfuls.next()) |handful| {
            var sets = splitSeq(u8, handful, ", "); // e.g. {"4 red", "5 blue", "2 green"}
            while (sets.next()) |set| {
                var fields = std.mem.splitBackwards(u8, set, " "); // e.g. {"red", "4"}
                const color = fields.next().?;
                const num = try std.fmt.parseInt(u32, fields.next().?, 10);
                const over_red = eql(u8, color, "red") and num > max_red;
                const over_green = eql(u8, color, "green") and num > max_green;
                const over_blue = eql(u8, color, "blue") and num > max_blue;

                if (over_red or over_green or over_blue) {
                    continue :game_loop; // ggwp though
                }
            }
        }

        total += try std.fmt.parseInt(u32, game_id, 10);
    }

    return total;
}

fn part2() !u32 {
    return 0;
}

pub fn main() !void {
    print("Day 01 (Part 1) answer: {any}\n", .{part1()});
    print("Day 01 (Part 2) answer: {any}\n", .{part2()});
}
