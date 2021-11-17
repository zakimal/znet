import sets
import deques
import sequtils
import strformat
import tables
import system

import ../../graph
import ../../readwrite

proc pagerankPowerIteration(
    dg: ref DirectedGraph,
    alpha: float = 0.85,
    personalization: Table[Node, float] = initTable[Node, float](),
    maxIter: int = 100,
    tol: float = 1.0e-6,
    nstart: Table[Node, float] = initTable[Node, float](),
    dangling: Table[Node, int] = initTable[Node, int]()
): Table[Node, float] =
    var ret: Table[Node, float] = initTable[Node, float]()
    if len(dg) == 0:
        return ret

    let N = dg.numberOfNodes()

    var x: Table[Node, float] = initTable[Node, float]()
    if len(nstart) == 0:
        for node in dg.nodes():
            x[node] = 1.0 / float(N)
    else:
        var s: float = 0
        for val in nstart.values():
            s += val
        for (node, val) in nstart.pairs():
            x[node] = val / float(s)

    var p: Table[Node, float] = initTable[Node, float]()
    if len(personalization) == 0:
        for node in dg.nodes():
            p[node] = 1.0 / float(N)
    else:
        var s: float = 0
        for val in personalization.values():
            s += val
        for (node, val) in personalization.pairs():
            x[node] = val / float(s)

    var danglingWeights: Table[Node, float] = initTable[Node, float]()
    if len(danglingWeights) == 0:
        danglingWeights = p
    else:
        var s: float = 0
        for val in dangling.values():
            s += float(val)
        for (node, val) in dangling.pairs():
            x[node] = float(val) / float(s)
    var danglingNodes: seq[Node] = @[]
    for node in dg.nodes():
        if dg.outdegree(node) == 0:
            danglingNodes.add(node)

    var currentIter: int = 0
    while currentIter < maxIter:
        var xlast = x;
        x = initTable[Node, float]()
        for key in xlast.keys():
            x[key] = 0.0

        var dangleSum: float = 0.0
        for node in danglingNodes:
            dangleSum += xlast[node]
        dangleSum *= alpha

        for n in x.keys():
            for nbr in dg.neighbors(n):
                x[nbr] += alpha * xlast[n] / float(dg.outdegree(n))
            x[n] += dangleSum * danglingWeights.getOrDefault(n, 0.0) + (1.0 - alpha) * p.getOrDefault(n, 0.0)

        var err: float = 0.0
        for n in x.keys():
            err += abs(x[n] - xlast[n])
        if err < float(N) * tol:
            return x
        else:
            currentIter += 1
    return x


proc pagerank*(
    dg: ref DirectedGraph,
    alpha: float = 0.85,
    personalization: Table[Node, float] = initTable[Node, float](),
    maxIter: int = 100,
    tol: float = 1.0e-6,
    nstart: Table[Node, float] = initTable[Node, float](),
    dangling: Table[Node, int] = initTable[Node, int]()
): Table[Node, float] =
    return pagerankPowerIteration(
        dg, alpha, personalization, maxIter, tol, nstart, dangling
    )

when isMainModule:
    var G = newDirectedGraph()
    G.addEdge((0, 1))
    G.addEdge((0, 2))
    G.addEdge((0, 3))
    G.addEdge((0, 4))
    G.addEdge((0, 5))
    G.addEdge((0, 6))
    G.addEdge((0, 7))
    G.addEdge((0, 8))
    G.addEdge((0, 10))
    G.addEdge((0, 11))
    G.addEdge((0, 12))
    G.addEdge((0, 13))
    G.addEdge((0, 17))
    G.addEdge((0, 19))
    G.addEdge((0, 21))
    G.addEdge((0, 31))
    G.addEdge((1, 2))
    G.addEdge((1, 3))
    G.addEdge((1, 7))
    G.addEdge((1, 13))
    G.addEdge((1, 17))
    G.addEdge((1, 19))
    G.addEdge((1, 21))
    G.addEdge((1, 30))
    G.addEdge((2, 3))
    G.addEdge((2, 7))
    G.addEdge((2, 8))
    G.addEdge((2, 9))
    G.addEdge((2, 13))
    G.addEdge((2, 27))
    G.addEdge((2, 28))
    G.addEdge((2, 32))
    G.addEdge((3, 7))
    G.addEdge((3, 12))
    G.addEdge((3, 13))
    G.addEdge((4, 6))
    G.addEdge((4, 10))
    G.addEdge((5, 6))
    G.addEdge((5, 10))
    G.addEdge((5, 16))
    G.addEdge((6, 16))
    G.addEdge((8, 30))
    G.addEdge((8, 32))
    G.addEdge((8, 33))
    G.addEdge((9, 33))
    G.addEdge((13, 33))
    G.addEdge((14, 32))
    G.addEdge((14, 33))
    G.addEdge((15, 32))
    G.addEdge((15, 33))
    G.addEdge((18, 32))
    G.addEdge((18, 33))
    G.addEdge((19, 33))
    G.addEdge((20, 32))
    G.addEdge((20, 33))
    G.addEdge((22, 32))
    G.addEdge((22, 33))
    G.addEdge((23, 25))
    G.addEdge((23, 27))
    G.addEdge((23, 29))
    G.addEdge((23, 32))
    G.addEdge((23, 33))
    G.addEdge((24, 25))
    G.addEdge((24, 27))
    G.addEdge((24, 31))
    G.addEdge((25, 31))
    G.addEdge((26, 29))
    G.addEdge((26, 33))
    G.addEdge((27, 33))
    G.addEdge((28, 31))
    G.addEdge((28, 33))
    G.addEdge((29, 32))
    G.addEdge((29, 33))
    G.addEdge((30, 32))
    G.addEdge((30, 33))
    G.addEdge((31, 32))
    G.addEdge((31, 33))
    G.addEdge((32, 33))

    echo(G.pagerank())