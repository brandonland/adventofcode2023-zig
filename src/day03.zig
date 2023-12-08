const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

// Useful stdlib functions
const testing = std.testing;
const isDigit = std.ascii.isDigit;
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

const data = @embedFile("data/day03.txt");

const Point = struct {
    const Self = @This();

    x: usize,
    y: usize,

    pub fn reset(self: *Self) void {
        self.x = 0;
        self.y = 0;
    }
};

const Num = struct {
    const Self = @This();
    pos: Point = Point{ .x = undefined, .y = undefined },
    num: [5:0]u8 = [5:0]u8{ 0, 0, 0, 0, 0 }, // container with 5 decimal places
    is_valid: bool = false,
    is_complete: bool = false,
    len: u8 = 0,
    line: []const u8,
    prev_line: ?[]const u8,
    next_line: ?[]const u8,

    pub fn reset(self: *Self) void {
        self.pos.reset();
        var i: u8 = 0;
        while (i < self.num.len) : (i += 1) {
            self.num[i] = 0;
        }
        self.is_complete = false;
        self.is_valid = false;
        self.len = 0;
    }
};

const LineLevel = enum { prev, current, next };

/// Takes a num_struct, a line level, and a pointer to a list of points.
/// Line level just means num_y - 1 for `.prev`, and num_y + 1 for `.next`.
/// Populates the list that gets passed to the function.
///
/// jk
///
/// Validates by walking through adjacent cells given the num and the line level.
//fn populateLineAdjPoints(num: Num, line_level: LineLevel, points: *List(Point)) !void {
fn validateNum(num: *Num) !void {
    if (num.prev_line == null) {
        // handle the very first line
        if (try isNumValidFromLine(num, num.line) or try isNumValidFromLine(num, num.next_line.?)) {
            num.is_valid = true;
        }
    } else {
        if (num.next_line != null and num.next_line.?.len != 0) {
            // handle the lines in between
            if (try isNumValidFromLine(num, num.prev_line.?) or try isNumValidFromLine(num, num.line) or try isNumValidFromLine(num, num.next_line.?)) {
                num.is_valid = true;
            }
        } else {
            // handle the last line
            if (try isNumValidFromLine(num, num.prev_line.?) or try isNumValidFromLine(num, num.line)) {
                num.is_valid = true;
            }
        }
    }
}

/// This function actually modifies num if it's valid by toggling is_valid to true,
/// which is why num is a pointer.
fn isNumValidFromLine(num: *Num, line: []const u8) !bool {
    const x_width = 140; // number of chars each line holds

    const num_x: usize = num.pos.x;
    //const num_y: usize = num.pos.y;

    const is_leftmost = num_x == 0;
    const is_rightmost = num_x + num.len == x_width;

    // If the number hugs the left wall, the starting point is the same as the
    // index of the left-most digit of the number, which is num_x. Otherwise,
    // the starting point is left-adjacent to it. Same logic applies to right-most.
    const start_point: usize = if (is_leftmost) num_x else num_x - 1;
    const end_point: usize = if (is_rightmost) (x_width - 1) else (num_x + num.len);

    const box_len = (end_point - start_point) + 1;

    //print("box_len: {d}\n", .{box_len});

    var i: u16 = 0;
    while (i < box_len) : (i += 1) {
        const x = start_point + i;
        //try points.append(Point{ .x = x, .y = y });

        // if *any* of these chars are symbols, then validate num and return.
        const c = line[x];
        //print("x is {d} and line[x] is {c}\n", .{ x, line[x] });
        if (!isDigit(c) and c != '.') {
            //print("{s}: has adjacent symbol of {c}\n", .{ num.num, line[x] });
            return true;
        }
    }
    return false;
}

