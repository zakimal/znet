import algorithm
import sequtils
import tables
import strformat
import sets
import deques
import heapqueue

import ../../graph.nim
import ../../exception.nim

# FIXME: ポインタを積極的に使った実装への全面リファクタ

iterator buildPathsFromPredecessors(
    sources: HashSet[Node],
    target: Node,
    pred: Table[Node, seq[Node]]
): seq[Node] =
    if target notin pred:
        var e = ZNetNoPath()
        e.msg = fmt"the target node {target} cannot be reached from given sources {sources}"
        raise e
    var seen: HashSet[Node] = initHashSet[Node]()
    var stack: seq[tuple[node: Node, i: int]] = newSeq[tuple[node: Node, i: int]]()
    stack.add((target, 0))
    var top = 0
    while 0 <= top:
        var (node, i) = stack[top]
        if node in sources:
            var ret: seq[Node] = newSeq[Node]()
            for idx in countdown(top, 0):
                ret.add(stack[idx].node)
            yield ret
        if i < len(pred[node]):
            stack[top].i = i + 1
            var next = pred[node][i]
            if next in seen:
                continue
            else:
                seen.incl(next)
            top += 1
            if top == len(stack):
                stack.add((next, 0))
            else:
                stack[top] = (next, 0)
        else:
            seen.excl(node)
            top -= 1

type DistNodePair = object
    dist: float
    node: Node
proc `<`(a, b: DistNodePair): bool =
    if a.dist == b.dist:
        return a.node.int < b.node.int
    return a.dist < b.dist

proc dijkstraMultiSource(
    g: Graph,
    sources: seq[Node],
    weight: Table[Edge, float],
    pred: Table[Node, seq[Node]] = initTable[Node, seq[Node]](),
    paths: Table[Node, seq[Node]] = initTable[Node, seq[Node]](),
    cutoff: float = -1.0,
    target: Node = None
): tuple[preds: Table[Node, seq[Node]], paths: Table[Node, seq[Node]], dists: Table[Node, float]] =
    var predUsing = pred
    var pathsUsing = paths
    var gSucc = g.adj
    var dist: Table[Node, float] = initTable[Node, float]()
    var seen: Table[Node, float] = initTable[Node, float]()
    var fringe = initHeapQueue[DistNodePair]()

    for source in sources:
        seen[source] = 0.0
        fringe.push(DistNodePair(dist: 0.0, node: source))

    while len(fringe) != 0:
        var dn = fringe.pop()
        var d = dn.dist
        var v = dn.node
        if v in dist:
            continue
        dist[v] = d
        if v == target:
            break
        for u in gSucc[v]:
            var cost = weight.getOrDefault((v, u), 1.0)
            var vuDist = dist[v] + cost
            if cutoff != -1:
                if cutoff < vuDist:
                    continue
            if u in dist:
                var uDist = dist[u]
                if vuDist < uDist:
                    raise newException(ValueError, "contradictory paths found: negative weights?")
                elif len(predUsing.keys().toSeq()) != 0 and vuDist == uDist:
                    predUsing[u].add(v)
            elif u notin seen or vuDist < seen[u]:
                seen[u] = vuDist
                fringe.push(DistNodePair(dist: vuDist, node: u))
                if len(pathsUsing.keys().toSeq()) != 0:
                    pathsUsing[u] = pathsUsing[v]
                    pathsUsing[u].add(u)
                if len(predUsing.keys().toSeq()) != 0:
                    predUsing[u] = @[v]
            elif vuDist == seen[u]:
                if len(predUsing.keys().toSeq()) != 0:
                    predUsing[u].add(v)
    return (predUsing, pathsUsing, dist)

proc dijkstra(
    g: Graph,
    source: Node,
    weight: Table[Edge, float],
    pred: Table[Node, seq[Node]] = initTable[Node, seq[Node]](),
    paths: Table[Node, seq[Node]] = initTable[Node, seq[Node]](),
    cutoff: float = -1.0,
    target: Node = None
): tuple[preds: Table[Node, seq[Node]], paths: Table[Node, seq[Node]], dists: Table[Node, float]] =
    var sources = @[source]
    return dijkstraMultiSource(g=g, sources=sources, weight=weight, pred=pred, paths=paths, cutoff=cutoff, target=target)

proc multiSourceDijkstra*(
    g: Graph,
    sources: HashSet[Node],
    target: Node = None,
    cutoff: float = -1.0,
    weight: Table[Edge, float] = initTable[Edge, float]()
): tuple[dists: Table[Node, float], paths: Table[Node, seq[Node]]] =
    if len(sources) == 0:
        raise newException(ValueError, "sources must not be empty")
    for s in sources:
        if s notin g.nodeSet():
            var e = ZNetNodeNotFound()
            e.msg = fmt"the node {s} not found in the graph"
            raise e
    var paths: Table[Node, seq[Node]] = initTable[Node, seq[Node]]()
    for source in sources:
        paths[source] = @[source]
    var (_, returnedPaths, dists) = dijkstraMultiSource(g=g, sources=sources.toSeq(), weight=weight, paths=paths, cutoff=cutoff, target=target)
    return (dists, returnedPaths)

proc multiSourceDijkstraPath*(
    g: Graph,
    sources: HashSet[Node],
    cutoff: float = -1.0,
    weight: Table[Edge, float] = initTable[Edge, float]()
): Table[Node, seq[Node]] =
    return multiSourceDijkstra(g=g, sources=sources, cutoff=cutoff, weight=weight).paths

proc multiSourceDijkstraPathLength*(
    g: Graph,
    sources: HashSet[Node],
    cutoff: float = -1.0,
    weight: Table[Edge, float] = initTable[Edge, float]()
): Table[Node, float] =
    if len(sources) == 0:
        raise newException(ValueError, "sources must not be empty")
    for s in sources:
        if s notin g.nodeSet():
            var e = ZNetNodeNotFound()
            e.msg = fmt"the node {s} not found in the graph"
            raise e
    return dijkstraMultiSource(g=g, sources=sources.toSeq(), weight=weight, cutoff=cutoff).dists

proc singleSourceDijkstra*(
    g: Graph,
    source: Node,
    target: Node = None,
    cutoff: float = -1.0,
    weight: Table[Edge, float] = initTable[Edge, float]()
): tuple[dists: Table[Node, float], paths: Table[Node, seq[Node]]] =
    var sources = @[source].toHashSet()
    return multiSourceDijkstra(g=g, sources=sources, cutoff=cutoff, target=target, weight=weight)

proc singleSourceDijkstraPath*(
    g: Graph,
    source: Node,
    cutoff: float = -1.0,
    weight: Table[Edge, float] = initTable[Edge, float]()
): Table[Node, seq[Node]] =
    var sources = @[source].toHashSet()
    return multiSourceDijkstraPath(g=g, sources=sources, cutoff=cutoff, weight=weight)

proc singleSourceDijkstraPathLength*(
    g: Graph,
    source: Node,
    cutoff: float = -1.0,
    weight: Table[Edge, float] = initTable[Edge, float]()
): Table[Node, float] =
    var sources = @[source].toHashSet()
    return multiSourceDijkstraPathLength(g=g, sources=sources, cutoff=cutoff, weight=weight)

proc dijkstraPath*(
    g: Graph,
    source: Node,
    target: Node,
    weight: Table[Edge, float] = initTable[Edge, float]()
): seq[Node] =
    return singleSourceDijkstra(g=g, source=source, target=target, weight=weight).paths[source]

proc dijkstraPathLength*(
    g: Graph,
    source: Node,
    target: Node,
    weight: Table[Edge, float] = initTable[Edge, float]()
): float =
    if source notin g.nodeSet():
        var e = ZNetNodeNotFound()
        e.msg = fmt"the source node {source} not found in the graph"
        raise e
    if source == target:
        return 0
    var (_, _, dists) = dijkstra(g=g, source=source, target=target, weight=weight)
    try:
        return dists[target]
    except KeyError:
        var e = ZNetNoPath()
        e.msg = fmt"the target node {target} not reachable from the source node {source}"
        raise e

proc dijkstraPredecessorAndDistance*(
    g: Graph,
    source: Node,
    cutoff: float = -1.0,
    weight: Table[Edge, float] = initTable[Edge, float]()
): tuple[pred: Table[Node, seq[Node]], dist: Table[Node, float]] =
    if source notin g.nodeSet():
        var e = ZNetNodeNotFound()
        e.msg = fmt"the source node {source} not found in the graph"
        raise e
    var pred: Table[Node, seq[Node]] = initTable[Node, seq[Node]]()
    pred[source] = @[]
    var (returnedPred, _, dist) = dijkstra(g=g, source=source, weight=weight, pred=pred, cutoff=cutoff)
    return (returnedPred, dist)

iterator allPairsDijkstra*(
    g: Graph,
    cutoff: float = -1.0,
    weight: Table[Edge, float] = initTable[Edge, float]()
): tuple[node: Node, dists: Table[Node, float], paths: Table[Node, seq[Node]]] =
    for n in g.nodes():
        var (dist, path) = singleSourceDijkstra(g=g, source=n, cutoff=cutoff, weight=weight)
        yield (n, dist, path)

iterator allPairsDijkstraLength*(
    g: Graph,
    cutoff: float = -1.0,
    weight: Table[Edge, float] = initTable[Edge, float]()
): tuple[source: Node, dists: Table[Node, float]] =
    for n in g.nodes():
        var dists = singleSourceDijkstraPathLength(g=g, source=n, cutoff=cutoff, weight=weight)
        yield (n, dists)

iterator allPairsDijkstraPath*(
    g: Graph,
    cutoff: float = -1.0,
    weight: Table[Edge, float] = initTable[Edge, float]()
): tuple[source: Node, paths: Table[Node, seq[Node]]] =
    for n in g.nodes():
        yield (n, singleSourceDijkstraPath(g=g, source=n, cutoff=cutoff, weight=weight))

proc innerBellmanFord(
    g: Graph,
    sources: seq[Node],
    weight: Table[Edge, float] = initTable[Edge, float](),
    pred: Table[Node, seq[Node]] = initTable[Node, seq[Node]](),
    dist: Table[Node, float] = initTable[Node, float](),
    heuristic: bool = true
): Node =
    for s in sources:
        if s notin g.nodeSet():
            var e = ZNetNodeNotFound()
            e.msg = fmt"the source node {s} not in the graph"
            raise e
    var predUsing: Table[Node, seq[Node]] = initTable[Node, seq[Node]]()
    if len(pred.keys().toSeq()) == 0:
        for v in sources:
            predUsing[v] = @[]

    var distUsing: Table[Node, float] = initTable[Node, float]()
    if len(dist.keys().toSeq()) == 0:
        for v in sources:
            distUsing[v] = 0.0

    var nonExistentEdge = (None, None)
    var predEdge: Table[Node, Node] = initTable[Node, Node]()
    for v in sources:
        predEdge[v] = None
    var recentUpdate: Table[Node, Edge] = initTable[Node, Edge]()
    for v in sources:
        recentUpdate[v] = nonExistentEdge

    var gSucc = g.adj
    var inf = Inf
    var n = g.len()

    var count: Table[Node, int] = initTable[Node, int]()
    var q: Deque[Node] = sources.toDeque()
    var inQ: HashSet[Node] = sources.toHashSet()

    while len(q) != 0:
        var u = q.popFirst()
        inQ.excl(u)

        var isAll = true
        for predU in predUsing[u]:
            if predU in inQ:
                isAll = false
                break
        if isAll:
            var distU = distUsing[u]
            for v in gSucc[u]:
                var distV = distU + weight.getOrDefault((u, v), 1.0)
                if distV < distUsing.getOrDefault(v, inf):
                    if heuristic:
                        if v == recentUpdate[u].u or v == recentUpdate[u].v:
                            predUsing[v].add(u)
                            return v
                        if v in predEdge and predEdge[v] == u:
                            recentUpdate[v] = recentUpdate[u]
                        else:
                            recentUpdate[v] = (u, v)
                    if v notin inQ:
                        q.addLast(v)
                        inQ.incl(v)
                        var countV = count.getOrDefault(v, 0) + 1
                        if countV == n:
                            return v
                        count[v] = countV
                    distUsing[v] = distV
                    predUsing[v] = @[u]
                    predEdge[v] = u
                elif v in distUsing and distV == distUsing[v]:
                    predUsing[v].add(u)
    return None

proc bellmanFord(
    g: Graph,
    sources: seq[Node],
    weight: Table[Edge, float] = initTable[Edge, float](),
    pred: Table[Node, seq[Node]] = initTable[Node, seq[Node]](),
    paths: Table[Node, seq[Node]] = initTable[Node, seq[Node]](),
    dist: Table[Node, float] = initTable[Node, float](),
    target: Node = None,
    heuristic: bool = true
): tuple[pred: Table[Node, seq[Node]], path: Table[Node, seq[Node]], dist: Table[Node, float]] =
    var predUsing = pred
    if len(pred.keys().toSeq()) == 0:
        for v in sources:
            predUsing[v] = @[]

    var distUsing = dist
    if len(dist.keys().toSeq()) == 0:
        for v in sources:
            distUsing[v] = 0.0

    var negativeCycleFound = innerBellmanFord(g=g, sources=sources, weight=weight, pred=predUsing, dist=distUsing, heuristic=heuristic)
    if negativeCycleFound != None:
        var e = ZNetUnbounded()
        e.msg = "negative cycle detected"
        raise e

    var pathsUsing = paths
    if len(paths.keys().toSeq()) != 0:
        var sourcesUsing = sources.toHashSet()
        var dsts: seq[Node]
        if target != None:
            dsts = @[target]
        else:
            dsts = pred.keys().toSeq()
        for dst in dsts:
            for gen in buildPathsFromPredecessors(sourcesUsing, dst, predUsing):
                pathsUsing[dst] = gen

    return (predUsing, pathsUsing, distUsing)

proc bellmanFordPredecessorAndDistance*(
    g: Graph,
    source: Node,
    target: Node = None,
    weight: Table[Edge, float] = initTable[Edge, float](),
    heuristic: bool = false
): tuple[pred: Table[Node, seq[Node]], dist: Table[Node, float]] =
    if source notin g.nodeSet():
        var e = ZNetNodeNotFound()
        e.msg = fmt"the source node {source} not found in the graph"
        raise e
    for edge in g.selfloopEdges():
        if weight[edge] < 0:
            var e = ZNetUnbounded()
            e.msg = "negative cycle detected"
            raise e

    var dist: Table[Node, float] = initTable[Node, float]()
    dist[source] = 0.0

    var pred: Table[Node, seq[Node]] = initTable[Node, seq[Node]]()
    pred[source] = @[]

    var sources = @[source]

    var (returnedPred, _, returnedDist) = bellmanFord(g=g, sources=sources, weight=weight, pred=pred, dist=dist, target=target, heuristic=heuristic)
    return (returnedPred, returnedDist)

proc singleSourceBellmanFord*(
    g: Graph,
    source: Node,
    target: Node = None,
    weight: Table[Edge, float] = initTable[Edge, float]()
): tuple[dist: Table[Node, float], path: Table[Node, seq[Node]]] =
    if source == target:
        if source notin g.nodeSet():
            var e = ZNetNodeNotFound()
            e.msg = fmt"the source node {source} not found in the graph"
            raise e
        return ({target: 0.0}.toTable(), {target: @[target]}.toTable())

    var sources: seq[Node] = @[source]
    var pathsUsing: Table[Node, seq[Node]] = initTable[Node, seq[Node]]()
    pathsUsing[source] = @[source]

    var (_, returnedPath, returnedDist) = bellmanFord(g=g, sources=sources, weight=weight, paths=pathsUsing, target=target)
    return (returnedDist, returnedPath)

proc singleSourceBellmanFordPathLength*(
    g: Graph,
    source: Node,
    weight: Table[Edge, float] = initTable[Edge, float]()
): Table[Node, float] =
    var sources = @[source]
    return bellmanFord(g=g, sources=sources, weight=weight).dist

proc singleSourceBellmanFordPath*(
    g: Graph,
    source: Node,
    weight: Table[Edge, float] = initTable[Edge, float]()
): Table[Node, seq[Node]] =
    return singleSourceBellmanFord(g=g, source=source, weight=weight).path

proc bellmanFordPath*(
    g: Graph,
    source: Node,
    target: Node,
    weight: Table[Edge, float] = initTable[Edge, float]()
): seq[Node] =
    return singleSourceBellmanFord(g=g, source=source, target=target, weight=weight).path[target]

proc bellmanFordPathLength*(
    g: Graph,
    source: Node,
    target: Node,
    weight: Table[Edge, float] = initTable[Edge, float]()
): float =
    if source == target:
        if source notin g.nodeSet():
            var e = ZNetNodeNotFound()
            e.msg = fmt"the source node {source} not found in the graph"
            raise e
        return 0.0

    var sources = @[source]
    var length = bellmanFord(g=g, sources=sources, weight=weight, target=target).dist

    try:
        return length[target]
    except KeyError:
        var e = ZNetNoPath()
        e.msg = fmt"the target node {target} is not reachable from the source node {source}"
        raise e

iterator allPairsBellmanFordPathLength*(
    g: Graph,
    weight: Table[Edge, float] = initTable[Edge, float]()
): tuple[source: Node, dists: Table[Node, float]] =
    for n in g.nodeSet():
        yield (n, singleSourceBellmanFordPathLength(g=g, source=n, weight=weight))

iterator allPairsBellmanFordPath(
    g: Graph,
    weight: Table[Edge, float] = initTable[Edge, float]()
): tuple[source: Node, paths: Table[Node, seq[Node]]] =
    for n in g.nodeSet():
        yield (n, singleSourceBellmanFordPath(g=g, source=n, weight=weight))

# TODO: goldberg radzik
# TODO: bidirectional dijkstra
# TODO: johnson

# --------------------------------------------

proc dijkstraMultiSource(
    dg: DirectedGraph,
    sources: seq[Node],
    weight: Table[Edge, float],
    pred: Table[Node, seq[Node]] = initTable[Node, seq[Node]](),
    paths: Table[Node, seq[Node]] = initTable[Node, seq[Node]](),
    cutoff: float = -1.0,
    target: Node = None
): tuple[preds: Table[Node, seq[Node]], paths: Table[Node, seq[Node]], dists: Table[Node, float]] =
    var predUsing = pred
    var pathsUsing = paths
    var gSucc = dg.adj
    var dist: Table[Node, float] = initTable[Node, float]()
    var seen: Table[Node, float] = initTable[Node, float]()
    var fringe = initHeapQueue[DistNodePair]()

    for source in sources:
        seen[source] = 0.0
        fringe.push(DistNodePair(dist: 0.0, node: source))

    while len(fringe) != 0:
        var dn = fringe.pop()
        var d = dn.dist
        var v = dn.node
        if v in dist:
            continue
        dist[v] = d
        if v == target:
            break
        for u in gSucc[v]:
            var cost = weight.getOrDefault((v, u), 1.0)
            var vuDist = dist[v] + cost
            if cutoff != -1:
                if cutoff < vuDist:
                    continue
            if u in dist:
                var uDist = dist[u]
                if vuDist < uDist:
                    raise newException(ValueError, "contradictory paths found: negative weights?")
                elif len(predUsing.keys().toSeq()) != 0 and vuDist == uDist:
                    predUsing[u].add(v)
            elif u notin seen or vuDist < seen[u]:
                seen[u] = vuDist
                fringe.push(DistNodePair(dist: vuDist, node: u))
                if len(pathsUsing.keys().toSeq()) != 0:
                    pathsUsing[u] = pathsUsing[v]
                    pathsUsing[u].add(u)
                if len(predUsing.keys().toSeq()) != 0:
                    predUsing[u] = @[v]
            elif vuDist == seen[u]:
                if len(predUsing.keys().toSeq()) != 0:
                    predUsing[u].add(v)
    return (predUsing, pathsUsing, dist)

proc dijkstra(
    dg: DirectedGraph,
    source: Node,
    weight: Table[Edge, float],
    pred: Table[Node, seq[Node]] = initTable[Node, seq[Node]](),
    paths: Table[Node, seq[Node]] = initTable[Node, seq[Node]](),
    cutoff: float = -1.0,
    target: Node = None
): tuple[preds: Table[Node, seq[Node]], paths: Table[Node, seq[Node]], dists: Table[Node, float]] =
    var sources = @[source]
    return dijkstraMultiSource(dg=dg, sources=sources, weight=weight, pred=pred, paths=paths, cutoff=cutoff, target=target)

