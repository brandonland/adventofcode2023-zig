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
const count = std.mem.count;
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

const testing = std.testing;

const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.block;
const asc = std.sort.asc;
const desc = std.sort.desc;

const data = @embedFile("data/day07.txt");

const Card = enum(u8) {
    @"2" = 2,
    @"3" = 3,
    @"4" = 4,
    @"5" = 5,
    @"6" = 6,
    @"7" = 7,
    @"8" = 8,
    @"9" = 9,
    T = 10,
    J = 11,
    Q = 12,
    K = 13,
    A = 14,

    const Self = @This();

    pub fn strength(self: Self) u8 {
        return @intFromEnum(self);
    }
    pub fn name(self: Self) u8 {
        return @tagName(self)[0];
    }
};

const HandType = enum(u8) {
    HighCard = 1,
    OnePair = 2,
    TwoPair = 3,
    ThreeOfAKind = 4,
    FullHouse = 5,
    FourOfAKind = 6,
    FiveOfAKind = 7,

    const Self = @This();

    pub fn strength(self: Self) u8 {
        return @intFromEnum(self);
    }
};

const Duplicate = struct {
    count: u8,
    char: u8,
};

fn isFiveOfAKind(str: []const u8) bool {
    return count(u8, str, str[0..1]) == 5;
}
fn isFourOfAKind(str: []const u8) bool {
    return count(u8, str, str[0..1]) == 4 or count(u8, str, str[1..2]) == 4;
}

fn getUniquesCount(str: []const u8) u8 {
    var uniques: [5]u8 = [_]u8{ 0, 0, 0, 0, 0 };
    var total: u8 = 0;
    for (uniques[0..], 0..) |_, i| {
        for (str[0..], 0..) |c, j| {
            _ = j;
            if (indexOf(u8, &uniques, c) == null) {
                uniques[i] = c;
                total += 1;
                break;
            }
        }
    }
    return total;
}

/// Returns either a HandType.FullHouse or HandType.ThreeOfAKind
fn getHandType(str: []const u8) HandType {
    if (isFiveOfAKind(str)) return .FiveOfAKind;
    if (isFourOfAKind(str)) return .FourOfAKind;

    //var uniques: [5]u8 = [_]u8{ 0, 0, 0, 0, 0 };
    //for (uniques[0..], 0..) |_, i| {
    //    for (str[0..], 0..) |c, j| {
    //        _ = j;

    //        if (indexOf(u8, &uniques, c) == null) {
    //            uniques[i] = c;
    //            break;
    //        }
    //    }
    //}

    if (getUniquesCount(str) == 2) {
        return .FullHouse;
    }
    if (getUniquesCount(str) == 3) {
        // Could be either a Three Of A Kind or a Two Pair.
        // If *any* character exists 3 times in the string, it's a .ThreeOfAKind.
        for (str[0..], 0..) |_, i| {
            const end = i + 1;
            if (count(u8, str, str[i..end]) == 3) {
                return .ThreeOfAKind;
            }
        }
        return .TwoPair;
    }
    if (getUniquesCount(str) == 4) {
        return .OnePair;
    }

    // Final fallback: If this code is reached, the only thing it could be is a High Card.
    return .HighCard;
}

const Hand = struct {
    cards: [5]Card,
    str: []const u8,
    strength: usize = 0,
    type: HandType = .FullHouse,

    const Self = @This();

    pub fn init(self: *Self) void {
        self.type = determineType(self.str);
    }

    fn determineType(str: []const u8) HandType {
        return getHandType(str);
    }
};

//fn getCardFromChar(char: u8) Card {}
fn getHandFromStr(str: []const u8) !Hand {
    const allocator = std.heap.page_allocator;

    const memory = try allocator.alloc(u8, 100);
    defer allocator.free(memory);

    var cardmap = std.StringHashMap(Card).init(allocator);
    defer cardmap.deinit();

    try cardmap.put("2", .@"2");
    try cardmap.put("3", .@"3");
    try cardmap.put("4", .@"4");
    try cardmap.put("5", .@"5");
    try cardmap.put("6", .@"6");
    try cardmap.put("7", .@"7");
    try cardmap.put("8", .@"8");
    try cardmap.put("9", .@"9");
    try cardmap.put("T", .T);
    try cardmap.put("J", .J);
    try cardmap.put("Q", .Q);
    try cardmap.put("K", .K);
    try cardmap.put("A", .A);

    var cards: [5]Card = [_]Card{ .A, .A, .A, .A, .A };
    for (str[0..], 0..) |_, i| {
        const end = i + 1;
        const key = str[i..end];
        const card = cardmap.get(key);
        cards[i] = card.?;
    }

    var hand = Hand{ .cards = cards, .str = str };
    hand.init();
    return hand;
}

fn part1() !u32 {
    const card = Card.@"2";
    print("Card strength: {d}\n", .{card.strength()});
    print("Card character: {c}\n", .{card.name()});

    var lines = splitSca(u8, data, '\n');
    while (lines.next()) |line| {
        var sep = indexOf(u8, line, ' ').?;
        const hand = line[0..sep];
        _ = hand;
        sep += 1;
        const bid = line[sep..];
        _ = bid;
    }

    return 0;
}

fn part2() !u32 {
    return 0;
}

pub fn main() !void {
    print("Day 07 (Part 1) answer: {any}\n", .{part1()});
    print("Day 07 (Part 2) answer: {any}\n", .{part2()});
}

test "Five of a kind" {
    const hand = try getHandFromStr("QQQQQ");
    try testing.expectEqual(HandType.FiveOfAKind, hand.type);
}
test "Four of a kind" {
    const hand = try getHandFromStr("KQQQQ");
    try testing.expectEqual(HandType.FourOfAKind, hand.type);
}
test "Full House" {
    const hand = try getHandFromStr("KQQQK");
    try testing.expectEqual(HandType.FullHouse, hand.type);
}
test "Three of a Kind" {
    const hand = try getHandFromStr("KQQQJ");
    try testing.expectEqual(HandType.ThreeOfAKind, hand.type);
}
test "Two Pair" {
    const hand = try getHandFromStr("23432");
    try testing.expectEqual(HandType.TwoPair, hand.type);
}
test "One Pair" {
    const hand = try getHandFromStr("A23A4");
    try testing.expectEqual(HandType.OnePair, hand.type);
}
test "High Card" {
    const hand = try getHandFromStr("23456");
    try testing.expectEqual(HandType.HighCard, hand.type);
}
