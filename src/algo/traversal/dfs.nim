import sets
import deques
import sequtils
import strformat
import tables

import ../../graph
import ../../readwrite

iterator dfsEdges*(
    dg: ref DirectedGraph,
    source: Node = -1, # TODO: 変更の必要あり
    depthLimit: int = -1
): Edge =
    var nodes: seq[Node]
    if source == -1:
        nodes = dg.nodes().toSeq()
    else:
        nodes = newSeq[Node]()
        nodes.add(source)
    var visited: HashSet[Node] = initHashSet[Node]()
    var depthLimit0: int = depthLimit
    if depthLimit0 == -1:
        depthLimit0 = dg.len()
    for start in nodes:
        if start in visited:
            continue
        visited.incl(start)
        var stack: seq[tuple[node: Node, depthLimit: int, neighbors: iterator(): Node]]
        stack.add((start, depthLimit0, dg.getNeighborsIterator(start)))
        while len(stack) != 0:
            var parent: Node
            var depthNow: int
            var children: iterator(): Node
            (parent, depthNow, children) = pop(stack)
            for child in children:
                if child notin visited:
                    yield (parent, child)
                    visited.incl(child)
                    if 1 < depthNow:
                        stack.add((child, depthNow - 1, dg.getNeighborsIterator(child)))


proc dfsTree*(
    dg: ref DirectedGraph,
    source: Node = -1, # TODO: 変更の必要あり
    depthLimit: int = -1
): ref DirectedGraph =
    var tree = newDirectedGraph()
    if source == -1:
        for node in dg.nodes():
            tree.addNode(node)
    else:
        tree.addNode(source)
    for edge in dfsEdges(
        dg,
        source,
        depthLimit,
    ):
        tree.addEdge(edge)
    return tree

proc dfsPredecessors*(
    dg: ref DirectedGraph,
    source: Node = -1,
    depthLimit: int = -1
): Table[Node, Node] =
    var ret = initTable[Node, Node]()
    for (node, predecessor) in dfsEdges(
        dg,
        source,
        depthLimit
    ):
        ret[node] = predecessor
    return ret

proc dfsSuccessors*(
    dg: ref DirectedGraph,
    source: Node = -1, # TODO: 変更の必要あり
    depthLimit: int = -1
): Table[Node, seq[Node]] =
    var ret = initTable[Node, seq[Node]]()
    for (node, predecessor) in dfsEdges(
        dg,
        source,
        depthLimit
    ):
        if node notin ret:
            ret[node] = newSeq[Node]()
        ret[node].add(predecessor)
    return ret

iterator dfsLabeledEdges*(
    dg: ref DirectedGraph,
    source: Node = -1, # TODO: 変更の必要あり
    depthLimit: int = -1
): tuple[u: Node, v: Node, direction: string] =
    var nodes: seq[Node]
    if source == -1:
        nodes = dg.nodes().toSeq()
    else:
        nodes = newSeq[Node]()
        nodes.add(source)
    var visited: HashSet[Node] = initHashSet[Node]()
    var depthLimit0: int = depthLimit
    if depthLimit0 == -1:
        depthLimit0 = dg.len()
    for start in nodes:
        if start in visited:
            continue
        yield (start, start, "forward")
        visited.incl(start)
        var stack: seq[tuple[node: Node, depthLimit: int, neighbors: iterator(): Node]]
        stack.add((start, depthLimit0, dg.getNeighborsIterator(start)))
        while len(stack) != 0:
            var parent: Node
            var depthNow: int
            var children: iterator(): Node
            (parent, depthNow, children) = pop(stack)
            for child in children:
                if child in visited:
                    yield (parent, child, "nontree")
                else:
                    yield (parent, child, "forward")
                    visited.incl(child)
                    if 1 < depthNow:
                        stack.add((child, depthNow - 1, dg.getNeighborsIterator(child)))
            if len(stack) != 0:
                yield (parent, stack[^1][0], "reverse")
        yield (start, start, "reverse")

proc dfsPreorderNodes*(
    dg: ref DirectedGraph,
    source: Node = -1, # TODO: 変更の必要あり
    depthLimit: int = -1
): iterator(): Node =
    var ret: seq[Node] = newSeq[Node]()
    for edge in dfsLabeledEdges(
        dg,
        source,
        depthLimit
    ):
        if edge.direction == "forward":
            ret.add(edge.v)
    return iterator(): Node =
        for node in ret:
            yield node

proc dfsPostorderNodes*(
    dg: ref DirectedGraph,
    source: Node = -1, # TODO: 変更の必要あり
    depthLimit: int = -1
): iterator(): Node =
    var ret: seq[Node] = newSeq[Node]()
    for edge in dfsLabeledEdges(
        dg,
        source,
        depthLimit
    ):
        if edge.direction == "reverse":
            ret.add(edge.v)
    return iterator(): Node =
        for node in ret:
            yield node

when isMainModule:
    var G = newDirectedGraph()
    G.addEdge((0, 1))
    G.addEdge((1, 2))
    G.addEdge((2, 3))
    G.addEdge((3, 4))

    echo("---")
    for edge in G.edges:
        echo(edge)

    echo("---")
    for edge in G.dfsEdges(source=0, depthLimit=2):
        echo(edge)

    echo("---")
    var tree = G.dfsTree(source=0, depthLimit=2)
    for edge in tree.edges():
        echo(edge)
    tree = G.dfsTree(source=0)
    for edge in tree.edges():
        echo(edge)

    echo("---")
    var t = G.dfsPredecessors(source=0)
    for (node, predecessor) in t.pairs():
        echo(node, ", ", predecessor)
    t = G.dfsPredecessors(source=0, depthLimit=2)
    for (node, predecessor) in t.pairs():
        echo(node, ", ", predecessor)

    echo("---")
    G = newDirectedGraph()
    G.addEdge((0, 1))
    G.addEdge((1, 2))
    G.addEdge((2, 3))
    G.addEdge((3, 4))
    G.addEdge((1, 0))
    G.addEdge((2, 1))
    G.addEdge((3, 2))
    G.addEdge((4, 3))
    var tt = G.dfsSuccessors(source=0)
    for (node, successors) in tt.pairs():
        echo(node, ", ", successors)
    tt = G.dfsSuccessors(source=0, depthLimit=2)
    for (node, successors) in tt.pairs():
        echo(node, ", ", successors)

    echo("---")
    G = newDirectedGraph()
    G.addEdge((0, 1))
    G.addEdge((1, 2))
    G.addEdge((2, 3))
    G.addEdge((3, 4))
    G.addEdge((1, 0))
    G.addEdge((2, 1))
    G.addEdge((3, 2))
    G.addEdge((4, 3))
    var nodes = G.dfsPostorderNodes(source=0)
    echo(nodes.toSeq())

    echo("---")
    G = newDirectedGraph()
    G.addEdge((0, 1))
    G.addEdge((1, 2))
    G.addEdge((2, 3))
    G.addEdge((3, 4))
    G.addEdge((1, 0))
    G.addEdge((2, 1))
    G.addEdge((3, 2))
    G.addEdge((4, 3))
    nodes = G.dfsPreorderNodes(source=0)
    echo(nodes.toSeq())

    echo("---")
    G = newDirectedGraph()
    G.addEdge((0, 1))
    G.addEdge((1, 2))
    G.addEdge((2, 1))
    for edge in G.dfsLabeledEdges(source=0):
        echo(edge)