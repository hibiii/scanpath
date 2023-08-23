const Scanner = @This();
const std = @import("std");

allocator: std.mem.Allocator,
exe_map: std.StringHashMap([]const u8),

const logger = std.log;

pub fn scanDirForFiles(self: *Scanner, location: []const u8) !void {
    if (location.len == 0 or location[0] != '/') {
        logger.warn("relative directory found in path: \"{s}\"", .{location});
    }
    const dir = std.fs.cwd().openDir(location, .{}) catch |err| {
        logger.warn("could not open \"{s}\": {?}", .{ location, err });
        return;
    };
    const dir_iterable = dir.openIterableDir(".", .{}) catch unreachable;
    var iter2 = dir_iterable.iterate();

    var val = try self.allocator.dupe(u8, location);
    while (iter2.next() catch |err| {
        logger.err("cannot iterate over {s}: {?}", .{ location, err });
        return;
    }) |file| {
        if (file.kind != .file) {
            continue;
        }
        if (self.exe_map.get(file.name)) |existing| {
            logger.info("\"{s}\" of \"{s}\" shadowed by the one in \"{s}\"", .{ file.name, location, existing });
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

        var key = try self.allocator.dupe(u8, file.name);
        try self.exe_map.put(key, val);
    }
}
