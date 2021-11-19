import strformat
import sequtils
import sets
import deques
import tables

import ../../graph.nim
import ../../exception.nim

iterator dfsEdges*(
    g: Graph,
    source: Node = None,
    depthLimit: int = -1
): Edge =
    var nodes: seq[Node];
    if source == None:
        nodes = g.nodeSeq()
    else:
        nodes = @[source]

    var visited: HashSet[Node] = initHashSet[Node]()

    var depthLimitUsing: int
    if depthLimit == -1:
        depthLimitUsing = len(g)
    else:
        depthLimitUsing = depthLimit

    for start in nodes:
        if start in visited:
            continue
        visited.incl(start)
        var stack: Deque[tuple[parent: Node, depthLimit: int, children: iterator: Node]]
            = initDeque[tuple[parent: Node, depthLimit: int, children: iterator: Node]]()
        stack.addFirst((start, depthLimitUsing, g.neighborIterator(start)))
        while len(stack) != 0:
            var (parent, depthNow, children) = stack.popLast()
            for child in children:
                if child notin visited:
                    yield (parent, child)
                    visited.incl(child)
                    if 1 < depthNow:
                        stack.addLast((child, depthNow - 1, g.neighborIterator(child)))

proc dfsTree*(
    g: Graph,
    source: Node = None,
    depthLimit: int = -1
): DirectedGraph =
    var T = newDirectedGraph()
    if source == None:
        T.addNodesFrom(g.nodeSeq())
    else:
        T.addNode(source)
    T.addEdgesFrom(dfsEdges(g, source, depthLimit).toSeq())
    return T

proc dfsPredecessors*(
    g: Graph,
    source: Node = None,
    depthLimit: int = -1
): Table[Node, Node] =
    var ret: Table[Node, Node] = initTable[Node, Node]()
    for (s, t) in dfsEdges(g, source, depthLimit):
        ret[t] = s
    return ret

proc dfsSuccessors*(
    g: Graph,
    source: Node = None,
    depthLimit: int = -1
): Table[Node, seq[Node]] =
    var ret: Table[Node, seq[Node]] = initTable[Node, seq[Node]]()
    for (s, t) in g.dfsEdges(source=source, depthLimit=depthLimit):
        if s notin ret:
            ret[s] = @[t]
        else:
            ret[s].add(t)
    return ret


iterator dfsLabeledEdges*(
    g: Graph,
    source: Node = None,
    depthLimit: int = -1
): tuple[u, v: Node, dir: string, depth: int] =
    var nodes: seq[Node];
    if source == None:
        nodes = g.nodes()
    else:
        nodes = @[source]

    var visited: HashSet[Node] = initHashSet[Node]()
    var visitedEdge: HashSet[Edge] = initHashSet[Edge]()

    var depthLimitUsing: int
    if depthLimit == -1:
        depthLimitUsing = len(g)
    else:
        depthLimitUsing = depthLimit

    for start in nodes:
        if start in visited:
            continue
        yield (start, start, "forward", 0)
        visited.incl(start)
        var stack: Deque[tuple[parent: Node, depthLimit: int, children: iterator: Node]]
            = initDeque[tuple[parent: Node, depthLimit: int, children: iterator: Node]]()
        stack.addFirst((start, depthLimitUsing, g.neighborIterator(start)))
        var goBackFlag: bool = false
        while len(stack) != 0:
            var (parent, depthNow, children) = stack[^1]
            for child in children:
                if child in visited:
                    yield (parent, child, "nontree", depthLimitUsing - depthNow + 1)
                else:
                    yield (parent, child, "forward", depthLimitUsing - depthNow + 1)
                    visited.incl(child)
                    if 1 < depthNow:
                        stack.addLast((child, depthNow - 1, g.neighborIterator(child)))
                visitedEdge.incl((parent, child))
            # if visitedEdge == g.toDirected().edgeSet() or depthNow == 1:
            if visitedEdge == g.toDirected().edgeSet() or depthNow == 1 or goBackFlag:
                goBackFlag = true
                discard stack.popLast()
                if len(stack) != 0:
                    if (stack[^1][0], parent) in g.edgeSet():
                        yield (stack[^1][0], parent, "reverse", depthLimitUsing - depthNow + 1)
        yield (start, start, "reverse", 0)

