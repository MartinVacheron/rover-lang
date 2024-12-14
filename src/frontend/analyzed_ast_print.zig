const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const ArrayList = std.ArrayList;
const AnalyzedAst = @import("analyzed_ast.zig");
const AnalyzedStmt = AnalyzedAst.AnalyzedStmt;
const TypeManager = @import("analyzer.zig").TypeManager;

pub const AnalyzedAstPrinter = struct {
    source: []const u8,
    indent_level: u8 = 0,
    tree: std.ArrayList(u8),
    type_manager: *const TypeManager,

    const indent_size: u8 = 4;
    const spaces: [1024]u8 = [_]u8{' '} ** 1024;

    const Error = Allocator.Error || std.fmt.BufPrintError;
    const Self = @This();

    pub fn init(allocator: Allocator, type_manager: *const TypeManager) Self {
        return .{
            .source = undefined,
            .indent_level = 0,
            .tree = std.ArrayList(u8).init(allocator),
            .type_manager = type_manager,
        };
    }

    pub fn deinit(self: *Self) void {
        self.tree.deinit();
    }

    pub fn display(self: *const Self) void {
        print("\n--- Analyzed AST informations ---\n{s}", .{self.tree.items});
    }

    fn indent(self: *Self) !void {
        try self.tree.appendSlice(Self.spaces[0 .. self.indent_level * Self.indent_size]);
    }

    pub fn parse(self: *Self, source: []const u8, stmts: []const AnalyzedStmt) !void {
        self.source = source;

        for (stmts) |*stmt| {
            try switch (stmt.*) {
                .Binop => |*s| self.binop(s),
                .Unary => |*s| self.unary(s),
                .Variable => |*s| self.variable(s),
            };
        }
    }

    fn binop(self: *Self, stmt: *const AnalyzedAst.BinOp) !void {
        try self.indent();

        var buf: [100]u8 = undefined;
        const written = try std.fmt.bufPrint(
            &buf,
            "[Binop cast {s}, type {s}]\n",
            .{ @tagName(stmt.cast), self.type_manager.str(stmt.type_) },
        );
        try self.tree.appendSlice(written);
    }

    fn unary(self: *Self, stmt: *const AnalyzedAst.Unary) !void {
        try self.indent();
        var buf: [100]u8 = undefined;
        const written = try std.fmt.bufPrint(
            &buf,
            "[Unary type {s}]\n",
            .{self.type_manager.str(stmt.type_)},
        );
        try self.tree.appendSlice(written);
    }

    fn variable(self: *Self, stmt: *const AnalyzedAst.Variable) !void {
        try self.indent();
        var buf: [100]u8 = undefined;
        const written = try std.fmt.bufPrint(
            &buf,
            "[Variable scope {s}, index {}]\n",
            .{ @tagName(stmt.scope), stmt.index },
        );
        try self.tree.appendSlice(written);
    }
};