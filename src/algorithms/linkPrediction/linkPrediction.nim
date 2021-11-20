import tables
import strformat
import sequtils
import sets
import math

import ../../graph.nim
import ../../exception.nim


proc applyPrediction(
    g: Graph,
    applying: proc (u, v: Node): float,
    ebunch: seq[Edge] = @[]
): seq[tuple[u, v: Node, prediction: float]] =
    var ebunchUsing = ebunch
    if len(ebunchUsing) == 0:
        ebunchUsing = g.nonEdges().toSeq()
    var ret: seq[tuple[u, v: Node, prediction: float]] = @[]
    for edge in ebunchUsing:
        ret.add((edge.u, edge.v, applying(edge.u, edge.v)))
    return ret

proc resourceAllocationIndex*(
    g: Graph,
    ebunch: seq[Edge] = @[]
): seq[tuple[u, v: Node, prediction: float]] =
    if g.isDirected:
        var e = ZNetError()
        e.msg = "resourceAllocationIndex is not implemented for directed graph"
        raise e
    var applying: proc (u, v: Node): float =
        proc (u, v: Node): float =
            var s = 0.0
            for n in g.commonNeighbors(u, v):
                s += 1.0 / float(g.degree(n))
            return s
    return applyPrediction(g, applying, ebunch)

proc jaccardCoefficient*(
    g: Graph,
    ebunch: seq[Edge] = @[]
): seq[tuple[u, v: Node, prediction: float]] =
    if g.isDirected:
        var e = ZNetError()
        e.msg = "jaccardCoefficient is not implemented for directed graph"
        raise e
    var applying: proc (u, v: Node): float =
        proc (u, v: Node): float =
            var unionSize = len(g.neighborSet(u) + g.neighborSet(v))
            if unionSize == 0:
                return 0.0
            return float(len(g.commonNeighbors(u, v).toSeq())) / float(unionSize)
    return applyPrediction(g, applying, ebunch)

proc adamicAdarIndex*(
    g: Graph,
    ebunch: seq[Edge] = @[]
): seq[tuple[u, v: Node, prediction: float]] =
    if g.isDirected:
        var e = ZNetError()
        e.msg = "adamicAdarIndex is not implemented for directed graph"
        raise e
    var applying: proc (u, v: Node): float =
        proc (u, v: Node): float =
            var s = 0.0
            for n in g.commonNeighbors(u, v):
                s += 1.0 / log(float(g.degree(n)), E)
            return s
    return applyPrediction(g, applying, ebunch)

# TODO:
# proc commonNeighborCentrality*(
#     g: Graph,
#     ebunch: seq[Edge] = @[],
#     alpha: float = 0.8
# ): seq[tuple[u, v: Node, prediction: float]]

proc prefentialAttachment*(
    g: Graph,
    ebunch: seq[Edge] = @[]
): seq[tuple[u, v: Node, prediction: float]] =
    if g.isDirected:
        var e = ZNetError()
        e.msg = "prefentialAttachment is not implemented for directed graph"
        raise e
    var applying: proc (u, v: Node): float =
        proc (u, v: Node): float =
           return float(g.degree(u) * g.degree(v))
    return applyPrediction(g, applying, ebunch)

proc cnSoundarajanHopcroft*(
    g: Graph,
    ebunch: seq[Edge] = @[],
    community: Table[Node, int]
): seq[tuple[u, v: Node, prediction: float]] =
    if g.isDirected:
        var e = ZNetError()
        e.msg = "cnSoundarajanHopcroft is not implemented for directed graph"
        raise e
    var applying: proc (u, v: Node): float =
        proc (u, v: Node): float =
            let cu = community[u]
            let cv = community[v]
            let conbrs = g.commonNeighbors(u, v).toSeq()
            var neighbors = 0
            for w in conbrs:
                if cu == cv:
                    if community[w] == cu:
                        neighbors += 1
            return float(neighbors + len(conbrs))
    return applyPrediction(g, applying, ebunch)

proc raIndexSoundarajanHopcroft*(
    g: Graph,
    ebunch: seq[Edge] = @[],
    community: Table[Node, int]
): seq[tuple[u, v: Node, prediction: float]] =
    if g.isDirected:
        var e = ZNetError()
        e.msg = "raIndexSoundarajanHopcroft is not implemented for directed graph"
        raise e
    var applying: proc (u, v: Node): float =
        proc (u, v: Node): float =
            let cu = community[u]
            let cv = community[v]
            if cu != cv:
                return 0.0
            var conbrs = g.commonNeighbors(u, v)
            var s = 0.0
            for w in conbrs:
                if community[w] == cu:
                    s += 1.0 / float(g.degree(w))
            return s
    return applyPrediction(g, applying, ebunch)

