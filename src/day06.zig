const std = @import("std");
const util = @import("util.zig");

// Useful stdlib functions
const print = std.debug.print;
const eql = std.mem.eql;
const splitAny = std.mem.splitAny;
const splitSca = std.mem.splitScalar;
const indexOfAny = std.mem.indexOfAny;
const trim = std.mem.trim;
const trimLeft = std.mem.trimLeft;
const trimRight = std.mem.trimRight;
const parseInt = std.fmt.parseInt;

// Custom functions
const removeSpaces = util.removeSpaces;

const data = @embedFile("data/day06.txt");

/// Given a time and a record distance, get the number of ways to win.
fn getNumOfWays(comptime T: type, time: T, record: T) T {
    var num_of_ways: T = 0;
    var button_time: T = 1;
    while (button_time < time) : (button_time += 1) {
        const time_remaining = time - button_time;
        const distance: T = time_remaining * button_time;
        // if distance is greater than the record, push this to the list
        if (distance > record) {
            num_of_ways += 1;
        }
    }
    return num_of_ways;
}

fn part1() !usize {
    var lines = splitSca(u8, data, '\n');
    const times_str = trim(u8, lines.next().?, "Time:"); // time limits
    const distances_str = trim(u8, lines.next().?, "Distance:"); // record distances

    const times_trimmed = trimLeft(u8, times_str, " ");
    const dists_trimmed = trimLeft(u8, distances_str, " ");

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
        result *= getNumOfWays(usize, time, record);
    }

    return result;
}

fn part2() !u64 {
    var lines = splitSca(u8, data, '\n');
    const times_str = trim(u8, lines.next().?, "Time:"); // time limits
    const distances_str = trim(u8, lines.next().?, "Distance:"); // record distances
    const first_index_times = indexOfAny(u8, times_str, "1234567890").?;
    const first_index_dists = indexOfAny(u8, distances_str, "1234567890").?;

    const time_slice = trim(u8, times_str[first_index_times..], " ");
    const dists_slice = trim(u8, distances_str[first_index_dists..], " ");

    const time = try parseInt(u64, removeSpaces(time_slice), 10);
    const dists = try parseInt(u64, removeSpaces(dists_slice), 10);

    return getNumOfWays(u64, time, dists);
}

pub fn main() !void {
    print("Day 06 (Part 1) answer: {any}\n", .{part1()});
    print("Day 06 (Part 2) answer: {any}\n", .{part2()});
}
