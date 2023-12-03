const std = @import("std");
const util = @import("util.zig");

const trim = std.mem.trim;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

const data = @embedFile("data/day01.txt");

fn part1() !u32 {
    var lines = std.mem.tokenize(u8, data, "\n");

    var total: u32 = 0;
    while (lines.next()) |line| {
        const trimmed = trim(u8, line, "abcdefghijklmnopqrstuvwxyz");

        const first: u8 = trimmed[0];
        const last: u8 = trimmed[trimmed.len - 1];
        const both = [_]u8{ first, last };

        const number = try parseInt(u8, &both, 10);

        total += number;
    }

    return total;
}

fn part2() !u32 {
    var lines = std.mem.tokenize(u8, data, "\n");

    const nums: [9][]const u8 = [_][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };

    var total: u32 = 0;
    while (lines.next()) |line| {
        var first: ?u8 = null;
        var last: ?u8 = null;

        if (std.ascii.isDigit(line[0])) {
            first = line[0];
        }
        if (std.ascii.isDigit(line[line.len - 1])) {
            last = line[line.len - 1];
        }

        const index_first_num = std.mem.indexOfAny(u8, line, "123456789");
        const index_last_num = std.mem.lastIndexOfAny(u8, line, "123456789");

        var index_first_word: ?usize = null;
        var index_last_word: ?usize = null;

        var lowest_index: ?usize = index_first_num;
        var highest_index: ?usize = index_last_num;

        if (first == null) {
            for (nums, 0..) |word, i| {
                index_first_word = std.mem.indexOf(u8, line, word);
                if (index_first_word != null) {
                    if (lowest_index == null or index_first_word.? < lowest_index.?) {
                        first = std.fmt.digitToChar(@truncate(i + 1), .lower);
                        lowest_index = index_first_word;
                    }
                }
            }
            if (first == null) first = line[index_first_num.?];
        }
        if (last == null) {
            for (nums, 0..) |word, i| {
                index_last_word = std.mem.lastIndexOf(u8, line, word);
                if (index_last_word != null) {
                    if (highest_index == null or index_last_word.? > highest_index.?) {
                        last = std.fmt.digitToChar(@truncate(i + 1), .lower);
                        highest_index = index_last_word;
                    }
                }
            }
            if (last == null) last = line[index_last_num.?];
        }

        const both = [_]u8{ first.?, last.? };
        const number = try std.fmt.parseInt(u8, &both, 10);

        total += number;
    }

    return total;
}

pub fn main() !void {
    print("Day 1 (Part 1) answer: {any}\n", .{part1()});
    print("Day 1 (Part 2) answer: {any}\n", .{part2()});
}