fn part1() !u32 {
    var lines = splitSca(u8, data, '\n');

    var total: u32 = 0;

    var prev_line: ?[]const u8 = null;

    var y: usize = 0;
    while (lines.next()) |line| : (y += 1) {

        // temporary struct that, once completed, gets checked for validity
        // and then reset before the next number is found and checked.
        // If the number is "valid", it gets added to the total.
        var num_struct = Num{
            .prev_line = prev_line,
            .line = line,
            .next_line = lines.peek(),
        };

        //print("lines.index is {any}\n", .{lines.index});
        var digit_found = false;
        for (line, 0..) |c, x| {
            if (isDigit(c) and !digit_found) {
                // Found the first digit of a number!
                digit_found = true;
                num_struct.pos = Point{ .x = x, .y = y };

                num_struct.num[num_struct.len] = c;
                num_struct.len += 1;
            } else if (isDigit(c) and digit_found) {
                // This digit is not the first of a number
                //print("Found another digit.\n", .{});
                num_struct.num[num_struct.len] = c;
                num_struct.len += 1;
            }
            if ((!isDigit(c) and digit_found) or (isDigit(c) and digit_found and x == 139)) {
                // The num_struct is complete because this character is
                // directly right-adjacent to the final digit of a number,
                // OR it is a digit and the last character in the line.
                num_struct.is_complete = true;
                digit_found = false;

                // Validate
                try validateNum(&num_struct);

                //print("\nResetting num...\n", .{});
            }

            if (num_struct.is_complete and num_struct.is_valid) {
                //print("num: {any}\n", .{num});
                const number = parseInt(u16, num_struct.num[0..num_struct.len], 10) catch |err| {
                    print("Son of a nutcracker!{any}\n", .{err});
                    return err;
                };

                total += number;

                num_struct.reset();
                continue;
            }

            // as long as num_struct is complete, it can be reset at this point.
            if (num_struct.is_complete) {
                if (!num_struct.is_valid) {
                    print("{s}: \x1b[31mNumber is NOT valid!\x1b[0m Not adding.\n", .{num_struct.num});
                }
                num_struct.reset();
            }
        } // Loop over chars

        prev_line = line;
    } // Loop over lines

    return total;
}

fn part2() !u32 {
    // The struct for part2 will be a "gear" struct that will hold two "num" structs;
    // only these num structs will be much simpler:
    // The only properties the nums need are: pos, num, and len.
    // I will take a similar approach to part1, except instead of searching for
    // numbers, I will be searching for asterisk (*) symbols, determining if it is
    // indeed a valid gear (it has two adjacent nums), and if so, *walk* to the
    // left-most digit of each number, find its length, and then walk from
    // the left-most digit to the end in order to capture the number.
    // It would be more efficient to *first* determine if it is a valid gear
    // *before* doing all that walking. We don't want to walk digits if we don't
    // have to.

    //const Num = struct {
    //    const Self = @This();
    //    pos: Point = Point{ .x = undefined, .y = undefined },
    //    num: [5:0]u8 = [5:0]u8{ 0, 0, 0, 0, 0 }, // container with 5 decimal places
    //    is_valid: bool = false,
    //    is_complete: bool = false,
    //    len: u8 = 0,
    //    line: []const u8,
    //    prev_line: ?[]const u8,
    //    next_line: ?[]const u8,

    //    pub fn reset(self: *Self) void {
    //        self.pos.reset();
    //        var i: u8 = 0;
    //        while (i < self.num.len) : (i += 1) {
    //            self.num[i] = 0;
    //        }
    //        self.is_complete = false;
    //        self.is_valid = false;
    //        self.len = 0;
    //    }
    //};

    const GearNum = struct {
        pos: Point = Point{ .x = undefined, .y = undefined },
        num: [5:0]u8 = [5:0]u8{ 0, 0, 0, 0, 0 },
        len: u3 = 0,
    };
    const Gear = struct {
        pos: Point = Point{ .x = undefined, .y = undefined },
        is_valid: bool = false,
        nums: ?[2]?GearNum = null,
    };
    _ = Gear;

    //var total: usize = 0;

    //return total;
    return 0;
}

pub fn main() !void {
    print("Day 03 (Part 1) answer: {any}\n", .{part1()});
    print("Day 03 (Part 2) answer: {any}\n", .{part2()});
}