proc withinInterCluster*(
    g: Graph,
    ebunch: seq[Edge] = @[],
    community: Table[Node, int],
    delta: float = 0.001
): seq[tuple[u, v: Node, prediction: float]] =
    if g.isDirected:
        var e = ZNetError()
        e.msg = "withinInterCluster is not implemented for directed graph"
        raise e

    if delta <= 0.0:
        var e = ZNetAlgorithmError()
        e.msg = "delta must be greater than zero"
        raise e

    var applying: proc (u, v: Node): float =
        proc (u, v: Node): float =
            let cu = community[u]
            let cv = community[v]
            if cu != cv:
                return 0.0
            var conbrs = g.commonNeighbors(u, v).toSeq().toHashSet()
            var within: HashSet[Node] = initHashSet[Node]()
            for w in conbrs:
                if community[w] == cu:
                    within.incl(w)
            var inter: HashSet[Node] = conbrs - within
            return float(len(within)) / (float(len(inter)) + delta)
    return applyPrediction(g, applying, ebunch)



when isMainModule:
    block resourceAllocationIndex:
        var G = newGraph()
        var edges = @[(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        G.addEdgesFrom(edges)

        var preds = G.resourceAllocationIndex(@[(0, 1), (2, 3)])
        for (u, v, p) in preds:
            echo(fmt"({u}, {v}) -> {p}")

        try:
            var DG = newDirectedGraph()
            DG.addEdgesFrom(edges)
            discard DG.resourceAllocationIndex(@[(0, 1), (2, 3)])
        except ZNetError as e:
            echo(e.msg)

    block jaccardCoefficient:
        var G = newGraph()
        var edges = @[(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        G.addEdgesFrom(edges)
        var preds = G.jaccardCoefficient(@[(0, 1), (2, 3)])
        for (u, v, p) in preds:
            echo(fmt"({u}, {v}) -> {p}")

        try:
            var DG = newDirectedGraph()
            DG.addEdgesFrom(edges)
            discard DG.jaccardCoefficient(@[(0, 1), (2, 3)])
        except ZNetError as e:
            echo(e.msg)

    block adamicAdarIndex:
        var G = newGraph()
        var edges = @[(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        G.addEdgesFrom(edges)
        var preds = G.adamicAdarIndex(@[(0, 1), (2, 3)])
        for (u, v, p) in preds:
            echo(fmt"({u}, {v}) -> {p}")

        try:
            var DG = newDirectedGraph()
            DG.addEdgesFrom(edges)
            discard DG.adamicAdarIndex(@[(0, 1), (2, 3)])
        except ZNetError as e:
            echo(e.msg)

    block prefentialAttachment:
        var G = newGraph()
        var edges = @[(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)]
        G.addEdgesFrom(edges)
        var preds = G.prefentialAttachment(@[(0, 1), (2, 3)])
        for (u, v, p) in preds:
            echo(fmt"({u}, {v}) -> {p}")

        try:
            var DG = newDirectedGraph()
            DG.addEdgesFrom(edges)
            discard DG.prefentialAttachment(@[(0, 1), (2, 3)])
        except ZNetError as e:
            echo(e.msg)

    block cnSoundarajanHopcroft:
        var G = newGraph()
        var edges = @[(0, 1), (1, 2)]
        var community: Table[Node, int] = {0: 0, 1: 0, 2: 0}.toTable()
        G.addEdgesFrom(edges)
        var preds = G.cnSoundarajanHopcroft(@[(0, 2)], community)
        for (u, v, p) in preds:
            echo(fmt"({u}, {v}) -> {p}")

        try:
            var DG = newDirectedGraph()
            DG.addEdgesFrom(edges)
            discard DG.cnSoundarajanHopcroft(@[(0, 2)], community)
        except ZNetError as e:
            echo(e.msg)

    block raIndexSoundarajanHopcroft:
        var G = newGraph()
        var edges = @[(0, 1), (0, 2), (1, 3), (2, 3)]
        var community: Table[Node, int] = {0: 0, 1: 0, 2: 1, 3: 0}.toTable()
        G.addEdgesFrom(edges)
        var preds = G.raIndexSoundarajanHopcroft(@[(0, 3)], community)
        for (u, v, p) in preds:
            echo(fmt"({u}, {v}) -> {p}")

        try:
            var DG = newDirectedGraph()
            DG.addEdgesFrom(edges)
            discard DG.raIndexSoundarajanHopcroft(@[(0, 3)], community)
        except ZNetError as e:
            echo(e.msg)

    block withinInterCluster:
        var G = newGraph()
        var edges = @[(0, 1), (0, 2), (0, 3), (1, 4), (2, 4), (3, 4)]
        var community: Table[Node, int] = {0: 0, 1: 1, 2: 0, 3: 0, 4: 0}.toTable()
        G.addEdgesFrom(edges)
        var preds = G.withinInterCluster(@[(0, 4)], community)
        for (u, v, p) in preds:
            echo(fmt"({u}, {v}) -> {p}")
        preds = G.withinInterCluster(@[(0, 4)], community, delta=0.5)
        for (u, v, p) in preds:
            echo(fmt"({u}, {v}) -> {p}")

        try:
            var DG = newDirectedGraph()
            DG.addEdgesFrom(edges)
            discard DG.withinInterCluster(@[(0, 4)], community, delta=0.5)
        except ZNetError as e:
            echo(e.msg)