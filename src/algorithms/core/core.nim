import tables
import strformat
import algorithm
import sequtils
import sets

import ../../graph.nim
import ../../exception.nim

proc coreNumber*(g: Graph): Table[Node, int] =
    if 0 < g.numberOfSelfloop():
        var e = ZNetError()
        e.msg = "input graph has self loops which is not permitted"
        raise e
    var degrees = g.degree()
    var cmpDegree = proc (x, y: Node): int =
        result = system.cmp(degrees[x], degrees[y])
    var nodes = g.nodeSeq()
    nodes.sort(cmpDegree)
    var binBoundaries = @[0]
    var currDegree = 0
    for i, v in nodes:
        if currDegree < degrees[v] :
            for d in 0..<(degrees[v] - currDegree):
                binBoundaries.add(i)
            currDegree = degrees[v]
    var nodePos: Table[Node, int] = initTable[Node, int]()
    for pos, v in nodes:
        nodePos[v] = pos
    var core = degrees
    var nbrs: Table[Node, seq[Node]] = initTable[Node, seq[Node]]()
    for v in g.nodes():
        nbrs[v] = g.allNeighbors(v).toSeq()
    for v in nodes:
        for u in nbrs[v]:
            if core[v] < core[u]:
                nbrs[u].delete(nbrs[u].find(v))
                var pos = nodePos[u]
                var binStart = binBoundaries[core[u]]
                nodePos[u] = binStart
                nodePos[nodes[binStart]] = pos
                swap(nodes[binStart], nodes[pos])
                binBoundaries[core[u]] += 1
                core[u] -= 1
    return core
proc coreNumber*(dg: DirectedGraph): Table[Node, int] =
    if 0 < dg.numberOfSelfloop():
        var e = ZNetError()
        e.msg = "input graph has self loops which is not permitted"
        raise e
    var degrees = dg.degree()
    var cmpDegree = proc (x, y: Node): int =
        result = system.cmp(degrees[x], degrees[y])
    var nodes = dg.nodeSeq()
    nodes.sort(cmpDegree)
    var binBoundaries = @[0]
    var currDegree = 0
    for i, v in nodes:
        if currDegree < degrees[v] :
            for d in 0..<(degrees[v] - currDegree):
                binBoundaries.add(i)
            currDegree = degrees[v]
    var nodePos: Table[Node, int] = initTable[Node, int]()
    for pos, v in nodes:
        nodePos[v] = pos
    var core = degrees
    var nbrs: Table[Node, seq[Node]] = initTable[Node, seq[Node]]()
    for v in dg.nodes():
        nbrs[v] = dg.allNeighbors(v).toSeq()
    for v in nodes:
        for u in nbrs[v]:
            if core[v] < core[u]:
                nbrs[u].delete(nbrs[u].find(v))
                var pos = nodePos[u]
                var binStart = binBoundaries[core[u]]
                nodePos[u] = binStart
                nodePos[nodes[binStart]] = pos
                swap(nodes[binStart], nodes[pos])
                binBoundaries[core[u]] += 1
                core[u] -= 1
    return core

proc coreSubgraph(
    g: Graph,
    kFilter: proc(node: Node, cutoff: int, core: Table[Node, int]): bool,
    k : int = -1,
    core: Table[Node, int] = initTable[Node, int]()
): Graph =
    var coreUsing = core
    if len(core.keys().toSeq()) == 0:
        coreUsing = g.coreNumber()
    var kUsing = k
    if k == -1:
        kUsing = max(coreUsing.values().toSeq())
    var nodes: HashSet[Node] = initHashSet[Node]()
    for v in coreUsing.keys():
        if kFilter(v, kUsing, coreUsing):
            nodes.incl(v)
    return g.subgraph(nodes)
proc coreSubgraph(
    dg: DirectedGraph,
    kFilter: proc(node: Node, cutoff: int, core: Table[Node, int]): bool,
    k : int = -1,
    core: Table[Node, int] = initTable[Node, int]()
): Graph =
    var coreUsing = core
    if len(core.keys().toSeq()) == 0:
        coreUsing = dg.coreNumber()
    var kUsing = k
    if k == -1:
        kUsing = max(coreUsing.values().toSeq())
    var nodes: HashSet[Node] = initHashSet[Node]()
    for v in coreUsing.keys():
        if kFilter(v, kUsing, coreUsing):
            nodes.incl(v)
    return dg.subgraph(nodes)

proc kCore(g: Graph, k: int = -1, coreNumber: Table[Node, int] = initTable[Node, int]()): Graph =
    var kFilter: proc(node: Node, cutoff: int, core: Table[Node, int]): bool =
        proc(node: Node, cutoff: int, core: Table[Node, int]): bool =
            return cutoff <= core[node]
    return coreSubgraph(g, kFilter, k, coreNumber)
