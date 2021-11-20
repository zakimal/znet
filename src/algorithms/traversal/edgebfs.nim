# import strformat
# import sequtils
# import sets
# import deques

# import ../../graph.nim
# import ../../exception.nim

# const forward = "forward"
# const reverse = "reverse"

# iterator edgeBfs(g: Graph): Edge =
#     var nodes: seq[Node] = g.nbunchIter().toSeq()
#     if len(nodes) == 0:
#         var e = ZNetError()
#         e.msg = "cannnot traverse in BFS on graph with no nodes"
#         raise e
#     var edgesFrom: proc(node: Node): iterator: Edge =
#         proc(node: Node): iterator: Edge =
#             return g.edgeIterator(node)
#     let checkReverse: bool = false
#     let makeEdgeId = proc(edge: Edge): tuple[nodeSet: HashSet[Node], dir: string] =
#         var nodeSet = initHashSet[Node]()
#         nodeSet.incl(edge.u)
#         nodeSet.incl(edge.v)
#         return (nodeSet, "")

#     var visitedNodes = initHashSet[Node]()
#     for n in nodes:
#         visitedNodes.incl(n)
#     var visitedEdges = initHashSet[tuple[nodeSet: HashSet[Node], dir: string]]()
#     var queue = initDeque[tuple[node: Node, children: iterator: Edge]]()
#     for n in nodes:
#         queue.addLast((n, edgesFrom(n)))
#     while len(queue) != 0:
#         var childrenEdges = queue.popFirst().children
#         for edge in childrenEdges:
#             var child: Node
#             if checkReverse:
#                 child = edge.u
#             else:
#                 child = edge.v
#             if child notin visitedNodes:
#                 visitedNodes.incl(child)
#                 queue.addLast((child, edgesFrom(child)))
#             var edgeId = makeEdgeId(edge)
#             if edgeId notin visitedEdges:
#                 visitedEdges.incl(edgeId)
#                 yield edge
# # iterator edgeBfs(g: Graph, source: seq[Node])
# # iterator edgeBfs(g: Graph, orientation: string)
# # iterator edgeBfs(g: Graph, orientation: string, source: Node)
# # iterator edgeBfs(g: Graph, orientation: string, source: seq[Node])

# iterator edgeBfs(dg: DirectedGraph): Edge =
#     var nodes: seq[Node] = dg.nbunchIter().toSeq()
#     if len(nodes) == 0:
#         var e = ZNetError()
#         e.msg = "cannnot traverse in BFS on graph with no nodes"
#         raise e
#     var edgesFrom: proc(node: Node): iterator: Edge =
#         proc(node: Node): iterator: Edge =
#             return dg.edgeIterator(node)
#     let makeEdgeId = proc(edge: Edge): Edge =
#         return edge

#     var visitedNodes = initHashSet[Node]()
#     for n in nodes:
#         visitedNodes.incl(n)
#     var visitedEdges = initHashSet[Edge]()
#     var queue = initDeque[tuple[node: Node, children: iterator: Edge]]()
#     for n in nodes:
#         queue.addLast((n, edgesFrom(n)))
#     while len(queue) != 0:
#         var childrenEdges = queue.popFirst().children
#         for edge in childrenEdges:
#             var child = edge.u
#             if child notin visitedNodes:
#                 visitedNodes.incl(child)
#                 queue.addLast((child, edgesFrom(child)))
#             var edgeId = makeEdgeId(edge)
#             if edgeId notin visitedEdges:
#                 visitedEdges.incl(edgeId)
#                 yield edge
# # iterator edgeBfs(dg: DirectedGraph, source: seq[Node])
# # iterator edgeBfs(dg: DirectedGraph, orientation: string)
# # iterator edgeBfs(dg: DirectedGraph, orientation: string, source: Node)
# # iterator edgeBfs(dg: DirectedGraph, orientation: string, source: seq[Node])

# when isMainModule:
#     var G = newGraph()
#     var DG = newDirectedGraph()
#     var nodes = @[0, 1, 2, 3]
#     var edges = @[(0, 1), (1, 0), (1, 0), (2, 0), (2, 1), (3, 1)]

#     G.addNodesFrom(nodes)
#     G.addEdgesFrom(edges)

#     echo(G.edgeBfs().toSeq())
#     # [(0, 1), (0, 2), (1, 2), (1, 3)]
#     # echo(G.edgeBfs(source=nodes).toSeq())
#     # [(0, 1), (0, 2), (1, 2), (1, 3)]
#     # echo(G.edgeBfs(source=@[3, 2, 1, 0]).toSeq())
#     # [(3, 1), (2, 0), (2, 1), (1, 0)]
#     # echo(G.edgeBfs(source=@[3, 0, 1, 2]).toSeq())
#     # [(3, 1), (2, 0), (2, 1), (1, 0)]

#     DG.addNodesFrom(nodes)
#     DG.addEdgesFrom(edges)

#     echo(DG.edgeBfs().toSeq())
#     # [(0, 1), (1, 0), (2, 0), (2, 1), (3, 1)]
#     # echo(DG.edgeBfs(source=nodes).toSeq())
#     # [(0, 1), (1, 0), (2, 0), (2, 1), (3, 1)]
#     # echo(DG.edgeBfs(source=@[3, 2, 1, 0]).toSeq())
#     # [(3, 1), (2, 0), (2, 1), (1, 0), (0, 1)]
#     # echo(DG.edgeBfs(source=@[3, 0, 1, 2]).toSeq())
#     # [(3, 1), (0, 1), (1, 0), (2, 0), (2, 1)]