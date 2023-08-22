const std = @import("std");

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

    var iter = std.mem.splitSequence(u8, path.?, ":");
    var exemap = std.StringHashMap([]const u8).init(allocator);
    defer exemap.deinit();

    while (iter.next()) |loc| {
        if (loc.len == 0 or loc[0] != '/') {
            logger.warn("relative directory found in path: \"{s}\"", .{loc});
        }
        const dir = std.fs.cwd().openDir(loc, .{}) catch |err| {
            logger.warn("could not open \"{s}\": {?}", .{ loc, err });
            continue;
        };
        const dir_iterable = dir.openIterableDir(".", .{}) catch unreachable;
        var iter2 = dir_iterable.iterate();

        var val = try string_arena.dupe(u8, loc);
        while (iter2.next() catch |err| {
            logger.err("cannot iterate: {?}", .{err});
            continue;
        }) |file| {
            if (file.kind != .file) {
                continue;
            }
            if (exemap.get(file.name)) |existing| {
                logger.info("\"{s}\" of \"{s}\" shadowed by the one in \"{s}\"", .{ file.name, loc, existing });
            }

            // not system agnostic
            const stat = dir.statFile(file.name) catch |err| {
                logger.warn("could not stat \"{s}\": {?}", .{ file.name, err });
                continue;
            };
            const permissions = std.fs.File.PermissionsUnix{ .mode = stat.mode };
            if (!permissions.unixHas(.other, .execute) or !permissions.unixHas(.group, .execute) or !permissions.unixHas(.user, .execute)) {
                continue;
            }

            var key = try string_arena.dupe(u8, file.name);
            try exemap.put(key, val);
        }
    }
}
