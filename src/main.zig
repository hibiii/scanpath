const std = @import("std");

const Scanner = @import("./scanner.zig");

const logger = std.log;

pub fn main() !void {
    const path = std.os.getenv("PATH");
    if (path == null) {
        return error.PathNotSet;
    }

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var arena_alloc = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_alloc.deinit();
    const string_arena = arena_alloc.allocator();

    var exemap = std.StringHashMap([]const u8).init(allocator);
    defer exemap.deinit();

    var scanner = Scanner{ .allocator = string_arena, .exe_map = exemap };

    var iter = std.mem.splitSequence(u8, path.?, ":");
    while (iter.next()) |location| {
        try scanner.scanDirForFiles(location);
    }
}
