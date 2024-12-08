const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const Ast = @import("ast.zig");
const Expr = Ast.Expr;
const Stmt = Ast.Stmt;

pub const AstPrinter = struct {
    source: []const u8,
    indent_level: u8 = 0,
    tree: std.ArrayList(u8),

    const indent_size: u8 = 4;
    const spaces: [1024]u8 = [_]u8{' '} ** 1024;

    const Error = Allocator.Error || std.fmt.BufPrintError;
    const Self = @This();

    pub fn init(allocator: Allocator) Self {
        return .{
            .source = undefined,
            .indent_level = 0,
            .tree = std.ArrayList(u8).init(allocator),
        };
    }

    pub fn reinit(self: *Self) void {
        self.tree.clearRetainingCapacity();
    }

    pub fn deinit(self: *Self) void {
        self.tree.deinit();
    }

    pub fn display(self: *const Self) void {
        print("{s}", .{self.tree.items});
    }

    pub fn parse_ast(self: *Self, source: []const u8, nodes: []const Stmt) !void {
        self.source = source;

        for (nodes) |node| {
            try switch (node) {
                .Print => |*n| self.print_stmt(n),
                .VarDecl => |*n| self.var_decl(n),
                .Expr => |n| self.print_expr(n),
            };
        }
    }

    fn print_stmt(self: *Self, stmt: *const Ast.Print) !void {
        try self.indent();
        try self.tree.appendSlice("[Print]\n");
        self.indent_level += 1;
        try self.print_expr(stmt.expr);
        self.indent_level -= 1;
    }

    fn var_decl(self: *Self, stmt: *const Ast.VarDecl) !void {
        try self.indent();
        var buf: [100]u8 = undefined;

        const type_name = if (stmt.type_) |t| t.str() else "none";
        const written = try std.fmt.bufPrint(&buf, "[Var declaration {s}, type {s}, value\n", .{ stmt.name, type_name });
        try self.tree.appendSlice(written);

        self.indent_level += 1;

        if (stmt.value) |v| {
            try self.print_expr(v);
        } else {
            try self.tree.appendSlice("    none\n");
        }

        self.indent_level -= 1;

        try self.tree.appendSlice("]\n");
    }

    fn print_expr(self: *Self, expr: *const Expr) Error!void {
        try switch (expr.*) {
            .BinOp => |*e| self.binop_expr(e),
            .BoolLit => |*e| self.bool_expr(e),
            .Grouping => |*e| self.grouping_expr(e),
            .FloatLit => |*e| self.float_expr(e),
            .IntLit => |*e| self.int_expr(e),
            .NullLit => self.null_expr(),
            .StringLit => |*e| self.string_expr(e),
            .Unary => |*e| self.unary_expr(e),
        };
    }

    fn binop_expr(self: *Self, expr: *const Ast.BinOp) Error!void {
        try self.indent();

        var buf: [100]u8 = undefined;
        const written = try std.fmt.bufPrint(&buf, "[Binop {s}]\n", .{expr.op.symbol()});
        try self.tree.appendSlice(written);

        self.indent_level += 1;
        try self.print_expr(expr.lhs);
        try self.print_expr(expr.rhs);
        self.indent_level -= 1;
    }

    fn grouping_expr(self: *Self, expr: *const Ast.Grouping) Error!void {
        try self.indent();
        try self.tree.appendSlice("[Grouping]\n");

        self.indent_level += 1;
        try self.print_expr(expr.expr);
        self.indent_level -= 1;
    }

    fn bool_expr(self: *Self, expr: *const Ast.BoolLit) Error!void {
        try self.indent();
        var buf: [100]u8 = undefined;
        const written = try std.fmt.bufPrint(&buf, "[Bool literal {}]\n", .{expr.value});
        try self.tree.appendSlice(written);
    }

    fn float_expr(self: *Self, expr: *const Ast.FloatLit) Error!void {
        try self.indent();
        var buf: [100]u8 = undefined;
        const written = try std.fmt.bufPrint(&buf, "[Float literal {d}]\n", .{expr.value});
        try self.tree.appendSlice(written);
    }

    fn int_expr(self: *Self, expr: *const Ast.IntLit) Error!void {
        try self.indent();
        var buf: [100]u8 = undefined;
        const written = try std.fmt.bufPrint(&buf, "[Int literal {}]\n", .{expr.value});
        try self.tree.appendSlice(written);
    }

    fn null_expr(self: *Self) Error!void {
        try self.indent();
        try self.tree.appendSlice("[Null literal]\n");
    }

    fn string_expr(self: *Self, expr: *const Ast.StringLit) Error!void {
        try self.indent();
        var buf: [100]u8 = undefined;
        const written = try std.fmt.bufPrint(&buf, "[String literal {s}]\n", .{expr.value});
        try self.tree.appendSlice(written);
    }

    fn unary_expr(self: *Self, expr: *const Ast.Unary) Error!void {
        try self.indent();

        var buf: [100]u8 = undefined;
        const written = try std.fmt.bufPrint(&buf, "[Unary {s}]\n", .{expr.op.symbol()});
        try self.tree.appendSlice(written);

        self.indent_level += 1;
        try self.print_expr(expr.rhs);
        self.indent_level -= 1;
    }

    fn indent(self: *Self) !void {
        try self.tree.appendSlice(Self.spaces[0 .. self.indent_level * Self.indent_size]);
    }
};
