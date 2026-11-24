//! What every format shares: detection, the failure for unknown input,
//! empty input, and the readers.

const std = @import("std");
const oracle = @import("oracle.zig");

const gpa = std.testing.allocator;

test "unknown and empty inputs fail as in the original" {
    const inputs = [_][]const u8{ "", "x", "not an image at all", &@as([300]u8, @splat(0)) };
    for (inputs) |bytes| {
        try oracle.expectAllSame(gpa, bytes, .{ .name = "unknown" });
    }
}

test "fuzz: short random inputs fail as in the original" {
    const inputs = [_][]const u8{ "", "\x89PNG", "\xff\xd8\xff", "BM", "GIF89a", "8BPS", "P5\n" };
    try @import("fuzz.zig").run(gpa, .{ .name = "short inputs", .seed = 0x5eed_0001 }, &inputs);
}

test "a float load whose 8-bit load fails a size check as out of memory fails as in the original" {
    // A JPEG frame header of 46340 x 46340, one component: the image passes
    // the `INT_MAX` check, but its sample buffer, padded to whole blocks,
    // does not, which the original reports as out of memory.
    const bytes = "\xff\xd8\xff\xc0\x00\x0b\x08\xb5\x04\xb5\x04\x01\x01\x11\x00";
    for ([_]oracle.Bits{ .u8, .u16, .f32 }) |bits| {
        try oracle.expectLoadSame(gpa, bytes, .{ .bits = bits }, .{ .name = "size check" }, .same);
    }
}
