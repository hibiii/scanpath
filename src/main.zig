const std = @import("std");

const logger = std.log;

pub fn main() !void {
    const path = std.os.getenv("PATH");
    if (path == null) {
        return error.PathNotSet;
    }

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var iter = std.mem.splitSequence(u8, path.?, ":");
    var exemap = std.StringHashMap(*[]const u8).init(allocator);
    defer exemap.deinit();

    while (iter.next()) |loc| {
        if (loc.len == 0 or loc[0] != '/') {
            logger.warn("skipping relative directory \"{s}\": unimplemented", .{loc});
            continue;
        }
        var dir = std.fs.openDirAbsolute(loc, .{ .access_sub_paths = true }) catch |err| {
            logger.warn("could not open \"{s}\": {?}", .{ loc, err });
            continue;
        };
        defer dir.close();
    }
}
