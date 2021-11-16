import sets
import deques
import sequtils
import strformat

import ../../graph
import ../../readwrite

iterator genericBfsEdges(
    dg: ref DirectedGraph,
    source: Node,
    neighbors: proc(node: Node): iterator(): Node = nil,
    depthLimit: int = -1,
    sortNeighbors: proc(nodes: seq[Node]): iterator(): Node = nil,
): Edge =
    var neighbors0: proc(node: Node): iterator(): Node = neighbors
    if sortNeighbors != nil:
        neighbors0 = proc(node: Node): iterator(): Node = sortNeighbors(neighbors(node).toSeq())
    var visited: HashSet[Node]
    visited.incl(source)
    var depthLimit0: int = depthLimit
    if depthLimit == -1:
        depthLimit0 = dg.len()
    var queue: Deque[tuple[node: Node, depthLimit: int, neighbors: iterator(): Node]]
    queue.addFirst((source, depthLimit0, neighbors0(source)))
    while queue.len() != 0:
        var parent: Node
        var depthNow: int
        var children: iterator(): Node
        (parent, depthNow, children) = queue.popFirst()
        for child in children():
            if child notin visited:
                yield (parent, child)
                if 1 < depthNow:
                    queue.addLast((child, depthNow - 1, neighbors0(child)))


iterator bfsEdges*(
    dg: ref DirectedGraph,
    source: Node,
    reverse: bool = false,
    depthLimit: int = -1,
    sortNeighbors: proc(nodes: seq[Node]): iterator(): Node = nil,
): Edge =
    var successors: proc(node: Node): iterator(): Node
    if reverse:
        successors =
            proc (node: Node): iterator(): Node =
                return getPredecessorsIterator(dg, node)
    else:
        successors =
            proc (node: Node): iterator(): Node =
                return getNeighborsIterator(dg, node)
    for edge in genericBfsEdges(dg, source, successors, depthLimit, sortNeighbors):
        yield edge

proc bfsTree*(
    dg: ref DirectedGraph,
    source: Node,
    reverse: bool = false,
    depthLimit: int = -1,
    sortNeighbors: proc(nodes: seq[Node]): iterator(): Node = nil,
): ref DirectedGraph =
    var tree = newDirectedGraph()
    tree.addNode(source)
    for edge in bfsEdges(
        dg,
        source,
        reverse,
        depthLimit,
        sortNeighbors,
    ):
        tree.addEdge(edge)
    return tree

iterator bfsPredecessors*(
    dg: ref DirectedGraph,
    source: Node,
    depthLimit: int = -1,
    sortNeighbors: proc(nodes: seq[Node]): iterator(): Node = nil,
): tuple[node: Node, predecessor: Node] =
    for (s, t) in bfsEdges(
        dg,
        source,
        false,
        depthLimit,
        sortNeighbors,
    ):
        yield (t, s)

iterator bfsSuccessors*(
    dg: ref DirectedGraph,
    source: Node,
    depthLimit: int = -1,
    sortNeighbors: proc(nodes: seq[Node]): iterator(): Node = nil,
): tuple[node: Node, successors: seq[Node]] =
    var parent = source
    var children = newSeq[Node]()
    for (p, c) in bfsEdges(
        dg,
        source,
        false,
        depthLimit,
        sortNeighbors,
    ):
        if p == parent:
            children.add(c)
            continue
        yield (parent, children)
        children = newSeq[Node]()
        children.add(c)
        parent = p
    yield (parent, children)


proc descendantsAtDistance*(
    dg: ref DirectedGraph,
    source: Node,
    distance: int
): HashSet[Node] =
    if not dg.hasNode(source):
        raise newException(KeyError, "source node not found in directed graph")
    var currentDistance = 0
    var currentLayer = initHashSet[Node]()
    currentLayer.incl(source)
    var visited = initHashSet[Node]()
    visited.incl(source)

    while currentDistance < distance:
        var nextLayer = initHashSet[Node]()
        for node in currentLayer:
            for child in dg.neighbors(node):
                if child notin visited:
                    visited.incl(child)
                    nextLayer.incl(child)
        currentLayer = nextLayer
        currentDistance += 1
    return currentLayer


when isMainModule:
    var G = newDirectedGraph()
    G.addEdge((0, 1))
    G.addEdge((1, 2))

    echo("---")
    for edge in G.edges:
        echo(edge)

    echo("--- bfsEdges ---")
    for edge in bfsEdges(G, source=0, reverse=false, depthLimit=1, sortNeighbors=nil):
        echo(edge)

    echo("--- bfsEdges ---")
    var root = 2
    var bfsOrderedNodes: seq[Node] = @[root]
    for edge in bfsEdges(G, source=root):
        bfsOrderedNodes.add(edge.toNode)
    echo(bfsOrderedNodes)

    echo("--- bfsTree ---")
    var H = newDirectedGraph()
    H.addEdge((0, 1))
    H.addEdge((1, 0))
    H.addEdge((1, 2))
    H.addEdge((2, 1))
    H.addEdge((2, 3))
    H.addEdge((3, 2))
    H.addEdge((3, 4))
    H.addEdge((4, 3))
    H.addEdge((4, 5))
    H.addEdge((5, 4))
    H.addEdge((5, 6))
    H.addEdge((6, 5))
    H.addEdge((2, 7))
    H.addEdge((7, 2))
    H.addEdge((7, 8))
    H.addEdge((8, 7))
    H.addEdge((8, 9))
    H.addEdge((9, 8))
    H.addEdge((9, 10))
    H.addEdge((10, 9))
    echo(H.edges.toSeq())
    var t = bfsTree(H, source=3, depthLimit=3)
    echo("tree")
    echo(t.edges.toSeq())

    echo("--- bfsPredecessors ---")
    for (node, predecessor) in bfsPredecessors(G, source=0):
        echo(fmt"{node}: {predecessor}")

    echo("--- bfsPredecessors ---")
    H = newDirectedGraph()
    H.addEdge((0, 1))
    H.addEdge((1, 2))
    H.addEdge((2, 3))
    H.addEdge((3, 4))
    H.addEdge((4, 7))
    H.addEdge((3, 5))
    H.addEdge((5, 6))
    H.addEdge((6, 7))
    # 0 -> 1 -> 2 -> 3 -> 4 ---> 7
    #                +-> 5 -> 6 -+
    for (node, predecessor) in bfsPredecessors(H, source=2):
        echo(fmt"{node}: {predecessor}")

    echo("--- bfsSuccessors ---")
    G = newDirectedGraph()
    G.addEdge((0, 1))
    G.addEdge((1, 2))
    G.addEdge((2, 3))
    G.addEdge((3, 4))
    G.addEdge((4, 5))
    # 0 -> 1 -> 2 -> 3 -> 4 -> 5
    for (node, successor) in bfsSuccessors(G, source=3):
        echo(fmt"{node}: {successor}")

    echo("--- descendantsAtDistance ---")
    G = newDirectedGraph()
    G.addEdge((0, 1))
    G.addEdge((0, 2))
    G.addEdge((1, 3))
    G.addEdge((1, 4))
    G.addEdge((2, 5))
    G.addEdge((2, 6))
    echo(descendantsAtDistance(G, 0, 2))
    echo(descendantsAtDistance(G, 5, 0))
    echo(descendantsAtDistance(G, 5, 1))