proc multiSourceDijkstra*(
    dg: DirectedGraph,
    sources: HashSet[Node],
    target: Node = None,
    cutoff: float = -1.0,
    weight: Table[Edge, float] = initTable[Edge, float]()
): tuple[dists: Table[Node, float], paths: Table[Node, seq[Node]]] =
    if len(sources) == 0:
        raise newException(ValueError, "sources must not be empty")
    for s in sources:
        if s notin dg.nodeSet():
            var e = ZNetNodeNotFound()
            e.msg = fmt"the node {s} not found in the graph"
            raise e
    var paths: Table[Node, seq[Node]] = initTable[Node, seq[Node]]()
    for source in sources:
        paths[source] = @[source]
    var (_, returnedPaths, dists) = dijkstraMultiSource(dg=dg, sources=sources.toSeq(), weight=weight, paths=paths, cutoff=cutoff, target=target)
    return (dists, returnedPaths)

proc multiSourceDijkstraPath*(
    dg: DirectedGraph,
    sources: HashSet[Node],
    cutoff: float = -1.0,
    weight: Table[Edge, float] = initTable[Edge, float]()
): Table[Node, seq[Node]] =
    return multiSourceDijkstra(dg=dg, sources=sources, cutoff=cutoff, weight=weight).paths

proc multiSourceDijkstraPathLength*(
    dg: DirectedGraph,
    sources: HashSet[Node],
    cutoff: float = -1.0,
    weight: Table[Edge, float] = initTable[Edge, float]()
): Table[Node, float] =
    if len(sources) == 0:
        raise newException(ValueError, "sources must not be empty")
    for s in sources:
        if s notin dg.nodeSet():
            var e = ZNetNodeNotFound()
            e.msg = fmt"the node {s} not found in the graph"
            raise e
    return dijkstraMultiSource(dg=dg, sources=sources.toSeq(), weight=weight, cutoff=cutoff).dists

proc singleSourceDijkstra*(
    dg: DirectedGraph,
    source: Node,
    target: Node = None,
    cutoff: float = -1.0,
    weight: Table[Edge, float] = initTable[Edge, float]()
): tuple[dists: Table[Node, float], paths: Table[Node, seq[Node]]] =
    var sources = @[source].toHashSet()
    return multiSourceDijkstra(dg=dg, sources=sources, cutoff=cutoff, target=target, weight=weight)

proc singleSourceDijkstraPath*(
    dg: DirectedGraph,
    source: Node,
    cutoff: float = -1.0,
    weight: Table[Edge, float] = initTable[Edge, float]()
): Table[Node, seq[Node]] =
    var sources = @[source].toHashSet()
    return multiSourceDijkstraPath(dg=dg, sources=sources, cutoff=cutoff, weight=weight)

proc singleSourceDijkstraPathLength*(
    dg: DirectedGraph,
    source: Node,
    cutoff: float = -1.0,
    weight: Table[Edge, float] = initTable[Edge, float]()
): Table[Node, float] =
    var sources = @[source].toHashSet()
    return multiSourceDijkstraPathLength(dg=dg, sources=sources, cutoff=cutoff, weight=weight)

proc dijkstraPath*(
    dg: DirectedGraph,
    source: Node,
    target: Node,
    weight: Table[Edge, float] = initTable[Edge, float]()
): seq[Node] =
    return singleSourceDijkstra(dg=dg, source=source, target=target, weight=weight).paths[source]

proc dijkstraPathLength*(
    dg: DirectedGraph,
    source: Node,
    target: Node,
    weight: Table[Edge, float] = initTable[Edge, float]()
): float =
    if source notin dg.nodeSet():
        var e = ZNetNodeNotFound()
        e.msg = fmt"the source node {source} not found in the graph"
        raise e
    if source == target:
        return 0
    var (_, _, dists) = dijkstra(dg=dg, source=source, target=target, weight=weight)
    try:
        return dists[target]
    except KeyError:
        var e = ZNetNoPath()
        e.msg = fmt"the target node {target} not reachable from the source node {source}"
        raise e

proc dijkstraPredecessorsAndDistance*(
    dg: DirectedGraph,
    source: Node,
    cutoff: float = -1.0,
    weight: Table[Edge, float] = initTable[Edge, float]()
): tuple[preds: Table[Node, seq[Node]], dists: Table[Node, float]] =
    if source notin dg.nodeSet():
        var e = ZNetNodeNotFound()
        e.msg = fmt"the source node {source} not found in the graph"
        raise e
    var pred: Table[Node, seq[Node]] = initTable[Node, seq[Node]]()
    pred[source] = @[]
    var (preds, _, dists) = dijkstra(dg=dg, source=source, weight=weight, pred=pred, cutoff=cutoff)
    return (preds, dists)

iterator allPairsDijkstra*(
    dg: DirectedGraph,
    cutoff: float = -1.0,
    weight: Table[Edge, float] = initTable[Edge, float]()
): tuple[node: Node, dists: Table[Node, float], paths: Table[Node, seq[Node]]] =
    for n in dg.nodes():
        var (dist, path) = singleSourceDijkstra(dg=dg, source=n, cutoff=cutoff, weight=weight)
        yield (n, dist, path)

iterator allPairsDijkstraLength*(
    dg: DirectedGraph,
    cutoff: float = -1.0,
    weight: Table[Edge, float] = initTable[Edge, float]()
): tuple[source: Node, dists: Table[Node, float]] =
    for n in dg.nodes():
        var dists = singleSourceDijkstraPathLength(dg=dg, source=n, cutoff=cutoff, weight=weight)
        yield (n, dists)

iterator allPairsDijkstraPath*(
    dg: DirectedGraph,
    cutoff: float = -1.0,
    weight: Table[Edge, float] = initTable[Edge, float]()
): tuple[source: Node, paths: Table[Node, seq[Node]]] =
    for n in dg.nodes():
        yield (n, singleSourceDijkstraPath(dg=dg, source=n, cutoff=cutoff, weight=weight))

proc innerBellmanFord(
    dg: DirectedGraph,
    sources: seq[Node],
    weight: Table[Edge, float] = initTable[Edge, float](),
    pred: Table[Node, seq[Node]] = initTable[Node, seq[Node]](),
    dist: Table[Node, float] = initTable[Node, float](),
    heuristic: bool = true
): Node =
    for s in sources:
        if s notin dg.nodeSet():
            var e = ZNetNodeNotFound()
            e.msg = fmt"the source node {s} not in the graph"
            raise e
    var predUsing: Table[Node, seq[Node]] = initTable[Node, seq[Node]]()
    if len(pred.keys().toSeq()) == 0:
        for v in sources:
            predUsing[v] = @[]

    var distUsing: Table[Node, float] = initTable[Node, float]()
    if len(dist.keys().toSeq()) == 0:
        for v in sources:
            distUsing[v] = 0.0

    var nonExistentEdge = (None, None)
    var predEdge: Table[Node, Node] = initTable[Node, Node]()
    for v in sources:
        predEdge[v] = None
    var recentUpdate: Table[Node, Edge] = initTable[Node, Edge]()
    for v in sources:
        recentUpdate[v] = nonExistentEdge

    var gSucc = dg.adj
    var inf = Inf
    var n = dg.len()

    var count: Table[Node, int] = initTable[Node, int]()
    var q: Deque[Node] = sources.toDeque()
    var inQ: HashSet[Node] = sources.toHashSet()

    while len(q) != 0:
        var u = q.popFirst()
        inQ.excl(u)

        var isAll = true
        for predU in predUsing[u]:
            if predU in inQ:
                isAll = false
                break
        if isAll:
            var distU = distUsing[u]
            for v in gSucc[u]:
                var distV = distU + weight.getOrDefault((u, v), 1.0)
                if distV < distUsing.getOrDefault(v, inf):
                    if heuristic:
                        if v == recentUpdate[u].u or v == recentUpdate[u].v:
                            predUsing[v].add(u)
                            return v
                        if v in predEdge and predEdge[v] == u:
                            recentUpdate[v] = recentUpdate[u]
                        else:
                            recentUpdate[v] = (u, v)
                    if v notin inQ:
                        q.addLast(v)
                        inQ.incl(v)
                        var countV = count.getOrDefault(v, 0) + 1
                        if countV == n:
                            return v
                        count[v] = countV
                    distUsing[v] = distV
                    predUsing[v] = @[u]
                    predEdge[v] = u
                elif v in distUsing and distV == distUsing[v]:
                    predUsing[v].add(u)
    return None

proc bellmanFord(
    dg: DirectedGraph,
    sources: seq[Node],
    weight: Table[Edge, float] = initTable[Edge, float](),
    pred: Table[Node, seq[Node]] = initTable[Node, seq[Node]](),
    paths: Table[Node, seq[Node]] = initTable[Node, seq[Node]](),
    dist: Table[Node, float] = initTable[Node, float](),
    target: Node = None,
    heuristic: bool = true
): tuple[pred: Table[Node, seq[Node]], path: Table[Node, seq[Node]], dist: Table[Node, float]] =
    var predUsing = pred
    if len(pred.keys().toSeq()) == 0:
        for v in sources:
            predUsing[v] = @[]

    var distUsing = dist
    if len(dist.keys().toSeq()) == 0:
        for v in sources:
            distUsing[v] = 0.0

    var negativeCycleFound = innerBellmanFord(dg=dg, sources=sources, weight=weight, pred=predUsing, dist=distUsing, heuristic=heuristic)
    if negativeCycleFound != None:
        var e = ZNetUnbounded()
        e.msg = "negative cycle detected"
        raise e

    var pathsUsing = paths
    if len(paths.keys().toSeq()) != 0:
        var sourcesUsing = sources.toHashSet()
        var dsts: seq[Node]
        if target != None:
            dsts = @[target]
        else:
            dsts = pred.keys().toSeq()
        for dst in dsts:
            for gen in buildPathsFromPredecessors(sourcesUsing, dst, predUsing):
                pathsUsing[dst] = gen

    return (predUsing, pathsUsing, distUsing)

proc bellmanFordPredecessorAndDistance*(
    dg: DirectedGraph,
    source: Node,
    target: Node = None,
    weight: Table[Edge, float] = initTable[Edge, float](),
    heuristic: bool = false
): tuple[pred: Table[Node, seq[Node]], dist: Table[Node, float]] =
    if source notin dg.nodeSet():
        var e = ZNetNodeNotFound()
        e.msg = fmt"the source node {source} not found in the graph"
        raise e
    for edge in dg.selfloopEdges():
        if weight[edge] < 0:
            var e = ZNetUnbounded()
            e.msg = "negative cycle detected"
            raise e

    var dist: Table[Node, float] = initTable[Node, float]()
    dist[source] = 0.0

    var pred: Table[Node, seq[Node]] = initTable[Node, seq[Node]]()
    pred[source] = @[]

    var sources = @[source]

    var (returnedPred, _, returnedDist) = bellmanFord(dg=dg, sources=sources, weight=weight, pred=pred, dist=dist, target=target, heuristic=heuristic)
    return (returnedPred, returnedDist)

proc singleSourceBellmanFord*(
    dg: DirectedGraph,
    source: Node,
    target: Node = None,
    weight: Table[Edge, float] = initTable[Edge, float]()
): tuple[dist: Table[Node, float], path: Table[Node, seq[Node]]] =
    if source == target:
        if source notin dg.nodeSet():
            var e = ZNetNodeNotFound()
            e.msg = fmt"the source node {source} not found in the graph"
            raise e
        return ({target: 0.0}.toTable(), {target: @[target]}.toTable())

    var sources: seq[Node] = @[source]
    var pathsUsing: Table[Node, seq[Node]] = initTable[Node, seq[Node]]()
    pathsUsing[source] = @[source]

    var (_, returnedPath, returnedDist) = bellmanFord(dg=dg, sources=sources, weight=weight, paths=pathsUsing, target=target)
    return (returnedDist, returnedPath)

proc singleSourceBellmanFordPathLength*(
    dg: DirectedGraph,
    source: Node,
    weight: Table[Edge, float] = initTable[Edge, float]()
): Table[Node, float] =
    var sources = @[source]
    return bellmanFord(dg=dg, sources=sources, weight=weight).dist

proc singleSourceBellmanFordPath*(
    dg: DirectedGraph,
    source: Node,
    weight: Table[Edge, float] = initTable[Edge, float]()
): Table[Node, seq[Node]] =
    return singleSourceBellmanFord(dg=dg, source=source, weight=weight).path

proc bellmanFordPath*(
    dg: DirectedGraph,
    source: Node,
    target: Node,
    weight: Table[Edge, float] = initTable[Edge, float]()
): seq[Node] =
    return singleSourceBellmanFord(dg=dg, source=source, target=target, weight=weight).path[target]

proc bellmanFordPathLength*(
    dg: DirectedGraph,
    source: Node,
    target: Node,
    weight: Table[Edge, float] = initTable[Edge, float]()
): float =
    if source == target:
        if source notin dg.nodeSet():
            var e = ZNetNodeNotFound()
            e.msg = fmt"the source node {source} not found in the graph"
            raise e
        return 0.0

    var sources = @[source]
    var length = bellmanFord(dg=dg, sources=sources, weight=weight, target=target).dist

    try:
        return length[target]
    except KeyError:
        var e = ZNetNoPath()
        e.msg = fmt"the target node {target} is not reachable from the source node {source}"
        raise e

iterator allPairsBellmanFordPathLength*(
    dg: DirectedGraph,
    weight: Table[Edge, float] = initTable[Edge, float]()
): tuple[source: Node, dists: Table[Node, float]] =
    for n in dg.nodeSet():
        yield (n, singleSourceBellmanFordPathLength(dg=dg, source=n, weight=weight))

iterator allPairsBellmanFordPath(
    dg: DirectedGraph,
    weight: Table[Edge, float] = initTable[Edge, float]()
): tuple[source: Node, paths: Table[Node, seq[Node]]] =
    for n in dg.nodeSet():
        yield (n, singleSourceBellmanFordPath(dg=dg, source=n, weight=weight))

# TODO: goldberg radzik
# TODO: bidirectional dijkstra
# TODO: johnson

