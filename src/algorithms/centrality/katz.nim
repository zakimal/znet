import tables
import strformat
import math

import ../../graph.nim
import ../../exception.nim

proc katzCentrality(
    g: Graph,
    alpha: float = 0.1,
    beta: float = 1.0,
    maxIter: int = 1000,
    tol: float = 1e-06,
    nstart: TableRef[Node, float] = nil,
    normalized: bool = true
): Table[Node, float] =
    if len(g) == 0:
        return newTable[Node, float]()[]

    let nnodes = g.numberOfNodes()

    var x: TableRef[Node, float] = newTable[Node, float]()
    if nstart == nil:
        for node in g.nodes():
            x[node] = 0.0
    else:
        x = nstart

    var b: TableRef[Node, float] = newTable[Node, float]()
    for node in g.nodes():
        b[node] = beta

    for i in 0..<maxIter:
        var xlast = x[]
        for node in xlast.keys():
            x[node] = 0.0
        for n in x.keys():
            for nbr in g.neighbors(n):
                x[nbr] += xlast[n]
        for n in x.keys():
            x[n] = alpha * x[n] + b[n]

        var err: float = 0.0
        for n in x.keys():
            err += abs(x[n] - xlast[n])
        if err < float(nnodes) * tol:
            var s: float
            if normalized:
                try:
                    for v in x.values():
                        s += v * v
                    s = sqrt(s)
                    s = 1.0 / s
                except FloatDivByZeroDefect:
                    s = 1.0
            else:
                s = 1.0
            for n in x.keys():
                x[n] *= s
            return x[]
    raise newZNetPowerIterationFailedConvergence(maxIter)

proc katzCentrality(
    dg: DirectedGraph,
    alpha: float = 0.1,
    beta: float = 1.0,
    maxIter: int = 1000,
    tol: float = 1e-06,
    nstart: TableRef[Node, float] = nil,
    normalized: bool = true
): Table[Node, float] =
    if len(dg) == 0:
        return newTable[Node, float]()[]

    let nnodes = dg.numberOfNodes()

    var x: TableRef[Node, float] = newTable[Node, float]()
    if nstart == nil:
        for node in dg.nodes():
            x[node] = 0.0
    else:
        x = nstart

    var b: TableRef[Node, float] = newTable[Node, float]()
    for node in dg.nodes():
        b[node] = beta

    for i in 0..<maxIter:
        var xlast = x[]
        for node in xlast.keys():
            x[node] = 0.0
        for n in x.keys():
            for nbr in dg.neighbors(n):
                x[nbr] += xlast[n]
        for n in x.keys():
            x[n] = alpha * x[n] + b[n]

        var err: float = 0.0
        for n in x.keys():
            err += abs(x[n] - xlast[n])
        if err < float(nnodes) * tol:
            var s: float
            if normalized:
                try:
                    for v in x.values():
                        s += v * v
                    s = sqrt(s)
                    s = 1.0 / s
                except FloatDivByZeroDefect:
                    s = 1.0
            else:
                s = 1.0
            for n in x.keys():
                x[n] *= s
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
    let ret0 = katzCentrality(G)
    let nxRet0: Table[Node, float]
        = {
            0: 0.32132459695923254,
            1: 0.23548425319449465,
            2: 0.26576588481542884,
            3: 0.19491320249172545,
            4: 0.12190440564948415,
            5: 0.13097227932864922,
            6: 0.13097227932864922,
            7: 0.16623305202689406,
            8: 0.20071781096610813,
            10: 0.12190440564948415,
            11: 0.09661674181730144,
            12: 0.11610805572826274,
            13: 0.1993736805731885,
            17: 0.12016515915440101,
            19: 0.15330578770069545,
            21: 0.12016515915440101,
            31: 0.1938016017020055,
            30: 0.16875361802889588,
            9: 0.12420150029869699,
            27: 0.15190166582081863,
            28: 0.14358165473533302,
            32: 0.2750851434662392,
            16: 0.09067874388549632,
            33: 0.33140639752189366,
            14: 0.12513342642033798,
            15: 0.12513342642033798,
            18: 0.12513342642033798,
            20: 0.12513342642033798,
            22: 0.12513342642033798,
            23: 0.16679064809871577,
            25: 0.11156461274962844,
            29: 0.1531060365504152,
            24: 0.11021106930146939,
            26: 0.11293552094158045
        }.toTable()
    for (node, val) in ret0.pairs():
        if 1e-15 < abs(val - nxRet0[node]):
            echo(fmt"node {node}: got {val}, expected {nxRet0[node]}")
            echo(fmt"diff={val - nxRet0[node]}")

    var DG = newDirectedGraph()
    DG.addEdgesFrom(edges)
    let ret1 = katzCentrality(DG)
    let nxRet1: Table[Node, float]
        = {
            0: 0.1304033914867838,
            1: 0.14344373063546217,
            2: 0.1577881036990084,
            3: 0.17356691406890923,
            4: 0.14344373063546217,
            5: 0.14344373063546217,
            6: 0.1721324767625546,
            7: 0.19092360547580015,
            8: 0.159222541005363,
            10: 0.1721324767625546,
            11: 0.14344373063546217,
            12: 0.1608004220423531,
            13: 0.19092360547580015,
            17: 0.1577881036990084,
            19: 0.1577881036990084,
            21: 0.1577881036990084,
            31: 0.18675069694822305,
            30: 0.1606700186508663,
            9: 0.14618220185668462,
            27: 0.17226288015404137,
            28: 0.14618220185668462,
            32: 0.2907369693876142,
            16: 0.16196101222658546,
            33: 0.398406094409375,
            14: 0.1304033914867838,
            15: 0.1304033914867838,
            18: 0.1304033914867838,
            20: 0.1304033914867838,
            22: 0.1304033914867838,
            23: 0.1304033914867838,
            25: 0.15648406978414053,
            29: 0.15648406978414053,
            24: 0.1304033914867838,
            26: 0.1304033914867838
        }.toTable()
    for (node, val) in ret1.pairs():
        if 1e-15 < abs(val - nxRet1[node]):
            echo(fmt"node {node}: got {val}, expected {nxRet1[node]}")
            echo(fmt"diff={val - nxRet1[node]}")