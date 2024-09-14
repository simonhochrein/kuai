const std = @import("std");
const ziglua = @import("ziglua");

const testing = std.testing;
const Lua = ziglua.Lua;

fn add(a: i32, b: i32) i32 {
    return a + b;
}

const Build = struct { name: []const u8, version: u32 };

fn debug(lua: *Lua, index: i32) !void {
    const out = std.io.getStdOut();

    switch (lua.typeOf(index)) {
        .string => {
            _ = try out.write("\"");
            _ = try out.write(try lua.toString(index));
            _ = try out.write("\"");
        },
        .table => {
            lua.pushValue(index);
            lua.pushNil();
            _ = try out.write("{ ");
            while (lua.next(-2)) {
                debug(lua, -2) catch unreachable;
                _ = try out.write(": ");
                debug(lua, -1) catch unreachable;
                _ = try out.write(", ");

                lua.pop(1);
            }
            lua.pop(1);
            _ = try out.write("}");
        },
        .number => {
            if (lua.isInteger(index)) {
                const value = try lua.toInteger(index);
                std.debug.print("{}", .{value});
            } else {
                const value = try lua.toNumber(index);
                std.debug.print("{}", .{value});
            }
        },
        else => {
            _ = try out.write("<");
            _ = try out.write(lua.typeNameIndex(index));
            _ = try out.write(">");
        },
    }

    return;
}

fn build(lua: *Lua) i32 {
    lua.pushNil();
    while (lua.next(1)) {
        debug(lua, -1) catch unreachable;

        lua.pop(1);
    }

    return 0;
}

fn libraryOpts(lua: *Lua) i32 {
    _ = lua.pushValue(1);

    _ = lua.pushString("type");
    _ = lua.pushString("library");
    lua.setTable(-3);
    return 1;
}

fn library(lua: *Lua) i32 {
    const name = lua.toString(-1) catch "";
    std.log.err("{s}", .{name});
    lua.pushFunction(ziglua.wrap(libraryOpts));

    return 1;
}

pub fn loadConfig() anyerror!void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var lua = try Lua.init(&allocator);
    defer lua.deinit();

    lua.pushAny(add) catch unreachable;
    lua.setGlobal("add");

    lua.pushFunction(ziglua.wrap(build));
    lua.setGlobal("build");

    lua.pushFunction(ziglua.wrap(library));
    lua.setGlobal("library");

    lua
        .openBase();

    const fileOrErr = std.fs.cwd().statFile("kuai.lua");

    if (fileOrErr == error.FileNotFound) {
        std.log.err("Not found", .{});
        return;
    }

    _ = fileOrErr catch unreachable;

    lua.doFile("kuai.lua") catch {
        std.log.err("Lua Runtime Error: {s}", .{try lua.toString(-1)});
    };
}
