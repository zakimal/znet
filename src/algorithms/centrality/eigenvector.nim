import tables
import strformat
import math

import ../../graph.nim
import ../../exception.nim

proc eigenvectorCentrality(
    g: Graph,
    maxIter: int = 100,
    tol: float = 1e-06,
    nstart: TableRef[Node, float] = nil
): Table[Node, float] =
    if len(g) == 0:
        var e = ZNetPointlessConcept()
        e.msg = "cannot compute centrality for the null graph"
        raise e

    var initialVector: TableRef[Node, float] = newTable[Node, float]()
    if nstart == nil:
        for node in g.nodes():
            initialVector[node] = 1.0
    else:
        initialVector = nstart

    var initialVectorSum: float = 0.0
    for val in initialVector.values():
        if val == 0.0:
            var e = ZNetError()
            e.msg = "initial vector cannot have all zero values"
            raise e
        initialVectorSum += val

    var x: TableRef[Node, float] = newTable[Node, float]()
    for (node, val) in initialVector.pairs():
        x[node] = val / initialVectorSum

    let nnodes = g.numberOfNodes()
    for i in 0..<maxIter:
        var xlast = x[]
        for n in x.keys():
            for nbr in g.neighbors(n):
                x[nbr] += xlast[n]

        var norm: float = 0.0
        for z in x.values():
            norm += z * z
        norm = sqrt(norm)
        if norm == 0.0:
            norm = 1.0

        for (k, v) in x.pairs():
            x[k] = v / norm

        var err: float = 0.0
        for n in x.keys():
            err += abs(x[n] - xlast[n])
        if err < float(nnodes) * tol:
            return x[]
    raise newZNetPowerIterationFailedConvergence(maxIter)

proc eigenvectorCentrality(
    dg: DirectedGraph,
    maxIter: int = 100,
    tol: float = 1e-06,
    nstart: TableRef[Node, float] = nil
): Table[Node, float] =
    if len(dg) == 0:
        var e = ZNetPointlessConcept()
        e.msg = "cannot compute centrality for the null graph"
        raise e

    var initialVector: TableRef[Node, float] = newTable[Node, float]()
    if nstart == nil:
        for node in dg.nodes():
            initialVector[node] = 1.0
    else:
        initialVector = nstart

    var initialVectorSum: float = 0.0
    for val in initialVector.values():
        if val == 0.0:
            var e = ZNetError()
            e.msg = "initial vector cannot have all zero values"
            raise e
        initialVectorSum += val

    var x: TableRef[Node, float] = newTable[Node, float]()
    for (node, val) in initialVector.pairs():
        x[node] = val / initialVectorSum

    let nnodes = dg.numberOfNodes()
    for i in 0..<maxIter:
        var xlast = x[]
        for n in x.keys():
            for nbr in dg.neighbors(n):
                x[nbr] += xlast[n]

        var norm: float = 0.0
        for z in x.values():
            norm += z * z
        norm = sqrt(norm)
        if norm == 0.0:
            norm = 1.0

        for (k, v) in x.pairs():
            x[k] = v / norm

        var err: float = 0.0
        for n in x.keys():
            err += abs(x[n] - xlast[n])
        if err < float(nnodes) * tol:
            return x[]
    raise newZNetPowerIterationFailedConvergence(maxIter)

