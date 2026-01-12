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

        const AdjacencyList = std.AutoHashMap(Node, EdgeList);
        const Self = @This();

        pub const Edge = struct {
            to: Node,
            weight: ?Weight,
        };
        const EdgeList = std.ArrayList(Edge);

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

        const NeighborIterator = struct {
            graph: *const Self,
            node: Node,
            index: usize,

            pub fn next(self: *NeighborIterator) ?Node {
                const edge_list = self.graph.adjacency_list.get(self.node) orelse return null;
                if (self.index < edge_list.items.len) {
                    defer self.index += 1;
                    return edge_list.items[self.index].to;
                }
                return null;
            }
        };

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

        pub fn add_node(self: *Self, node: Node) void {
            const edge: EdgeList = .empty;
            const result = self.adjacency_list.getOrPut(node) catch unreachable;
            if (!result.found_existing) {
                result.value_ptr.* = edge;
                self.node_count += 1;
            }
        }

        pub fn add_edge(self: *Self, from: Node, to: Node, weight: ?Weight) void {
            const edge = Edge{
                .to = to,
                .weight = weight,
            };

            var result = self.adjacency_list.getOrPut(from) catch unreachable;
            if (!result.found_existing) {
                result.value_ptr.* = EdgeList.empty;
                self.node_count += 1;
            }
            result.value_ptr.append(self.allocator, edge) catch unreachable;
            self.edge_count += 1;

            if (!self.adjacency_list.contains(to)) {
                self.add_node(to);
            }
        }

        pub fn remove_node(self: *Self, node: Node) void {
            if (self.adjacency_list.fetchRemove(node)) |entry| {
                var edge_list = entry.value;
                edge_list.deinit(self.allocator);
                self.node_count -= 1;
            }

            var it = self.adjacency_list.valueIterator();
            while (it.next()) |edge_list| {
                for (edge_list.items, 0..) |edge, i| {
                    if (edge.to == node) {
                        _ = edge_list.orderedRemove(i);
                        self.edge_count -= 1;
                        break;
                    }
                }
            }
        }

        pub fn remove_edge(self: *Self, from: Node, to: Node) void {
            var edge_list = self.adjacency_list.get(from) orelse return;
            for (edge_list.items, 0..) |edge, i| {
                if (edge.to == to) {
                    _ = edge_list.orderedRemove(i);
                    self.edge_count -= 1;
                    break;
                }
            }
        }

        pub fn neighbors(self: *const Self, node: Node) NeighborIterator {
            return .{
                .graph = self,
                .node = node,
                .index = 0,
            };
        }
        //pub fn nodes(self: Self) NodeIterator {}
        //pub fn edges(self: Self) EdgeIterator {}
        //pub fn get_edge_weight(self: Self, from: Node, to: Node) ?Weight {}
    };
}

test "api" {
    var graph: Graph(u8, u8) = .init(testing.allocator);
    defer graph.deinit();

    graph.add_node(8);
    graph.add_node(255);
    graph.add_node(0);
    graph.add_node(18);

    graph.add_edge(2, 24, null);
    graph.add_edge(8, 18, null);
    graph.add_edge(8, 255, null);
    graph.add_edge(8, 0, null);
    graph.add_edge(8, 255, null);
    graph.add_edge(255, 8, null);

    var count: usize = 0;
    var it = graph.neighbors(8);
    while (it.next()) |_| {
        count += 1;
    }
    try testing.expectEqual(count, graph.adjacency_list.get(8).?.items.len);

    graph.remove_node(2);
    graph.remove_node(2);

    graph.remove_edge(8, 255);
    graph.remove_edge(8, 255);
    graph.remove_edge(8, 255);

    try testing.expectEqual(5, graph.node_count);
    try testing.expectEqual(4, graph.edge_count);
}
