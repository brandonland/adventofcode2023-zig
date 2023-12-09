const std = @import("std");

// Useful stdlib functions
const testing = std.testing;
const isDigit = std.ascii.isDigit;
const eql = std.mem.eql;
const splitSca = std.mem.splitScalar;
const parseInt = std.fmt.parseInt;
const print = std.debug.print;

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

/// Validates by walking through adjacent cells when given a num structure
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

        // temporary struct that, once completed, gets checked for validity,
        // then resets before the next number is found and checked.
        // If the number "is_valid", it gets added to the total.
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

            if (num_struct.is_complete) num_struct.reset();
        } // Loop over chars

        prev_line = line;
    } // Loop over lines

    return total;
}

fn part2() !u32 {
    // As a special note: when checking for adjacent nums *above* and *below*
    // a potential gear (asterisk), if it there is a digit *directly above*
    // (not diagonal), then that means *only one* adjacent number exists on that
    // level. Likewise, left/right adjacent checks are easy, because if a
    // digit is left-or-right adjacent, then we know that is also exactly 1 number.

    const Gear = struct {
        const Self = @This();

        pos: Point = Point{ .x = undefined, .y = undefined },
        //nums: [2]?GearNum = [_]GearNum{null, null},
        nums: [2]u32 = [_]u32{ 0, 0 },
        line: []const u8,
        prev_line: ?[]const u8,
        next_line: ?[]const u8,
        is_valid: bool = false,
        is_complete: bool = false,

        pub fn is_leftmost(self: Self) bool {
            return self.pos.x == 0;
        }
        pub fn is_rightmost(self: Self) bool {
            return self.pos.x == 139;
        }
        pub fn is_top(self: Self) bool {
            return self.prev_line == null;
        }
        pub fn is_bottom(self: Self) bool {
            return self.next_line == null;
        }
        pub fn reset(self: *Self) void {
            self.pos = Point{ .x = 0, .y = 0 };
            self.is_valid = false;
            self.is_complete = false;
            self.nums[0] = 0;
            self.nums[1] = 0;
        }
    };

    var lines = splitSca(u8, data, '\n');
    var prev_line: ?[]const u8 = null;
    var total: u32 = 0;

    var y: usize = 0;
    while (lines.next()) |line| : (y += 1) {
        var gear = Gear{
            .line = line,
            .prev_line = prev_line,
            .next_line = lines.peek(),
        };

        for (line, 0..) |c, x| {
            if (c != '*') continue; // Below code doesn't run unless char is '*'

            gear.pos.x = x;
            gear.pos.y = y;

            // Check left-right-top-bottom for digits. If these are greater than
            // 2, then we can continue because it is not a valid gear.
            // This is just an efficicent check.
            var hits: u3 = 0;
            if (!gear.is_leftmost()) {
                // check left
                hits += if (isDigit(line[x - 1])) 1 else 0;
            }
            if (!gear.is_rightmost()) {
                // check right
                hits += if (isDigit(line[x + 1])) 1 else 0;
            }
            if (!gear.is_top()) {
                // check top
                hits += if (isDigit(gear.prev_line.?[x])) 1 else 0;
            }
            if (!gear.is_bottom()) {
                // check bottom
                hits += if (isDigit(gear.next_line.?[x])) 1 else 0;
            }
            if (hits > 2) continue;

            // Check diagonals, but only if top/bottom are not digits
            if (!gear.is_top() and !isDigit(gear.prev_line.?[x])) {
                // if gear is not top row and top cell is not a digit,
                // we can check top-left/right, but only if not left/rightmost.
                if (!gear.is_leftmost()) {
                    hits += if (isDigit(gear.prev_line.?[x - 1])) 1 else 0;
                }
                if (!gear.is_rightmost()) {
                    hits += if (isDigit(gear.prev_line.?[x + 1])) 1 else 0;
                }

                if (hits > 2) continue;
            }
            if (!gear.is_bottom() and !isDigit(gear.next_line.?[x])) {
                // if gear is not top row and top cell is not a digit,
                // we can check top-left/right, but only if not left/rightmost.
                if (!gear.is_leftmost()) {
                    hits += if (isDigit(gear.next_line.?[x - 1])) 1 else 0;
                }
                if (!gear.is_rightmost()) {
                    hits += if (isDigit(gear.next_line.?[x + 1])) 1 else 0;
                }

                if (hits > 2) continue;
            }

            // Since we've run all checks, we can do one more check:
            // if hits is not exactly equal to 2, the gear is not valid.
            if (hits != 2) continue;
            //print("Found a valid gear! Position is y: {d}, x: {d}\n", .{ y, x });
            gear.is_valid = true;

            // If this code runs, that means the asterisk is a valid gear.
            // Now we can collect the num data and push it to the struct.
            //
            // Collect direct left numbers:
            if (!gear.is_leftmost() and isDigit(line[x - 1])) {
                var i: u3 = 0;
                var sel = x - 1; // selected index
                var num: [5]u8 = [5]u8{ 0, 0, 0, 0, 0 }; // container
                while (sel >= 0 and isDigit(line[sel])) : (sel -= 1) {
                    num[num.len - 1 - i] = line[sel];
                    i += 1;
                }
                const num_trimmed = std.mem.trim(u8, &num, &[_]u8{0});
                const num_parsed = try parseInt(u16, num_trimmed, 10);
                var j: u2 = 0;
                for (gear.nums) |n| {
                    if (n == 0) {
                        gear.nums[j] = num_parsed;
                        break;
                    }
                    j += 1;
                }
            }
            // Collect direct right numbers:
            if (!gear.is_rightmost() and isDigit(line[x + 1])) {
                var i: u3 = 0;
                var sel = x + 1; // selected index
                var num: [5]u8 = [5]u8{ 0, 0, 0, 0, 0 }; // container
                while (sel <= 139 and isDigit(line[sel])) : (sel += 1) {
                    num[i] = line[sel];
                    i += 1;
                }
                const num_trimmed = std.mem.trim(u8, &num, &[_]u8{0});
                const num_parsed = try parseInt(u16, num_trimmed, 10);
                var j: u2 = 0;
                for (gear.nums) |n| {
                    if (n == 0) {
                        gear.nums[j] = num_parsed;
                        break;
                    }
                    j += 1;
                }
            }
            // Collect top numbers:
            if (!gear.is_top() and isDigit(gear.prev_line.?[x])) {
                // digit found is middle top.
                var i: u3 = 0;
                var sel = x;
                var num: [5]u8 = [5]u8{ 0, 0, 0, 0, 0 }; // container
                // set selection to the leftmost digit.
                while (true) : (sel -= 1) {
                    if (sel == 0) break;
                    if (!isDigit(gear.prev_line.?[sel - 1])) break;
                }
                // now we can walk right to get full length and capture the number.
                while (sel <= 139 and isDigit(gear.prev_line.?[sel])) : (sel += 1) {
                    num[i] = gear.prev_line.?[sel];
                    i += 1;
                }
                const num_trimmed = std.mem.trim(u8, &num, &[_]u8{0});
                const num_parsed = try parseInt(u16, num_trimmed, 10);
                var j: u2 = 0;
                for (gear.nums) |n| {
                    if (n == 0) {
                        gear.nums[j] = num_parsed;
                        break;
                    }
                    j += 1;
                }
            } else if (!gear.is_top()) {
                if (!gear.is_leftmost() and isDigit(gear.prev_line.?[x - 1])) {
                    var i: u3 = 0;
                    var sel = x - 1; // selected index
                    var num: [5]u8 = [5]u8{ 0, 0, 0, 0, 0 }; // container
                    while (sel >= 0 and isDigit(gear.prev_line.?[sel])) : (sel -= 1) {
                        num[num.len - 1 - i] = gear.prev_line.?[sel];
                        i += 1;
                        if (sel == 0) break;
                    }
                    const num_trimmed = std.mem.trim(u8, &num, &[_]u8{0});
                    const num_parsed = try parseInt(u16, num_trimmed, 10);
                    var j: u2 = 0;
                    for (gear.nums) |n| {
                        if (n == 0) {
                            gear.nums[j] = num_parsed;
                            break;
                        }
                        j += 1;
                    }
                }
                if (!gear.is_rightmost() and isDigit(gear.prev_line.?[x + 1])) {
                    // digit found at top-right, but not middle top
                    var i: u3 = 0;
                    var sel = x + 1; // selected index
                    var num: [5]u8 = [5]u8{ 0, 0, 0, 0, 0 }; // container
                    while (sel <= 139 and isDigit(gear.prev_line.?[sel])) : (sel += 1) {
                        num[i] = gear.prev_line.?[sel];
                        i += 1;
                    }
                    const num_trimmed = std.mem.trim(u8, &num, &[_]u8{0});
                    const num_parsed = try parseInt(u16, num_trimmed, 10);
                    var j: u2 = 0;
                    for (gear.nums) |n| {
                        if (n == 0) {
                            gear.nums[j] = num_parsed;
                            break;
                        }
                        j += 1;
                    }
                }
            }
            // Collect bottom numbers:
            if (!gear.is_bottom() and isDigit(gear.next_line.?[x])) {
                // digit found is middle bottom.
                var i: u3 = 0;
                var sel = x;
                var num: [5]u8 = [5]u8{ 0, 0, 0, 0, 0 }; // container
                // set selection to the leftmost digit.
                while (true) : (sel -= 1) {
                    if (sel == 0) break;
                    if (!isDigit(gear.next_line.?[sel - 1])) break;
                }
                // now we can walk right to get full length and capture the number.
                while (sel <= 139 and isDigit(gear.next_line.?[sel])) : (sel += 1) {
                    num[i] = gear.next_line.?[sel];
                    i += 1;
                }
                const num_trimmed = std.mem.trim(u8, &num, &[_]u8{0});
                const num_parsed = try parseInt(u16, num_trimmed, 10);
                var j: u2 = 0;
                for (gear.nums) |n| {
                    if (n == 0) {
                        gear.nums[j] = num_parsed;
                        break;
                    }
                    j += 1;
                }
            } else if (!gear.is_bottom()) {
                // gear is not bottom, but direct bottom is not a digit.
                if (!gear.is_leftmost() and isDigit(gear.next_line.?[x - 1])) {
                    // digit found at bottom-left, but not middle bottom
                    var i: u3 = 0;
                    var sel = x - 1; // selected index
                    var num: [5]u8 = [5]u8{ 0, 0, 0, 0, 0 }; // container
                    while (sel >= 0 and isDigit(gear.next_line.?[sel])) : (sel -= 1) {
                        num[num.len - 1 - i] = gear.next_line.?[sel];
                        i += 1;
                        if (sel == 0) break;
                    }
                    const num_trimmed = std.mem.trim(u8, &num, &[_]u8{0});
                    const num_parsed = try parseInt(u16, num_trimmed, 10);
                    var j: u2 = 0;
                    for (gear.nums) |n| {
                        if (n == 0) {
                            gear.nums[j] = num_parsed;
                            break;
                        }
                        j += 1;
                    }
                }
                if (!gear.is_rightmost() and isDigit(gear.next_line.?[x + 1])) {
                    // digit found at bottom-right, but not middle top
                    var i: u3 = 0;
                    var sel = x + 1; // selected index
                    var num: [5]u8 = [5]u8{ 0, 0, 0, 0, 0 }; // container
                    while (sel <= 139 and isDigit(gear.next_line.?[sel])) : (sel += 1) {
                        num[i] = gear.next_line.?[sel];
                        i += 1;
                    }
                    const num_trimmed = std.mem.trim(u8, &num, &[_]u8{0});
                    const num_parsed = try parseInt(u16, num_trimmed, 10);
                    var j: u2 = 0;
                    for (gear.nums) |n| {
                        if (n == 0) {
                            gear.nums[j] = num_parsed;
                            break;
                        }
                        j += 1;
                    }
                }
            }

            total += gear.nums[0] * gear.nums[1];
            gear.reset();
        }

        prev_line = line;
    }

    return total;
}

pub fn main() !void {
    print("Day 03 (Part 1) answer: {any}\n", .{part1()});
    print("Day 03 (Part 2) answer: {any}\n", .{part2()});
}