proc kCore(dg: DirectedGraph, k: int = -1, coreNumber: Table[Node, int] = initTable[Node, int]()): Graph =
    var kFilter: proc(node: Node, cutoff: int, core: Table[Node, int]): bool =
        proc(node: Node, cutoff: int, core: Table[Node, int]): bool =
            return cutoff <= core[node]
    return coreSubgraph(dg, kFilter, k, coreNumber)

proc kShell(g: Graph, k: int = -1, coreNumber: Table[Node, int] = initTable[Node, int]()): Graph =
    var kFilter: proc(node: Node, cutoff: int, core: Table[Node, int]): bool =
        proc(node: Node, cutoff: int, core: Table[Node, int]): bool =
            return cutoff == core[node]
    return coreSubgraph(g, kFilter, k, coreNumber)
proc kShell(dg: DirectedGraph, k: int = -1, coreNumber: Table[Node, int] = initTable[Node, int]()): Graph =
    var kFilter: proc(node: Node, cutoff: int, core: Table[Node, int]): bool =
        proc(node: Node, cutoff: int, core: Table[Node, int]): bool =
            return cutoff == core[node]
    return coreSubgraph(dg, kFilter, k, coreNumber)

proc kCrust*(g: Graph, k: int = -1, coreNumber: Table[Node, int] = initTable[Node, int]()): Graph =
    var coreNumberUsing = coreNumber
    if len(coreNumber.keys().toSeq()) == 0:
        coreNumberUsing = g.coreNumber()
    var kUsing = k
    if k == -1:
        kUsing = max(coreNumberUsing.values().toSeq()) - 1
    var nodes: HashSet[Node] = initHashSet[Node]()
    for (k, v) in coreNumberUsing.pairs():
        if v <= kUsing:
            nodes.incl(k)
    return g.subgraph(nodes)
proc kCrust*(dg: DirectedGraph, k: int = -1, coreNumber: Table[Node, int] = initTable[Node, int]()): Graph =
    var coreNumberUsing = coreNumber
    if len(coreNumber.keys().toSeq()) == 0:
        coreNumberUsing = dg.coreNumber()
    var kUsing = k
    if k == -1:
        kUsing = max(coreNumberUsing.values().toSeq()) - 1
    var nodes: HashSet[Node] = initHashSet[Node]()
    for (k, v) in coreNumberUsing.pairs():
        if v <= kUsing:
            nodes.incl(k)
    return dg.subgraph(nodes)

proc kCorona*(g: Graph, k: int = -1, coreNumber: Table[Node, int] = initTable[Node, int]()): Graph =
    var kFilter: proc(node: Node, cutoff: int, core: Table[Node, int]): bool =
        proc(node: Node, cutoff: int, core: Table[Node, int]): bool =
            var s = 0
            for w in g.neighbors(node):
                if core[w] >= cutoff:
                    s += 1
            return cutoff == core[node] and k == s
    return coreSubgraph(g, kFilter, k, coreNumber)
proc kCorona*(dg: DirectedGraph, k: int = -1, coreNumber: Table[Node, int] = initTable[Node, int]()): Graph =
    var kFilter: proc(node: Node, cutoff: int, core: Table[Node, int]): bool =
        proc(node: Node, cutoff: int, core: Table[Node, int]): bool =
            var s = 0
            for w in dg.neighbors(node):
                if core[w] >= cutoff:
                    s += 1
            return cutoff == core[node] and k == s
    return coreSubgraph(dg, kFilter, k, coreNumber)

proc kTruss*(g: Graph, k: int): Graph =
    if g.isDirected:
        var e = ZNetError()
        e.msg = "kTruss is not implemented for directed graph"
        raise e
    var h = g.copy()

    var nDropped = 1
    while 0 < nDropped:
        nDropped = 0
        var toDrop: seq[Edge] = @[]
        var seen = initHashSet[Node]()
        for u in h.nodes():
            var nbrsU = h.neighborSet(u)
            seen.incl(u)
            var newNbrs: seq[Node] = @[]
            for v in nbrsU:
                if v notin seen:
                    newNbrs.add(v)
            for v in newNbrs:
                if len(nbrsU * h.neighborSet(v)) < (k - 2):
                    toDrop.add((u, v))
        h.removeEdgesFrom(toDrop)
        nDropped = len(toDrop)
        var isolatedNodes: seq[Node] = @[]
        for v in h.nodes():
            if h.degree(v) == 0:
                isolatedNodes.add(v)
        g.removeNodesFrom(isolatedNodes)
    return h

