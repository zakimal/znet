import strformat
import sequtils
import sets
import deques

import ../../graph.nim
import ../../exception.nim

iterator genericBfsEdges*(
    g: Graph,
    source: Node,
    neighbors: ref proc(node: Node): iterator: Node = nil,
    depthLimit: int = -1,
    sortNeighbors: ref proc(nodes: seq[Node]): iterator: Node = nil
): Edge =
    var neighborsUsing: ref proc(node: Node): iterator: Node = new proc(node: Node): iterator: Node
    if sortNeighbors != nil:
        neighborsUsing[] = proc(node: Node): iterator: Node =
            return iterator: Node =
                for nbr in sortNeighbors[](neighbors[](node).toSeq()):
                    yield nbr
    else:
        # neighborsUsing[] = proc(node: Node): iterator: Node =
        #     return g.neighborIterator(node)
        neighborsUsing[] = neighbors[]

    var visited: HashSet[Node] = initHashSet[Node]()
    visited.incl(source)

    var depthLimitUsing = depthLimit;
    if depthLimit == -1:
        depthLimitUsing = len(g)

    var queue: Deque[tuple[node: Node, depthLimit: int, neighborIterator: iterator: Node]]
        = initDeque[tuple[node: Node, depthLimit: int, neighborIterator: iterator: Node]]()
    queue.addLast((source, depthLimitUsing, neighborsUsing[](source)))

    while len(queue) != 0:
        let (parent, depthNow, children) = queue[0]
        for child in children:
            if child notin visited:
                yield (parent, child)
                visited.incl(child)
                if 1 < depthNow:
                    queue.addLast((child, depthNow - 1, neighborsUsing[](child)))
        discard queue.popFirst()

iterator bfsEdges*(
    g: Graph,
    source: Node,
    reverse: bool = false,
    depthLimit: int = -1,
    sortNeighbors: ref proc(nodes: seq[Node]): iterator: Node = nil
): Edge =
    var successors: ref proc(node: Node): iterator: Node = new proc(node: Node): iterator: Node
    if reverse and g.isDirected:
        successors[] = proc(node: Node): iterator: Node =
            return DirectedGraph(g).predecessorIterator(node)
    else:
        successors[] = proc(node: Node): iterator: Node =
            return g.neighborIterator(node)
    for edge in genericBfsEdges(g, source, successors, depthLimit, sortNeighbors):
        yield edge

proc bfsTree*(
    g: Graph,
    source: Node,
    reverse: bool = false,
    depthLimit: int = -1,
    sortNeighbors: ref proc(nodes: seq[Node]): iterator: Node = nil
): DirectedGraph =
    var T = newDirectedGraph()
    T.addNode(source)
    for edge in bfsEdges(
        g,
        source,
        reverse=reverse,
        depthLimit=depthLimit,
        sortNeighbors=sortNeighbors
    ):
        T.addEdge(edge)
    return T

iterator bfsPredecessors*(
    g: Graph,
    source: Node,
    depthLimit: int = -1,
    sortNeighbors: ref proc(nodes: seq[Node]): iterator: Node = nil
): tuple[node: Node, predecessor: Node] =
    for (s, t) in bfsEdges(
        g,
        source,
        depthLimit=depthLimit,
        sortNeighbors=sortNeighbors
    ):
        yield (t, s)

iterator bfsSuccessors*(
    g: Graph,
    source: Node,
    depthLimit: int = -1,
    sortNeighbors: ref proc(nodes: seq[Node]): iterator: Node = nil
): tuple[node: Node, successor: seq[Node]] =
    var parent = source
    var children: seq[Node] = newSeq[Node]()
    for (p, c) in bfsEdges(
        g,
        source,
        depthLimit=depthLimit,
        sortNeighbors=sortNeighbors
    ):
        if p == parent:
            children.add(c)
            continue
        yield (parent, children)
        children = @[c]
        parent = p
    yield (parent, children)


proc descendantsAtDistance*(
    g: Graph,
    source: Node,
    distance: int
): HashSet[Node] =
    if not g.hasNode(source):
        var e = ZNetError()
        e.msg = fmt"The node {source} is not in the graph"
        raise e
    var currentDistance = 0
    var currentLayer: HashSet[Node] = initHashSet[Node]()
    currentLayer.incl(source)
    var visited: HashSet[Node] = initHashSet[Node]()
    visited.incl(source)

    while currentDistance < distance:
        var nextLayer: HashSet[Node] = initHashSet[Node]()
        for node in currentLayer:
            for child in g.neighbors(node):
                if child notin visited:
                    visited.incl(child)
                    nextLayer.incl(child)
        currentLayer = nextLayer
        currentDistance += 1
    return currentLayer

when isMainModule:
    echo("bfsEdges")
    var G = newGraph()
    G.addEdgesFrom(@[(0, 1), (1, 2), (2, 3)])
    echo(G.bfsEdges(source=0).toSeq())

    var DG = newDirectedGraph()
    DG.addEdgesFrom(@[(0, 1), (2, 1), (2, 3)])
    echo(DG.bfsEdges(source=0).toSeq())

    echo("bfsTree")
    G = newGraph()
    G.addEdgesFrom(@[(0, 1), (1, 2)])
    echo(G.bfsTree(1).edges())
    var H = newGraph()
    H.addPath(@[0, 1, 2, 3, 4, 5, 6])
    H.addPath(@[2, 7, 8, 9, 10])
    echo(H.bfsTree(source=3, depthLimit=3).edges())

    echo("bfsPredecessors")
    G = newGraph()
    G.addPath(@[0, 1, 2])
    echo(G.bfsPredecessors(source=0).toSeq())
    H = newGraph()
    H.addEdgesFrom(@[(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (2, 6)])
    echo(H.bfsPredecessors(source=0).toSeq())
    var M = newGraph()
    M.addPath(@[0, 1, 2, 3, 4, 5, 6])
    M.addPath(@[2, 7, 8, 9, 10])
    echo(M.bfsPredecessors(source=1, depthLimit=3).toSeq())
    var DN = newDirectedGraph()
    DN.addPath(@[0, 1, 2, 3, 4, 7])
    DN.addPath(@[3, 5, 6, 7])
    echo(DN.bfsPredecessors(source=2).toSeq())

    echo("bfsSuccessors")
    G = newGraph()
    G.addPath(@[0, 1, 2])
    echo(G.bfsSuccessors(source=0).toSeq())
    H = newGraph()
    H.addEdgesFrom(@[(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (2, 6)])
    echo(H.bfsSuccessors(source=0).toSeq())
    G = newGraph()
    G.addPath(@[0, 1, 2, 3, 4, 5, 6])
    G.addPath(@[2, 7, 8, 9, 10])
    echo(G.bfsSuccessors(source=1, depthLimit=3).toSeq())
    DG = newDirectedGraph()
    DG.addPath(@[0, 1, 2, 3, 4, 5])
    echo(DG.bfsSuccessors(source=3).toSeq())

    echo("descendantsAtDistance")
    G = newGraph()
    G.addPath(@[0, 1, 2, 3, 4])
    echo(G.descendantsAtDistance(2, 2))
    var DH = newDirectedGraph()
    DH.addEdgesFrom(@[(0, 1), (0, 2), (1, 3), (1, 4), (2, 5), (2, 6)])
    echo(DH.descendantsAtDistance(0, 2))
    echo(DH.descendantsAtDistance(5, 0))
    echo(DH.descendantsAtDistance(5, 1))