when isMainModule:
    let edges = @[
        (0, 1), (0, 2), (0, 3), (0, 4), (0, 5),
        (0, 6), (0, 7), (0, 8), (0, 10), (0, 11),
        (0, 12), (0, 13), (0, 17), (0, 19), (0, 21),
        (0, 31), (1, 2), (1, 3), (1, 7), (1, 13),
        (1, 17), (1, 19), (1, 21), (1, 30), (2, 3),
        (2, 7), (2, 8), (2, 9), (2, 13), (2, 27),
        (2, 28), (2, 32), (3, 7), (3, 12), (3, 13),
        (4, 6), (4, 10), (5, 6), (5, 10), (5, 16),
        (6, 16), (8, 30), (8, 32), (8, 33), (9, 33),
        (13, 33), (14, 32), (14, 33), (15, 32),
        (15, 33), (18, 32), (18, 33), (19, 33),
        (20, 32), (20, 33), (22, 32), (22, 33),
        (23, 25), (23, 27), (23, 29), (23, 32),
        (23, 33), (24, 25), (24, 27), (24, 31),
        (25, 31), (26, 29), (26, 33), (27, 33),
        (28, 31), (28, 33), (29, 32), (29, 33),
        (30, 32), (30, 33), (31, 32), (31, 33),
        (32, 33)
    ]
    var G = newGraph()
    G.addEdgesFrom(edges)
    let ret0 = eigenvectorCentrality(G)
    let nxRet0: Table[Node, float]
        = {
            0: 0.3554834941851944,
            1: 0.26595387045450253,
            2: 0.3171893899684448,
            3: 0.21117407832057064,
            4: 0.07596645881657382,
            5: 0.07948057788594248,
            6: 0.07948057788594248,
            7: 0.17095511498035437,
            8: 0.22740509147166055,
            10: 0.07596645881657382,
            11: 0.05285416945233647,
            12: 0.08425192086558088,
            13: 0.22646969838808154,
            17: 0.09239675666845955,
            19: 0.14791134007618673,
            21: 0.09239675666845955,
            31: 0.19103626979791707,
            30: 0.17476027834493094,
            9: 0.10267519030637762,
            27: 0.13347932684333313,
            28: 0.1310792562722122,
            32: 0.308651047733696,
            16: 0.023634794260596875,
            33: 0.37337121301323506,
            14: 0.10140627846270836,
            15: 0.10140627846270836,
            18: 0.10140627846270836,
            20: 0.10140627846270836,
            22: 0.10140627846270836,
            23: 0.1501232869172679,
            25: 0.05920820250279011,
            29: 0.13496528673866573,
            24: 0.05705373563802807,
            26: 0.07558192219009328
        }.toTable()
    for (node, val) in ret0.pairs():
        if 1e-15 < abs(val - nxRet0[node]):
            echo(fmt"node {node}: got {val}, expected {nxRet0[node]}")
            echo(fmt"diff={val - nxRet0[node]}")

    var DG = newDirectedGraph()
    DG.addEdgesFrom(edges)
    try:
        discard eigenvectorCentrality(DG)
    except ZNetPowerIterationFailedConvergence as e:
        doAssert e.msg == "power iteration failed to converge within 100 iterations"

    let ret1 = eigenvectorCentrality(DG, maxIter=500)
    let nxRet1: Table[Node, float]
        = {
            0: 5.572922000776945e-14,
            1: 2.4019293823348602e-11,
            2: 5.188167465843299e-09,
            3: 7.488255042367173e-07,
            4: 2.4019293823348602e-11,
            5: 2.4019293823348602e-11,
            6: 1.0352315637863233e-08,
            7: 8.124756720968379e-05,
            8: 7.436613560646967e-07,
            10: 1.0352315637863233e-08,
            11: 2.4019293823348602e-11,
            12: 8.049876572474091e-05,
            13: 8.124756720968379e-05,
            17: 5.188167465843299e-09,
            19: 5.188167465843299e-09,
            21: 5.188167465843299e-09,
            31: 7.976548064787868e-05,
            30: 7.976543272074943e-05,
            9: 7.436373925000932e-07,
            27: 7.436853196293002e-07,
            28: 7.436373925000932e-07,
            32: 0.013737552442991612,
            16: 1.4872747292709631e-06,
            33: 0.9999056191663537,
            14: 5.572922000776945e-14,
            15: 5.572922000776945e-14,
            18: 5.572922000776945e-14,
            20: 5.572922000776945e-14,
            22: 5.572922000776945e-14,
            23: 5.572922000776945e-14,
            25: 4.798285842668944e-11,
            29: 4.798285842668944e-11,
            24: 5.572922000776945e-14,
            26: 5.572922000776945e-14
        }.toTable()
    for (node, val) in ret1.pairs():
        if 1e-15 < abs(val - nxRet1[node]):
            echo(fmt"node {node}: got {val}, expected {nxRet1[node]}")
            echo(fmt"diff={val - nxRet1[node]}")