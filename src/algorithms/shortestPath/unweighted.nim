import algorithm
import sequtils
import tables
import strformat
import sets

import ../../graph.nim
import ../../exception.nim

iterator singleSourceShortestPathLengthIterator*(
    adj: Table[Node, HashSet[Node]],
    firstLevel: Table[Node, int],
    cutoff: int
): tuple[node: Node, level: int] =
    var seen = initTable[Node, int]()
    var level = 0
    var nextLevel = initHashSet[Node]()
    for k in firstLeveL.keys():
        nextLevel.incl(k)
    var n = len(adj)
    if cutoff == -1:
        while len(nextLevel) != 0:
            var thisLevel = nextLevel
            nextLevel = initHashSet[Node]()
            var found: seq[Node] = @[]
            for v in thisLeveL:
                if v notin seen:
                    seen[v] = level
                    found.add(v)
                    yield (v, level)
            if len(seen) == n:
                break
            for v in found:
                nextLevel = nextLevel + adj[v]
            level += 1
    else:
        while len(nextLevel) != 0 and level <= cutoff:
            var thisLevel = nextLevel
            nextLevel = initHashSet[Node]()
            var found: seq[Node] = @[]
            for v in thisLeveL:
                if v notin seen:
                    seen[v] = level
                    found.add(v)
                    yield (v, level)
            if len(seen) == n:
                break
            for v in found:
                nextLevel = nextLevel + adj[v]
            level += 1

proc singleSourceShortestPathLength*(
    g: Graph,
    source: Node,
    cutoff: int = -1
): Table[Node, int] =
    if source notin g.nodeSet():
        var e = ZNetNodeNotFound()
        e.msg = fmt"the source node {source} is not in the graph"
        raise e
    var cutoffUsing = cutoff
    if cutoff != -1:
        cutoffUsing = cutoff
    var nextLevel: Table[Node, int] = initTable[Node, int]()
    nextLevel[source] = 1

    var ret: Table[Node, int] = initTable[Node, int]()
    for (node, length) in singleSourceShortestPathLengthIterator(g.adj, nextLevel, cutoffUsing):
        ret[node] = length
    return ret

proc singleSourceShortestPathLength*(
    dg: DirectedGraph,
    source: Node,
    cutoff: int = -1
): Table[Node, int] =
    if source notin dg.nodeSet():
        var e = ZNetNodeNotFound()
        e.msg = fmt"the source node {source} is not in the graph"
        raise e
    var cutoffUsing = cutoff
    if cutoff != -1:
        cutoffUsing = cutoff
    var nextLevel: Table[Node, int] = initTable[Node, int]()
    nextLevel[source] = 1

    var ret: Table[Node, int] = initTable[Node, int]()
    for (node, length) in singleSourceShortestPathLengthIterator(dg.adj, nextLevel, cutoffUsing):
        ret[node] = length
    return ret

proc singleTargetShortestPathLength*(
    g: Graph,
    target: Node,
    cutoff: int = -1
): Table[Node, int] =
    if target notin g.nodeSet():
        var e = ZNetNodeNotFound()
        e.msg = fmt"the target node {target} is not in the graph"
        raise e
    var cutoffUsing = cutoff
    if cutoff != -1:
        cutoffUsing = cutoff
    var nextLevel: Table[Node, int] = initTable[Node, int]()
    nextLevel[target] = 1

    var ret: Table[Node, int] = initTable[Node, int]()
    for (node, length) in singleSourceShortestPathLengthIterator(g.adj, nextLevel, cutoffUsing):
        ret[node] = length
    return ret

proc singleTargetShortestPathLength*(
    dg: DirectedGraph,
    target: Node,
    cutoff: int = -1
): Table[Node, int] =
    if target notin dg.nodeSet():
        var e = ZNetNodeNotFound()
        e.msg = fmt"the target node {target} is not in the graph"
        raise e
    var cutoffUsing = cutoff
    if cutoff != -1:
        cutoffUsing = cutoff
    var nextLevel: Table[Node, int] = initTable[Node, int]()
    nextLevel[target] = 1

    var ret: Table[Node, int] = initTable[Node, int]()
    for (node, length) in singleSourceShortestPathLengthIterator(dg.pred, nextLevel, cutoffUsing):
        ret[node] = length
    return ret

iterator allPairsShortestPathLength*(
    g: Graph,
    cutoff: int = -1
): tuple[source: Node, lengths: Table[Node, int]] =
    for n in g.nodes():
        yield (n, g.singleSourceShortestPathLength(n, cutoff))

iterator allPairsShortestPathLength*(
    dg: DirectedGraph,
    cutoff: int = -1
): tuple[source: Node, lengths: Table[Node, int]] =
    for n in dg.nodes():
        yield (n, dg.singleSourceShortestPathLength(n, cutoff))

proc bidirectionalShortestPathHelper(
    g: Graph,
    source: Node,
    target: Node
): tuple[pred: Table[Node, Node], succ: Table[Node, Node], w: Node] =
    if target == source:
        return ({target: None}.toTable(), {source: None}.toTable(), source)
    var Gpred = g.adj
    var Gsucc = g.adj
    var pred = {source: None}.toTable()
    var succ = {target: None}.toTable()
    var forwardFringe = @[source]
    var reverseFringe = @[target]
    while len(forwardFringe) != 0 and len(reverseFringe) != 0:
        if len(forwardFringe) <= len(reverseFringe):
            var thisLevel = forwardFringe
            forwardFringe = @[]
            for v in thisLevel:
                for w in Gsucc[v]:
                    if w notin pred:
                        forwardFringe.add(w)
                        pred[w] = v
                    if w in succ:
                        return (pred, succ, w)
        else:
            var thisLevel = reverseFringe
            reverseFringe = @[]
            for v in thisLevel:
                for w in Gpred[v]:
                    if w notin succ:
                        succ[w] = v
                        reverseFringe.add(w)
                    if w in pred:
                        return (pred, succ, w)
    var e = ZNetNoPath()
    e.msg = fmt"no path between {source} and {target} exists"
    raise e

proc bidirectionalShortestPath*(
    g: Graph,
    source: Node,
    target: Node
): seq[Node] =
    if source notin g.nodeSet() or target notin g.nodeSet():
        var e = ZNetNodeNotFound()
        e.msg = fmt"either source {source} or target {target} is not in the graph"
        raise e
    var (pred, succ, w) = bidirectionalShortestPathHelper(g, source, target)
    var path: seq[Node] = @[]
    while w != None:
        path.add(w)
        w = pred[w]
    path.reverse()
    w = succ[path[^1]]
    while w != None:
        path.add(w)
        w = succ[w]
    return path

proc bidirectionalShortestPathHelper(
    dg: DirectedGraph,
    source: Node,
    target: Node
): tuple[pred: Table[Node, Node], succ: Table[Node, Node], w: Node] =
    if target == source:
        return ({target: None}.toTable(), {source: None}.toTable(), source)
    var Gpred = dg.pred
    var Gsucc = dg.adj
    var pred = {source: None}.toTable()
    var succ = {target: None}.toTable()
    var forwardFringe = @[source]
    var reverseFringe = @[target]
    while len(forwardFringe) != 0 and len(reverseFringe) != 0:
        if len(forwardFringe) <= len(reverseFringe):
            var thisLevel = forwardFringe
            forwardFringe = @[]
            for v in thisLevel:
                for w in Gsucc[v]:
                    if w notin pred:
                        forwardFringe.add(w)
                        pred[w] = v
                    if w in succ:
                        return (pred, succ, w)
        else:
            var thisLevel = reverseFringe
            reverseFringe = @[]
            for v in thisLevel:
                for w in Gpred[v]:
                    if w notin succ:
                        succ[w] = v
                        reverseFringe.add(w)
                    if w in pred:
                        return (pred, succ, w)
    var e = ZNetNoPath()
    e.msg = fmt"no path between {source} and {target} exists"
    raise e

