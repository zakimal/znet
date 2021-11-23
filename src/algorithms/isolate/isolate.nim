import ../../graph.nim

proc isIsolate*(g: Graph, n: Node): bool =
    return g.degree(n) == 0

proc isolates*(g: Graph): seq[Node] =
    var ret: seq[Node] = @[]
    for n in g.nodes():
        if g.degree(n) == 0:
            ret.add(n)
    return ret

proc numberOfIsolates(g: Graph): int =
    return len(g.isolates())

proc isIsolate*(dg: DirectedGraph, n: Node): bool =
    return dg.degree(n) == 0

proc isolates*(dg: DirectedGraph): seq[Node] =
    var ret: seq[Node] = @[]
    for n in dg.nodes():
        if dg.degree(n) == 0:
            ret.add(n)
    return ret

proc numberOfIsolates(dg: DirectedGraph): int =
    return len(dg.isolates())

when isMainModule:
    var G = newGraph()
    G.addEdge(1, 2)
    G.addNode(3)
    doAssert G.isolates() == @[3]
    G.removeNodesFrom(G.isolates())
    doAssert G.nodeSeq() == @[1, 2]

    var DG = newDirectedGraph()
    DG.addEdgesFrom(@[(0, 1), (1, 2)])
    DG.addNode(3)
    doAssert DG.isolates() == @[3]