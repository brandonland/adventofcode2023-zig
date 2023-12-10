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

const data = @embedFile("data/day05.txt");

/// This function determines whether or not the source is mapped for a given
/// source map and range. Given a row of 3 columns:
/// Row 1: destination map
/// Row 2: source map
/// Row 3: range
/// With the above in mind, if the source (`input`) number (seed if starting from square 1)
/// lies *in between* the source map number (row 2) and the range (row 3), then
/// we are certain that the seed is mapped.
fn isSourceMapped(input: u64, row: [3]u64) bool {
    return input >= row[1] and input <= row[1] + row[2];
}

fn part1() !u64 {
    var sections = splitSeq(u8, data, "\n\n");
    var seeds_line = splitSeq(u8, sections.next().?, ": ");
    _ = seeds_line.next();
    const seeds_text = seeds_line.next().?;

    var seeds = splitSca(u8, seeds_text, ' ');
    _ = &seeds;

    var seeds_count: u8 = 0;
    while (seeds.next()) |seed| {
        _ = seed;
        seeds_count += 1;
    }
    seeds.reset();

    const chars_to_strip = "abcdeghijklmnopqrstuvwxyz-:";

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var location_nums: List(u64) = List(u64).init(allocator);
    var new_input: ?u64 = null;

    while (seeds.next()) |seed| {
        const initial_input = try parseInt(u64, seed, 10);
        new_input = null;

        var section_count: u8 = 1;
        while (sections.next()) |section| {
            var matched_row: ?[3]u64 = null;
            const input = if (new_input == null) initial_input else new_input.?;

            const text = trim(u8, section, chars_to_strip);
            var rows_text = splitSca(u8, text, '\n');
            _ = rows_text.next().?; // Skip title of section

            var rows: List([3]u64) = List([3]u64).init(allocator);

            while (rows_text.next()) |line| {
                if (eql(u8, line, "")) continue;
                var cols = splitSca(u8, line, ' ');
                const col1: u64 = try parseInt(u64, cols.next().?, 10);
                const col2: u64 = try parseInt(u64, cols.next().?, 10);
                const col3: u64 = try parseInt(u64, cols.next().?, 10);
                try rows.append([3]u64{ col1, col2, col3 });
            }

            for (rows.items) |row| {
                if (isSourceMapped(input, row)) {
                    matched_row = row;
                    break;
                }
            }
            if (matched_row) |row| {
                // There is a match
                if (row[0] > row[1]) {
                    new_input = (row[0] - row[1]) + input;
                } else if (row[0] < row[1]) {
                    new_input = input - (row[1] - row[0]);
                } else {
                    // if sourcemap is equal to destmap
                    new_input = input;
                }
            } else {
                // No match, so result is the same as the input
                new_input = input;
            }

            section_count += 1;
        } // end of section

        sections.reset(); // This is important!

        // At this point, new_input should be equal to the location number,
        // as it has gone through every section, being mutated in the process.
        // So we can push it to location_nums.
        if (new_input) |input| {
            try location_nums.append(input);
        }
    } // end of seed number loop

    return std.mem.min(u64, location_nums.items);
}

fn part2() !u64 {
    return 0;
}

pub fn main() !void {
    print("Day 05 (Part 1) answer: {any}\n", .{part1()});
    print("Day 05 (Part 2) answer: {any}\n", .{part2()});
}
