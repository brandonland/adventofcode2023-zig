const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
//const gpa = util.gpa;

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

const ArrayList = std.ArrayList;

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
    None = 0,
    HighCard = 1,
    OnePair = 2,
    TwoPair = 3,
    ThreeOfAKind = 4,
    FullHouse = 5,
    FourOfAKind = 6,
    FiveOfAKind = 7,

    const Self = @This();

    pub fn getBaseRank(self: Self) u8 {
        return @intFromEnum(self);
    }
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

    // Final fallback: The only other thing it could be.
    return .HighCard;
}

const Hand = struct {
    cards: [5]Card,
    str: []const u8,
    strength: usize = 0,
    type: HandType,
    rank: u64 = 0,
    bid: u64 = 1,

    const Self = @This();

    fn getType(str: []const u8) HandType {
        return getHandType(str);
    }
    fn getBaseRank(self: *Self) u8 {
        return self.type.getBaseRank();
    }
    pub fn init(self: *Self) void {
        self.type = getType(self.str);
        self.rank = getBaseRank(self);
    }
};

//fn getCardFromChar(char: u8) Card {}

// TODO: This is code smell. If I can instantiate Hands like:
// `const hand = Hand("AAJAA");`, that would be optimal. May need to return
// a struct from a `Hand()` function.
fn createHandFromStr(str: []const u8) !Hand {
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

    var cards: [5]Card = [_]Card{ .A, .A, .A, .A, .A }; // Aaaaaaaaaaaa!
    for (str[0..], 0..) |_, i| {
        const end = i + 1;
        const key = str[i..end];
        const card = cardmap.get(key);
        cards[i] = card.?;
    }

    var hand = Hand{
        .cards = cards,
        .str = str,
        .type = .None,
    };
    hand.init();
    return hand;
}

const HandList = std.MultiArrayList(Hand);

fn part1() !usize {
    //const card = Card.@"2";
    //print("Card strength: {d}\n", .{card.strength()});
    //print("Card character: {c}\n", .{card.name()});
    //
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    // Struct of Arrays
    var soa = HandList{};
    defer soa.deinit(allocator);

    var num_lines: u32 = 0;

    var lines = tokenizeSca(u8, data, '\n');
    while (lines.next()) |line| {
        var sep = indexOf(u8, line, ' ').?;

        const hand_str = line[0..sep];
        var hand = try createHandFromStr(hand_str);
        const initial_rank = hand.rank;

        var rank = initial_rank;
        _ = &rank;

        sep += 1;
        const bid_str = line[sep..];
        const bid = try parseInt(usize, bid_str, 10);

        // Attach the bid number to the Hand object
        hand.bid = bid;

        // TODO: Every Hand needs a unique, newly-generated rank number, which
        // is initially determined by its base rank (1-7, depending on on HandType).
        //
        // This may involve needing to separate every Hand by its base_rank beforehand.
        // I will have to learn to do this more efficiently. This is probably not
        // the best approach.
        //
        //if ()
        //

        //switch (hand.type) {
        //    .HighCard => total_highcards += 1,
        //    .OnePair => total_onepairs += 1,
        //    .TwoPair => total_twopairs += 1,
        //    .ThreeOfAKind => total_threeofkinds += 1,
        //    .FullHouse => total_fullhouses += 1,
        //    .FourOfAKind => total_fourofkinds += 1,
        //    .FiveOfAKind => total_fiveofkinds += 1,
        //    else => unreachable,
        //}

        try soa.append(allocator, hand);

        num_lines += 1;
        print("{d} -- Hand: {s}  |  Bid: {d} -- {s}\n", .{ num_lines, hand_str, hand.bid, @tagName(hand.type) });
    }

    // TODO: Defeat the repetition.

    // Count the number of High Cards.
    var total_highcards: usize = 0; // 207
    var total_onepairs: usize = 0; // 211
    var total_twopairs: usize = 0; // 184
    var total_threeofkinds: usize = 0; // 187
    var total_fullhouses: usize = 0; // 110
    var total_fourofkinds: usize = 0; // 100
    var total_fiveofkinds: usize = 0; // 1

    print("soa.items.len: {d}\n", .{soa.len});

    for (soa.items(.type)) |t| {
        if (t == .HighCard) {
            total_highcards += 1;
        }
    }
    for (soa.items(.type)) |t| {
        if (t == .OnePair) total_onepairs += 1;
    }
    for (soa.items(.type)) |t| {
        if (t == .TwoPair) total_twopairs += 1;
    }
    for (soa.items(.type)) |t| {
        if (t == .ThreeOfAKind) total_threeofkinds += 1;
    }
    for (soa.items(.type)) |t| {
        if (t == .FullHouse) total_fullhouses += 1;
    }
    for (soa.items(.type)) |t| {
        if (t == .FourOfAKind) total_fourofkinds += 1;
    }
    for (soa.items(.type)) |t| {
        if (t == .FiveOfAKind) total_fiveofkinds += 1;
    }

    const grand_total = total_highcards + total_onepairs + total_twopairs + total_threeofkinds + total_fullhouses + total_fourofkinds + total_fiveofkinds;

    print("\nTotal high cards: {d}\n", .{total_highcards});
    print("Total one pairs: {d}\n", .{total_onepairs});
    print("Total two pairs: {d}\n", .{total_twopairs});
    print("Total three of a kinds: {d}\n", .{total_threeofkinds});
    print("Total full houses: {d}\n", .{total_fullhouses});
    print("Total four of a kinds: {d}\n", .{total_fourofkinds});
    print("Total five of a kinds: {d}\n", .{total_fiveofkinds});
    print("Grand total: {d}\n\n", .{grand_total});

    //for (soa.items(.hp)) |*hp| {
    //    hp.* = 100;
    //}

    return 0;
}

fn part2() !u32 {
    return 0;
}

pub fn main() !void {
    print("Day 07 (Part 1) answer: {any}\n", .{part1()});
    print("Day 07 (Part 2) answer: {any}\n", .{part2()});
}

test "All Hand types" {
    const hand = try createHandFromStr("QQQQQ");
    try testing.expectEqual(HandType.FiveOfAKind, hand.type);

    hand = try createHandFromStr("KQQQQ");
    try testing.expectEqual(HandType.FourOfAKind, hand.type);

    hand = try createHandFromStr("KQQQK");
    try testing.expectEqual(HandType.FullHouse, hand.type);

    hand = try createHandFromStr("KQQQJ");
    try testing.expectEqual(HandType.ThreeOfAKind, hand.type);

    hand = try createHandFromStr("23432");
    try testing.expectEqual(HandType.TwoPair, hand.type);

    hand = try createHandFromStr("A23A4");
    try testing.expectEqual(HandType.OnePair, hand.type);

    hand = try createHandFromStr("23456");
    try testing.expectEqual(HandType.HighCard, hand.type);
}