proc bidirectionalShortestPath*(
    dg: DirectedGraph,
    source: Node,
    target: Node
): seq[Node] =
    if source notin dg.nodeSet() or target notin dg.nodeSet():
        var e = ZNetNodeNotFound()
        e.msg = fmt"either source {source} or target {target} is not in the graph"
        raise e
    var (pred, succ, w) = bidirectionalShortestPathHelper(dg, source, target)
    var path: seq[Node] = @[]
    while w != None:
        path.add(w)
        w = pred[w]
    path.reverse()
    w = succ[path[^1]]
    while w != None:
        path.add(w)
        w = succ[w]
    return path

proc singleShortestPath(
    adj: Table[Node, HashSet[Node]],
    firstLevel: Table[Node, int],
    paths: Table[Node, seq[Node]],
    cutoff: int,
    join: proc(p1, p2: seq[Node]): seq[Node]
): Table[Node, seq[Node]] =
    var level = 0
    var nextLevel = firstLevel
    var ret: Table[Node, seq[Node]] = paths
    while len(nextLevel) != 0 and level < cutoff:
        var thisLevel = nextLevel
        nextLevel = initTable[Node, int]()
        for v in thisLevel.keys():
            for w in adj[v]:
                if w notin ret:
                    ret[w] = join(ret[v], @[w])
                    nextLevel[w] = 1
        level += 1
    return ret

proc singleSourceShortestPath*(
    g: Graph,
    source: Node,
    cutoff: int = -1
): Table[Node, seq[Node]] =
    if source notin g.nodeSet():
        var e = ZNetNodeNotFound()
        e.msg = fmt"the souce node {source} is not in the graph"
        raise e
    let join: proc(p1, p2: seq[Node]): seq[Node] =
        proc(p1, p2: seq[Node]): seq[Node] =
            return concat(p1, p2)
    var nextLevel: Table[Node, int] = initTable[Node, int]()
    nextLevel[source] = 1
    var paths: Table[Node, seq[Node]] = initTable[Node, seq[Node]]()
    paths[source] = @[source]
    return singleShortestPath(g.adj, nextLevel, paths, cutoff, join)

proc singleSourceShortestPath*(
    dg: DirectedGraph,
    source: Node,
    cutoff: int = -1
): Table[Node, seq[Node]] =
    if source notin dg.nodeSet():
        var e = ZNetNodeNotFound()
        e.msg = fmt"the souce node {source} is not in the graph"
        raise e
    let join: proc(p1, p2: seq[Node]): seq[Node] =
        proc(p1, p2: seq[Node]): seq[Node] =
            return concat(p1, p2)
    var nextLevel: Table[Node, int] = initTable[Node, int]()
    nextLevel[source] = 1
    var paths: Table[Node, seq[Node]] = initTable[Node, seq[Node]]()
    paths[source] = @[source]
    return singleShortestPath(dg.adj, nextLevel, paths, cutoff, join)

proc singleTargetShortestPath*(
    g: Graph,
    target: Node,
    cutoff: int = -1
): Table[Node, seq[Node]] =
    if target notin g.nodeSet():
        var e = ZNetNodeNotFound()
        e.msg = fmt"the target node {target} is not in the graph"
        raise e
    let join: proc(p1, p2: seq[Node]): seq[Node] =
        proc(p1, p2: seq[Node]): seq[Node] =
            return concat(p1, p2)
    var nextLevel: Table[Node, int] = initTable[Node, int]()
    nextLevel[target] = 1
    var paths: Table[Node, seq[Node]] = initTable[Node, seq[Node]]()
    paths[target] = @[target]
    return singleShortestPath(g.adj, nextLevel, paths, cutoff, join)

proc singleTargetShortestPath*(
    dg: DirectedGraph,
    target: Node,
    cutoff: int = -1
): Table[Node, seq[Node]] =
    if target notin dg.nodeSet():
        var e = ZNetNodeNotFound()
        e.msg = fmt"the target node {target} is not in the graph"
        raise e
    let join: proc(p1, p2: seq[Node]): seq[Node] =
        proc(p1, p2: seq[Node]): seq[Node] =
            return concat(p1, p2)
    var nextLevel: Table[Node, int] = initTable[Node, int]()
    nextLevel[target] = 1
    var paths: Table[Node, seq[Node]] = initTable[Node, seq[Node]]()
    paths[target] = @[target]
    return singleShortestPath(dg.pred, nextLevel, paths, cutoff, join)

iterator allPairsShortestPath*(
    g: Graph,
    cutoff: int = -1
): tuple[source: Node, lengths: Table[Node, seq[Node]]] =
    for n in g.nodes():
        yield (n, g.singleSourceShortestPath(n, cutoff))

iterator allPairsShortestPath*(
    dg: DirectedGraph,
    cutoff: int = -1
): tuple[source: Node, lengths: Table[Node, seq[Node]]] =
    for n in dg.nodes():
        yield (n, dg.singleSourceShortestPath(n, cutoff))

proc predecessor*(
    g: Graph,
    source: Node,
    cutoff: int = -1,
): Table[Node, seq[Node]] =
    if source notin g.nodeSet():
        var e = ZNetNodeNotFound()
        e.msg = fmt"the source node {source} is not in the graph"
        raise e
    var level = 0
    var nextLevel = @[source]
    var seen: Table[Node, int] = initTable[Node, int]()
    seen[source] = level
    var pred: Table[Node, seq[Node]] = initTable[Node, seq[Node]]()
    pred[source] = @[]
    while len(nextLevel) != 0:
        level += 1
        var thisLevel = nextLevel
        nextLevel = @[]
        for v in thisLevel:
            for w in g.neighbors(v):
                if w notin seen:
                    pred[w] = @[v]
                    seen[w] = level
                    nextLevel.add(w)
                elif seen[w] == level:
                    pred[w].add(v)
        if cutoff != -1 and cutoff <= level:
            break
    return pred

proc predecessor*(
    g: Graph,
    source: Node,
    target: Node,
    cutoff: int = -1,
): seq[Node] =
    if source notin g.nodeSet():
        var e = ZNetNodeNotFound()
        e.msg = fmt"the source node {source} is not in the graph"
        raise e
    var level = 0
    var nextLevel = @[source]
    var seen: Table[Node, int] = initTable[Node, int]()
    seen[source] = level
    var pred: Table[Node, seq[Node]] = initTable[Node, seq[Node]]()
    pred[source] = @[]
    while len(nextLevel) != 0:
        level += 1
        var thisLevel = nextLevel
        nextLevel = @[]
        for v in thisLevel:
            for w in g.neighbors(v):
                if w notin seen:
                    pred[w] = @[v]
                    seen[w] = level
                    nextLevel.add(w)
                elif seen[w] == level:
                    pred[w].add(v)
        if cutoff != -1 and cutoff <= level:
            break
    if target notin pred:
        return @[]
    return pred[target]

