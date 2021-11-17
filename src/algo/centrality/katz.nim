import sets
import deques
import sequtils
import strformat
import tables
import system
import math

import ../../graph
import ../../readwrite

proc katzCentrality(
    dg: ref DirectedGraph,
    alpha: float = 0.1,
    beta: float = 1.0,
    maxIter: int = 1000,
    tol: float = 1.0e-6,
    nstart: Table[Node, float] = initTable[Node, float](),
    normalized: bool = true
): Table[Node, float] =
    if len(dg) == 0:
        return initTable[Node, float]()

    let N = dg.numberOfNodes()

    var x: Table[Node, float] = initTable[Node, float]()
    if len(nstart) == 0:
        for node in dg.nodes():
            x[node] = 0.0
    else:
        x = nstart

    var b: Table[Node, float] = initTable[Node, float]()
    for node in dg.nodes():
        b[node] = beta

    var currentIter: int = 0
    while currentIter < maxIter:
        var xlast = x;
        x = initTable[Node, float]()
        for key in xlast.keys():
            x[key] = 0.0
        for n in x.keys():
            for nbr in dg.neighbors(n):
                x[nbr] += xlast[n]
        for n in x.keys():
            x[n] = alpha * x[n] + b[n]

        var err: float = 0.0
        for n in x.keys():
            err += abs(x[n] - xlast[n])

        var s: float = 0.0
        if err < float(N) * tol:
            if normalized:
                for val in x.values():
                    s += val * val
                if s != 0.0:
                    s = 1.0 / sqrt(s)
                else:
                    s = 1.0
            else:
                s = 1.0
            for n in x.keys():
                x[n] *= s
            return x
        else:
            currentIter += 1
    return x

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

    let ret = G.katzCentrality()
    let trueKatzs = {0: 0.1304033914867838, 1: 0.14344373063546217, 2: 0.1577881036990084, 3: 0.17356691406890923, 4: 0.14344373063546217, 5: 0.14344373063546217, 6: 0.1721324767625546, 7: 0.19092360547580015, 8: 0.159222541005363, 10: 0.1721324767625546, 11: 0.14344373063546217, 12: 0.1608004220423531, 13: 0.19092360547580015, 17: 0.1577881036990084, 19: 0.1577881036990084, 21: 0.1577881036990084, 31: 0.18675069694822305, 30: 0.1606700186508663, 9: 0.14618220185668462, 27: 0.17226288015404137, 28: 0.14618220185668462, 32: 0.2907369693876142, 16: 0.16196101222658546, 33: 0.398406094409375, 14: 0.1304033914867838, 15: 0.1304033914867838, 18: 0.1304033914867838, 20: 0.1304033914867838, 22: 0.1304033914867838, 23: 0.1304033914867838, 25: 0.15648406978414053, 29: 0.15648406978414053, 24: 0.1304033914867838, 26: 0.1304033914867838}.toTable()
    for (node, val) in ret.pairs():
        echo(node)
        echo(fmt"got {val}, expected {trueKatzs[node]}, diff={trueKatzs[node] - val}")