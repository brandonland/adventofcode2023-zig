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

const data = @embedFile("data/day06.txt");

fn part1() !usize {
    var lines = splitSca(u8, data, '\n');
    const times_str = trim(u8, lines.next().?, "Time:"); // time limits
    const distances_str = trim(u8, lines.next().?, "Distance:"); // record distances

    const times_trimmed = std.mem.trimLeft(u8, times_str, " ");
    const dists_trimmed = std.mem.trimLeft(u8, distances_str, " ");

    print("Times trimmed: {s}\n", .{times_trimmed});

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var times_array: [4]usize = [4]usize{ 0, 0, 0, 0 }; // initialized with zeros
    var dists_array: [4]usize = [4]usize{ 0, 0, 0, 0 }; // initialized with zeros

    var times_it = splitAny(u8, times_trimmed, " ");
    var dists_it = splitAny(u8, dists_trimmed, " ");

    // Populate the arrays
    var i: usize = 0;
    while (times_it.next()) |time| {
        if (eql(u8, "", time)) continue;
        const num = try parseInt(usize, time, 10);
        times_array[i] = num;
        i += 1;
    }
    i = 0;
    while (dists_it.next()) |dist| {
        if (eql(u8, "", dist)) continue;
        const num = try parseInt(usize, dist, 10);
        dists_array[i] = num;
        i += 1;
    }

    var result: usize = 1;
    for (times_array, dists_array) |time, record| {
        // a list might not be needed for part 1, but it might for part 2. Who knows.
        var best_btn_hold_times: List(usize) = List(usize).init(allocator);
        var button_time: usize = 1;
        while (button_time < time) : (button_time += 1) {
            const time_remaining = time - button_time;
            const distance: usize = time_remaining * button_time;
            //print("Distance: {d}\n", .{distance});
            // if distance is greater than the record, push this to the list
            if (distance > record) {
                try best_btn_hold_times.append(button_time);
            }
        }
        result *= best_btn_hold_times.items.len;
    }

    return result;
}

fn part2() !u32 {
    var lines = splitSca(u8, data, '\n');
    const times_str = trim(u8, lines.next().?, "Time:"); // time limits
    const distances_str = trim(u8, lines.next().?, "Distance:"); // record distances
    const first_index_times = indexOfAny(u8, times_str, "1234567890").?;
    const first_index_dists = indexOfAny(u8, distances_str, "1234567890").?;
    const time_slice = trim(u8, times_str[first_index_times..], " ");
    const dists_slice = trim(u8, distances_str[first_index_dists..], " ");

    print("Time line: {s}\n", .{times_str});
    print("Distance line: {s}\n", .{distances_str});
    print("first index of times: {d}\n", .{first_index_times});
    print("first index of dists: {d}\n", .{first_index_dists});
    print("time slice: {s}\n", .{time_slice});
    print("dists slice: {s}\n", .{dists_slice});

    return 0;
}

pub fn main() !void {
    print("Day 06 (Part 1) answer: {any}\n", .{part1()});
    print("Day 06 (Part 2) answer: {any}\n", .{part2()});
}