when isMainModule:
    # discard
    block karateAllPairsDijkstra:
        var karate = newGraph()
        karate.addEdgesFrom(@[(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)])
        var nxRet: Table[Node, tuple[dists: Table[Node, float], paths: Table[Node, seq[Node]]]] =
            {
                0: ({0: 0.0, 1: 1.0, 2: 1.0, 3: 1.0, 4: 1.0, 5: 1.0, 6: 1.0, 7: 1.0, 8: 1.0, 10: 1.0, 11: 1.0, 12: 1.0, 13: 1.0, 17: 1.0, 19: 1.0, 21: 1.0, 31: 1.0, 30: 2.0, 9: 2.0, 27: 2.0, 28: 2.0, 32: 2.0, 16: 2.0, 33: 2.0, 24: 2.0, 25: 2.0, 23: 3.0, 14: 3.0, 15: 3.0, 18: 3.0, 20: 3.0, 22: 3.0, 29: 3.0, 26: 3.0}.toTable(), {0: @[0], 1: @[0, 1], 2: @[0, 2], 3: @[0, 3], 4: @[0, 4], 5: @[0, 5], 6: @[0, 6], 7: @[0, 7], 8: @[0, 8], 10: @[0, 10], 11: @[0, 11], 12: @[0, 12], 13: @[0, 13], 17: @[0, 17], 19: @[0, 19], 21: @[0, 21], 31: @[0, 31], 30: @[0, 1, 30], 9: @[0, 2, 9], 27: @[0, 2, 27], 28: @[0, 2, 28], 32: @[0, 2, 32], 16: @[0, 5, 16], 33: @[0, 8, 33], 24: @[0, 31, 24], 25: @[0, 31, 25], 23: @[0, 2, 27, 23], 14: @[0, 2, 32, 14], 15: @[0, 2, 32, 15], 18: @[0, 2, 32, 18], 20: @[0, 2, 32, 20], 22: @[0, 2, 32, 22], 29: @[0, 2, 32, 29], 26: @[0, 8, 33, 26]}.toTable()),
                1: ({1: 0.0, 0: 1.0, 2: 1.0, 3: 1.0, 7: 1.0, 13: 1.0, 17: 1.0, 19: 1.0, 21: 1.0, 30: 1.0, 4: 2.0, 5: 2.0, 6: 2.0, 8: 2.0, 10: 2.0, 11: 2.0, 12: 2.0, 31: 2.0, 9: 2.0, 27: 2.0, 28: 2.0, 32: 2.0, 33: 2.0, 16: 3.0, 24: 3.0, 25: 3.0, 23: 3.0, 14: 3.0, 15: 3.0, 18: 3.0, 20: 3.0, 22: 3.0, 29: 3.0, 26: 3.0}.toTable(), {1: @[1], 0: @[1, 0], 2: @[1, 2], 3: @[1, 3], 7: @[1, 7], 13: @[1, 13], 17: @[1, 17], 19: @[1, 19], 21: @[1, 21], 30: @[1, 30], 4: @[1, 0, 4], 5: @[1, 0, 5], 6: @[1, 0, 6], 8: @[1, 0, 8], 10: @[1, 0, 10], 11: @[1, 0, 11], 12: @[1, 0, 12], 31: @[1, 0, 31], 9: @[1, 2, 9], 27: @[1, 2, 27], 28: @[1, 2, 28], 32: @[1, 2, 32], 33: @[1, 13, 33], 16: @[1, 0, 5, 16], 24: @[1, 0, 31, 24], 25: @[1, 0, 31, 25], 23: @[1, 2, 27, 23], 14: @[1, 2, 32, 14], 15: @[1, 2, 32, 15], 18: @[1, 2, 32, 18], 20: @[1, 2, 32, 20], 22: @[1, 2, 32, 22], 29: @[1, 2, 32, 29], 26: @[1, 13, 33, 26]}.toTable()),
                2: ({2: 0.0, 0: 1.0, 1: 1.0, 3: 1.0, 7: 1.0, 8: 1.0, 9: 1.0, 13: 1.0, 27: 1.0, 28: 1.0, 32: 1.0, 4: 2.0, 5: 2.0, 6: 2.0, 10: 2.0, 11: 2.0, 12: 2.0, 17: 2.0, 19: 2.0, 21: 2.0, 31: 2.0, 30: 2.0, 33: 2.0, 23: 2.0, 24: 2.0, 14: 2.0, 15: 2.0, 18: 2.0, 20: 2.0, 22: 2.0, 29: 2.0, 16: 3.0, 25: 3.0, 26: 3.0}.toTable(), {2: @[2], 0: @[2, 0], 1: @[2, 1], 3: @[2, 3], 7: @[2, 7], 8: @[2, 8], 9: @[2, 9], 13: @[2, 13], 27: @[2, 27], 28: @[2, 28], 32: @[2, 32], 4: @[2, 0, 4], 5: @[2, 0, 5], 6: @[2, 0, 6], 10: @[2, 0, 10], 11: @[2, 0, 11], 12: @[2, 0, 12], 17: @[2, 0, 17], 19: @[2, 0, 19], 21: @[2, 0, 21], 31: @[2, 0, 31], 30: @[2, 1, 30], 33: @[2, 8, 33], 23: @[2, 27, 23], 24: @[2, 27, 24], 14: @[2, 32, 14], 15: @[2, 32, 15], 18: @[2, 32, 18], 20: @[2, 32, 20], 22: @[2, 32, 22], 29: @[2, 32, 29], 16: @[2, 0, 5, 16], 25: @[2, 0, 31, 25], 26: @[2, 8, 33, 26]}.toTable()),
                3: ({3: 0.0, 0: 1.0, 1: 1.0, 2: 1.0, 7: 1.0, 12: 1.0, 13: 1.0, 4: 2.0, 5: 2.0, 6: 2.0, 8: 2.0, 10: 2.0, 11: 2.0, 17: 2.0, 19: 2.0, 21: 2.0, 31: 2.0, 30: 2.0, 9: 2.0, 27: 2.0, 28: 2.0, 32: 2.0, 33: 2.0, 16: 3.0, 24: 3.0, 25: 3.0, 23: 3.0, 14: 3.0, 15: 3.0, 18: 3.0, 20: 3.0, 22: 3.0, 29: 3.0, 26: 3.0}.toTable(), {3: @[3], 0: @[3, 0], 1: @[3, 1], 2: @[3, 2], 7: @[3, 7], 12: @[3, 12], 13: @[3, 13], 4: @[3, 0, 4], 5: @[3, 0, 5], 6: @[3, 0, 6], 8: @[3, 0, 8], 10: @[3, 0, 10], 11: @[3, 0, 11], 17: @[3, 0, 17], 19: @[3, 0, 19], 21: @[3, 0, 21], 31: @[3, 0, 31], 30: @[3, 1, 30], 9: @[3, 2, 9], 27: @[3, 2, 27], 28: @[3, 2, 28], 32: @[3, 2, 32], 33: @[3, 13, 33], 16: @[3, 0, 5, 16], 24: @[3, 0, 31, 24], 25: @[3, 0, 31, 25], 23: @[3, 2, 27, 23], 14: @[3, 2, 32, 14], 15: @[3, 2, 32, 15], 18: @[3, 2, 32, 18], 20: @[3, 2, 32, 20], 22: @[3, 2, 32, 22], 29: @[3, 2, 32, 29], 26: @[3, 13, 33, 26]}.toTable()),
                4: ({4: 0.0, 0: 1.0, 6: 1.0, 10: 1.0, 1: 2.0, 2: 2.0, 3: 2.0, 5: 2.0, 7: 2.0, 8: 2.0, 11: 2.0, 12: 2.0, 13: 2.0, 17: 2.0, 19: 2.0, 21: 2.0, 31: 2.0, 16: 2.0, 30: 3.0, 9: 3.0, 27: 3.0, 28: 3.0, 32: 3.0, 33: 3.0, 24: 3.0, 25: 3.0, 23: 4.0, 14: 4.0, 15: 4.0, 18: 4.0, 20: 4.0, 22: 4.0, 29: 4.0, 26: 4.0}.toTable(), {4: @[4], 0: @[4, 0], 6: @[4, 6], 10: @[4, 10], 1: @[4, 0, 1], 2: @[4, 0, 2], 3: @[4, 0, 3], 5: @[4, 0, 5], 7: @[4, 0, 7], 8: @[4, 0, 8], 11: @[4, 0, 11], 12: @[4, 0, 12], 13: @[4, 0, 13], 17: @[4, 0, 17], 19: @[4, 0, 19], 21: @[4, 0, 21], 31: @[4, 0, 31], 16: @[4, 6, 16], 30: @[4, 0, 1, 30], 9: @[4, 0, 2, 9], 27: @[4, 0, 2, 27], 28: @[4, 0, 2, 28], 32: @[4, 0, 2, 32], 33: @[4, 0, 8, 33], 24: @[4, 0, 31, 24], 25: @[4, 0, 31, 25], 23: @[4, 0, 2, 27, 23], 14: @[4, 0, 2, 32, 14], 15: @[4, 0, 2, 32, 15], 18: @[4, 0, 2, 32, 18], 20: @[4, 0, 2, 32, 20], 22: @[4, 0, 2, 32, 22], 29: @[4, 0, 2, 32, 29], 26: @[4, 0, 8, 33, 26]}.toTable()),
                5: ({5: 0.0, 0: 1.0, 6: 1.0, 10: 1.0, 16: 1.0, 1: 2.0, 2: 2.0, 3: 2.0, 4: 2.0, 7: 2.0, 8: 2.0, 11: 2.0, 12: 2.0, 13: 2.0, 17: 2.0, 19: 2.0, 21: 2.0, 31: 2.0, 30: 3.0, 9: 3.0, 27: 3.0, 28: 3.0, 32: 3.0, 33: 3.0, 24: 3.0, 25: 3.0, 23: 4.0, 14: 4.0, 15: 4.0, 18: 4.0, 20: 4.0, 22: 4.0, 29: 4.0, 26: 4.0}.toTable(), {5: @[5], 0: @[5, 0], 6: @[5, 6], 10: @[5, 10], 16: @[5, 16], 1: @[5, 0, 1], 2: @[5, 0, 2], 3: @[5, 0, 3], 4: @[5, 0, 4], 7: @[5, 0, 7], 8: @[5, 0, 8], 11: @[5, 0, 11], 12: @[5, 0, 12], 13: @[5, 0, 13], 17: @[5, 0, 17], 19: @[5, 0, 19], 21: @[5, 0, 21], 31: @[5, 0, 31], 30: @[5, 0, 1, 30], 9: @[5, 0, 2, 9], 27: @[5, 0, 2, 27], 28: @[5, 0, 2, 28], 32: @[5, 0, 2, 32], 33: @[5, 0, 8, 33], 24: @[5, 0, 31, 24], 25: @[5, 0, 31, 25], 23: @[5, 0, 2, 27, 23], 14: @[5, 0, 2, 32, 14], 15: @[5, 0, 2, 32, 15], 18: @[5, 0, 2, 32, 18], 20: @[5, 0, 2, 32, 20], 22: @[5, 0, 2, 32, 22], 29: @[5, 0, 2, 32, 29], 26: @[5, 0, 8, 33, 26]}.toTable()),
                6: ({6: 0.0, 0: 1.0, 4: 1.0, 5: 1.0, 16: 1.0, 1: 2.0, 2: 2.0, 3: 2.0, 7: 2.0, 8: 2.0, 10: 2.0, 11: 2.0, 12: 2.0, 13: 2.0, 17: 2.0, 19: 2.0, 21: 2.0, 31: 2.0, 30: 3.0, 9: 3.0, 27: 3.0, 28: 3.0, 32: 3.0, 33: 3.0, 24: 3.0, 25: 3.0, 23: 4.0, 14: 4.0, 15: 4.0, 18: 4.0, 20: 4.0, 22: 4.0, 29: 4.0, 26: 4.0}.toTable(), {6: @[6], 0: @[6, 0], 4: @[6, 4], 5: @[6, 5], 16: @[6, 16], 1: @[6, 0, 1], 2: @[6, 0, 2], 3: @[6, 0, 3], 7: @[6, 0, 7], 8: @[6, 0, 8], 10: @[6, 0, 10], 11: @[6, 0, 11], 12: @[6, 0, 12], 13: @[6, 0, 13], 17: @[6, 0, 17], 19: @[6, 0, 19], 21: @[6, 0, 21], 31: @[6, 0, 31], 30: @[6, 0, 1, 30], 9: @[6, 0, 2, 9], 27: @[6, 0, 2, 27], 28: @[6, 0, 2, 28], 32: @[6, 0, 2, 32], 33: @[6, 0, 8, 33], 24: @[6, 0, 31, 24], 25: @[6, 0, 31, 25], 23: @[6, 0, 2, 27, 23], 14: @[6, 0, 2, 32, 14], 15: @[6, 0, 2, 32, 15], 18: @[6, 0, 2, 32, 18], 20: @[6, 0, 2, 32, 20], 22: @[6, 0, 2, 32, 22], 29: @[6, 0, 2, 32, 29], 26: @[6, 0, 8, 33, 26]}.toTable()),
                7: ({7: 0.0, 0: 1.0, 1: 1.0, 2: 1.0, 3: 1.0, 4: 2.0, 5: 2.0, 6: 2.0, 8: 2.0, 10: 2.0, 11: 2.0, 12: 2.0, 13: 2.0, 17: 2.0, 19: 2.0, 21: 2.0, 31: 2.0, 30: 2.0, 9: 2.0, 27: 2.0, 28: 2.0, 32: 2.0, 16: 3.0, 33: 3.0, 24: 3.0, 25: 3.0, 23: 3.0, 14: 3.0, 15: 3.0, 18: 3.0, 20: 3.0, 22: 3.0, 29: 3.0, 26: 4.0}.toTable(), {7: @[7], 0: @[7, 0], 1: @[7, 1], 2: @[7, 2], 3: @[7, 3], 4: @[7, 0, 4], 5: @[7, 0, 5], 6: @[7, 0, 6], 8: @[7, 0, 8], 10: @[7, 0, 10], 11: @[7, 0, 11], 12: @[7, 0, 12], 13: @[7, 0, 13], 17: @[7, 0, 17], 19: @[7, 0, 19], 21: @[7, 0, 21], 31: @[7, 0, 31], 30: @[7, 1, 30], 9: @[7, 2, 9], 27: @[7, 2, 27], 28: @[7, 2, 28], 32: @[7, 2, 32], 16: @[7, 0, 5, 16], 33: @[7, 0, 8, 33], 24: @[7, 0, 31, 24], 25: @[7, 0, 31, 25], 23: @[7, 2, 27, 23], 14: @[7, 2, 32, 14], 15: @[7, 2, 32, 15], 18: @[7, 2, 32, 18], 20: @[7, 2, 32, 20], 22: @[7, 2, 32, 22], 29: @[7, 2, 32, 29], 26: @[7, 0, 8, 33, 26]}.toTable()),
                8: ({8: 0.0, 0: 1.0, 2: 1.0, 30: 1.0, 32: 1.0, 33: 1.0, 1: 2.0, 3: 2.0, 4: 2.0, 5: 2.0, 6: 2.0, 7: 2.0, 10: 2.0, 11: 2.0, 12: 2.0, 13: 2.0, 17: 2.0, 19: 2.0, 21: 2.0, 31: 2.0, 9: 2.0, 27: 2.0, 28: 2.0, 14: 2.0, 15: 2.0, 18: 2.0, 20: 2.0, 22: 2.0, 23: 2.0, 29: 2.0, 26: 2.0, 16: 3.0, 24: 3.0, 25: 3.0}.toTable(), {8: @[8], 0: @[8, 0], 2: @[8, 2], 30: @[8, 30], 32: @[8, 32], 33: @[8, 33], 1: @[8, 0, 1], 3: @[8, 0, 3], 4: @[8, 0, 4], 5: @[8, 0, 5], 6: @[8, 0, 6], 7: @[8, 0, 7], 10: @[8, 0, 10], 11: @[8, 0, 11], 12: @[8, 0, 12], 13: @[8, 0, 13], 17: @[8, 0, 17], 19: @[8, 0, 19], 21: @[8, 0, 21], 31: @[8, 0, 31], 9: @[8, 2, 9], 27: @[8, 2, 27], 28: @[8, 2, 28], 14: @[8, 32, 14], 15: @[8, 32, 15], 18: @[8, 32, 18], 20: @[8, 32, 20], 22: @[8, 32, 22], 23: @[8, 32, 23], 29: @[8, 32, 29], 26: @[8, 33, 26], 16: @[8, 0, 5, 16], 24: @[8, 0, 31, 24], 25: @[8, 0, 31, 25]}.toTable()),
                9: ({9: 0.0, 2: 1.0, 33: 1.0, 0: 2.0, 1: 2.0, 3: 2.0, 7: 2.0, 8: 2.0, 13: 2.0, 27: 2.0, 28: 2.0, 32: 2.0, 14: 2.0, 15: 2.0, 18: 2.0, 19: 2.0, 20: 2.0, 22: 2.0, 23: 2.0, 26: 2.0, 29: 2.0, 30: 2.0, 31: 2.0, 4: 3.0, 5: 3.0, 6: 3.0, 10: 3.0, 11: 3.0, 12: 3.0, 17: 3.0, 21: 3.0, 24: 3.0, 25: 3.0, 16: 4.0}.toTable(), {9: @[9], 2: @[9, 2], 33: @[9, 33], 0: @[9, 2, 0], 1: @[9, 2, 1], 3: @[9, 2, 3], 7: @[9, 2, 7], 8: @[9, 2, 8], 13: @[9, 2, 13], 27: @[9, 2, 27], 28: @[9, 2, 28], 32: @[9, 2, 32], 14: @[9, 33, 14], 15: @[9, 33, 15], 18: @[9, 33, 18], 19: @[9, 33, 19], 20: @[9, 33, 20], 22: @[9, 33, 22], 23: @[9, 33, 23], 26: @[9, 33, 26], 29: @[9, 33, 29], 30: @[9, 33, 30], 31: @[9, 33, 31], 4: @[9, 2, 0, 4], 5: @[9, 2, 0, 5], 6: @[9, 2, 0, 6], 10: @[9, 2, 0, 10], 11: @[9, 2, 0, 11], 12: @[9, 2, 0, 12], 17: @[9, 2, 0, 17], 21: @[9, 2, 0, 21], 24: @[9, 2, 27, 24], 25: @[9, 33, 23, 25], 16: @[9, 2, 0, 5, 16]}.toTable()),
                10: ({10: 0.0, 0: 1.0, 4: 1.0, 5: 1.0, 1: 2.0, 2: 2.0, 3: 2.0, 6: 2.0, 7: 2.0, 8: 2.0, 11: 2.0, 12: 2.0, 13: 2.0, 17: 2.0, 19: 2.0, 21: 2.0, 31: 2.0, 16: 2.0, 30: 3.0, 9: 3.0, 27: 3.0, 28: 3.0, 32: 3.0, 33: 3.0, 24: 3.0, 25: 3.0, 23: 4.0, 14: 4.0, 15: 4.0, 18: 4.0, 20: 4.0, 22: 4.0, 29: 4.0, 26: 4.0}.toTable(), {10: @[10], 0: @[10, 0], 4: @[10, 4], 5: @[10, 5], 1: @[10, 0, 1], 2: @[10, 0, 2], 3: @[10, 0, 3], 6: @[10, 0, 6], 7: @[10, 0, 7], 8: @[10, 0, 8], 11: @[10, 0, 11], 12: @[10, 0, 12], 13: @[10, 0, 13], 17: @[10, 0, 17], 19: @[10, 0, 19], 21: @[10, 0, 21], 31: @[10, 0, 31], 16: @[10, 5, 16], 30: @[10, 0, 1, 30], 9: @[10, 0, 2, 9], 27: @[10, 0, 2, 27], 28: @[10, 0, 2, 28], 32: @[10, 0, 2, 32], 33: @[10, 0, 8, 33], 24: @[10, 0, 31, 24], 25: @[10, 0, 31, 25], 23: @[10, 0, 2, 27, 23], 14: @[10, 0, 2, 32, 14], 15: @[10, 0, 2, 32, 15], 18: @[10, 0, 2, 32, 18], 20: @[10, 0, 2, 32, 20], 22: @[10, 0, 2, 32, 22], 29: @[10, 0, 2, 32, 29], 26: @[10, 0, 8, 33, 26]}.toTable()),
                11: ({11: 0.0, 0: 1.0, 1: 2.0, 2: 2.0, 3: 2.0, 4: 2.0, 5: 2.0, 6: 2.0, 7: 2.0, 8: 2.0, 10: 2.0, 12: 2.0, 13: 2.0, 17: 2.0, 19: 2.0, 21: 2.0, 31: 2.0, 30: 3.0, 9: 3.0, 27: 3.0, 28: 3.0, 32: 3.0, 16: 3.0, 33: 3.0, 24: 3.0, 25: 3.0, 23: 4.0, 14: 4.0, 15: 4.0, 18: 4.0, 20: 4.0, 22: 4.0, 29: 4.0, 26: 4.0}.toTable(), {11: @[11], 0: @[11, 0], 1: @[11, 0, 1], 2: @[11, 0, 2], 3: @[11, 0, 3], 4: @[11, 0, 4], 5: @[11, 0, 5], 6: @[11, 0, 6], 7: @[11, 0, 7], 8: @[11, 0, 8], 10: @[11, 0, 10], 12: @[11, 0, 12], 13: @[11, 0, 13], 17: @[11, 0, 17], 19: @[11, 0, 19], 21: @[11, 0, 21], 31: @[11, 0, 31], 30: @[11, 0, 1, 30], 9: @[11, 0, 2, 9], 27: @[11, 0, 2, 27], 28: @[11, 0, 2, 28], 32: @[11, 0, 2, 32], 16: @[11, 0, 5, 16], 33: @[11, 0, 8, 33], 24: @[11, 0, 31, 24], 25: @[11, 0, 31, 25], 23: @[11, 0, 2, 27, 23], 14: @[11, 0, 2, 32, 14], 15: @[11, 0, 2, 32, 15], 18: @[11, 0, 2, 32, 18], 20: @[11, 0, 2, 32, 20], 22: @[11, 0, 2, 32, 22], 29: @[11, 0, 2, 32, 29], 26: @[11, 0, 8, 33, 26]}.toTable()),
                12: ({12: 0.0, 0: 1.0, 3: 1.0, 1: 2.0, 2: 2.0, 4: 2.0, 5: 2.0, 6: 2.0, 7: 2.0, 8: 2.0, 10: 2.0, 11: 2.0, 13: 2.0, 17: 2.0, 19: 2.0, 21: 2.0, 31: 2.0, 30: 3.0, 9: 3.0, 27: 3.0, 28: 3.0, 32: 3.0, 16: 3.0, 33: 3.0, 24: 3.0, 25: 3.0, 23: 4.0, 14: 4.0, 15: 4.0, 18: 4.0, 20: 4.0, 22: 4.0, 29: 4.0, 26: 4.0}.toTable(), {12: @[12], 0: @[12, 0], 3: @[12, 3], 1: @[12, 0, 1], 2: @[12, 0, 2], 4: @[12, 0, 4], 5: @[12, 0, 5], 6: @[12, 0, 6], 7: @[12, 0, 7], 8: @[12, 0, 8], 10: @[12, 0, 10], 11: @[12, 0, 11], 13: @[12, 0, 13], 17: @[12, 0, 17], 19: @[12, 0, 19], 21: @[12, 0, 21], 31: @[12, 0, 31], 30: @[12, 0, 1, 30], 9: @[12, 0, 2, 9], 27: @[12, 0, 2, 27], 28: @[12, 0, 2, 28], 32: @[12, 0, 2, 32], 16: @[12, 0, 5, 16], 33: @[12, 0, 8, 33], 24: @[12, 0, 31, 24], 25: @[12, 0, 31, 25], 23: @[12, 0, 2, 27, 23], 14: @[12, 0, 2, 32, 14], 15: @[12, 0, 2, 32, 15], 18: @[12, 0, 2, 32, 18], 20: @[12, 0, 2, 32, 20], 22: @[12, 0, 2, 32, 22], 29: @[12, 0, 2, 32, 29], 26: @[12, 0, 8, 33, 26]}.toTable()),
                13: ({13: 0.0, 0: 1.0, 1: 1.0, 2: 1.0, 3: 1.0, 33: 1.0, 4: 2.0, 5: 2.0, 6: 2.0, 7: 2.0, 8: 2.0, 10: 2.0, 11: 2.0, 12: 2.0, 17: 2.0, 19: 2.0, 21: 2.0, 31: 2.0, 30: 2.0, 9: 2.0, 27: 2.0, 28: 2.0, 32: 2.0, 14: 2.0, 15: 2.0, 18: 2.0, 20: 2.0, 22: 2.0, 23: 2.0, 26: 2.0, 29: 2.0, 16: 3.0, 24: 3.0, 25: 3.0}.toTable(), {13: @[13], 0: @[13, 0], 1: @[13, 1], 2: @[13, 2], 3: @[13, 3], 33: @[13, 33], 4: @[13, 0, 4], 5: @[13, 0, 5], 6: @[13, 0, 6], 7: @[13, 0, 7], 8: @[13, 0, 8], 10: @[13, 0, 10], 11: @[13, 0, 11], 12: @[13, 0, 12], 17: @[13, 0, 17], 19: @[13, 0, 19], 21: @[13, 0, 21], 31: @[13, 0, 31], 30: @[13, 1, 30], 9: @[13, 2, 9], 27: @[13, 2, 27], 28: @[13, 2, 28], 32: @[13, 2, 32], 14: @[13, 33, 14], 15: @[13, 33, 15], 18: @[13, 33, 18], 20: @[13, 33, 20], 22: @[13, 33, 22], 23: @[13, 33, 23], 26: @[13, 33, 26], 29: @[13, 33, 29], 16: @[13, 0, 5, 16], 24: @[13, 0, 31, 24], 25: @[13, 0, 31, 25]}.toTable()),
                14: ({14: 0.0, 32: 1.0, 33: 1.0, 2: 2.0, 8: 2.0, 15: 2.0, 18: 2.0, 20: 2.0, 22: 2.0, 23: 2.0, 29: 2.0, 30: 2.0, 31: 2.0, 9: 2.0, 13: 2.0, 19: 2.0, 26: 2.0, 27: 2.0, 28: 2.0, 0: 3.0, 1: 3.0, 3: 3.0, 7: 3.0, 25: 3.0, 24: 3.0, 4: 4.0, 5: 4.0, 6: 4.0, 10: 4.0, 11: 4.0, 12: 4.0, 17: 4.0, 21: 4.0, 16: 5.0}.toTable(), {14: @[14], 32: @[14, 32], 33: @[14, 33], 2: @[14, 32, 2], 8: @[14, 32, 8], 15: @[14, 32, 15], 18: @[14, 32, 18], 20: @[14, 32, 20], 22: @[14, 32, 22], 23: @[14, 32, 23], 29: @[14, 32, 29], 30: @[14, 32, 30], 31: @[14, 32, 31], 9: @[14, 33, 9], 13: @[14, 33, 13], 19: @[14, 33, 19], 26: @[14, 33, 26], 27: @[14, 33, 27], 28: @[14, 33, 28], 0: @[14, 32, 2, 0], 1: @[14, 32, 2, 1], 3: @[14, 32, 2, 3], 7: @[14, 32, 2, 7], 25: @[14, 32, 23, 25], 24: @[14, 32, 31, 24], 4: @[14, 32, 2, 0, 4], 5: @[14, 32, 2, 0, 5], 6: @[14, 32, 2, 0, 6], 10: @[14, 32, 2, 0, 10], 11: @[14, 32, 2, 0, 11], 12: @[14, 32, 2, 0, 12], 17: @[14, 32, 2, 0, 17], 21: @[14, 32, 2, 0, 21], 16: @[14, 32, 2, 0, 5, 16]}.toTable()),
                15: ({15: 0.0, 32: 1.0, 33: 1.0, 2: 2.0, 8: 2.0, 14: 2.0, 18: 2.0, 20: 2.0, 22: 2.0, 23: 2.0, 29: 2.0, 30: 2.0, 31: 2.0, 9: 2.0, 13: 2.0, 19: 2.0, 26: 2.0, 27: 2.0, 28: 2.0, 0: 3.0, 1: 3.0, 3: 3.0, 7: 3.0, 25: 3.0, 24: 3.0, 4: 4.0, 5: 4.0, 6: 4.0, 10: 4.0, 11: 4.0, 12: 4.0, 17: 4.0, 21: 4.0, 16: 5.0}.toTable(), {15: @[15], 32: @[15, 32], 33: @[15, 33], 2: @[15, 32, 2], 8: @[15, 32, 8], 14: @[15, 32, 14], 18: @[15, 32, 18], 20: @[15, 32, 20], 22: @[15, 32, 22], 23: @[15, 32, 23], 29: @[15, 32, 29], 30: @[15, 32, 30], 31: @[15, 32, 31], 9: @[15, 33, 9], 13: @[15, 33, 13], 19: @[15, 33, 19], 26: @[15, 33, 26], 27: @[15, 33, 27], 28: @[15, 33, 28], 0: @[15, 32, 2, 0], 1: @[15, 32, 2, 1], 3: @[15, 32, 2, 3], 7: @[15, 32, 2, 7], 25: @[15, 32, 23, 25], 24: @[15, 32, 31, 24], 4: @[15, 32, 2, 0, 4], 5: @[15, 32, 2, 0, 5], 6: @[15, 32, 2, 0, 6], 10: @[15, 32, 2, 0, 10], 11: @[15, 32, 2, 0, 11], 12: @[15, 32, 2, 0, 12], 17: @[15, 32, 2, 0, 17], 21: @[15, 32, 2, 0, 21], 16: @[15, 32, 2, 0, 5, 16]}.toTable()),
                16: ({16: 0.0, 5: 1.0, 6: 1.0, 0: 2.0, 10: 2.0, 4: 2.0, 1: 3.0, 2: 3.0, 3: 3.0, 7: 3.0, 8: 3.0, 11: 3.0, 12: 3.0, 13: 3.0, 17: 3.0, 19: 3.0, 21: 3.0, 31: 3.0, 30: 4.0, 9: 4.0, 27: 4.0, 28: 4.0, 32: 4.0, 33: 4.0, 24: 4.0, 25: 4.0, 23: 5.0, 14: 5.0, 15: 5.0, 18: 5.0, 20: 5.0, 22: 5.0, 29: 5.0, 26: 5.0}.toTable(), {16: @[16], 5: @[16, 5], 6: @[16, 6], 0: @[16, 5, 0], 10: @[16, 5, 10], 4: @[16, 6, 4], 1: @[16, 5, 0, 1], 2: @[16, 5, 0, 2], 3: @[16, 5, 0, 3], 7: @[16, 5, 0, 7], 8: @[16, 5, 0, 8], 11: @[16, 5, 0, 11], 12: @[16, 5, 0, 12], 13: @[16, 5, 0, 13], 17: @[16, 5, 0, 17], 19: @[16, 5, 0, 19], 21: @[16, 5, 0, 21], 31: @[16, 5, 0, 31], 30: @[16, 5, 0, 1, 30], 9: @[16, 5, 0, 2, 9], 27: @[16, 5, 0, 2, 27], 28: @[16, 5, 0, 2, 28], 32: @[16, 5, 0, 2, 32], 33: @[16, 5, 0, 8, 33], 24: @[16, 5, 0, 31, 24], 25: @[16, 5, 0, 31, 25], 23: @[16, 5, 0, 2, 27, 23], 14: @[16, 5, 0, 2, 32, 14], 15: @[16, 5, 0, 2, 32, 15], 18: @[16, 5, 0, 2, 32, 18], 20: @[16, 5, 0, 2, 32, 20], 22: @[16, 5, 0, 2, 32, 22], 29: @[16, 5, 0, 2, 32, 29], 26: @[16, 5, 0, 8, 33, 26]}.toTable()),
                17: ({17: 0.0, 0: 1.0, 1: 1.0, 2: 2.0, 3: 2.0, 4: 2.0, 5: 2.0, 6: 2.0, 7: 2.0, 8: 2.0, 10: 2.0, 11: 2.0, 12: 2.0, 13: 2.0, 19: 2.0, 21: 2.0, 31: 2.0, 30: 2.0, 9: 3.0, 27: 3.0, 28: 3.0, 32: 3.0, 16: 3.0, 33: 3.0, 24: 3.0, 25: 3.0, 23: 4.0, 14: 4.0, 15: 4.0, 18: 4.0, 20: 4.0, 22: 4.0, 29: 4.0, 26: 4.0}.toTable(), {17: @[17], 0: @[17, 0], 1: @[17, 1], 2: @[17, 0, 2], 3: @[17, 0, 3], 4: @[17, 0, 4], 5: @[17, 0, 5], 6: @[17, 0, 6], 7: @[17, 0, 7], 8: @[17, 0, 8], 10: @[17, 0, 10], 11: @[17, 0, 11], 12: @[17, 0, 12], 13: @[17, 0, 13], 19: @[17, 0, 19], 21: @[17, 0, 21], 31: @[17, 0, 31], 30: @[17, 1, 30], 9: @[17, 0, 2, 9], 27: @[17, 0, 2, 27], 28: @[17, 0, 2, 28], 32: @[17, 0, 2, 32], 16: @[17, 0, 5, 16], 33: @[17, 0, 8, 33], 24: @[17, 0, 31, 24], 25: @[17, 0, 31, 25], 23: @[17, 0, 2, 27, 23], 14: @[17, 0, 2, 32, 14], 15: @[17, 0, 2, 32, 15], 18: @[17, 0, 2, 32, 18], 20: @[17, 0, 2, 32, 20], 22: @[17, 0, 2, 32, 22], 29: @[17, 0, 2, 32, 29], 26: @[17, 0, 8, 33, 26]}.toTable()),
                18: ({18: 0.0, 32: 1.0, 33: 1.0, 2: 2.0, 8: 2.0, 14: 2.0, 15: 2.0, 20: 2.0, 22: 2.0, 23: 2.0, 29: 2.0, 30: 2.0, 31: 2.0, 9: 2.0, 13: 2.0, 19: 2.0, 26: 2.0, 27: 2.0, 28: 2.0, 0: 3.0, 1: 3.0, 3: 3.0, 7: 3.0, 25: 3.0, 24: 3.0, 4: 4.0, 5: 4.0, 6: 4.0, 10: 4.0, 11: 4.0, 12: 4.0, 17: 4.0, 21: 4.0, 16: 5.0}.toTable(), {18: @[18], 32: @[18, 32], 33: @[18, 33], 2: @[18, 32, 2], 8: @[18, 32, 8], 14: @[18, 32, 14], 15: @[18, 32, 15], 20: @[18, 32, 20], 22: @[18, 32, 22], 23: @[18, 32, 23], 29: @[18, 32, 29], 30: @[18, 32, 30], 31: @[18, 32, 31], 9: @[18, 33, 9], 13: @[18, 33, 13], 19: @[18, 33, 19], 26: @[18, 33, 26], 27: @[18, 33, 27], 28: @[18, 33, 28], 0: @[18, 32, 2, 0], 1: @[18, 32, 2, 1], 3: @[18, 32, 2, 3], 7: @[18, 32, 2, 7], 25: @[18, 32, 23, 25], 24: @[18, 32, 31, 24], 4: @[18, 32, 2, 0, 4], 5: @[18, 32, 2, 0, 5], 6: @[18, 32, 2, 0, 6], 10: @[18, 32, 2, 0, 10], 11: @[18, 32, 2, 0, 11], 12: @[18, 32, 2, 0, 12], 17: @[18, 32, 2, 0, 17], 21: @[18, 32, 2, 0, 21], 16: @[18, 32, 2, 0, 5, 16]}.toTable()),
                19: ({19: 0.0, 0: 1.0, 1: 1.0, 33: 1.0, 2: 2.0, 3: 2.0, 4: 2.0, 5: 2.0, 6: 2.0, 7: 2.0, 8: 2.0, 10: 2.0, 11: 2.0, 12: 2.0, 13: 2.0, 17: 2.0, 21: 2.0, 31: 2.0, 30: 2.0, 9: 2.0, 14: 2.0, 15: 2.0, 18: 2.0, 20: 2.0, 22: 2.0, 23: 2.0, 26: 2.0, 27: 2.0, 28: 2.0, 29: 2.0, 32: 2.0, 16: 3.0, 24: 3.0, 25: 3.0}.toTable(), {19: @[19], 0: @[19, 0], 1: @[19, 1], 33: @[19, 33], 2: @[19, 0, 2], 3: @[19, 0, 3], 4: @[19, 0, 4], 5: @[19, 0, 5], 6: @[19, 0, 6], 7: @[19, 0, 7], 8: @[19, 0, 8], 10: @[19, 0, 10], 11: @[19, 0, 11], 12: @[19, 0, 12], 13: @[19, 0, 13], 17: @[19, 0, 17], 21: @[19, 0, 21], 31: @[19, 0, 31], 30: @[19, 1, 30], 9: @[19, 33, 9], 14: @[19, 33, 14], 15: @[19, 33, 15], 18: @[19, 33, 18], 20: @[19, 33, 20], 22: @[19, 33, 22], 23: @[19, 33, 23], 26: @[19, 33, 26], 27: @[19, 33, 27], 28: @[19, 33, 28], 29: @[19, 33, 29], 32: @[19, 33, 32], 16: @[19, 0, 5, 16], 24: @[19, 0, 31, 24], 25: @[19, 0, 31, 25]}.toTable()),
                20: ({20: 0.0, 32: 1.0, 33: 1.0, 2: 2.0, 8: 2.0, 14: 2.0, 15: 2.0, 18: 2.0, 22: 2.0, 23: 2.0, 29: 2.0, 30: 2.0, 31: 2.0, 9: 2.0, 13: 2.0, 19: 2.0, 26: 2.0, 27: 2.0, 28: 2.0, 0: 3.0, 1: 3.0, 3: 3.0, 7: 3.0, 25: 3.0, 24: 3.0, 4: 4.0, 5: 4.0, 6: 4.0, 10: 4.0, 11: 4.0, 12: 4.0, 17: 4.0, 21: 4.0, 16: 5.0}.toTable(), {20: @[20], 32: @[20, 32], 33: @[20, 33], 2: @[20, 32, 2], 8: @[20, 32, 8], 14: @[20, 32, 14], 15: @[20, 32, 15], 18: @[20, 32, 18], 22: @[20, 32, 22], 23: @[20, 32, 23], 29: @[20, 32, 29], 30: @[20, 32, 30], 31: @[20, 32, 31], 9: @[20, 33, 9], 13: @[20, 33, 13], 19: @[20, 33, 19], 26: @[20, 33, 26], 27: @[20, 33, 27], 28: @[20, 33, 28], 0: @[20, 32, 2, 0], 1: @[20, 32, 2, 1], 3: @[20, 32, 2, 3], 7: @[20, 32, 2, 7], 25: @[20, 32, 23, 25], 24: @[20, 32, 31, 24], 4: @[20, 32, 2, 0, 4], 5: @[20, 32, 2, 0, 5], 6: @[20, 32, 2, 0, 6], 10: @[20, 32, 2, 0, 10], 11: @[20, 32, 2, 0, 11], 12: @[20, 32, 2, 0, 12], 17: @[20, 32, 2, 0, 17], 21: @[20, 32, 2, 0, 21], 16: @[20, 32, 2, 0, 5, 16]}.toTable()),
                21: ({21: 0.0, 0: 1.0, 1: 1.0, 2: 2.0, 3: 2.0, 4: 2.0, 5: 2.0, 6: 2.0, 7: 2.0, 8: 2.0, 10: 2.0, 11: 2.0, 12: 2.0, 13: 2.0, 17: 2.0, 19: 2.0, 31: 2.0, 30: 2.0, 9: 3.0, 27: 3.0, 28: 3.0, 32: 3.0, 16: 3.0, 33: 3.0, 24: 3.0, 25: 3.0, 23: 4.0, 14: 4.0, 15: 4.0, 18: 4.0, 20: 4.0, 22: 4.0, 29: 4.0, 26: 4.0}.toTable(), {21: @[21], 0: @[21, 0], 1: @[21, 1], 2: @[21, 0, 2], 3: @[21, 0, 3], 4: @[21, 0, 4], 5: @[21, 0, 5], 6: @[21, 0, 6], 7: @[21, 0, 7], 8: @[21, 0, 8], 10: @[21, 0, 10], 11: @[21, 0, 11], 12: @[21, 0, 12], 13: @[21, 0, 13], 17: @[21, 0, 17], 19: @[21, 0, 19], 31: @[21, 0, 31], 30: @[21, 1, 30], 9: @[21, 0, 2, 9], 27: @[21, 0, 2, 27], 28: @[21, 0, 2, 28], 32: @[21, 0, 2, 32], 16: @[21, 0, 5, 16], 33: @[21, 0, 8, 33], 24: @[21, 0, 31, 24], 25: @[21, 0, 31, 25], 23: @[21, 0, 2, 27, 23], 14: @[21, 0, 2, 32, 14], 15: @[21, 0, 2, 32, 15], 18: @[21, 0, 2, 32, 18], 20: @[21, 0, 2, 32, 20], 22: @[21, 0, 2, 32, 22], 29: @[21, 0, 2, 32, 29], 26: @[21, 0, 8, 33, 26]}.toTable()),
                22: ({22: 0.0, 32: 1.0, 33: 1.0, 2: 2.0, 8: 2.0, 14: 2.0, 15: 2.0, 18: 2.0, 20: 2.0, 23: 2.0, 29: 2.0, 30: 2.0, 31: 2.0, 9: 2.0, 13: 2.0, 19: 2.0, 26: 2.0, 27: 2.0, 28: 2.0, 0: 3.0, 1: 3.0, 3: 3.0, 7: 3.0, 25: 3.0, 24: 3.0, 4: 4.0, 5: 4.0, 6: 4.0, 10: 4.0, 11: 4.0, 12: 4.0, 17: 4.0, 21: 4.0, 16: 5.0}.toTable(), {22: @[22], 32: @[22, 32], 33: @[22, 33], 2: @[22, 32, 2], 8: @[22, 32, 8], 14: @[22, 32, 14], 15: @[22, 32, 15], 18: @[22, 32, 18], 20: @[22, 32, 20], 23: @[22, 32, 23], 29: @[22, 32, 29], 30: @[22, 32, 30], 31: @[22, 32, 31], 9: @[22, 33, 9], 13: @[22, 33, 13], 19: @[22, 33, 19], 26: @[22, 33, 26], 27: @[22, 33, 27], 28: @[22, 33, 28], 0: @[22, 32, 2, 0], 1: @[22, 32, 2, 1], 3: @[22, 32, 2, 3], 7: @[22, 32, 2, 7], 25: @[22, 32, 23, 25], 24: @[22, 32, 31, 24], 4: @[22, 32, 2, 0, 4], 5: @[22, 32, 2, 0, 5], 6: @[22, 32, 2, 0, 6], 10: @[22, 32, 2, 0, 10], 11: @[22, 32, 2, 0, 11], 12: @[22, 32, 2, 0, 12], 17: @[22, 32, 2, 0, 17], 21: @[22, 32, 2, 0, 21], 16: @[22, 32, 2, 0, 5, 16]}.toTable()),
                23: ({23: 0.0, 25: 1.0, 27: 1.0, 29: 1.0, 32: 1.0, 33: 1.0, 24: 2.0, 31: 2.0, 2: 2.0, 26: 2.0, 8: 2.0, 14: 2.0, 15: 2.0, 18: 2.0, 20: 2.0, 22: 2.0, 30: 2.0, 9: 2.0, 13: 2.0, 19: 2.0, 28: 2.0, 0: 3.0, 1: 3.0, 3: 3.0, 7: 3.0, 4: 4.0, 5: 4.0, 6: 4.0, 10: 4.0, 11: 4.0, 12: 4.0, 17: 4.0, 21: 4.0, 16: 5.0}.toTable(), {23: @[23], 25: @[23, 25], 27: @[23, 27], 29: @[23, 29], 32: @[23, 32], 33: @[23, 33], 24: @[23, 25, 24], 31: @[23, 25, 31], 2: @[23, 27, 2], 26: @[23, 29, 26], 8: @[23, 32, 8], 14: @[23, 32, 14], 15: @[23, 32, 15], 18: @[23, 32, 18], 20: @[23, 32, 20], 22: @[23, 32, 22], 30: @[23, 32, 30], 9: @[23, 33, 9], 13: @[23, 33, 13], 19: @[23, 33, 19], 28: @[23, 33, 28], 0: @[23, 25, 31, 0], 1: @[23, 27, 2, 1], 3: @[23, 27, 2, 3], 7: @[23, 27, 2, 7], 4: @[23, 25, 31, 0, 4], 5: @[23, 25, 31, 0, 5], 6: @[23, 25, 31, 0, 6], 10: @[23, 25, 31, 0, 10], 11: @[23, 25, 31, 0, 11], 12: @[23, 25, 31, 0, 12], 17: @[23, 25, 31, 0, 17], 21: @[23, 25, 31, 0, 21], 16: @[23, 25, 31, 0, 5, 16]}.toTable()),
                24: ({24: 0.0, 25: 1.0, 27: 1.0, 31: 1.0, 23: 2.0, 2: 2.0, 33: 2.0, 0: 2.0, 28: 2.0, 32: 2.0, 29: 3.0, 1: 3.0, 3: 3.0, 7: 3.0, 8: 3.0, 9: 3.0, 13: 3.0, 14: 3.0, 15: 3.0, 18: 3.0, 19: 3.0, 20: 3.0, 22: 3.0, 26: 3.0, 30: 3.0, 4: 3.0, 5: 3.0, 6: 3.0, 10: 3.0, 11: 3.0, 12: 3.0, 17: 3.0, 21: 3.0, 16: 4.0}.toTable(), {24: @[24], 25: @[24, 25], 27: @[24, 27], 31: @[24, 31], 23: @[24, 25, 23], 2: @[24, 27, 2], 33: @[24, 27, 33], 0: @[24, 31, 0], 28: @[24, 31, 28], 32: @[24, 31, 32], 29: @[24, 25, 23, 29], 1: @[24, 27, 2, 1], 3: @[24, 27, 2, 3], 7: @[24, 27, 2, 7], 8: @[24, 27, 2, 8], 9: @[24, 27, 2, 9], 13: @[24, 27, 2, 13], 14: @[24, 27, 33, 14], 15: @[24, 27, 33, 15], 18: @[24, 27, 33, 18], 19: @[24, 27, 33, 19], 20: @[24, 27, 33, 20], 22: @[24, 27, 33, 22], 26: @[24, 27, 33, 26], 30: @[24, 27, 33, 30], 4: @[24, 31, 0, 4], 5: @[24, 31, 0, 5], 6: @[24, 31, 0, 6], 10: @[24, 31, 0, 10], 11: @[24, 31, 0, 11], 12: @[24, 31, 0, 12], 17: @[24, 31, 0, 17], 21: @[24, 31, 0, 21], 16: @[24, 31, 0, 5, 16]}.toTable()),
                25: ({25: 0.0, 23: 1.0, 24: 1.0, 31: 1.0, 27: 2.0, 29: 2.0, 32: 2.0, 33: 2.0, 0: 2.0, 28: 2.0, 2: 3.0, 26: 3.0, 8: 3.0, 14: 3.0, 15: 3.0, 18: 3.0, 20: 3.0, 22: 3.0, 30: 3.0, 9: 3.0, 13: 3.0, 19: 3.0, 1: 3.0, 3: 3.0, 4: 3.0, 5: 3.0, 6: 3.0, 7: 3.0, 10: 3.0, 11: 3.0, 12: 3.0, 17: 3.0, 21: 3.0, 16: 4.0}.toTable(), {25: @[25], 23: @[25, 23], 24: @[25, 24], 31: @[25, 31], 27: @[25, 23, 27], 29: @[25, 23, 29], 32: @[25, 23, 32], 33: @[25, 23, 33], 0: @[25, 31, 0], 28: @[25, 31, 28], 2: @[25, 23, 27, 2], 26: @[25, 23, 29, 26], 8: @[25, 23, 32, 8], 14: @[25, 23, 32, 14], 15: @[25, 23, 32, 15], 18: @[25, 23, 32, 18], 20: @[25, 23, 32, 20], 22: @[25, 23, 32, 22], 30: @[25, 23, 32, 30], 9: @[25, 23, 33, 9], 13: @[25, 23, 33, 13], 19: @[25, 23, 33, 19], 1: @[25, 31, 0, 1], 3: @[25, 31, 0, 3], 4: @[25, 31, 0, 4], 5: @[25, 31, 0, 5], 6: @[25, 31, 0, 6], 7: @[25, 31, 0, 7], 10: @[25, 31, 0, 10], 11: @[25, 31, 0, 11], 12: @[25, 31, 0, 12], 17: @[25, 31, 0, 17], 21: @[25, 31, 0, 21], 16: @[25, 31, 0, 5, 16]}.toTable()),
                26: ({26: 0.0, 29: 1.0, 33: 1.0, 23: 2.0, 32: 2.0, 8: 2.0, 9: 2.0, 13: 2.0, 14: 2.0, 15: 2.0, 18: 2.0, 19: 2.0, 20: 2.0, 22: 2.0, 27: 2.0, 28: 2.0, 30: 2.0, 31: 2.0, 25: 3.0, 2: 3.0, 0: 3.0, 1: 3.0, 3: 3.0, 24: 3.0, 7: 4.0, 4: 4.0, 5: 4.0, 6: 4.0, 10: 4.0, 11: 4.0, 12: 4.0, 17: 4.0, 21: 4.0, 16: 5.0}.toTable(), {26: @[26], 29: @[26, 29], 33: @[26, 33], 23: @[26, 29, 23], 32: @[26, 29, 32], 8: @[26, 33, 8], 9: @[26, 33, 9], 13: @[26, 33, 13], 14: @[26, 33, 14], 15: @[26, 33, 15], 18: @[26, 33, 18], 19: @[26, 33, 19], 20: @[26, 33, 20], 22: @[26, 33, 22], 27: @[26, 33, 27], 28: @[26, 33, 28], 30: @[26, 33, 30], 31: @[26, 33, 31], 25: @[26, 29, 23, 25], 2: @[26, 29, 32, 2], 0: @[26, 33, 8, 0], 1: @[26, 33, 13, 1], 3: @[26, 33, 13, 3], 24: @[26, 33, 27, 24], 7: @[26, 29, 32, 2, 7], 4: @[26, 33, 8, 0, 4], 5: @[26, 33, 8, 0, 5], 6: @[26, 33, 8, 0, 6], 10: @[26, 33, 8, 0, 10], 11: @[26, 33, 8, 0, 11], 12: @[26, 33, 8, 0, 12], 17: @[26, 33, 8, 0, 17], 21: @[26, 33, 8, 0, 21], 16: @[26, 33, 8, 0, 5, 16]}.toTable()),
                27: ({27: 0.0, 2: 1.0, 23: 1.0, 24: 1.0, 33: 1.0, 0: 2.0, 1: 2.0, 3: 2.0, 7: 2.0, 8: 2.0, 9: 2.0, 13: 2.0, 28: 2.0, 32: 2.0, 25: 2.0, 29: 2.0, 31: 2.0, 14: 2.0, 15: 2.0, 18: 2.0, 19: 2.0, 20: 2.0, 22: 2.0, 26: 2.0, 30: 2.0, 4: 3.0, 5: 3.0, 6: 3.0, 10: 3.0, 11: 3.0, 12: 3.0, 17: 3.0, 21: 3.0, 16: 4.0}.toTable(), {27: @[27], 2: @[27, 2], 23: @[27, 23], 24: @[27, 24], 33: @[27, 33], 0: @[27, 2, 0], 1: @[27, 2, 1], 3: @[27, 2, 3], 7: @[27, 2, 7], 8: @[27, 2, 8], 9: @[27, 2, 9], 13: @[27, 2, 13], 28: @[27, 2, 28], 32: @[27, 2, 32], 25: @[27, 23, 25], 29: @[27, 23, 29], 31: @[27, 24, 31], 14: @[27, 33, 14], 15: @[27, 33, 15], 18: @[27, 33, 18], 19: @[27, 33, 19], 20: @[27, 33, 20], 22: @[27, 33, 22], 26: @[27, 33, 26], 30: @[27, 33, 30], 4: @[27, 2, 0, 4], 5: @[27, 2, 0, 5], 6: @[27, 2, 0, 6], 10: @[27, 2, 0, 10], 11: @[27, 2, 0, 11], 12: @[27, 2, 0, 12], 17: @[27, 2, 0, 17], 21: @[27, 2, 0, 21], 16: @[27, 2, 0, 5, 16]}.toTable()),
                28: ({28: 0.0, 2: 1.0, 31: 1.0, 33: 1.0, 0: 2.0, 1: 2.0, 3: 2.0, 7: 2.0, 8: 2.0, 9: 2.0, 13: 2.0, 27: 2.0, 32: 2.0, 24: 2.0, 25: 2.0, 14: 2.0, 15: 2.0, 18: 2.0, 19: 2.0, 20: 2.0, 22: 2.0, 23: 2.0, 26: 2.0, 29: 2.0, 30: 2.0, 4: 3.0, 5: 3.0, 6: 3.0, 10: 3.0, 11: 3.0, 12: 3.0, 17: 3.0, 21: 3.0, 16: 4.0}.toTable(), {28: @[28], 2: @[28, 2], 31: @[28, 31], 33: @[28, 33], 0: @[28, 2, 0], 1: @[28, 2, 1], 3: @[28, 2, 3], 7: @[28, 2, 7], 8: @[28, 2, 8], 9: @[28, 2, 9], 13: @[28, 2, 13], 27: @[28, 2, 27], 32: @[28, 2, 32], 24: @[28, 31, 24], 25: @[28, 31, 25], 14: @[28, 33, 14], 15: @[28, 33, 15], 18: @[28, 33, 18], 19: @[28, 33, 19], 20: @[28, 33, 20], 22: @[28, 33, 22], 23: @[28, 33, 23], 26: @[28, 33, 26], 29: @[28, 33, 29], 30: @[28, 33, 30], 4: @[28, 2, 0, 4], 5: @[28, 2, 0, 5], 6: @[28, 2, 0, 6], 10: @[28, 2, 0, 10], 11: @[28, 2, 0, 11], 12: @[28, 2, 0, 12], 17: @[28, 2, 0, 17], 21: @[28, 2, 0, 21], 16: @[28, 2, 0, 5, 16]}.toTable()),
                29: ({29: 0.0, 23: 1.0, 26: 1.0, 32: 1.0, 33: 1.0, 25: 2.0, 27: 2.0, 2: 2.0, 8: 2.0, 14: 2.0, 15: 2.0, 18: 2.0, 20: 2.0, 22: 2.0, 30: 2.0, 31: 2.0, 9: 2.0, 13: 2.0, 19: 2.0, 28: 2.0, 24: 3.0, 0: 3.0, 1: 3.0, 3: 3.0, 7: 3.0, 4: 4.0, 5: 4.0, 6: 4.0, 10: 4.0, 11: 4.0, 12: 4.0, 17: 4.0, 21: 4.0, 16: 5.0}.toTable(), {29: @[29], 23: @[29, 23], 26: @[29, 26], 32: @[29, 32], 33: @[29, 33], 25: @[29, 23, 25], 27: @[29, 23, 27], 2: @[29, 32, 2], 8: @[29, 32, 8], 14: @[29, 32, 14], 15: @[29, 32, 15], 18: @[29, 32, 18], 20: @[29, 32, 20], 22: @[29, 32, 22], 30: @[29, 32, 30], 31: @[29, 32, 31], 9: @[29, 33, 9], 13: @[29, 33, 13], 19: @[29, 33, 19], 28: @[29, 33, 28], 24: @[29, 23, 25, 24], 0: @[29, 32, 2, 0], 1: @[29, 32, 2, 1], 3: @[29, 32, 2, 3], 7: @[29, 32, 2, 7], 4: @[29, 32, 2, 0, 4], 5: @[29, 32, 2, 0, 5], 6: @[29, 32, 2, 0, 6], 10: @[29, 32, 2, 0, 10], 11: @[29, 32, 2, 0, 11], 12: @[29, 32, 2, 0, 12], 17: @[29, 32, 2, 0, 17], 21: @[29, 32, 2, 0, 21], 16: @[29, 32, 2, 0, 5, 16]}.toTable()),
                30: ({30: 0.0, 1: 1.0, 8: 1.0, 32: 1.0, 33: 1.0, 0: 2.0, 2: 2.0, 3: 2.0, 7: 2.0, 13: 2.0, 17: 2.0, 19: 2.0, 21: 2.0, 14: 2.0, 15: 2.0, 18: 2.0, 20: 2.0, 22: 2.0, 23: 2.0, 29: 2.0, 31: 2.0, 9: 2.0, 26: 2.0, 27: 2.0, 28: 2.0, 4: 3.0, 5: 3.0, 6: 3.0, 10: 3.0, 11: 3.0, 12: 3.0, 25: 3.0, 24: 3.0, 16: 4.0}.toTable(), {30: @[30], 1: @[30, 1], 8: @[30, 8], 32: @[30, 32], 33: @[30, 33], 0: @[30, 1, 0], 2: @[30, 1, 2], 3: @[30, 1, 3], 7: @[30, 1, 7], 13: @[30, 1, 13], 17: @[30, 1, 17], 19: @[30, 1, 19], 21: @[30, 1, 21], 14: @[30, 32, 14], 15: @[30, 32, 15], 18: @[30, 32, 18], 20: @[30, 32, 20], 22: @[30, 32, 22], 23: @[30, 32, 23], 29: @[30, 32, 29], 31: @[30, 32, 31], 9: @[30, 33, 9], 26: @[30, 33, 26], 27: @[30, 33, 27], 28: @[30, 33, 28], 4: @[30, 1, 0, 4], 5: @[30, 1, 0, 5], 6: @[30, 1, 0, 6], 10: @[30, 1, 0, 10], 11: @[30, 1, 0, 11], 12: @[30, 1, 0, 12], 25: @[30, 32, 23, 25], 24: @[30, 32, 31, 24], 16: @[30, 1, 0, 5, 16]}.toTable()),
                31: ({31: 0.0, 0: 1.0, 24: 1.0, 25: 1.0, 28: 1.0, 32: 1.0, 33: 1.0, 1: 2.0, 2: 2.0, 3: 2.0, 4: 2.0, 5: 2.0, 6: 2.0, 7: 2.0, 8: 2.0, 10: 2.0, 11: 2.0, 12: 2.0, 13: 2.0, 17: 2.0, 19: 2.0, 21: 2.0, 27: 2.0, 23: 2.0, 14: 2.0, 15: 2.0, 18: 2.0, 20: 2.0, 22: 2.0, 29: 2.0, 30: 2.0, 9: 2.0, 26: 2.0, 16: 3.0}.toTable(), {31: @[31], 0: @[31, 0], 24: @[31, 24], 25: @[31, 25], 28: @[31, 28], 32: @[31, 32], 33: @[31, 33], 1: @[31, 0, 1], 2: @[31, 0, 2], 3: @[31, 0, 3], 4: @[31, 0, 4], 5: @[31, 0, 5], 6: @[31, 0, 6], 7: @[31, 0, 7], 8: @[31, 0, 8], 10: @[31, 0, 10], 11: @[31, 0, 11], 12: @[31, 0, 12], 13: @[31, 0, 13], 17: @[31, 0, 17], 19: @[31, 0, 19], 21: @[31, 0, 21], 27: @[31, 24, 27], 23: @[31, 25, 23], 14: @[31, 32, 14], 15: @[31, 32, 15], 18: @[31, 32, 18], 20: @[31, 32, 20], 22: @[31, 32, 22], 29: @[31, 32, 29], 30: @[31, 32, 30], 9: @[31, 33, 9], 26: @[31, 33, 26], 16: @[31, 0, 5, 16]}.toTable()),
                32: ({32: 0.0, 2: 1.0, 8: 1.0, 14: 1.0, 15: 1.0, 18: 1.0, 20: 1.0, 22: 1.0, 23: 1.0, 29: 1.0, 30: 1.0, 31: 1.0, 33: 1.0, 0: 2.0, 1: 2.0, 3: 2.0, 7: 2.0, 9: 2.0, 13: 2.0, 27: 2.0, 28: 2.0, 25: 2.0, 26: 2.0, 24: 2.0, 19: 2.0, 4: 3.0, 5: 3.0, 6: 3.0, 10: 3.0, 11: 3.0, 12: 3.0, 17: 3.0, 21: 3.0, 16: 4.0}.toTable(), {32: @[32], 2: @[32, 2], 8: @[32, 8], 14: @[32, 14], 15: @[32, 15], 18: @[32, 18], 20: @[32, 20], 22: @[32, 22], 23: @[32, 23], 29: @[32, 29], 30: @[32, 30], 31: @[32, 31], 33: @[32, 33], 0: @[32, 2, 0], 1: @[32, 2, 1], 3: @[32, 2, 3], 7: @[32, 2, 7], 9: @[32, 2, 9], 13: @[32, 2, 13], 27: @[32, 2, 27], 28: @[32, 2, 28], 25: @[32, 23, 25], 26: @[32, 29, 26], 24: @[32, 31, 24], 19: @[32, 33, 19], 4: @[32, 2, 0, 4], 5: @[32, 2, 0, 5], 6: @[32, 2, 0, 6], 10: @[32, 2, 0, 10], 11: @[32, 2, 0, 11], 12: @[32, 2, 0, 12], 17: @[32, 2, 0, 17], 21: @[32, 2, 0, 21], 16: @[32, 2, 0, 5, 16]}.toTable()),
                33: ({33: 0.0, 8: 1.0, 9: 1.0, 13: 1.0, 14: 1.0, 15: 1.0, 18: 1.0, 19: 1.0, 20: 1.0, 22: 1.0, 23: 1.0, 26: 1.0, 27: 1.0, 28: 1.0, 29: 1.0, 30: 1.0, 31: 1.0, 32: 1.0, 0: 2.0, 2: 2.0, 1: 2.0, 3: 2.0, 25: 2.0, 24: 2.0, 4: 3.0, 5: 3.0, 6: 3.0, 7: 3.0, 10: 3.0, 11: 3.0, 12: 3.0, 17: 3.0, 21: 3.0, 16: 4.0}.toTable(), {33: @[33], 8: @[33, 8], 9: @[33, 9], 13: @[33, 13], 14: @[33, 14], 15: @[33, 15], 18: @[33, 18], 19: @[33, 19], 20: @[33, 20], 22: @[33, 22], 23: @[33, 23], 26: @[33, 26], 27: @[33, 27], 28: @[33, 28], 29: @[33, 29], 30: @[33, 30], 31: @[33, 31], 32: @[33, 32], 0: @[33, 8, 0], 2: @[33, 8, 2], 1: @[33, 13, 1], 3: @[33, 13, 3], 25: @[33, 23, 25], 24: @[33, 27, 24], 4: @[33, 8, 0, 4], 5: @[33, 8, 0, 5], 6: @[33, 8, 0, 6], 7: @[33, 8, 0, 7], 10: @[33, 8, 0, 10], 11: @[33, 8, 0, 11], 12: @[33, 8, 0, 12], 17: @[33, 8, 0, 17], 21: @[33, 8, 0, 21], 16: @[33, 8, 0, 5, 16]}.toTable()),
            }.toTable()
        for (source, dists, paths) in allPairsDijkstra(g=karate):
            doAssert nxRet[source].dists == dists
            for (target, path) in paths.pairs():
                if nxRet[source].paths[target] != path:
                    echo("nxRet[source].paths[target]: ", nxRet[source].paths[target])
                    echo("  ret[source].paths[target]: ", path)
            # doAssert nxRet[source].paths == paths

    # block dkarateAllPairsDijkstra:
    #     var dkarate = newDirectedGraph()
    #     dkarate.addEdgesFrom(@[(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)])
    #     var nxRet: Table[Node, tuple[dists: Table[Node, float], paths: Table[Node, seq[Node]]]] =
    #         {
    #             0: ({0: 0.0, 1: 1.0, 2: 1.0, 3: 1.0, 4: 1.0, 5: 1.0, 6: 1.0, 7: 1.0, 8: 1.0, 10: 1.0, 11: 1.0, 12: 1.0, 13: 1.0, 17: 1.0, 19: 1.0, 21: 1.0, 31: 1.0, 30: 2.0, 9: 2.0, 27: 2.0, 28: 2.0, 32: 2.0, 16: 2.0, 33: 2.0, 24: 2.0, 25: 2.0, 23: 3.0, 14: 3.0, 15: 3.0, 18: 3.0, 20: 3.0, 22: 3.0, 29: 3.0, 26: 3.0}.toTable(), {0: @[0], 1: @[0, 1], 2: @[0, 2], 3: @[0, 3], 4: @[0, 4], 5: @[0, 5], 6: @[0, 6], 7: @[0, 7], 8: @[0, 8], 10: @[0, 10], 11: @[0, 11], 12: @[0, 12], 13: @[0, 13], 17: @[0, 17], 19: @[0, 19], 21: @[0, 21], 31: @[0, 31], 30: @[0, 1, 30], 9: @[0, 2, 9], 27: @[0, 2, 27], 28: @[0, 2, 28], 32: @[0, 2, 32], 16: @[0, 5, 16], 33: @[0, 8, 33], 24: @[0, 31, 24], 25: @[0, 31, 25], 23: @[0, 2, 27, 23], 14: @[0, 2, 32, 14], 15: @[0, 2, 32, 15], 18: @[0, 2, 32, 18], 20: @[0, 2, 32, 20], 22: @[0, 2, 32, 22], 29: @[0, 2, 32, 29], 26: @[0, 8, 33, 26]}.toTable()),
    #             1: ({1: 0.0, 0: 1.0, 2: 1.0, 3: 1.0, 7: 1.0, 13: 1.0, 17: 1.0, 19: 1.0, 21: 1.0, 30: 1.0, 4: 2.0, 5: 2.0, 6: 2.0, 8: 2.0, 10: 2.0, 11: 2.0, 12: 2.0, 31: 2.0, 9: 2.0, 27: 2.0, 28: 2.0, 32: 2.0, 33: 2.0, 16: 3.0, 24: 3.0, 25: 3.0, 23: 3.0, 14: 3.0, 15: 3.0, 18: 3.0, 20: 3.0, 22: 3.0, 29: 3.0, 26: 3.0}.toTable(), {1: @[1], 0: @[1, 0], 2: @[1, 2], 3: @[1, 3], 7: @[1, 7], 13: @[1, 13], 17: @[1, 17], 19: @[1, 19], 21: @[1, 21], 30: @[1, 30], 4: @[1, 0, 4], 5: @[1, 0, 5], 6: @[1, 0, 6], 8: @[1, 0, 8], 10: @[1, 0, 10], 11: @[1, 0, 11], 12: @[1, 0, 12], 31: @[1, 0, 31], 9: @[1, 2, 9], 27: @[1, 2, 27], 28: @[1, 2, 28], 32: @[1, 2, 32], 33: @[1, 13, 33], 16: @[1, 0, 5, 16], 24: @[1, 0, 31, 24], 25: @[1, 0, 31, 25], 23: @[1, 2, 27, 23], 14: @[1, 2, 32, 14], 15: @[1, 2, 32, 15], 18: @[1, 2, 32, 18], 20: @[1, 2, 32, 20], 22: @[1, 2, 32, 22], 29: @[1, 2, 32, 29], 26: @[1, 13, 33, 26]}.toTable()),
    #             2: ({2: 0.0, 0: 1.0, 1: 1.0, 3: 1.0, 7: 1.0, 8: 1.0, 9: 1.0, 13: 1.0, 27: 1.0, 28: 1.0, 32: 1.0, 4: 2.0, 5: 2.0, 6: 2.0, 10: 2.0, 11: 2.0, 12: 2.0, 17: 2.0, 19: 2.0, 21: 2.0, 31: 2.0, 30: 2.0, 33: 2.0, 23: 2.0, 24: 2.0, 14: 2.0, 15: 2.0, 18: 2.0, 20: 2.0, 22: 2.0, 29: 2.0, 16: 3.0, 25: 3.0, 26: 3.0}.toTable(), {2: @[2], 0: @[2, 0], 1: @[2, 1], 3: @[2, 3], 7: @[2, 7], 8: @[2, 8], 9: @[2, 9], 13: @[2, 13], 27: @[2, 27], 28: @[2, 28], 32: @[2, 32], 4: @[2, 0, 4], 5: @[2, 0, 5], 6: @[2, 0, 6], 10: @[2, 0, 10], 11: @[2, 0, 11], 12: @[2, 0, 12], 17: @[2, 0, 17], 19: @[2, 0, 19], 21: @[2, 0, 21], 31: @[2, 0, 31], 30: @[2, 1, 30], 33: @[2, 8, 33], 23: @[2, 27, 23], 24: @[2, 27, 24], 14: @[2, 32, 14], 15: @[2, 32, 15], 18: @[2, 32, 18], 20: @[2, 32, 20], 22: @[2, 32, 22], 29: @[2, 32, 29], 16: @[2, 0, 5, 16], 25: @[2, 0, 31, 25], 26: @[2, 8, 33, 26]}.toTable()),
    #             3: ({3: 0.0, 0: 1.0, 1: 1.0, 2: 1.0, 7: 1.0, 12: 1.0, 13: 1.0, 4: 2.0, 5: 2.0, 6: 2.0, 8: 2.0, 10: 2.0, 11: 2.0, 17: 2.0, 19: 2.0, 21: 2.0, 31: 2.0, 30: 2.0, 9: 2.0, 27: 2.0, 28: 2.0, 32: 2.0, 33: 2.0, 16: 3.0, 24: 3.0, 25: 3.0, 23: 3.0, 14: 3.0, 15: 3.0, 18: 3.0, 20: 3.0, 22: 3.0, 29: 3.0, 26: 3.0}.toTable(), {3: @[3], 0: @[3, 0], 1: @[3, 1], 2: @[3, 2], 7: @[3, 7], 12: @[3, 12], 13: @[3, 13], 4: @[3, 0, 4], 5: @[3, 0, 5], 6: @[3, 0, 6], 8: @[3, 0, 8], 10: @[3, 0, 10], 11: @[3, 0, 11], 17: @[3, 0, 17], 19: @[3, 0, 19], 21: @[3, 0, 21], 31: @[3, 0, 31], 30: @[3, 1, 30], 9: @[3, 2, 9], 27: @[3, 2, 27], 28: @[3, 2, 28], 32: @[3, 2, 32], 33: @[3, 13, 33], 16: @[3, 0, 5, 16], 24: @[3, 0, 31, 24], 25: @[3, 0, 31, 25], 23: @[3, 2, 27, 23], 14: @[3, 2, 32, 14], 15: @[3, 2, 32, 15], 18: @[3, 2, 32, 18], 20: @[3, 2, 32, 20], 22: @[3, 2, 32, 22], 29: @[3, 2, 32, 29], 26: @[3, 13, 33, 26]}.toTable()),
    #             4: ({4: 0.0, 0: 1.0, 6: 1.0, 10: 1.0, 1: 2.0, 2: 2.0, 3: 2.0, 5: 2.0, 7: 2.0, 8: 2.0, 11: 2.0, 12: 2.0, 13: 2.0, 17: 2.0, 19: 2.0, 21: 2.0, 31: 2.0, 16: 2.0, 30: 3.0, 9: 3.0, 27: 3.0, 28: 3.0, 32: 3.0, 33: 3.0, 24: 3.0, 25: 3.0, 23: 4.0, 14: 4.0, 15: 4.0, 18: 4.0, 20: 4.0, 22: 4.0, 29: 4.0, 26: 4.0}.toTable(), {4: @[4], 0: @[4, 0], 6: @[4, 6], 10: @[4, 10], 1: @[4, 0, 1], 2: @[4, 0, 2], 3: @[4, 0, 3], 5: @[4, 0, 5], 7: @[4, 0, 7], 8: @[4, 0, 8], 11: @[4, 0, 11], 12: @[4, 0, 12], 13: @[4, 0, 13], 17: @[4, 0, 17], 19: @[4, 0, 19], 21: @[4, 0, 21], 31: @[4, 0, 31], 16: @[4, 6, 16], 30: @[4, 0, 1, 30], 9: @[4, 0, 2, 9], 27: @[4, 0, 2, 27], 28: @[4, 0, 2, 28], 32: @[4, 0, 2, 32], 33: @[4, 0, 8, 33], 24: @[4, 0, 31, 24], 25: @[4, 0, 31, 25], 23: @[4, 0, 2, 27, 23], 14: @[4, 0, 2, 32, 14], 15: @[4, 0, 2, 32, 15], 18: @[4, 0, 2, 32, 18], 20: @[4, 0, 2, 32, 20], 22: @[4, 0, 2, 32, 22], 29: @[4, 0, 2, 32, 29], 26: @[4, 0, 8, 33, 26]}.toTable()),
    #             5: ({5: 0.0, 0: 1.0, 6: 1.0, 10: 1.0, 16: 1.0, 1: 2.0, 2: 2.0, 3: 2.0, 4: 2.0, 7: 2.0, 8: 2.0, 11: 2.0, 12: 2.0, 13: 2.0, 17: 2.0, 19: 2.0, 21: 2.0, 31: 2.0, 30: 3.0, 9: 3.0, 27: 3.0, 28: 3.0, 32: 3.0, 33: 3.0, 24: 3.0, 25: 3.0, 23: 4.0, 14: 4.0, 15: 4.0, 18: 4.0, 20: 4.0, 22: 4.0, 29: 4.0, 26: 4.0}.toTable(), {5: @[5], 0: @[5, 0], 6: @[5, 6], 10: @[5, 10], 16: @[5, 16], 1: @[5, 0, 1], 2: @[5, 0, 2], 3: @[5, 0, 3], 4: @[5, 0, 4], 7: @[5, 0, 7], 8: @[5, 0, 8], 11: @[5, 0, 11], 12: @[5, 0, 12], 13: @[5, 0, 13], 17: @[5, 0, 17], 19: @[5, 0, 19], 21: @[5, 0, 21], 31: @[5, 0, 31], 30: @[5, 0, 1, 30], 9: @[5, 0, 2, 9], 27: @[5, 0, 2, 27], 28: @[5, 0, 2, 28], 32: @[5, 0, 2, 32], 33: @[5, 0, 8, 33], 24: @[5, 0, 31, 24], 25: @[5, 0, 31, 25], 23: @[5, 0, 2, 27, 23], 14: @[5, 0, 2, 32, 14], 15: @[5, 0, 2, 32, 15], 18: @[5, 0, 2, 32, 18], 20: @[5, 0, 2, 32, 20], 22: @[5, 0, 2, 32, 22], 29: @[5, 0, 2, 32, 29], 26: @[5, 0, 8, 33, 26]}.toTable()),
    #             6: ({6: 0.0, 0: 1.0, 4: 1.0, 5: 1.0, 16: 1.0, 1: 2.0, 2: 2.0, 3: 2.0, 7: 2.0, 8: 2.0, 10: 2.0, 11: 2.0, 12: 2.0, 13: 2.0, 17: 2.0, 19: 2.0, 21: 2.0, 31: 2.0, 30: 3.0, 9: 3.0, 27: 3.0, 28: 3.0, 32: 3.0, 33: 3.0, 24: 3.0, 25: 3.0, 23: 4.0, 14: 4.0, 15: 4.0, 18: 4.0, 20: 4.0, 22: 4.0, 29: 4.0, 26: 4.0}.toTable(), {6: @[6], 0: @[6, 0], 4: @[6, 4], 5: @[6, 5], 16: @[6, 16], 1: @[6, 0, 1], 2: @[6, 0, 2], 3: @[6, 0, 3], 7: @[6, 0, 7], 8: @[6, 0, 8], 10: @[6, 0, 10], 11: @[6, 0, 11], 12: @[6, 0, 12], 13: @[6, 0, 13], 17: @[6, 0, 17], 19: @[6, 0, 19], 21: @[6, 0, 21], 31: @[6, 0, 31], 30: @[6, 0, 1, 30], 9: @[6, 0, 2, 9], 27: @[6, 0, 2, 27], 28: @[6, 0, 2, 28], 32: @[6, 0, 2, 32], 33: @[6, 0, 8, 33], 24: @[6, 0, 31, 24], 25: @[6, 0, 31, 25], 23: @[6, 0, 2, 27, 23], 14: @[6, 0, 2, 32, 14], 15: @[6, 0, 2, 32, 15], 18: @[6, 0, 2, 32, 18], 20: @[6, 0, 2, 32, 20], 22: @[6, 0, 2, 32, 22], 29: @[6, 0, 2, 32, 29], 26: @[6, 0, 8, 33, 26]}.toTable()),
    #             7: ({7: 0.0, 0: 1.0, 1: 1.0, 2: 1.0, 3: 1.0, 4: 2.0, 5: 2.0, 6: 2.0, 8: 2.0, 10: 2.0, 11: 2.0, 12: 2.0, 13: 2.0, 17: 2.0, 19: 2.0, 21: 2.0, 31: 2.0, 30: 2.0, 9: 2.0, 27: 2.0, 28: 2.0, 32: 2.0, 16: 3.0, 33: 3.0, 24: 3.0, 25: 3.0, 23: 3.0, 14: 3.0, 15: 3.0, 18: 3.0, 20: 3.0, 22: 3.0, 29: 3.0, 26: 4.0}.toTable(), {7: @[7], 0: @[7, 0], 1: @[7, 1], 2: @[7, 2], 3: @[7, 3], 4: @[7, 0, 4], 5: @[7, 0, 5], 6: @[7, 0, 6], 8: @[7, 0, 8], 10: @[7, 0, 10], 11: @[7, 0, 11], 12: @[7, 0, 12], 13: @[7, 0, 13], 17: @[7, 0, 17], 19: @[7, 0, 19], 21: @[7, 0, 21], 31: @[7, 0, 31], 30: @[7, 1, 30], 9: @[7, 2, 9], 27: @[7, 2, 27], 28: @[7, 2, 28], 32: @[7, 2, 32], 16: @[7, 0, 5, 16], 33: @[7, 0, 8, 33], 24: @[7, 0, 31, 24], 25: @[7, 0, 31, 25], 23: @[7, 2, 27, 23], 14: @[7, 2, 32, 14], 15: @[7, 2, 32, 15], 18: @[7, 2, 32, 18], 20: @[7, 2, 32, 20], 22: @[7, 2, 32, 22], 29: @[7, 2, 32, 29], 26: @[7, 0, 8, 33, 26]}.toTable()),
    #             8: ({8: 0.0, 0: 1.0, 2: 1.0, 30: 1.0, 32: 1.0, 33: 1.0, 1: 2.0, 3: 2.0, 4: 2.0, 5: 2.0, 6: 2.0, 7: 2.0, 10: 2.0, 11: 2.0, 12: 2.0, 13: 2.0, 17: 2.0, 19: 2.0, 21: 2.0, 31: 2.0, 9: 2.0, 27: 2.0, 28: 2.0, 14: 2.0, 15: 2.0, 18: 2.0, 20: 2.0, 22: 2.0, 23: 2.0, 29: 2.0, 26: 2.0, 16: 3.0, 24: 3.0, 25: 3.0}.toTable(), {8: @[8], 0: @[8, 0], 2: @[8, 2], 30: @[8, 30], 32: @[8, 32], 33: @[8, 33], 1: @[8, 0, 1], 3: @[8, 0, 3], 4: @[8, 0, 4], 5: @[8, 0, 5], 6: @[8, 0, 6], 7: @[8, 0, 7], 10: @[8, 0, 10], 11: @[8, 0, 11], 12: @[8, 0, 12], 13: @[8, 0, 13], 17: @[8, 0, 17], 19: @[8, 0, 19], 21: @[8, 0, 21], 31: @[8, 0, 31], 9: @[8, 2, 9], 27: @[8, 2, 27], 28: @[8, 2, 28], 14: @[8, 32, 14], 15: @[8, 32, 15], 18: @[8, 32, 18], 20: @[8, 32, 20], 22: @[8, 32, 22], 23: @[8, 32, 23], 29: @[8, 32, 29], 26: @[8, 33, 26], 16: @[8, 0, 5, 16], 24: @[8, 0, 31, 24], 25: @[8, 0, 31, 25]}.toTable()),
    #             9: ({9: 0.0, 2: 1.0, 33: 1.0, 0: 2.0, 1: 2.0, 3: 2.0, 7: 2.0, 8: 2.0, 13: 2.0, 27: 2.0, 28: 2.0, 32: 2.0, 14: 2.0, 15: 2.0, 18: 2.0, 19: 2.0, 20: 2.0, 22: 2.0, 23: 2.0, 26: 2.0, 29: 2.0, 30: 2.0, 31: 2.0, 4: 3.0, 5: 3.0, 6: 3.0, 10: 3.0, 11: 3.0, 12: 3.0, 17: 3.0, 21: 3.0, 24: 3.0, 25: 3.0, 16: 4.0}.toTable(), {9: @[9], 2: @[9, 2], 33: @[9, 33], 0: @[9, 2, 0], 1: @[9, 2, 1], 3: @[9, 2, 3], 7: @[9, 2, 7], 8: @[9, 2, 8], 13: @[9, 2, 13], 27: @[9, 2, 27], 28: @[9, 2, 28], 32: @[9, 2, 32], 14: @[9, 33, 14], 15: @[9, 33, 15], 18: @[9, 33, 18], 19: @[9, 33, 19], 20: @[9, 33, 20], 22: @[9, 33, 22], 23: @[9, 33, 23], 26: @[9, 33, 26], 29: @[9, 33, 29], 30: @[9, 33, 30], 31: @[9, 33, 31], 4: @[9, 2, 0, 4], 5: @[9, 2, 0, 5], 6: @[9, 2, 0, 6], 10: @[9, 2, 0, 10], 11: @[9, 2, 0, 11], 12: @[9, 2, 0, 12], 17: @[9, 2, 0, 17], 21: @[9, 2, 0, 21], 24: @[9, 2, 27, 24], 25: @[9, 33, 23, 25], 16: @[9, 2, 0, 5, 16]}.toTable()),
    #             10: ({10: 0.0, 0: 1.0, 4: 1.0, 5: 1.0, 1: 2.0, 2: 2.0, 3: 2.0, 6: 2.0, 7: 2.0, 8: 2.0, 11: 2.0, 12: 2.0, 13: 2.0, 17: 2.0, 19: 2.0, 21: 2.0, 31: 2.0, 16: 2.0, 30: 3.0, 9: 3.0, 27: 3.0, 28: 3.0, 32: 3.0, 33: 3.0, 24: 3.0, 25: 3.0, 23: 4.0, 14: 4.0, 15: 4.0, 18: 4.0, 20: 4.0, 22: 4.0, 29: 4.0, 26: 4.0}.toTable(), {10: @[10], 0: @[10, 0], 4: @[10, 4], 5: @[10, 5], 1: @[10, 0, 1], 2: @[10, 0, 2], 3: @[10, 0, 3], 6: @[10, 0, 6], 7: @[10, 0, 7], 8: @[10, 0, 8], 11: @[10, 0, 11], 12: @[10, 0, 12], 13: @[10, 0, 13], 17: @[10, 0, 17], 19: @[10, 0, 19], 21: @[10, 0, 21], 31: @[10, 0, 31], 16: @[10, 5, 16], 30: @[10, 0, 1, 30], 9: @[10, 0, 2, 9], 27: @[10, 0, 2, 27], 28: @[10, 0, 2, 28], 32: @[10, 0, 2, 32], 33: @[10, 0, 8, 33], 24: @[10, 0, 31, 24], 25: @[10, 0, 31, 25], 23: @[10, 0, 2, 27, 23], 14: @[10, 0, 2, 32, 14], 15: @[10, 0, 2, 32, 15], 18: @[10, 0, 2, 32, 18], 20: @[10, 0, 2, 32, 20], 22: @[10, 0, 2, 32, 22], 29: @[10, 0, 2, 32, 29], 26: @[10, 0, 8, 33, 26]}.toTable()),
    #             11: ({11: 0.0, 0: 1.0, 1: 2.0, 2: 2.0, 3: 2.0, 4: 2.0, 5: 2.0, 6: 2.0, 7: 2.0, 8: 2.0, 10: 2.0, 12: 2.0, 13: 2.0, 17: 2.0, 19: 2.0, 21: 2.0, 31: 2.0, 30: 3.0, 9: 3.0, 27: 3.0, 28: 3.0, 32: 3.0, 16: 3.0, 33: 3.0, 24: 3.0, 25: 3.0, 23: 4.0, 14: 4.0, 15: 4.0, 18: 4.0, 20: 4.0, 22: 4.0, 29: 4.0, 26: 4.0}.toTable(), {11: @[11], 0: @[11, 0], 1: @[11, 0, 1], 2: @[11, 0, 2], 3: @[11, 0, 3], 4: @[11, 0, 4], 5: @[11, 0, 5], 6: @[11, 0, 6], 7: @[11, 0, 7], 8: @[11, 0, 8], 10: @[11, 0, 10], 12: @[11, 0, 12], 13: @[11, 0, 13], 17: @[11, 0, 17], 19: @[11, 0, 19], 21: @[11, 0, 21], 31: @[11, 0, 31], 30: @[11, 0, 1, 30], 9: @[11, 0, 2, 9], 27: @[11, 0, 2, 27], 28: @[11, 0, 2, 28], 32: @[11, 0, 2, 32], 16: @[11, 0, 5, 16], 33: @[11, 0, 8, 33], 24: @[11, 0, 31, 24], 25: @[11, 0, 31, 25], 23: @[11, 0, 2, 27, 23], 14: @[11, 0, 2, 32, 14], 15: @[11, 0, 2, 32, 15], 18: @[11, 0, 2, 32, 18], 20: @[11, 0, 2, 32, 20], 22: @[11, 0, 2, 32, 22], 29: @[11, 0, 2, 32, 29], 26: @[11, 0, 8, 33, 26]}.toTable()),
    #             12: ({12: 0.0, 0: 1.0, 3: 1.0, 1: 2.0, 2: 2.0, 4: 2.0, 5: 2.0, 6: 2.0, 7: 2.0, 8: 2.0, 10: 2.0, 11: 2.0, 13: 2.0, 17: 2.0, 19: 2.0, 21: 2.0, 31: 2.0, 30: 3.0, 9: 3.0, 27: 3.0, 28: 3.0, 32: 3.0, 16: 3.0, 33: 3.0, 24: 3.0, 25: 3.0, 23: 4.0, 14: 4.0, 15: 4.0, 18: 4.0, 20: 4.0, 22: 4.0, 29: 4.0, 26: 4.0}.toTable(), {12: @[12], 0: @[12, 0], 3: @[12, 3], 1: @[12, 0, 1], 2: @[12, 0, 2], 4: @[12, 0, 4], 5: @[12, 0, 5], 6: @[12, 0, 6], 7: @[12, 0, 7], 8: @[12, 0, 8], 10: @[12, 0, 10], 11: @[12, 0, 11], 13: @[12, 0, 13], 17: @[12, 0, 17], 19: @[12, 0, 19], 21: @[12, 0, 21], 31: @[12, 0, 31], 30: @[12, 0, 1, 30], 9: @[12, 0, 2, 9], 27: @[12, 0, 2, 27], 28: @[12, 0, 2, 28], 32: @[12, 0, 2, 32], 16: @[12, 0, 5, 16], 33: @[12, 0, 8, 33], 24: @[12, 0, 31, 24], 25: @[12, 0, 31, 25], 23: @[12, 0, 2, 27, 23], 14: @[12, 0, 2, 32, 14], 15: @[12, 0, 2, 32, 15], 18: @[12, 0, 2, 32, 18], 20: @[12, 0, 2, 32, 20], 22: @[12, 0, 2, 32, 22], 29: @[12, 0, 2, 32, 29], 26: @[12, 0, 8, 33, 26]}.toTable()),
    #             13: ({13: 0.0, 0: 1.0, 1: 1.0, 2: 1.0, 3: 1.0, 33: 1.0, 4: 2.0, 5: 2.0, 6: 2.0, 7: 2.0, 8: 2.0, 10: 2.0, 11: 2.0, 12: 2.0, 17: 2.0, 19: 2.0, 21: 2.0, 31: 2.0, 30: 2.0, 9: 2.0, 27: 2.0, 28: 2.0, 32: 2.0, 14: 2.0, 15: 2.0, 18: 2.0, 20: 2.0, 22: 2.0, 23: 2.0, 26: 2.0, 29: 2.0, 16: 3.0, 24: 3.0, 25: 3.0}.toTable(), {13: @[13], 0: @[13, 0], 1: @[13, 1], 2: @[13, 2], 3: @[13, 3], 33: @[13, 33], 4: @[13, 0, 4], 5: @[13, 0, 5], 6: @[13, 0, 6], 7: @[13, 0, 7], 8: @[13, 0, 8], 10: @[13, 0, 10], 11: @[13, 0, 11], 12: @[13, 0, 12], 17: @[13, 0, 17], 19: @[13, 0, 19], 21: @[13, 0, 21], 31: @[13, 0, 31], 30: @[13, 1, 30], 9: @[13, 2, 9], 27: @[13, 2, 27], 28: @[13, 2, 28], 32: @[13, 2, 32], 14: @[13, 33, 14], 15: @[13, 33, 15], 18: @[13, 33, 18], 20: @[13, 33, 20], 22: @[13, 33, 22], 23: @[13, 33, 23], 26: @[13, 33, 26], 29: @[13, 33, 29], 16: @[13, 0, 5, 16], 24: @[13, 0, 31, 24], 25: @[13, 0, 31, 25]}.toTable()),
    #             14: ({14: 0.0, 32: 1.0, 33: 1.0, 2: 2.0, 8: 2.0, 15: 2.0, 18: 2.0, 20: 2.0, 22: 2.0, 23: 2.0, 29: 2.0, 30: 2.0, 31: 2.0, 9: 2.0, 13: 2.0, 19: 2.0, 26: 2.0, 27: 2.0, 28: 2.0, 0: 3.0, 1: 3.0, 3: 3.0, 7: 3.0, 25: 3.0, 24: 3.0, 4: 4.0, 5: 4.0, 6: 4.0, 10: 4.0, 11: 4.0, 12: 4.0, 17: 4.0, 21: 4.0, 16: 5.0}.toTable(), {14: @[14], 32: @[14, 32], 33: @[14, 33], 2: @[14, 32, 2], 8: @[14, 32, 8], 15: @[14, 32, 15], 18: @[14, 32, 18], 20: @[14, 32, 20], 22: @[14, 32, 22], 23: @[14, 32, 23], 29: @[14, 32, 29], 30: @[14, 32, 30], 31: @[14, 32, 31], 9: @[14, 33, 9], 13: @[14, 33, 13], 19: @[14, 33, 19], 26: @[14, 33, 26], 27: @[14, 33, 27], 28: @[14, 33, 28], 0: @[14, 32, 2, 0], 1: @[14, 32, 2, 1], 3: @[14, 32, 2, 3], 7: @[14, 32, 2, 7], 25: @[14, 32, 23, 25], 24: @[14, 32, 31, 24], 4: @[14, 32, 2, 0, 4], 5: @[14, 32, 2, 0, 5], 6: @[14, 32, 2, 0, 6], 10: @[14, 32, 2, 0, 10], 11: @[14, 32, 2, 0, 11], 12: @[14, 32, 2, 0, 12], 17: @[14, 32, 2, 0, 17], 21: @[14, 32, 2, 0, 21], 16: @[14, 32, 2, 0, 5, 16]}.toTable()),
    #             15: ({15: 0.0, 32: 1.0, 33: 1.0, 2: 2.0, 8: 2.0, 14: 2.0, 18: 2.0, 20: 2.0, 22: 2.0, 23: 2.0, 29: 2.0, 30: 2.0, 31: 2.0, 9: 2.0, 13: 2.0, 19: 2.0, 26: 2.0, 27: 2.0, 28: 2.0, 0: 3.0, 1: 3.0, 3: 3.0, 7: 3.0, 25: 3.0, 24: 3.0, 4: 4.0, 5: 4.0, 6: 4.0, 10: 4.0, 11: 4.0, 12: 4.0, 17: 4.0, 21: 4.0, 16: 5.0}.toTable(), {15: @[15], 32: @[15, 32], 33: @[15, 33], 2: @[15, 32, 2], 8: @[15, 32, 8], 14: @[15, 32, 14], 18: @[15, 32, 18], 20: @[15, 32, 20], 22: @[15, 32, 22], 23: @[15, 32, 23], 29: @[15, 32, 29], 30: @[15, 32, 30], 31: @[15, 32, 31], 9: @[15, 33, 9], 13: @[15, 33, 13], 19: @[15, 33, 19], 26: @[15, 33, 26], 27: @[15, 33, 27], 28: @[15, 33, 28], 0: @[15, 32, 2, 0], 1: @[15, 32, 2, 1], 3: @[15, 32, 2, 3], 7: @[15, 32, 2, 7], 25: @[15, 32, 23, 25], 24: @[15, 32, 31, 24], 4: @[15, 32, 2, 0, 4], 5: @[15, 32, 2, 0, 5], 6: @[15, 32, 2, 0, 6], 10: @[15, 32, 2, 0, 10], 11: @[15, 32, 2, 0, 11], 12: @[15, 32, 2, 0, 12], 17: @[15, 32, 2, 0, 17], 21: @[15, 32, 2, 0, 21], 16: @[15, 32, 2, 0, 5, 16]}.toTable()),
    #             16: ({16: 0.0, 5: 1.0, 6: 1.0, 0: 2.0, 10: 2.0, 4: 2.0, 1: 3.0, 2: 3.0, 3: 3.0, 7: 3.0, 8: 3.0, 11: 3.0, 12: 3.0, 13: 3.0, 17: 3.0, 19: 3.0, 21: 3.0, 31: 3.0, 30: 4.0, 9: 4.0, 27: 4.0, 28: 4.0, 32: 4.0, 33: 4.0, 24: 4.0, 25: 4.0, 23: 5.0, 14: 5.0, 15: 5.0, 18: 5.0, 20: 5.0, 22: 5.0, 29: 5.0, 26: 5.0}.toTable(), {16: @[16], 5: @[16, 5], 6: @[16, 6], 0: @[16, 5, 0], 10: @[16, 5, 10], 4: @[16, 6, 4], 1: @[16, 5, 0, 1], 2: @[16, 5, 0, 2], 3: @[16, 5, 0, 3], 7: @[16, 5, 0, 7], 8: @[16, 5, 0, 8], 11: @[16, 5, 0, 11], 12: @[16, 5, 0, 12], 13: @[16, 5, 0, 13], 17: @[16, 5, 0, 17], 19: @[16, 5, 0, 19], 21: @[16, 5, 0, 21], 31: @[16, 5, 0, 31], 30: @[16, 5, 0, 1, 30], 9: @[16, 5, 0, 2, 9], 27: @[16, 5, 0, 2, 27], 28: @[16, 5, 0, 2, 28], 32: @[16, 5, 0, 2, 32], 33: @[16, 5, 0, 8, 33], 24: @[16, 5, 0, 31, 24], 25: @[16, 5, 0, 31, 25], 23: @[16, 5, 0, 2, 27, 23], 14: @[16, 5, 0, 2, 32, 14], 15: @[16, 5, 0, 2, 32, 15], 18: @[16, 5, 0, 2, 32, 18], 20: @[16, 5, 0, 2, 32, 20], 22: @[16, 5, 0, 2, 32, 22], 29: @[16, 5, 0, 2, 32, 29], 26: @[16, 5, 0, 8, 33, 26]}.toTable()),
    #             17: ({17: 0.0, 0: 1.0, 1: 1.0, 2: 2.0, 3: 2.0, 4: 2.0, 5: 2.0, 6: 2.0, 7: 2.0, 8: 2.0, 10: 2.0, 11: 2.0, 12: 2.0, 13: 2.0, 19: 2.0, 21: 2.0, 31: 2.0, 30: 2.0, 9: 3.0, 27: 3.0, 28: 3.0, 32: 3.0, 16: 3.0, 33: 3.0, 24: 3.0, 25: 3.0, 23: 4.0, 14: 4.0, 15: 4.0, 18: 4.0, 20: 4.0, 22: 4.0, 29: 4.0, 26: 4.0}.toTable(), {17: @[17], 0: @[17, 0], 1: @[17, 1], 2: @[17, 0, 2], 3: @[17, 0, 3], 4: @[17, 0, 4], 5: @[17, 0, 5], 6: @[17, 0, 6], 7: @[17, 0, 7], 8: @[17, 0, 8], 10: @[17, 0, 10], 11: @[17, 0, 11], 12: @[17, 0, 12], 13: @[17, 0, 13], 19: @[17, 0, 19], 21: @[17, 0, 21], 31: @[17, 0, 31], 30: @[17, 1, 30], 9: @[17, 0, 2, 9], 27: @[17, 0, 2, 27], 28: @[17, 0, 2, 28], 32: @[17, 0, 2, 32], 16: @[17, 0, 5, 16], 33: @[17, 0, 8, 33], 24: @[17, 0, 31, 24], 25: @[17, 0, 31, 25], 23: @[17, 0, 2, 27, 23], 14: @[17, 0, 2, 32, 14], 15: @[17, 0, 2, 32, 15], 18: @[17, 0, 2, 32, 18], 20: @[17, 0, 2, 32, 20], 22: @[17, 0, 2, 32, 22], 29: @[17, 0, 2, 32, 29], 26: @[17, 0, 8, 33, 26]}.toTable()),
    #             18: ({18: 0.0, 32: 1.0, 33: 1.0, 2: 2.0, 8: 2.0, 14: 2.0, 15: 2.0, 20: 2.0, 22: 2.0, 23: 2.0, 29: 2.0, 30: 2.0, 31: 2.0, 9: 2.0, 13: 2.0, 19: 2.0, 26: 2.0, 27: 2.0, 28: 2.0, 0: 3.0, 1: 3.0, 3: 3.0, 7: 3.0, 25: 3.0, 24: 3.0, 4: 4.0, 5: 4.0, 6: 4.0, 10: 4.0, 11: 4.0, 12: 4.0, 17: 4.0, 21: 4.0, 16: 5.0}.toTable(), {18: @[18], 32: @[18, 32], 33: @[18, 33], 2: @[18, 32, 2], 8: @[18, 32, 8], 14: @[18, 32, 14], 15: @[18, 32, 15], 20: @[18, 32, 20], 22: @[18, 32, 22], 23: @[18, 32, 23], 29: @[18, 32, 29], 30: @[18, 32, 30], 31: @[18, 32, 31], 9: @[18, 33, 9], 13: @[18, 33, 13], 19: @[18, 33, 19], 26: @[18, 33, 26], 27: @[18, 33, 27], 28: @[18, 33, 28], 0: @[18, 32, 2, 0], 1: @[18, 32, 2, 1], 3: @[18, 32, 2, 3], 7: @[18, 32, 2, 7], 25: @[18, 32, 23, 25], 24: @[18, 32, 31, 24], 4: @[18, 32, 2, 0, 4], 5: @[18, 32, 2, 0, 5], 6: @[18, 32, 2, 0, 6], 10: @[18, 32, 2, 0, 10], 11: @[18, 32, 2, 0, 11], 12: @[18, 32, 2, 0, 12], 17: @[18, 32, 2, 0, 17], 21: @[18, 32, 2, 0, 21], 16: @[18, 32, 2, 0, 5, 16]}.toTable()),
    #             19: ({19: 0.0, 0: 1.0, 1: 1.0, 33: 1.0, 2: 2.0, 3: 2.0, 4: 2.0, 5: 2.0, 6: 2.0, 7: 2.0, 8: 2.0, 10: 2.0, 11: 2.0, 12: 2.0, 13: 2.0, 17: 2.0, 21: 2.0, 31: 2.0, 30: 2.0, 9: 2.0, 14: 2.0, 15: 2.0, 18: 2.0, 20: 2.0, 22: 2.0, 23: 2.0, 26: 2.0, 27: 2.0, 28: 2.0, 29: 2.0, 32: 2.0, 16: 3.0, 24: 3.0, 25: 3.0}.toTable(), {19: @[19], 0: @[19, 0], 1: @[19, 1], 33: @[19, 33], 2: @[19, 0, 2], 3: @[19, 0, 3], 4: @[19, 0, 4], 5: @[19, 0, 5], 6: @[19, 0, 6], 7: @[19, 0, 7], 8: @[19, 0, 8], 10: @[19, 0, 10], 11: @[19, 0, 11], 12: @[19, 0, 12], 13: @[19, 0, 13], 17: @[19, 0, 17], 21: @[19, 0, 21], 31: @[19, 0, 31], 30: @[19, 1, 30], 9: @[19, 33, 9], 14: @[19, 33, 14], 15: @[19, 33, 15], 18: @[19, 33, 18], 20: @[19, 33, 20], 22: @[19, 33, 22], 23: @[19, 33, 23], 26: @[19, 33, 26], 27: @[19, 33, 27], 28: @[19, 33, 28], 29: @[19, 33, 29], 32: @[19, 33, 32], 16: @[19, 0, 5, 16], 24: @[19, 0, 31, 24], 25: @[19, 0, 31, 25]}.toTable()),
    #             20: ({20: 0.0, 32: 1.0, 33: 1.0, 2: 2.0, 8: 2.0, 14: 2.0, 15: 2.0, 18: 2.0, 22: 2.0, 23: 2.0, 29: 2.0, 30: 2.0, 31: 2.0, 9: 2.0, 13: 2.0, 19: 2.0, 26: 2.0, 27: 2.0, 28: 2.0, 0: 3.0, 1: 3.0, 3: 3.0, 7: 3.0, 25: 3.0, 24: 3.0, 4: 4.0, 5: 4.0, 6: 4.0, 10: 4.0, 11: 4.0, 12: 4.0, 17: 4.0, 21: 4.0, 16: 5.0}.toTable(), {20: @[20], 32: @[20, 32], 33: @[20, 33], 2: @[20, 32, 2], 8: @[20, 32, 8], 14: @[20, 32, 14], 15: @[20, 32, 15], 18: @[20, 32, 18], 22: @[20, 32, 22], 23: @[20, 32, 23], 29: @[20, 32, 29], 30: @[20, 32, 30], 31: @[20, 32, 31], 9: @[20, 33, 9], 13: @[20, 33, 13], 19: @[20, 33, 19], 26: @[20, 33, 26], 27: @[20, 33, 27], 28: @[20, 33, 28], 0: @[20, 32, 2, 0], 1: @[20, 32, 2, 1], 3: @[20, 32, 2, 3], 7: @[20, 32, 2, 7], 25: @[20, 32, 23, 25], 24: @[20, 32, 31, 24], 4: @[20, 32, 2, 0, 4], 5: @[20, 32, 2, 0, 5], 6: @[20, 32, 2, 0, 6], 10: @[20, 32, 2, 0, 10], 11: @[20, 32, 2, 0, 11], 12: @[20, 32, 2, 0, 12], 17: @[20, 32, 2, 0, 17], 21: @[20, 32, 2, 0, 21], 16: @[20, 32, 2, 0, 5, 16]}.toTable()),
    #             21: ({21: 0.0, 0: 1.0, 1: 1.0, 2: 2.0, 3: 2.0, 4: 2.0, 5: 2.0, 6: 2.0, 7: 2.0, 8: 2.0, 10: 2.0, 11: 2.0, 12: 2.0, 13: 2.0, 17: 2.0, 19: 2.0, 31: 2.0, 30: 2.0, 9: 3.0, 27: 3.0, 28: 3.0, 32: 3.0, 16: 3.0, 33: 3.0, 24: 3.0, 25: 3.0, 23: 4.0, 14: 4.0, 15: 4.0, 18: 4.0, 20: 4.0, 22: 4.0, 29: 4.0, 26: 4.0}.toTable(), {21: @[21], 0: @[21, 0], 1: @[21, 1], 2: @[21, 0, 2], 3: @[21, 0, 3], 4: @[21, 0, 4], 5: @[21, 0, 5], 6: @[21, 0, 6], 7: @[21, 0, 7], 8: @[21, 0, 8], 10: @[21, 0, 10], 11: @[21, 0, 11], 12: @[21, 0, 12], 13: @[21, 0, 13], 17: @[21, 0, 17], 19: @[21, 0, 19], 31: @[21, 0, 31], 30: @[21, 1, 30], 9: @[21, 0, 2, 9], 27: @[21, 0, 2, 27], 28: @[21, 0, 2, 28], 32: @[21, 0, 2, 32], 16: @[21, 0, 5, 16], 33: @[21, 0, 8, 33], 24: @[21, 0, 31, 24], 25: @[21, 0, 31, 25], 23: @[21, 0, 2, 27, 23], 14: @[21, 0, 2, 32, 14], 15: @[21, 0, 2, 32, 15], 18: @[21, 0, 2, 32, 18], 20: @[21, 0, 2, 32, 20], 22: @[21, 0, 2, 32, 22], 29: @[21, 0, 2, 32, 29], 26: @[21, 0, 8, 33, 26]}.toTable()),
    #             22: ({22: 0.0, 32: 1.0, 33: 1.0, 2: 2.0, 8: 2.0, 14: 2.0, 15: 2.0, 18: 2.0, 20: 2.0, 23: 2.0, 29: 2.0, 30: 2.0, 31: 2.0, 9: 2.0, 13: 2.0, 19: 2.0, 26: 2.0, 27: 2.0, 28: 2.0, 0: 3.0, 1: 3.0, 3: 3.0, 7: 3.0, 25: 3.0, 24: 3.0, 4: 4.0, 5: 4.0, 6: 4.0, 10: 4.0, 11: 4.0, 12: 4.0, 17: 4.0, 21: 4.0, 16: 5.0}.toTable(), {22: @[22], 32: @[22, 32], 33: @[22, 33], 2: @[22, 32, 2], 8: @[22, 32, 8], 14: @[22, 32, 14], 15: @[22, 32, 15], 18: @[22, 32, 18], 20: @[22, 32, 20], 23: @[22, 32, 23], 29: @[22, 32, 29], 30: @[22, 32, 30], 31: @[22, 32, 31], 9: @[22, 33, 9], 13: @[22, 33, 13], 19: @[22, 33, 19], 26: @[22, 33, 26], 27: @[22, 33, 27], 28: @[22, 33, 28], 0: @[22, 32, 2, 0], 1: @[22, 32, 2, 1], 3: @[22, 32, 2, 3], 7: @[22, 32, 2, 7], 25: @[22, 32, 23, 25], 24: @[22, 32, 31, 24], 4: @[22, 32, 2, 0, 4], 5: @[22, 32, 2, 0, 5], 6: @[22, 32, 2, 0, 6], 10: @[22, 32, 2, 0, 10], 11: @[22, 32, 2, 0, 11], 12: @[22, 32, 2, 0, 12], 17: @[22, 32, 2, 0, 17], 21: @[22, 32, 2, 0, 21], 16: @[22, 32, 2, 0, 5, 16]}.toTable()),
    #             23: ({23: 0.0, 25: 1.0, 27: 1.0, 29: 1.0, 32: 1.0, 33: 1.0, 24: 2.0, 31: 2.0, 2: 2.0, 26: 2.0, 8: 2.0, 14: 2.0, 15: 2.0, 18: 2.0, 20: 2.0, 22: 2.0, 30: 2.0, 9: 2.0, 13: 2.0, 19: 2.0, 28: 2.0, 0: 3.0, 1: 3.0, 3: 3.0, 7: 3.0, 4: 4.0, 5: 4.0, 6: 4.0, 10: 4.0, 11: 4.0, 12: 4.0, 17: 4.0, 21: 4.0, 16: 5.0}.toTable(), {23: @[23], 25: @[23, 25], 27: @[23, 27], 29: @[23, 29], 32: @[23, 32], 33: @[23, 33], 24: @[23, 25, 24], 31: @[23, 25, 31], 2: @[23, 27, 2], 26: @[23, 29, 26], 8: @[23, 32, 8], 14: @[23, 32, 14], 15: @[23, 32, 15], 18: @[23, 32, 18], 20: @[23, 32, 20], 22: @[23, 32, 22], 30: @[23, 32, 30], 9: @[23, 33, 9], 13: @[23, 33, 13], 19: @[23, 33, 19], 28: @[23, 33, 28], 0: @[23, 25, 31, 0], 1: @[23, 27, 2, 1], 3: @[23, 27, 2, 3], 7: @[23, 27, 2, 7], 4: @[23, 25, 31, 0, 4], 5: @[23, 25, 31, 0, 5], 6: @[23, 25, 31, 0, 6], 10: @[23, 25, 31, 0, 10], 11: @[23, 25, 31, 0, 11], 12: @[23, 25, 31, 0, 12], 17: @[23, 25, 31, 0, 17], 21: @[23, 25, 31, 0, 21], 16: @[23, 25, 31, 0, 5, 16]}.toTable()),
    #             24: ({24: 0.0, 25: 1.0, 27: 1.0, 31: 1.0, 23: 2.0, 2: 2.0, 33: 2.0, 0: 2.0, 28: 2.0, 32: 2.0, 29: 3.0, 1: 3.0, 3: 3.0, 7: 3.0, 8: 3.0, 9: 3.0, 13: 3.0, 14: 3.0, 15: 3.0, 18: 3.0, 19: 3.0, 20: 3.0, 22: 3.0, 26: 3.0, 30: 3.0, 4: 3.0, 5: 3.0, 6: 3.0, 10: 3.0, 11: 3.0, 12: 3.0, 17: 3.0, 21: 3.0, 16: 4.0}.toTable(), {24: @[24], 25: @[24, 25], 27: @[24, 27], 31: @[24, 31], 23: @[24, 25, 23], 2: @[24, 27, 2], 33: @[24, 27, 33], 0: @[24, 31, 0], 28: @[24, 31, 28], 32: @[24, 31, 32], 29: @[24, 25, 23, 29], 1: @[24, 27, 2, 1], 3: @[24, 27, 2, 3], 7: @[24, 27, 2, 7], 8: @[24, 27, 2, 8], 9: @[24, 27, 2, 9], 13: @[24, 27, 2, 13], 14: @[24, 27, 33, 14], 15: @[24, 27, 33, 15], 18: @[24, 27, 33, 18], 19: @[24, 27, 33, 19], 20: @[24, 27, 33, 20], 22: @[24, 27, 33, 22], 26: @[24, 27, 33, 26], 30: @[24, 27, 33, 30], 4: @[24, 31, 0, 4], 5: @[24, 31, 0, 5], 6: @[24, 31, 0, 6], 10: @[24, 31, 0, 10], 11: @[24, 31, 0, 11], 12: @[24, 31, 0, 12], 17: @[24, 31, 0, 17], 21: @[24, 31, 0, 21], 16: @[24, 31, 0, 5, 16]}.toTable()),
    #             25: ({25: 0.0, 23: 1.0, 24: 1.0, 31: 1.0, 27: 2.0, 29: 2.0, 32: 2.0, 33: 2.0, 0: 2.0, 28: 2.0, 2: 3.0, 26: 3.0, 8: 3.0, 14: 3.0, 15: 3.0, 18: 3.0, 20: 3.0, 22: 3.0, 30: 3.0, 9: 3.0, 13: 3.0, 19: 3.0, 1: 3.0, 3: 3.0, 4: 3.0, 5: 3.0, 6: 3.0, 7: 3.0, 10: 3.0, 11: 3.0, 12: 3.0, 17: 3.0, 21: 3.0, 16: 4.0}.toTable(), {25: @[25], 23: @[25, 23], 24: @[25, 24], 31: @[25, 31], 27: @[25, 23, 27], 29: @[25, 23, 29], 32: @[25, 23, 32], 33: @[25, 23, 33], 0: @[25, 31, 0], 28: @[25, 31, 28], 2: @[25, 23, 27, 2], 26: @[25, 23, 29, 26], 8: @[25, 23, 32, 8], 14: @[25, 23, 32, 14], 15: @[25, 23, 32, 15], 18: @[25, 23, 32, 18], 20: @[25, 23, 32, 20], 22: @[25, 23, 32, 22], 30: @[25, 23, 32, 30], 9: @[25, 23, 33, 9], 13: @[25, 23, 33, 13], 19: @[25, 23, 33, 19], 1: @[25, 31, 0, 1], 3: @[25, 31, 0, 3], 4: @[25, 31, 0, 4], 5: @[25, 31, 0, 5], 6: @[25, 31, 0, 6], 7: @[25, 31, 0, 7], 10: @[25, 31, 0, 10], 11: @[25, 31, 0, 11], 12: @[25, 31, 0, 12], 17: @[25, 31, 0, 17], 21: @[25, 31, 0, 21], 16: @[25, 31, 0, 5, 16]}.toTable()),
    #             26: ({26: 0.0, 29: 1.0, 33: 1.0, 23: 2.0, 32: 2.0, 8: 2.0, 9: 2.0, 13: 2.0, 14: 2.0, 15: 2.0, 18: 2.0, 19: 2.0, 20: 2.0, 22: 2.0, 27: 2.0, 28: 2.0, 30: 2.0, 31: 2.0, 25: 3.0, 2: 3.0, 0: 3.0, 1: 3.0, 3: 3.0, 24: 3.0, 7: 4.0, 4: 4.0, 5: 4.0, 6: 4.0, 10: 4.0, 11: 4.0, 12: 4.0, 17: 4.0, 21: 4.0, 16: 5.0}.toTable(), {26: @[26], 29: @[26, 29], 33: @[26, 33], 23: @[26, 29, 23], 32: @[26, 29, 32], 8: @[26, 33, 8], 9: @[26, 33, 9], 13: @[26, 33, 13], 14: @[26, 33, 14], 15: @[26, 33, 15], 18: @[26, 33, 18], 19: @[26, 33, 19], 20: @[26, 33, 20], 22: @[26, 33, 22], 27: @[26, 33, 27], 28: @[26, 33, 28], 30: @[26, 33, 30], 31: @[26, 33, 31], 25: @[26, 29, 23, 25], 2: @[26, 29, 32, 2], 0: @[26, 33, 8, 0], 1: @[26, 33, 13, 1], 3: @[26, 33, 13, 3], 24: @[26, 33, 27, 24], 7: @[26, 29, 32, 2, 7], 4: @[26, 33, 8, 0, 4], 5: @[26, 33, 8, 0, 5], 6: @[26, 33, 8, 0, 6], 10: @[26, 33, 8, 0, 10], 11: @[26, 33, 8, 0, 11], 12: @[26, 33, 8, 0, 12], 17: @[26, 33, 8, 0, 17], 21: @[26, 33, 8, 0, 21], 16: @[26, 33, 8, 0, 5, 16]}.toTable()),
    #             27: ({27: 0.0, 2: 1.0, 23: 1.0, 24: 1.0, 33: 1.0, 0: 2.0, 1: 2.0, 3: 2.0, 7: 2.0, 8: 2.0, 9: 2.0, 13: 2.0, 28: 2.0, 32: 2.0, 25: 2.0, 29: 2.0, 31: 2.0, 14: 2.0, 15: 2.0, 18: 2.0, 19: 2.0, 20: 2.0, 22: 2.0, 26: 2.0, 30: 2.0, 4: 3.0, 5: 3.0, 6: 3.0, 10: 3.0, 11: 3.0, 12: 3.0, 17: 3.0, 21: 3.0, 16: 4.0}.toTable(), {27: @[27], 2: @[27, 2], 23: @[27, 23], 24: @[27, 24], 33: @[27, 33], 0: @[27, 2, 0], 1: @[27, 2, 1], 3: @[27, 2, 3], 7: @[27, 2, 7], 8: @[27, 2, 8], 9: @[27, 2, 9], 13: @[27, 2, 13], 28: @[27, 2, 28], 32: @[27, 2, 32], 25: @[27, 23, 25], 29: @[27, 23, 29], 31: @[27, 24, 31], 14: @[27, 33, 14], 15: @[27, 33, 15], 18: @[27, 33, 18], 19: @[27, 33, 19], 20: @[27, 33, 20], 22: @[27, 33, 22], 26: @[27, 33, 26], 30: @[27, 33, 30], 4: @[27, 2, 0, 4], 5: @[27, 2, 0, 5], 6: @[27, 2, 0, 6], 10: @[27, 2, 0, 10], 11: @[27, 2, 0, 11], 12: @[27, 2, 0, 12], 17: @[27, 2, 0, 17], 21: @[27, 2, 0, 21], 16: @[27, 2, 0, 5, 16]}.toTable()),
    #             28: ({28: 0.0, 2: 1.0, 31: 1.0, 33: 1.0, 0: 2.0, 1: 2.0, 3: 2.0, 7: 2.0, 8: 2.0, 9: 2.0, 13: 2.0, 27: 2.0, 32: 2.0, 24: 2.0, 25: 2.0, 14: 2.0, 15: 2.0, 18: 2.0, 19: 2.0, 20: 2.0, 22: 2.0, 23: 2.0, 26: 2.0, 29: 2.0, 30: 2.0, 4: 3.0, 5: 3.0, 6: 3.0, 10: 3.0, 11: 3.0, 12: 3.0, 17: 3.0, 21: 3.0, 16: 4.0}.toTable(), {28: @[28], 2: @[28, 2], 31: @[28, 31], 33: @[28, 33], 0: @[28, 2, 0], 1: @[28, 2, 1], 3: @[28, 2, 3], 7: @[28, 2, 7], 8: @[28, 2, 8], 9: @[28, 2, 9], 13: @[28, 2, 13], 27: @[28, 2, 27], 32: @[28, 2, 32], 24: @[28, 31, 24], 25: @[28, 31, 25], 14: @[28, 33, 14], 15: @[28, 33, 15], 18: @[28, 33, 18], 19: @[28, 33, 19], 20: @[28, 33, 20], 22: @[28, 33, 22], 23: @[28, 33, 23], 26: @[28, 33, 26], 29: @[28, 33, 29], 30: @[28, 33, 30], 4: @[28, 2, 0, 4], 5: @[28, 2, 0, 5], 6: @[28, 2, 0, 6], 10: @[28, 2, 0, 10], 11: @[28, 2, 0, 11], 12: @[28, 2, 0, 12], 17: @[28, 2, 0, 17], 21: @[28, 2, 0, 21], 16: @[28, 2, 0, 5, 16]}.toTable()),
    #             29: ({29: 0.0, 23: 1.0, 26: 1.0, 32: 1.0, 33: 1.0, 25: 2.0, 27: 2.0, 2: 2.0, 8: 2.0, 14: 2.0, 15: 2.0, 18: 2.0, 20: 2.0, 22: 2.0, 30: 2.0, 31: 2.0, 9: 2.0, 13: 2.0, 19: 2.0, 28: 2.0, 24: 3.0, 0: 3.0, 1: 3.0, 3: 3.0, 7: 3.0, 4: 4.0, 5: 4.0, 6: 4.0, 10: 4.0, 11: 4.0, 12: 4.0, 17: 4.0, 21: 4.0, 16: 5.0}.toTable(), {29: @[29], 23: @[29, 23], 26: @[29, 26], 32: @[29, 32], 33: @[29, 33], 25: @[29, 23, 25], 27: @[29, 23, 27], 2: @[29, 32, 2], 8: @[29, 32, 8], 14: @[29, 32, 14], 15: @[29, 32, 15], 18: @[29, 32, 18], 20: @[29, 32, 20], 22: @[29, 32, 22], 30: @[29, 32, 30], 31: @[29, 32, 31], 9: @[29, 33, 9], 13: @[29, 33, 13], 19: @[29, 33, 19], 28: @[29, 33, 28], 24: @[29, 23, 25, 24], 0: @[29, 32, 2, 0], 1: @[29, 32, 2, 1], 3: @[29, 32, 2, 3], 7: @[29, 32, 2, 7], 4: @[29, 32, 2, 0, 4], 5: @[29, 32, 2, 0, 5], 6: @[29, 32, 2, 0, 6], 10: @[29, 32, 2, 0, 10], 11: @[29, 32, 2, 0, 11], 12: @[29, 32, 2, 0, 12], 17: @[29, 32, 2, 0, 17], 21: @[29, 32, 2, 0, 21], 16: @[29, 32, 2, 0, 5, 16]}.toTable()),
    #             30: ({30: 0.0, 1: 1.0, 8: 1.0, 32: 1.0, 33: 1.0, 0: 2.0, 2: 2.0, 3: 2.0, 7: 2.0, 13: 2.0, 17: 2.0, 19: 2.0, 21: 2.0, 14: 2.0, 15: 2.0, 18: 2.0, 20: 2.0, 22: 2.0, 23: 2.0, 29: 2.0, 31: 2.0, 9: 2.0, 26: 2.0, 27: 2.0, 28: 2.0, 4: 3.0, 5: 3.0, 6: 3.0, 10: 3.0, 11: 3.0, 12: 3.0, 25: 3.0, 24: 3.0, 16: 4.0}.toTable(), {30: @[30], 1: @[30, 1], 8: @[30, 8], 32: @[30, 32], 33: @[30, 33], 0: @[30, 1, 0], 2: @[30, 1, 2], 3: @[30, 1, 3], 7: @[30, 1, 7], 13: @[30, 1, 13], 17: @[30, 1, 17], 19: @[30, 1, 19], 21: @[30, 1, 21], 14: @[30, 32, 14], 15: @[30, 32, 15], 18: @[30, 32, 18], 20: @[30, 32, 20], 22: @[30, 32, 22], 23: @[30, 32, 23], 29: @[30, 32, 29], 31: @[30, 32, 31], 9: @[30, 33, 9], 26: @[30, 33, 26], 27: @[30, 33, 27], 28: @[30, 33, 28], 4: @[30, 1, 0, 4], 5: @[30, 1, 0, 5], 6: @[30, 1, 0, 6], 10: @[30, 1, 0, 10], 11: @[30, 1, 0, 11], 12: @[30, 1, 0, 12], 25: @[30, 32, 23, 25], 24: @[30, 32, 31, 24], 16: @[30, 1, 0, 5, 16]}.toTable()),
    #             31: ({31: 0.0, 0: 1.0, 24: 1.0, 25: 1.0, 28: 1.0, 32: 1.0, 33: 1.0, 1: 2.0, 2: 2.0, 3: 2.0, 4: 2.0, 5: 2.0, 6: 2.0, 7: 2.0, 8: 2.0, 10: 2.0, 11: 2.0, 12: 2.0, 13: 2.0, 17: 2.0, 19: 2.0, 21: 2.0, 27: 2.0, 23: 2.0, 14: 2.0, 15: 2.0, 18: 2.0, 20: 2.0, 22: 2.0, 29: 2.0, 30: 2.0, 9: 2.0, 26: 2.0, 16: 3.0}.toTable(), {31: @[31], 0: @[31, 0], 24: @[31, 24], 25: @[31, 25], 28: @[31, 28], 32: @[31, 32], 33: @[31, 33], 1: @[31, 0, 1], 2: @[31, 0, 2], 3: @[31, 0, 3], 4: @[31, 0, 4], 5: @[31, 0, 5], 6: @[31, 0, 6], 7: @[31, 0, 7], 8: @[31, 0, 8], 10: @[31, 0, 10], 11: @[31, 0, 11], 12: @[31, 0, 12], 13: @[31, 0, 13], 17: @[31, 0, 17], 19: @[31, 0, 19], 21: @[31, 0, 21], 27: @[31, 24, 27], 23: @[31, 25, 23], 14: @[31, 32, 14], 15: @[31, 32, 15], 18: @[31, 32, 18], 20: @[31, 32, 20], 22: @[31, 32, 22], 29: @[31, 32, 29], 30: @[31, 32, 30], 9: @[31, 33, 9], 26: @[31, 33, 26], 16: @[31, 0, 5, 16]}.toTable()),
    #             32: ({32: 0.0, 2: 1.0, 8: 1.0, 14: 1.0, 15: 1.0, 18: 1.0, 20: 1.0, 22: 1.0, 23: 1.0, 29: 1.0, 30: 1.0, 31: 1.0, 33: 1.0, 0: 2.0, 1: 2.0, 3: 2.0, 7: 2.0, 9: 2.0, 13: 2.0, 27: 2.0, 28: 2.0, 25: 2.0, 26: 2.0, 24: 2.0, 19: 2.0, 4: 3.0, 5: 3.0, 6: 3.0, 10: 3.0, 11: 3.0, 12: 3.0, 17: 3.0, 21: 3.0, 16: 4.0}.toTable(), {32: @[32], 2: @[32, 2], 8: @[32, 8], 14: @[32, 14], 15: @[32, 15], 18: @[32, 18], 20: @[32, 20], 22: @[32, 22], 23: @[32, 23], 29: @[32, 29], 30: @[32, 30], 31: @[32, 31], 33: @[32, 33], 0: @[32, 2, 0], 1: @[32, 2, 1], 3: @[32, 2, 3], 7: @[32, 2, 7], 9: @[32, 2, 9], 13: @[32, 2, 13], 27: @[32, 2, 27], 28: @[32, 2, 28], 25: @[32, 23, 25], 26: @[32, 29, 26], 24: @[32, 31, 24], 19: @[32, 33, 19], 4: @[32, 2, 0, 4], 5: @[32, 2, 0, 5], 6: @[32, 2, 0, 6], 10: @[32, 2, 0, 10], 11: @[32, 2, 0, 11], 12: @[32, 2, 0, 12], 17: @[32, 2, 0, 17], 21: @[32, 2, 0, 21], 16: @[32, 2, 0, 5, 16]}.toTable()),
    #             33: ({33: 0.0, 8: 1.0, 9: 1.0, 13: 1.0, 14: 1.0, 15: 1.0, 18: 1.0, 19: 1.0, 20: 1.0, 22: 1.0, 23: 1.0, 26: 1.0, 27: 1.0, 28: 1.0, 29: 1.0, 30: 1.0, 31: 1.0, 32: 1.0, 0: 2.0, 2: 2.0, 1: 2.0, 3: 2.0, 25: 2.0, 24: 2.0, 4: 3.0, 5: 3.0, 6: 3.0, 7: 3.0, 10: 3.0, 11: 3.0, 12: 3.0, 17: 3.0, 21: 3.0, 16: 4.0}.toTable(), {33: @[33], 8: @[33, 8], 9: @[33, 9], 13: @[33, 13], 14: @[33, 14], 15: @[33, 15], 18: @[33, 18], 19: @[33, 19], 20: @[33, 20], 22: @[33, 22], 23: @[33, 23], 26: @[33, 26], 27: @[33, 27], 28: @[33, 28], 29: @[33, 29], 30: @[33, 30], 31: @[33, 31], 32: @[33, 32], 0: @[33, 8, 0], 2: @[33, 8, 2], 1: @[33, 13, 1], 3: @[33, 13, 3], 25: @[33, 23, 25], 24: @[33, 27, 24], 4: @[33, 8, 0, 4], 5: @[33, 8, 0, 5], 6: @[33, 8, 0, 6], 7: @[33, 8, 0, 7], 10: @[33, 8, 0, 10], 11: @[33, 8, 0, 11], 12: @[33, 8, 0, 12], 17: @[33, 8, 0, 17], 21: @[33, 8, 0, 21], 16: @[33, 8, 0, 5, 16]}.toTable()),
    #         }.toTable()
    #     for (source, dists, paths) in allPairsDijkstra(g=dkarate):
    #         doAssert nxRet[source].dists == dists
    #         if nxRet[source].paths != paths:
    #             echo("nxRet[source].paths: ", nxRet[source].paths)
    #             echo("paths: ", paths)
    #             break
    #     doAssert nxRet[source].paths == paths