const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;

const util = @import("util.zig");
const gpa = util.gpa;

// Useful stdlib functions
const print = std.debug.print;
const eql = std.mem.eql;
const tokenizeAny = std.mem.tokenizeAny;
const splitSca = std.mem.splitScalar;
const trim = std.mem.trim;

const testing = std.testing;
const expect = testing.expect;

const parseInt = std.fmt.parseInt;

const data = @embedFile("data/day04.txt");

fn getMatches(winning_nums: []const u8, player_nums: []const u8) !u8 {
    var matches: u8 = 0;
    var p_nums_it = tokenizeAny(u8, player_nums, " ");
    while (p_nums_it.next()) |p_num| {
        if (eql(u8, " ", p_num)) continue;
        var w_nums_it = tokenizeAny(u8, winning_nums, " ");
        const p_integer = try parseInt(u16, p_num, 10);
        while (w_nums_it.next()) |w_num| {
            const w_integer = try parseInt(u16, w_num, 10);
            if (p_integer == w_integer) {
                matches += 1;
            }
        }
    }
    return matches;
}

fn part1() !u32 {
    var lines = splitSca(u8, data, '\n');
    var total: u32 = 0;
    while (lines.next()) |line| {
        var points: u32 = 0;
        var groups = tokenizeAny(u8, line, ":|");
        _ = groups.next(); // chops off the "Card XX:" from the beginning of the line.

        const winning_nums = groups.next();
        const player_nums = groups.next();

        var matches: u8 = 0;
        if (player_nums) |p| {
            matches = try getMatches(winning_nums.?, p);
        }
        var i: u8 = 0;
        while (i < matches) : (i += 1) {
            points = if (points == 0) 1 else points * 2;
        }

        total += points;
    }
    return total;
}

fn part2() !u32 {
    var lines = splitSca(u8, data, '\n');
    var total: u32 = 0;
    const Card = struct {
        num: u16 = 0,
        matches: u8 = 0,
        copies: u32 = 1,
    };

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var list: List(Card) = List(Card).init(allocator);

    while (lines.next()) |line| {
        var card = Card{};
        var groups = tokenizeAny(u8, line, ":|");

        const header = groups.next();
        const winning_nums = groups.next();
        const player_nums = groups.next();

        if (header) |h| {
            card.num = try parseInt(u16, trim(u8, h, "Card :"), 10);
        } else continue;

        if (player_nums) |p| {
            card.matches = try getMatches(winning_nums.?, p);
        }
        try list.append(card);
    }

    for (list.items, 0..) |card, i| {
        var j: u8 = 1;
        while (j <= card.matches) : (j += 1) {
            var k: u32 = 0;
            while (k < card.copies) : (k += 1) {
                list.items[i + j].copies += 1;
            }
        }

        total += card.copies;
    }

    return total;
}

pub fn main() !void {
    print("Day 04 (Part 1) answer: {any}\n", .{part1()});
    print("Day 04 (Part 2) answer: {any}\n", .{part2()});
}