proc onionLayers(g: Graph): Table[Node, int] =
    if g.isDirected:
        var e = ZNetError()
        e.msg = "kTruss is not implemented for directed graph"
        raise e
    var h = g.copy()
    if 0 < g.numberOfSelfloop():
        var e = ZNetError()
        e.msg = "input graph contains self loops which is not permitted"
        raise e
    var odLayers: Table[Node, int] = initTable[Node, int]()
    var neighbors: Table[Node, seq[Node]] = initTable[Node, seq[Node]]()
    for v in g.nodes():
        neighbors[v] = g.neighbors(v)
    var degrees = g.degree()
    var currentCore = 1
    var currentLayer = 1
    var isolatedNodes: seq[Node] = @[]
    for v in h.nodes():
        if h.degree(v) == 0:
            isolatedNodes.add(v)
    if 0 < len(isolatedNodes):
        for v in isolatedNodes:
            odLayers[v] = currentLayer
            degrees.del(v)
        currentLayer = 2
    while 0 < len(degrees):
        var nodes = degrees.keys().toSeq()
        var cmpDegree = proc (x, y: Node): int =
            result = system.cmp(degrees[x], degrees[y])
        nodes.sort(cmpDegree)
        var minDegree = degrees[nodes[0]]
        if currentCore < minDegree:
            currentCore = minDegree
        var thisLayer: seq[Node] = @[]
        for n in nodes:
            if currentCore < degrees[n]:
                break
            thisLayer.add(n)
        for v in thisLayer:
            odLayers[v] = currentLayer
            for n in neighbors[v]:
                neighbors[n].delete(neighbors[n].find(v))
                degrees[n] -= 1
            degrees.del(v)
        currentLayer += 1
    return odLayers


when isMainModule:
    let edges = @[(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]

    block karateCoreNumber:
        var G = newGraph()
        G.addEdgesFrom(edges)
        var ret = G.coreNumber()
        var nxRet = {0: 4, 1: 4, 2: 4, 3: 4, 4: 3, 5: 3, 6: 3, 7: 4, 8: 4, 9: 2, 10: 3, 11: 1, 12: 2, 13: 4, 14: 2, 15: 2, 16: 2, 17: 2, 18: 2, 19: 3, 20: 2, 21: 2, 22: 2, 23: 3, 24: 3, 25: 3, 26: 2, 27: 3, 28: 3, 29: 3, 30: 4, 31: 3, 32: 4, 33: 4}.toTable()
        for (k, v) in ret.pairs():
            doAssert nxRet[k] == v
    block dkarateCoreNumber:
        var DG = newDirectedGraph()
        DG.addEdgesFrom(edges)
        var ret = DG.coreNumber()
        var nxRet = {0: 4, 1: 4, 2: 4, 3: 4, 4: 3, 5: 3, 6: 3, 7: 4, 8: 4, 10: 3, 11: 1, 12: 2, 13: 4, 17: 2, 19: 3, 21: 2, 31: 3, 30: 4, 9: 2, 27: 3, 28: 3, 32: 4, 16: 2, 33: 4, 14: 2, 15: 2, 18: 2, 20: 2, 22: 2, 23: 3, 25: 3, 29: 3, 24: 3, 26: 2}.toTable()
        for (k, v) in ret.pairs():
            doAssert nxRet[k] == v

    block karateKCore:
        var G = newGraph()
        G.addEdgesFrom(edges)
        var ret = G.kCore().edgeSeq()
        ret.sort()
        var nxRet = @[(0, 1), (0, 2), (0, 3), (0, 7), (0, 8), (0, 13), (1, 2), (1, 3), (1, 7), (1, 13), (1, 30), (2, 3), (2, 7), (2, 8), (2, 13), (2, 32), (3, 7), (3, 13), (8, 30), (8, 32), (8, 33), (13, 33), (30, 32), (30, 33), (32, 33)]
        doAssert ret == nxRet
    block dkarateKCore:
        var DG = newDirectedGraph()
        DG.addEdgesFrom(edges)
        var ret = DG.kCore().edgeSeq()
        ret.sort()
        var nxRet = @[(0, 1), (0, 2), (0, 3), (0, 7), (0, 8), (0, 13), (1, 2), (1, 3), (1, 7), (1, 13), (1, 30), (2, 3), (2, 7), (2, 8), (2, 13), (2, 32), (3, 7), (3, 13), (8, 30), (8, 32), (8, 33), (13, 33), (30, 32), (30, 33), (32, 33)]
        doAssert ret == nxRet

    block karateOnionLayers:
        var G = newGraph()
        G.addEdgesFrom(edges)
        var ret = G.onionLayers()
        var nxRet = {11: 1, 9: 2, 12: 2, 14: 2, 15: 2, 16: 2, 17: 2, 18: 2, 20: 2, 21: 2, 22: 2, 26: 2, 4: 3, 5: 3, 6: 3, 10: 3, 19: 3, 24: 3, 25: 3, 28: 3, 29: 3, 23: 4, 27: 4, 31: 4, 7: 5, 30: 5, 32: 5, 33: 5, 8: 6, 1: 6, 3: 6, 13: 6, 0: 7, 2: 7}.toTable()
        doAssert nxRet == ret
