import hashes
import sets
import tables
import sequtils

type Node* = int
type Edge* = tuple[fromNode, toNode: Node]

type DirectedGraph* = object of RootObj
    AdjLists*: Table[Node, HashSet[Node]]
    # TODO: reversedadjLists

# TODO: proc reversed(dg: ref DirectedGraph): DirectedGraph
# TODO: addEdgesなどにも修正が必要

proc initDirectedGraph*(dg: ref DirectedGraph) =
    dg.AdjLists = initTable[Node, HashSet[Node]]()

proc newDirectedGraph*(): ref DirectedGraph =
    new(result)
    initDirectedGraph(result)
    return result

proc len*(dg: ref DirectedGraph): int =
    return dg.AdjLists.len()

proc size*(dg: ref DirectedGraph): int =
    return dg.AdjLists.len()

proc hasNode*(dg: ref DirectedGraph, node: Node): bool =
    return dg.AdjLists.contains(node)

proc contains*(dg: ref DirectedGraph, node: Node): bool =
    return dg.hasNode(node)

proc addNode*(dg: ref DirectedGraph, node: Node): Node {.discardable.} =
    if not dg.contains(node):
        dg.AdjLists[node] = HashSet[Node]()
        dg.AdjLists[node].init()
    return node

proc removeNode*(dg: ref DirectedGraph, node: Node) =
    for neighbor in dg.AdjLists[node]:
        dg.AdjLists[node].excl(neighbor)
    dg.AdjLists.del(node)

proc numberOfNodes*(dg: ref DirectedGraph): int =
    return dg.len()

proc clear*(dg: ref DirectedGraph) =
    dg.AdjLists.clear()

proc hasEdge*(dg: ref DirectedGraph, fromNode, toNode: Node): bool =
    return (fromNode in dg.AdjLists) and (toNode in dg.AdjLists) and (toNode in dg.AdjLists[fromNode])

proc contains*(dg: ref DirectedGraph, edge: Edge): bool =
    return dg.hasEdge(edge.fromNode, edge.toNode)

proc addEdge*(dg: ref DirectedGraph, fromNode, toNode: Node) =
    dg.addNode(fromNode)
    dg.addNode(toNode)
    dg.AdjLists[fromNode].incl(toNode)

proc addEdge*(dg: ref DirectedGraph, edge: Edge) =
    dg.addNode(edge.fromNode)
    dg.addNode(edge.toNode)
    dg.AdjLists[edge.fromNode].incl(edge.toNode)

proc removeEdge*(dg: ref DirectedGraph, fromNode, toNode: Node) =
    if (fromNode notin dg) or (toNode notin dg):
        return
    dg.AdjLists[fromNode].excl(toNode)

proc removeEdge*(dg: ref DirectedGraph, edge: Edge) =
    if (edge.fromNode notin dg) or (edge.toNode notin dg):
        return
    dg.AdjLists[edge.fromNode].excl(edge.toNode)

proc numberOfEdges*(dg: ref DirectedGraph): int =
    var ret = 0
    for node in dg.AdjLists.keys():
        ret += dg.AdjLists[node].len()
    return ret

iterator nodes*(dg: ref DirectedGraph): Node =
    for node in dg.AdjLists.keys():
        yield node

iterator edges*(dg: ref DirectedGraph): Edge =
    for fromNode, toNodes in dg.AdjLists.pairs():
        for toNode in toNodes.items():
            yield (fromNode, toNode)

proc indegree*(dg: ref DirectedGraph, node: Node): int =
    var ret = 0
    for toNodes in dg.AdjLists.values():
        if node in toNodes:
            ret += 1
    return ret

proc outdegree*(dg: ref DirectedGraph, node: Node): int =
    return dg.AdjLists[node].len()

proc neighbors*(dg: ref DirectedGraph, node: Node): HashSet[Node] =
    return dg.AdjLists[node]

iterator neighbors*(dg: ref DirectedGraph, node: Node): Node =
    for neighbor in dg.AdjLists[node]:
        yield neighbor

proc getNeighborsIterator*(dg: ref DirectedGraph, node: Node): iterator(): Node =
    return iterator(): Node =
        for neighbor in dg.AdjLists[node]:
            yield neighbor


proc successors*(dg: ref DirectedGraph, node: Node): HashSet[Node] =
    return dg.AdjLists[node]

iterator successors*(dg: ref DirectedGraph, node: Node): Node =
    for successor in dg.AdjLists[node]:
        yield successor

proc getSuccessorsIterator*(dg: ref DirectedGraph, node: Node): iterator(): Node =
    return iterator (): Node =
        for neighbor in dg.AdjLists[node]:
            yield neighbor

proc predecessors*(dg: ref DirectedGraph, node: Node): HashSet[Node] =
    var ret: HashSet[Node] = initHashSet[Node]()
    for (fromNode, toNodes) in dg.AdjLists.pairs():
        if node in toNodes:
            ret.incl(fromNode)
    return ret

iterator predecessors*(dg: ref DirectedGraph, node: Node): Node =
    var predecessorSeq: seq[Node] = @[]
    for (fromNode, toNodes) in dg.AdjLists.pairs():
        if node in toNodes:
            predecessorSeq.add(fromNode)
    for predecessor in predecessorSeq:
        yield predecessor

proc getPredecessorsIterator*(dg: ref DirectedGraph, node: Node): iterator(): Node =
    return iterator (): Node =
        var predecessorSeq: seq[Node] = @[]
        for (fromNode, toNodes) in dg.AdjLists.pairs():
            if node in toNodes:
                predecessorSeq.add(fromNode)
        for predecessor in predecessorSeq:
            yield predecessor

# tests
when isMainModule:
    var G = newDirectedGraph()

    assert 1 notin G

    G.addNode(1)
    assert 1 in G

    assert (not G.hasEdge(1, 2))

    G.addEdge(1, 2)
    assert G.hasEdge(1, 2)
    assert not G.hasEdge(2, 1)

    G.addEdge(2, 3)
    assert G.hasEdge(2, 3)
    assert not G.hasEdge(3, 2)
    G.addEdge(3, 2)
    assert G.hasEdge(3, 2)

    assert G.numberOfEdges() == 3
    for edge in G.edges:
        echo($edge.fromNode, ", ", $edge.toNode)

    G.removeEdge(3, 2)
    assert not G.hasEdge(3, 2)
    assert G.hasEdge(2, 3)
    assert G.numberOfEdges() == 2
    G.removeEdge(2, 3)
    assert G.numberOfEdges() == 1
    assert G.numberOfNodes() == 3
    assert G.hasNode(1)

    G.removeNode(1)
    assert (not G.hasNode(1))
    assert G.numberOfEdges() == 0
    assert G.len() == 2

    G.add_edge(2, 3)
    assert G.numberOfEdges() == 1
    assert G.numberOfNodes() == 2

    G.clear()
    assert G.numberOfNodes() == 0
    assert G.numberOfEdges() == 0