proc predecessor*(
    dg: DirectedGraph,
    source: Node,
    cutoff: int = -1,
): Table[Node, seq[Node]] =
    if source notin dg.nodeSet():
        var e = ZNetNodeNotFound()
        e.msg = fmt"the source node {source} is not in the graph"
        raise e
    var level = 0
    var nextLevel = @[source]
    var seen: Table[Node, int] = initTable[Node, int]()
    seen[source] = level
    var pred: Table[Node, seq[Node]] = initTable[Node, seq[Node]]()
    pred[source] = @[]
    while len(nextLevel) != 0:
        level += 1
        var thisLevel = nextLevel
        nextLevel = @[]
        for v in thisLevel:
            for w in dg.neighbors(v):
                if w notin seen:
                    pred[w] = @[v]
                    seen[w] = level
                    nextLevel.add(w)
                elif seen[w] == level:
                    pred[w].add(v)
        if cutoff != -1 and cutoff <= level:
            break
    return pred

proc predecessor*(
    dg: DirectedGraph,
    source: Node,
    target: Node,
    cutoff: int = -1,
): seq[Node] =
    if source notin dg.nodeSet():
        var e = ZNetNodeNotFound()
        e.msg = fmt"the source node {source} is not in the graph"
        raise e
    var level = 0
    var nextLevel = @[source]
    var seen: Table[Node, int] = initTable[Node, int]()
    seen[source] = level
    var pred: Table[Node, seq[Node]] = initTable[Node, seq[Node]]()
    pred[source] = @[]
    while len(nextLevel) != 0:
        level += 1
        var thisLevel = nextLevel
        nextLevel = @[]
        for v in thisLevel:
            for w in dg.neighbors(v):
                if w notin seen:
                    pred[w] = @[v]
                    seen[w] = level
                    nextLevel.add(w)
                elif seen[w] == level:
                    pred[w].add(v)
        if cutoff != -1 and cutoff <= level:
            break
    if target notin pred:
        return @[]
    return pred[target]