iterator dfsLabeledEdges*(
    dg: DirectedGraph,
    source: Node = None,
    depthLimit: int = -1
): tuple[u, v: Node, dir: string, depth: int] =
    var nodes: seq[Node];
    if source == None:
        nodes = dg.nodes()
    else:
        nodes = @[source]

    var visited: HashSet[Node] = initHashSet[Node]()
    var visitedEdge: HashSet[Edge] = initHashSet[Edge]()

    var depthLimitUsing: int
    if depthLimit == -1:
        depthLimitUsing = len(dg)
    else:
        depthLimitUsing = depthLimit

    for start in nodes:
        if start in visited:
            continue
        yield (start, start, "forward", 0)
        visited.incl(start)
        var stack: Deque[tuple[parent: Node, depthLimit: int, children: iterator: Node]]
            = initDeque[tuple[parent: Node, depthLimit: int, children: iterator: Node]]()
        stack.addFirst((start, depthLimitUsing, dg.neighborIterator(start)))
        var goBackFlag: bool = false
        while len(stack) != 0:
            var (parent, depthNow, children) = stack[^1]
            for child in children:
                if child in visited:
                    yield (parent, child, "nontree", depthLimitUsing - depthNow + 1)
                else:
                    yield (parent, child, "forward", depthLimitUsing - depthNow + 1)
                    visited.incl(child)
                    if 1 < depthNow:
                        stack.addLast((child, depthNow - 1, dg.neighborIterator(child)))
                visitedEdge.incl((parent, child))
            if visitedEdge == dg.edgeSet() or depthNow == 1 or goBackFlag:
                goBackFlag = true
                discard stack.popLast()
                if len(stack) != 0:
                    if (stack[^1][0], parent) in dg.edgeSet():
                        yield (stack[^1][0], parent, "reverse", depthLimitUsing - depthNow + 1)
        yield (start, start, "reverse", 0)

iterator dfsPostorderNodes*(
    g: Graph,
    source: Node = None,
    depthLimit: int = -1
): Node =
    if depthLimit == -1:
        for edge in g.dfsLabeledEdges(source=source, depthLimit=depthLimit):
            if edge.dir == "reverse":
                yield edge.v
    else:
        for edge in g.dfsLabeledEdges(source=source, depthLimit=depthLimit):
            if edge.dir == "reverse" and edge.depth <= depthLimit:
                yield edge.v

iterator dfsPreorderNodes*(
    g: Graph,
    source: Node = None,
    depthLimit: int = -1
): Node =
    if depthLimit == -1:
        for edge in g.dfsLabeledEdges(source=source, depthLimit=depthLimit):
            if edge.dir == "forward":
                yield edge.v
    else:
        for edge in g.dfsLabeledEdges(source=source, depthLimit=depthLimit):
            if edge.dir == "forward" and edge.depth <= depthLimit:
                yield edge.v

when isMainModule:
    var G = newGraph()
    G.addPath(@[0, 1, 2, 3, 4])
    echo(G.dfsEdges(source=0).toSeq())
    echo(G.dfsEdges(source=0, depthLimit=2).toSeq())

    var T = G.dfsTree(source=0, depthLimit=2)
    echo(T.edges())
    T = G.dfsTree(source=0)
    echo(T.edges())

    G = newGraph()
    G.addPath(@[0, 1, 2, 3])
    echo(G.dfsPredecessors(source=0))
    echo(G.dfsPredecessors(source=0, depthLimit=2))

    G = newGraph()
    G.addPath(@[0, 1, 2, 3, 4])
    echo(G.dfsSuccessors(source=0))
    echo(G.dfsSuccessors(source=0, depthLimit=2))

    G = newGraph()
    G.addEdgesFrom(@[(0, 1), (1, 2)])
    for edge in G.dfsLabeledEdges(source=0):
        echo(edge)

    var DG = newDirectedGraph()
    DG.addEdgesFrom(@[(0, 1), (1, 2), (2, 1)])
    for edge in DG.dfsLabeledEdges(source=0):
        echo(edge)

    G = newGraph()
    G.addPath(@[0, 1, 2, 3, 4])
    var nodes: seq[Node] = @[]
    for node in G.dfsPostorderNodes(source=0):
        nodes.add(node)
    echo(nodes)

    echo(G.dfsPostorderNodes(source=0, depthLimit=2).toSeq())
    echo(G.dfsPostorderNodes(source=0).toSeq())
    echo(G.dfsPostorderNodes(source=0, depthLimit=2).toSeq())

    nodes = @[]
    for node in G.dfsPostorderNodes(source=0, depthLimit=2):
        nodes.add(node)
    echo(nodes)

    for edge in G.dfsLabeledEdges(source=0, depthLimit=2):
        echo(edge)

    echo(G.dfsPreorderNodes(source=0, depthLimit=2).toSeq())
    echo(G.dfsPreorderNodes(source=0).toSeq())
