const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;
const Allocator = std.mem.Allocator;

/// Directed graph
pub fn Graph(comptime Node: type, comptime Weight: type) type {
    return struct {
        allocator: Allocator,
        adjacency_list: AdjacencyList,
        node_count: usize,
        edge_count: usize,

        const AdjacencyList = std.AutoHashMap(Node, std.ArrayList(Edge));
        const Self = @This();

        const Edge = struct {
            to: Node,
            weight: ?Weight,
        };
//
        //const NodeIterator = struct {
            //graph: *const Graph(Node, Weight),
//
            //pub fn next(self: NodeIterator) ?Node {}
        //};
//
        //const EdgeIterator = struct {
            //graph: *const Graph(Node, Weight),
//
            //pub fn next(self: EdgeIterator) ?Edge {}
        //};
//
        //const NeighborIterator = struct {
            //list: AdjacencyList,
            //
            //pub fn next(self: EdgeIterator) ?Node {}
        //};

        pub fn init(allocator: Allocator) Self {
            return .{
                .allocator = allocator,
                .adjacency_list = AdjacencyList.init(allocator),
                .node_count = 0,
                .edge_count = 0,
            };
        }

        pub fn deinit(self: *Self) void {
            var it = self.adjacency_list.valueIterator();
            while (it.next()) |edge_list| {
                edge_list.deinit(self.allocator);
            }
            self.adjacency_list.deinit();
        }

        //pub fn add_node(self: *Self, node: Node) void {}
        //pub fn add_edge(self: *Self, from: Node, to: Node, weight: ?Weight) void {}
        //pub fn remove_edge(self: *Self, from: Node, to: Node) void {}
        //pub fn neighbors_iterator(self: Self, node: Node) NeighborIterator {}
        //pub fn nodes_iterator(self: Self) NodeIterator {}
        //pub fn edges_iterator(self: Self) EdgeIterator {}
        //pub fn get_edge_weight(self: Self, from: Node, to: Node) ?Weight {}
    };
}

test "api" {
    var graph: Graph(u8, u8) = .init(testing.allocator);
    defer graph.deinit();

    try testing.expectEqual(0, graph.node_count);
    try testing.expectEqual(0, graph.edge_count);
}