when isMainModule:
    block singleSourceShortestPathLength:
        var G = newGraph()
        G.addPath(@[0, 1, 2, 3, 4])
        var ret = singleSourceShortestPathLength(G, 0)
        var nxRet = {4: 4, 3: 3, 2: 2, 0: 0, 1: 1}.toTable()
        for (node, length) in ret.pairs():
            doAssert length == nxRet[node]
    block karateSingleSourceShortestPathLength:
        var karate = newGraph()
        karate.addEdgesFrom(@[(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)])
        var ret = karate.singleSourceShortestPathLength(0)
        var nxRet = {0: 0, 1: 1, 2: 1, 3: 1, 4: 1, 5: 1, 6: 1, 7: 1, 8: 1, 10: 1, 11: 1, 12: 1, 13: 1, 17: 1, 19: 1, 21: 1, 31: 1, 9: 2, 16: 2, 24: 2, 25: 2, 27: 2, 28: 2, 30: 2, 32: 2, 33: 2, 14: 3, 15: 3, 18: 3, 20: 3, 22: 3, 23: 3, 26: 3, 29: 3}.toTable()
        for (node, length) in ret.pairs():
            doAssert length == nxRet[node]
    block dkarateSingleSourceShortestPathLength:
        var dkarate = newDirectedGraph()
        dkarate.addEdgesFrom(@[(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)])
        var ret = dkarate.singleSourceShortestPathLength(0)
        var nxRet = {0: 0, 1: 1, 2: 1, 3: 1, 4: 1, 5: 1, 6: 1, 7: 1, 8: 1, 10: 1, 11: 1, 12: 1, 13: 1, 17: 1, 19: 1, 21: 1, 31: 1, 32: 2, 33: 2, 9: 2, 16: 2, 27: 2, 28: 2, 30: 2}.toTable()
        for (node, length) in ret.pairs():
            doAssert length == nxRet[node]

    block singleTargetShortestPathLength:
        var G = newGraph()
        G.addPath(@[0, 1, 2, 3, 4])
        var ret = singleSourceShortestPathLength(G, 4)
        var nxRet = {4: 0, 3: 1, 2: 2, 0: 4, 1: 3}.toTable()
        for (node, length) in ret.pairs():
            doAssert length == nxRet[node]
    block karateSingleTargetShortestPathLength:
        var karate = newGraph()
        karate.addEdgesFrom(@[(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)])
        var ret = karate.singleTargetShortestPathLength(7)
        var nxRet = {7: 0, 0: 1, 1: 1, 2: 1, 3: 1, 4: 2, 5: 2, 6: 2, 8: 2, 9: 2, 10: 2, 11: 2, 12: 2, 13: 2, 17: 2, 19: 2, 21: 2, 27: 2, 28: 2, 30: 2, 31: 2, 32: 2, 14: 3, 15: 3, 16: 3, 18: 3, 20: 3, 22: 3, 23: 3, 24: 3, 25: 3, 29: 3, 33: 3, 26: 4}.toTable()
        for (node, length) in ret.pairs():
            doAssert length == nxRet[node]
    block dkarateSingleTargetShortestPathLength:
        var dkarate = newDirectedGraph()
        dkarate.addEdgesFrom(@[(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)])
        var ret = dkarate.singleTargetShortestPathLength(7)
        var nxRet = {7: 0, 0: 1, 1: 1, 2: 1, 3: 1}.toTable()
        for (node, length) in ret.pairs():
            doAssert length == nxRet[node]

    block allPairsShortestPathLength:
        var G = newGraph()
        G.addPath(@[0, 1, 2, 3, 4])
        var nxRet =
            {
                0: {0: 0, 1: 1, 2: 2, 3: 3, 4: 4}.toTable(),
                1: {1: 0, 0: 1, 2: 1, 3: 2, 4: 3}.toTable(),
                2: {2: 0, 1: 1, 3: 1, 0: 2, 4: 2}.toTable(),
                3: {3: 0, 2: 1, 4: 1, 1: 2, 0: 3}.toTable(),
                4: {4: 0, 3: 1, 2: 2, 1: 3, 0: 4}.toTable()
            }.toTable()
        for (source, lengths) in G.allPairsShortestPathLength():
            for (target, length) in lengths.pairs():
                doAssert length == nxRet[source][target]
    block karateAllPairsShortestPathLength:
        var karate = newGraph()
        karate.addEdgesFrom(@[(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)])
        var nxRet =
            {
                0: {0: 0, 1: 1, 2: 1, 3: 1, 4: 1, 5: 1, 6: 1, 7: 1, 8: 1, 10: 1, 11: 1, 12: 1, 13: 1, 17: 1, 19: 1, 21: 1, 31: 1, 9: 2, 16: 2, 24: 2, 25: 2, 27: 2, 28: 2, 30: 2, 32: 2, 33: 2, 14: 3, 15: 3, 18: 3, 20: 3, 22: 3, 23: 3, 26: 3, 29: 3}.toTable(),
                1: {1: 0, 0: 1, 2: 1, 3: 1, 7: 1, 13: 1, 17: 1, 19: 1, 21: 1, 30: 1, 4: 2, 5: 2, 6: 2, 8: 2, 9: 2, 10: 2, 11: 2, 12: 2, 27: 2, 28: 2, 31: 2, 32: 2, 33: 2, 14: 3, 15: 3, 16: 3, 18: 3, 20: 3, 22: 3, 23: 3, 24: 3, 25: 3, 26: 3, 29: 3}.toTable(),
                2: {2: 0, 0: 1, 1: 1, 32: 1, 3: 1, 7: 1, 8: 1, 9: 1, 13: 1, 27: 1, 28: 1, 4: 2, 5: 2, 6: 2, 10: 2, 11: 2, 12: 2, 14: 2, 15: 2, 17: 2, 18: 2, 19: 2, 20: 2, 21: 2, 22: 2, 23: 2, 24: 2, 29: 2, 30: 2, 31: 2, 33: 2, 16: 3, 25: 3, 26: 3}.toTable(),
                3: {3: 0, 0: 1, 1: 1, 2: 1, 7: 1, 12: 1, 13: 1, 4: 2, 5: 2, 6: 2, 8: 2, 9: 2, 10: 2, 11: 2, 17: 2, 19: 2, 21: 2, 27: 2, 28: 2, 30: 2, 31: 2, 32: 2, 33: 2, 14: 3, 15: 3, 16: 3, 18: 3, 20: 3, 22: 3, 23: 3, 24: 3, 25: 3, 26: 3, 29: 3}.toTable(),
                4: {4: 0, 0: 1, 10: 1, 6: 1, 1: 2, 2: 2, 3: 2, 5: 2, 7: 2, 8: 2, 11: 2, 12: 2, 13: 2, 16: 2, 17: 2, 19: 2, 21: 2, 31: 2, 9: 3, 24: 3, 25: 3, 27: 3, 28: 3, 30: 3, 32: 3, 33: 3, 14: 4, 15: 4, 18: 4, 20: 4, 22: 4, 23: 4, 26: 4, 29: 4}.toTable(),
                5: {5: 0, 0: 1, 16: 1, 10: 1, 6: 1, 1: 2, 2: 2, 3: 2, 4: 2, 7: 2, 8: 2, 11: 2, 12: 2, 13: 2, 17: 2, 19: 2, 21: 2, 31: 2, 9: 3, 24: 3, 25: 3, 27: 3, 28: 3, 30: 3, 32: 3, 33: 3, 14: 4, 15: 4, 18: 4, 20: 4, 22: 4, 23: 4, 26: 4, 29: 4}.toTable(),
                6: {6: 0, 0: 1, 16: 1, 4: 1, 5: 1, 1: 2, 2: 2, 3: 2, 7: 2, 8: 2, 10: 2, 11: 2, 12: 2, 13: 2, 17: 2, 19: 2, 21: 2, 31: 2, 9: 3, 24: 3, 25: 3, 27: 3, 28: 3, 30: 3, 32: 3, 33: 3, 14: 4, 15: 4, 18: 4, 20: 4, 22: 4, 23: 4, 26: 4, 29: 4}.toTable(),
                7: {7: 0, 0: 1, 1: 1, 2: 1, 3: 1, 4: 2, 5: 2, 6: 2, 8: 2, 9: 2, 10: 2, 11: 2, 12: 2, 13: 2, 17: 2, 19: 2, 21: 2, 27: 2, 28: 2, 30: 2, 31: 2, 32: 2, 14: 3, 15: 3, 16: 3, 18: 3, 20: 3, 22: 3, 23: 3, 24: 3, 25: 3, 29: 3, 33: 3, 26: 4}.toTable(),
                8: {8: 0, 0: 1, 33: 1, 2: 1, 32: 1, 30: 1, 1: 2, 3: 2, 4: 2, 5: 2, 6: 2, 7: 2, 9: 2, 10: 2, 11: 2, 12: 2, 13: 2, 14: 2, 15: 2, 17: 2, 18: 2, 19: 2, 20: 2, 21: 2, 22: 2, 23: 2, 26: 2, 27: 2, 28: 2, 29: 2, 31: 2, 16: 3, 24: 3, 25: 3}.toTable(),
                9: {9: 0, 33: 1, 2: 1, 0: 2, 1: 2, 3: 2, 7: 2, 8: 2, 13: 2, 14: 2, 15: 2, 18: 2, 19: 2, 20: 2, 22: 2, 23: 2, 26: 2, 27: 2, 28: 2, 29: 2, 30: 2, 31: 2, 32: 2, 4: 3, 5: 3, 6: 3, 10: 3, 11: 3, 12: 3, 17: 3, 21: 3, 24: 3, 25: 3, 16: 4}.toTable(),
                10: {10: 0, 0: 1, 4: 1, 5: 1, 1: 2, 2: 2, 3: 2, 6: 2, 7: 2, 8: 2, 11: 2, 12: 2, 13: 2, 16: 2, 17: 2, 19: 2, 21: 2, 31: 2, 9: 3, 24: 3, 25: 3, 27: 3, 28: 3, 30: 3, 32: 3, 33: 3, 14: 4, 15: 4, 18: 4, 20: 4, 22: 4, 23: 4, 26: 4, 29: 4}.toTable(),
                11: {11: 0, 0: 1, 1: 2, 2: 2, 3: 2, 4: 2, 5: 2, 6: 2, 7: 2, 8: 2, 10: 2, 12: 2, 13: 2, 17: 2, 19: 2, 21: 2, 31: 2, 9: 3, 16: 3, 24: 3, 25: 3, 27: 3, 28: 3, 30: 3, 32: 3, 33: 3, 14: 4, 15: 4, 18: 4, 20: 4, 22: 4, 23: 4, 26: 4, 29: 4}.toTable(),
                12: {12: 0, 0: 1, 3: 1, 1: 2, 2: 2, 4: 2, 5: 2, 6: 2, 7: 2, 8: 2, 10: 2, 11: 2, 13: 2, 17: 2, 19: 2, 21: 2, 31: 2, 9: 3, 16: 3, 24: 3, 25: 3, 27: 3, 28: 3, 30: 3, 32: 3, 33: 3, 14: 4, 15: 4, 18: 4, 20: 4, 22: 4, 23: 4, 26: 4, 29: 4}.toTable(),
                13: {13: 0, 0: 1, 1: 1, 2: 1, 3: 1, 33: 1, 4: 2, 5: 2, 6: 2, 7: 2, 8: 2, 9: 2, 10: 2, 11: 2, 12: 2, 14: 2, 15: 2, 17: 2, 18: 2, 19: 2, 20: 2, 21: 2, 22: 2, 23: 2, 26: 2, 27: 2, 28: 2, 29: 2, 30: 2, 31: 2, 32: 2, 16: 3, 24: 3, 25: 3}.toTable(),
                14: {14: 0, 32: 1, 33: 1, 2: 2, 8: 2, 9: 2, 13: 2, 15: 2, 18: 2, 19: 2, 20: 2, 22: 2, 23: 2, 26: 2, 27: 2, 28: 2, 29: 2, 30: 2, 31: 2, 0: 3, 1: 3, 3: 3, 7: 3, 24: 3, 25: 3, 4: 4, 5: 4, 6: 4, 10: 4, 11: 4, 12: 4, 17: 4, 21: 4, 16: 5}.toTable(),
                15: {15: 0, 32: 1, 33: 1, 2: 2, 8: 2, 9: 2, 13: 2, 14: 2, 18: 2, 19: 2, 20: 2, 22: 2, 23: 2, 26: 2, 27: 2, 28: 2, 29: 2, 30: 2, 31: 2, 0: 3, 1: 3, 3: 3, 7: 3, 24: 3, 25: 3, 4: 4, 5: 4, 6: 4, 10: 4, 11: 4, 12: 4, 17: 4, 21: 4, 16: 5}.toTable(),
                16: {16: 0, 5: 1, 6: 1, 0: 2, 4: 2, 10: 2, 1: 3, 2: 3, 3: 3, 7: 3, 8: 3, 11: 3, 12: 3, 13: 3, 17: 3, 19: 3, 21: 3, 31: 3, 9: 4, 24: 4, 25: 4, 27: 4, 28: 4, 30: 4, 32: 4, 33: 4, 14: 5, 15: 5, 18: 5, 20: 5, 22: 5, 23: 5, 26: 5, 29: 5}.toTable(),
                17: {17: 0, 0: 1, 1: 1, 2: 2, 3: 2, 4: 2, 5: 2, 6: 2, 7: 2, 8: 2, 10: 2, 11: 2, 12: 2, 13: 2, 19: 2, 21: 2, 30: 2, 31: 2, 9: 3, 16: 3, 24: 3, 25: 3, 27: 3, 28: 3, 32: 3, 33: 3, 14: 4, 15: 4, 18: 4, 20: 4, 22: 4, 23: 4, 26: 4, 29: 4}.toTable(),
                18: {18: 0, 32: 1, 33: 1, 2: 2, 8: 2, 9: 2, 13: 2, 14: 2, 15: 2, 19: 2, 20: 2, 22: 2, 23: 2, 26: 2, 27: 2, 28: 2, 29: 2, 30: 2, 31: 2, 0: 3, 1: 3, 3: 3, 7: 3, 24: 3, 25: 3, 4: 4, 5: 4, 6: 4, 10: 4, 11: 4, 12: 4, 17: 4, 21: 4, 16: 5}.toTable(),
                19: {19: 0, 0: 1, 1: 1, 33: 1, 2: 2, 3: 2, 4: 2, 5: 2, 6: 2, 7: 2, 8: 2, 9: 2, 10: 2, 11: 2, 12: 2, 13: 2, 14: 2, 15: 2, 17: 2, 18: 2, 20: 2, 21: 2, 22: 2, 23: 2, 26: 2, 27: 2, 28: 2, 29: 2, 30: 2, 31: 2, 32: 2, 16: 3, 24: 3, 25: 3}.toTable(),
                20: {20: 0, 32: 1, 33: 1, 2: 2, 8: 2, 9: 2, 13: 2, 14: 2, 15: 2, 18: 2, 19: 2, 22: 2, 23: 2, 26: 2, 27: 2, 28: 2, 29: 2, 30: 2, 31: 2, 0: 3, 1: 3, 3: 3, 7: 3, 24: 3, 25: 3, 4: 4, 5: 4, 6: 4, 10: 4, 11: 4, 12: 4, 17: 4, 21: 4, 16: 5}.toTable(),
                21: {21: 0, 0: 1, 1: 1, 2: 2, 3: 2, 4: 2, 5: 2, 6: 2, 7: 2, 8: 2, 10: 2, 11: 2, 12: 2, 13: 2, 17: 2, 19: 2, 30: 2, 31: 2, 9: 3, 16: 3, 24: 3, 25: 3, 27: 3, 28: 3, 32: 3, 33: 3, 14: 4, 15: 4, 18: 4, 20: 4, 22: 4, 23: 4, 26: 4, 29: 4}.toTable(),
                22: {22: 0, 32: 1, 33: 1, 2: 2, 8: 2, 9: 2, 13: 2, 14: 2, 15: 2, 18: 2, 19: 2, 20: 2, 23: 2, 26: 2, 27: 2, 28: 2, 29: 2, 30: 2, 31: 2, 0: 3, 1: 3, 3: 3, 7: 3, 24: 3, 25: 3, 4: 4, 5: 4, 6: 4, 10: 4, 11: 4, 12: 4, 17: 4, 21: 4, 16: 5}.toTable(),
                23: {23: 0, 32: 1, 33: 1, 25: 1, 27: 1, 29: 1, 2: 2, 8: 2, 9: 2, 13: 2, 14: 2, 15: 2, 18: 2, 19: 2, 20: 2, 22: 2, 24: 2, 26: 2, 28: 2, 30: 2, 31: 2, 0: 3, 1: 3, 3: 3, 7: 3, 4: 4, 5: 4, 6: 4, 10: 4, 11: 4, 12: 4, 17: 4, 21: 4, 16: 5}.toTable(),
                24: {24: 0, 25: 1, 27: 1, 31: 1, 0: 2, 33: 2, 2: 2, 32: 2, 23: 2, 28: 2, 1: 3, 3: 3, 4: 3, 5: 3, 6: 3, 7: 3, 8: 3, 9: 3, 10: 3, 11: 3, 12: 3, 13: 3, 14: 3, 15: 3, 17: 3, 18: 3, 19: 3, 20: 3, 21: 3, 22: 3, 26: 3, 29: 3, 30: 3, 16: 4}.toTable(),
                25: {25: 0, 24: 1, 31: 1, 23: 1, 0: 2, 32: 2, 33: 2, 27: 2, 28: 2, 29: 2, 1: 3, 2: 3, 3: 3, 4: 3, 5: 3, 6: 3, 7: 3, 8: 3, 9: 3, 10: 3, 11: 3, 12: 3, 13: 3, 14: 3, 15: 3, 17: 3, 18: 3, 19: 3, 20: 3, 21: 3, 22: 3, 26: 3, 30: 3, 16: 4}.toTable(),
                26: {26: 0, 33: 1, 29: 1, 32: 2, 8: 2, 9: 2, 13: 2, 14: 2, 15: 2, 18: 2, 19: 2, 20: 2, 22: 2, 23: 2, 27: 2, 28: 2, 30: 2, 31: 2, 0: 3, 1: 3, 2: 3, 3: 3, 24: 3, 25: 3, 4: 4, 5: 4, 6: 4, 7: 4, 10: 4, 11: 4, 12: 4, 17: 4, 21: 4, 16: 5}.toTable(),
                27: {27: 0, 24: 1, 33: 1, 2: 1, 23: 1, 0: 2, 1: 2, 3: 2, 7: 2, 8: 2, 9: 2, 13: 2, 14: 2, 15: 2, 18: 2, 19: 2, 20: 2, 22: 2, 25: 2, 26: 2, 28: 2, 29: 2, 30: 2, 31: 2, 32: 2, 4: 3, 5: 3, 6: 3, 10: 3, 11: 3, 12: 3, 17: 3, 21: 3, 16: 4}.toTable(),
                28: {28: 0, 33: 1, 2: 1, 31: 1, 0: 2, 1: 2, 3: 2, 7: 2, 8: 2, 9: 2, 13: 2, 14: 2, 15: 2, 18: 2, 19: 2, 20: 2, 22: 2, 23: 2, 24: 2, 25: 2, 26: 2, 27: 2, 29: 2, 30: 2, 32: 2, 4: 3, 5: 3, 6: 3, 10: 3, 11: 3, 12: 3, 17: 3, 21: 3, 16: 4}.toTable(),
                29: {29: 0, 32: 1, 33: 1, 26: 1, 23: 1, 2: 2, 8: 2, 9: 2, 13: 2, 14: 2, 15: 2, 18: 2, 19: 2, 20: 2, 22: 2, 25: 2, 27: 2, 28: 2, 30: 2, 31: 2, 0: 3, 1: 3, 3: 3, 7: 3, 24: 3, 4: 4, 5: 4, 6: 4, 10: 4, 11: 4, 12: 4, 17: 4, 21: 4, 16: 5}.toTable(),
                30: {30: 0, 8: 1, 1: 1, 32: 1, 33: 1, 0: 2, 2: 2, 3: 2, 7: 2, 9: 2, 13: 2, 14: 2, 15: 2, 17: 2, 18: 2, 19: 2, 20: 2, 21: 2, 22: 2, 23: 2, 26: 2, 27: 2, 28: 2, 29: 2, 31: 2, 4: 3, 5: 3, 6: 3, 10: 3, 11: 3, 12: 3, 24: 3, 25: 3, 16: 4}.toTable(),
                31: {31: 0, 0: 1, 32: 1, 33: 1, 24: 1, 25: 1, 28: 1, 1: 2, 2: 2, 3: 2, 4: 2, 5: 2, 6: 2, 7: 2, 8: 2, 9: 2, 10: 2, 11: 2, 12: 2, 13: 2, 14: 2, 15: 2, 17: 2, 18: 2, 19: 2, 20: 2, 21: 2, 22: 2, 23: 2, 26: 2, 27: 2, 29: 2, 30: 2, 16: 3}.toTable(),
                32: {32: 0, 33: 1, 2: 1, 8: 1, 14: 1, 15: 1, 18: 1, 20: 1, 22: 1, 23: 1, 29: 1, 30: 1, 31: 1, 0: 2, 1: 2, 3: 2, 7: 2, 9: 2, 13: 2, 19: 2, 24: 2, 25: 2, 26: 2, 27: 2, 28: 2, 4: 3, 5: 3, 6: 3, 10: 3, 11: 3, 12: 3, 17: 3, 21: 3, 16: 4}.toTable(),
                33: {33: 0, 32: 1, 8: 1, 9: 1, 13: 1, 14: 1, 15: 1, 18: 1, 19: 1, 20: 1, 22: 1, 23: 1, 26: 1, 27: 1, 28: 1, 29: 1, 30: 1, 31: 1, 0: 2, 1: 2, 2: 2, 3: 2, 24: 2, 25: 2, 4: 3, 5: 3, 6: 3, 7: 3, 10: 3, 11: 3, 12: 3, 17: 3, 21: 3, 16: 4}.toTable(),
            }.toTable()
        for (source, lengths) in karate.allPairsShortestPathLength():
            for (target, length) in lengths.pairs():
                doAssert length == nxRet[source][target]
    block dkarateAllPairsShortestPathLength:
        var dkarate = newDirectedGraph()
        dkarate.addEdgesFrom(@[(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)])
        var nxRet =
            {
                0: {0: 0, 1: 1, 2: 1, 3: 1, 4: 1, 5: 1, 6: 1, 7: 1, 8: 1, 10: 1, 11: 1, 12: 1, 13: 1, 17: 1, 19: 1, 21: 1, 31: 1, 32: 2, 33: 2, 9: 2, 16: 2, 27: 2, 28: 2, 30: 2}.toTable(),
                1: {1: 0, 2: 1, 3: 1, 7: 1, 13: 1, 17: 1, 19: 1, 21: 1, 30: 1, 32: 2, 33: 2, 8: 2, 9: 2, 12: 2, 27: 2, 28: 2, 31: 3}.toTable(),
                2: {2: 0, 32: 1, 3: 1, 7: 1, 8: 1, 9: 1, 13: 1, 27: 1, 28: 1, 33: 2, 12: 2, 30: 2, 31: 2}.toTable(),
                3: {3: 0, 12: 1, 13: 1, 7: 1, 33: 2}.toTable(),
                4: {4: 0, 10: 1, 6: 1, 16: 2}.toTable(),
                5: {5: 0, 16: 1, 10: 1, 6: 1}.toTable(),
                6: {6: 0, 16: 1}.toTable(),
                7: {7: 0}.toTable(),
                8: {8: 0, 32: 1, 33: 1, 30: 1}.toTable(),
                10: {10: 0}.toTable(),
                11: {11: 0}.toTable(),
                12: {12: 0}.toTable(),
                13: {13: 0, 33: 1}.toTable(),
                17: {17: 0}.toTable(),
                19: {19: 0, 33: 1}.toTable(),
                21: {21: 0}.toTable(),
                31: {31: 0, 32: 1, 33: 1}.toTable(),
                30: {30: 0, 32: 1, 33: 1}.toTable(),
                9: {9: 0, 33: 1}.toTable(),
                27: {27: 0, 33: 1}.toTable(),
                28: {28: 0, 33: 1, 31: 1, 32: 2}.toTable(),
                32: {32: 0, 33: 1}.toTable(),
                16: {16: 0}.toTable(),
                33: {33: 0}.toTable(),
                14: {14: 0, 32: 1, 33: 1}.toTable(),
                15: {15: 0, 32: 1, 33: 1}.toTable(),
                18: {18: 0, 32: 1, 33: 1}.toTable(),
                20: {20: 0, 32: 1, 33: 1}.toTable(),
                22: {22: 0, 32: 1, 33: 1}.toTable(),
                23: {23: 0, 32: 1, 33: 1, 25: 1, 27: 1, 29: 1, 31: 2}.toTable(),
                25: {25: 0, 31: 1, 32: 2, 33: 2}.toTable(),
                29: {29: 0, 32: 1, 33: 1}.toTable(),
                24: {24: 0, 25: 1, 27: 1, 31: 1, 32: 2, 33: 2}.toTable(),
                26: {26: 0, 33: 1, 29: 1, 32: 2}.toTable()
            }.toTable()
        for (source, lengths) in dkarate.allPairsShortestPathLength():
            for (target, length) in lengths.pairs():
                doAssert length == nxRet[source][target]

    block karateBidirectionalShortestPath:
        var karate = newGraph()
        karate.addEdgesFrom(@[(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)])
        doAssert @[0, 2, 32, 29] == karate.bidirectionalShortestPath(0, 29)
    block dkarateBidirectionalShortestPath:
        var dkarate = newDirectedGraph()
        dkarate.addEdgesFrom(@[(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)])
        try:
            discard dkarate.bidirectionalShortestPath(0, 29)
        except ZNetNoPath as e:
            echo(e.msg)

    block karateSingleSourceShortestPath:
        var karate = newGraph()
        karate.addEdgesFrom(@[(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)])
        var ret: Table[Node, seq[Node]] = karate.singleSourceShortestPath(0)
        var nxRet =
            {
                0: @[0],
                1: @[0, 1],
                2: @[0, 2],
                3: @[0, 3],
                4: @[0, 4],
                5: @[0, 5],
                6: @[0, 6],
                7: @[0, 7],
                8: @[0, 8],
                10: @[0, 10],
                11: @[0, 11],
                12: @[0, 12],
                13: @[0, 13],
                17: @[0, 17],
                19: @[0, 19],
                21: @[0, 21],
                31: @[0, 31],
                30: @[0, 1, 30],
                9: @[0, 2, 9],
                27: @[0, 2, 27],
                28: @[0, 2, 28],
                32: @[0, 2, 32],
                16: @[0, 5, 16],
                33: @[0, 8, 33],
                24: @[0, 31, 24],
                25: @[0, 31, 25],
                23: @[0, 2, 27, 23],
                14: @[0, 2, 32, 14],
                15: @[0, 2, 32, 15],
                18: @[0, 2, 32, 18],
                20: @[0, 2, 32, 20],
                22: @[0, 2, 32, 22],
                29: @[0, 2, 32, 29],
                26: @[0, 8, 33, 26],
            }.toTable()
        for (node, path) in ret.pairs():
            doAssert path == nxRet[node]
    block dkarateSingleSourceShortestPath:
        var dkarate = newDirectedGraph()
        dkarate.addEdgesFrom(@[(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)])
        var ret: Table[Node, seq[Node]] = dkarate.singleSourceShortestPath(0)
        var nxRet =
            {
                0: @[0],
                1: @[0, 1],
                2: @[0, 2],
                3: @[0, 3],
                4: @[0, 4],
                5: @[0, 5],
                6: @[0, 6],
                7: @[0, 7],
                8: @[0, 8],
                10: @[0, 10],
                11: @[0, 11],
                12: @[0, 12],
                13: @[0, 13],
                17: @[0, 17],
                19: @[0, 19],
                21: @[0, 21],
                31: @[0, 31],
                30: @[0, 1, 30],
                9: @[0, 2, 9],
                27: @[0, 2, 27],
                28: @[0, 2, 28],
                32: @[0, 2, 32],
                16: @[0, 5, 16],
                33: @[0, 8, 33],
            }.toTable()
        for (node, path) in ret.pairs():
            doAssert path == nxRet[node]

    block karateSingleTargetShortestPath:
        var karate = newGraph()
        karate.addEdgesFrom(@[(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)])
        var ret: Table[Node, seq[Node]] = karate.singleTargetShortestPath(0)
        var nxRet =
            {
                0: @[0],
                1: @[1, 0],
                2: @[2, 0],
                3: @[3, 0],
                4: @[4, 0],
                5: @[5, 0],
                6: @[6, 0],
                7: @[7, 0],
                8: @[8, 0],
                10: @[10, 0],
                11: @[11, 0],
                12: @[12, 0],
                13: @[13, 0],
                17: @[17, 0],
                19: @[19, 0],
                21: @[21, 0],
                31: @[31, 0],
                30: @[30, 1, 0],
                9: @[9, 2, 0],
                27: @[27, 2, 0],
                28: @[28, 2, 0],
                32: @[32, 2, 0],
                16: @[16, 5, 0],
                33: @[33, 8, 0],
                24: @[24, 31, 0],
                25: @[25, 31, 0],
                23: @[23, 27, 2, 0],
                14: @[14, 32, 2, 0],
                15: @[15, 32, 2, 0],
                18: @[18, 32, 2, 0],
                20: @[20, 32, 2, 0],
                22: @[22, 32, 2, 0],
                29: @[29, 32, 2, 0],
                26: @[26, 33, 8, 0],
            }.toTable()
        for (node, path) in ret.pairs():
            doAssert path == nxRet[node]
    block dkarateSingleTargetShortestPath:
        var dkarate = newDirectedGraph()
        dkarate.addEdgesFrom(@[(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)])
        var ret: Table[Node, seq[Node]] = dkarate.singleTargetShortestPath(0)
        var nxRet =
            {
                0: @[0],
            }.toTable()
        for (node, path) in ret.pairs():
            doAssert path == nxRet[node]

    block karateAllPairsShortestPath:
        var karate = newGraph()
        karate.addEdgesFrom(@[(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)])
        var nxRet =
            {
                0: {0: @[0], 1: @[0, 1], 2: @[0, 2], 3: @[0, 3], 4: @[0, 4], 5: @[0, 5], 6: @[0, 6], 7: @[0, 7], 8: @[0, 8], 10: @[0, 10], 11: @[0, 11], 12: @[0, 12], 13: @[0, 13], 17: @[0, 17], 19: @[0, 19], 21: @[0, 21], 31: @[0, 31]}.toTable(),
                1: {1: @[1], 0: @[1, 0], 2: @[1, 2], 3: @[1, 3], 7: @[1, 7], 13: @[1, 13], 17: @[1, 17], 19: @[1, 19], 21: @[1, 21], 30: @[1, 30]}.toTable(),
                2: {2: @[2], 0: @[2, 0], 1: @[2, 1], 3: @[2, 3], 7: @[2, 7], 8: @[2, 8], 9: @[2, 9], 13: @[2, 13], 27: @[2, 27], 28: @[2, 28], 32: @[2, 32]}.toTable(),
                3: {3: @[3], 0: @[3, 0], 1: @[3, 1], 2: @[3, 2], 7: @[3, 7], 12: @[3, 12], 13: @[3, 13]}.toTable(),
                4: {4: @[4], 0: @[4, 0], 6: @[4, 6], 10: @[4, 10]}.toTable(),
                5: {5: @[5], 0: @[5, 0], 6: @[5, 6], 10: @[5, 10], 16: @[5, 16]}.toTable(),
                6: {6: @[6], 0: @[6, 0], 4: @[6, 4], 5: @[6, 5], 16: @[6, 16]}.toTable(),
                7: {7: @[7], 0: @[7, 0], 1: @[7, 1], 2: @[7, 2], 3: @[7, 3]}.toTable(),
                8: {8: @[8], 0: @[8, 0], 2: @[8, 2], 30: @[8, 30], 32: @[8, 32], 33: @[8, 33]}.toTable(),
                9: {9: @[9], 2: @[9, 2], 33: @[9, 33]}.toTable(),
                10: {10: @[10], 0: @[10, 0], 4: @[10, 4], 5: @[10, 5]}.toTable(),
                11: {11: @[11], 0: @[11, 0]}.toTable(),
                12: {12: @[12], 0: @[12, 0], 3: @[12, 3]}.toTable(),
                13: {13: @[13], 0: @[13, 0], 1: @[13, 1], 2: @[13, 2], 3: @[13, 3], 33: @[13, 33]}.toTable(),
                14: {14: @[14], 32: @[14, 32], 33: @[14, 33]}.toTable(),
                15: {15: @[15], 32: @[15, 32], 33: @[15, 33]}.toTable(),
                16: {16: @[16], 5: @[16, 5], 6: @[16, 6]}.toTable(),
                17: {17: @[17], 0: @[17, 0], 1: @[17, 1]}.toTable(),
                18: {18: @[18], 32: @[18, 32], 33: @[18, 33]}.toTable(),
                19: {19: @[19], 0: @[19, 0], 1: @[19, 1], 33: @[19, 33]}.toTable(),
                20: {20: @[20], 32: @[20, 32], 33: @[20, 33]}.toTable(),
                21: {21: @[21], 0: @[21, 0], 1: @[21, 1]}.toTable(),
                22: {22: @[22], 32: @[22, 32], 33: @[22, 33]}.toTable(),
                23: {23: @[23], 25: @[23, 25], 27: @[23, 27], 29: @[23, 29], 32: @[23, 32], 33: @[23, 33]}.toTable(),
                24: {24: @[24], 25: @[24, 25], 27: @[24, 27], 31: @[24, 31]}.toTable(),
                25: {25: @[25], 23: @[25, 23], 24: @[25, 24], 31: @[25, 31]}.toTable(),
                26: {26: @[26], 29: @[26, 29], 33: @[26, 33]}.toTable(),
                27: {27: @[27], 2: @[27, 2], 23: @[27, 23], 24: @[27, 24], 33: @[27, 33]}.toTable(),
                28: {28: @[28], 2: @[28, 2], 31: @[28, 31], 33: @[28, 33]}.toTable(),
                29: {29: @[29], 23: @[29, 23], 26: @[29, 26], 32: @[29, 32], 33: @[29, 33]}.toTable(),
                30: {30: @[30], 1: @[30, 1], 8: @[30, 8], 32: @[30, 32], 33: @[30, 33]}.toTable(),
                31: {31: @[31], 0: @[31, 0], 24: @[31, 24], 25: @[31, 25], 28: @[31, 28], 32: @[31, 32], 33: @[31, 33]}.toTable(),
                32: {32: @[32], 2: @[32, 2], 8: @[32, 8], 14: @[32, 14], 15: @[32, 15], 18: @[32, 18], 20: @[32, 20], 22: @[32, 22], 23: @[32, 23], 29: @[32, 29], 30: @[32, 30], 31: @[32, 31], 33: @[32, 33]}.toTable(),
                33: {33: @[33], 8: @[33, 8], 9: @[33, 9], 13: @[33, 13], 14: @[33, 14], 15: @[33, 15], 18: @[33, 18], 19: @[33, 19], 20: @[33, 20], 22: @[33, 22], 23: @[33, 23], 26: @[33, 26], 27: @[33, 27], 28: @[33, 28], 29: @[33, 29], 30: @[33, 30], 31: @[33, 31], 32: @[33, 32]}.toTable(),
            }.toTable()
        for (source, paths) in karate.allPairsShortestPath(1):
            for (target, path) in paths.pairs():
                doAssert path == nxRet[source][target]
    block dkarateAllPairsShortestPath:
        var dkarate = newDirectedGraph()
        dkarate.addEdgesFrom(@[(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)])
        var nxRet =
            {
                0: {0: @[0], 1: @[0, 1], 2: @[0, 2], 3: @[0, 3], 4: @[0, 4], 5: @[0, 5], 6: @[0, 6], 7: @[0, 7], 8: @[0, 8], 10: @[0, 10], 11: @[0, 11], 12: @[0, 12], 13: @[0, 13], 17: @[0, 17], 19: @[0, 19], 21: @[0, 21], 31: @[0, 31]}.toTable(),
                1: {1: @[1], 2: @[1, 2], 3: @[1, 3], 7: @[1, 7], 13: @[1, 13], 17: @[1, 17], 19: @[1, 19], 21: @[1, 21], 30: @[1, 30]}.toTable(),
                2: {2: @[2], 3: @[2, 3], 7: @[2, 7], 8: @[2, 8], 9: @[2, 9], 13: @[2, 13], 27: @[2, 27], 28: @[2, 28], 32: @[2, 32]}.toTable(),
                3: {3: @[3], 7: @[3, 7], 12: @[3, 12], 13: @[3, 13]}.toTable(),
                4: {4: @[4], 6: @[4, 6], 10: @[4, 10]}.toTable(),
                5: {5: @[5], 6: @[5, 6], 10: @[5, 10], 16: @[5, 16]}.toTable(),
                6: {6: @[6], 16: @[6, 16]}.toTable(),
                7: {7: @[7]}.toTable(),
                8: {8: @[8], 30: @[8, 30], 32: @[8, 32], 33: @[8, 33]}.toTable(),
                10: {10: @[10]}.toTable(),
                11: {11: @[11]}.toTable(),
                12: {12: @[12]}.toTable(),
                13: {13: @[13], 33: @[13, 33]}.toTable(),
                17: {17: @[17]}.toTable(),
                19: {19: @[19], 33: @[19, 33]}.toTable(),
                21: {21: @[21]}.toTable(),
                31: {31: @[31], 32: @[31, 32], 33: @[31, 33]}.toTable(),
                30: {30: @[30], 32: @[30, 32], 33: @[30, 33]}.toTable(),
                9: {9: @[9], 33: @[9, 33]}.toTable(),
                27: {27: @[27], 33: @[27, 33]}.toTable(),
                28: {28: @[28], 31: @[28, 31], 33: @[28, 33]}.toTable(),
                32: {32: @[32], 33: @[32, 33]}.toTable(),
                16: {16: @[16]}.toTable(),
                33: {33: @[33]}.toTable(),
                14: {14: @[14], 32: @[14, 32], 33: @[14, 33]}.toTable(),
                15: {15: @[15], 32: @[15, 32], 33: @[15, 33]}.toTable(),
                18: {18: @[18], 32: @[18, 32], 33: @[18, 33]}.toTable(),
                20: {20: @[20], 32: @[20, 32], 33: @[20, 33]}.toTable(),
                22: {22: @[22], 32: @[22, 32], 33: @[22, 33]}.toTable(),
                23: {23: @[23], 25: @[23, 25], 27: @[23, 27], 29: @[23, 29], 32: @[23, 32], 33: @[23, 33]}.toTable(),
                25: {25: @[25], 31: @[25, 31]}.toTable(),
                29: {29: @[29], 32: @[29, 32], 33: @[29, 33]}.toTable(),
                24: {24: @[24], 25: @[24, 25], 27: @[24, 27], 31: @[24, 31]}.toTable(),
                26: {26: @[26], 29: @[26, 29], 33: @[26, 33]}.toTable(),
            }.toTable()
        for (source, paths) in dkarate.allPairsShortestPath(1):
            for (target, path) in paths.pairs():
                doAssert path == nxRet[source][target]

    block karatePredecessors:
        var karate = newGraph()
        karate.addEdgesFrom(@[(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)])
        var ret = karate.predecessor(0)
        var nxRet =
            {
                0: @[],
                1: @[0],
                2: @[0],
                3: @[0],
                4: @[0],
                5: @[0],
                6: @[0],
                7: @[0],
                8: @[0],
                10: @[0],
                11: @[0],
                12: @[0],
                13: @[0],
                17: @[0],
                19: @[0],
                21: @[0],
                31: @[0],
                30: @[1, 8],
                9: @[2],
                27: @[2],
                28: @[2, 31],
                32: @[2, 8, 31],
                16: @[5, 6],
                33: @[8, 13, 19, 31],
                24: @[31],
                25: @[31],
                23: @[27, 32, 33, 25],
                14: @[32, 33],
                15: @[32, 33],
                18: @[32, 33],
                20: @[32, 33],
                22: @[32, 33],
                29: @[32, 33],
                26: @[33]
            }.toTable()
        for (node, predecessors) in ret.pairs():
            doAssert predecessors == nxRet[node]
    block dkaratePredecessors:
        var dkarate = newDirectedGraph()
        dkarate.addEdgesFrom(@[(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)])
        var ret = dkarate.predecessor(0)
        var nxRet =
            {
                0: @[],
                1: @[0],
                2: @[0],
                3: @[0],
                4: @[0],
                5: @[0],
                6: @[0],
                7: @[0],
                8: @[0],
                10: @[0],
                11: @[0],
                12: @[0],
                13: @[0],
                17: @[0],
                19: @[0],
                21: @[0],
                31: @[0],
                30: @[1, 8],
                9: @[2],
                27: @[2],
                28: @[2],
                32: @[2, 8, 31],
                16: @[5, 6],
                33: @[8, 13, 19, 31],
            }.toTable()
        for (node, predecessors) in ret.pairs():
            doAssert predecessors == nxRet[node]