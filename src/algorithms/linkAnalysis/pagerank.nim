import tables
import strformat

import ../../graph.nim
import ../../exception.nim

proc pagerank(
    dg: DirectedGraph,
    alpha: float = 0.85,
    personalization: TableRef[Node, float] = nil,
    maxIter: int = 100,
    tol: float = 1.0e-6,
    nstart: TableRef[Node, float] = nil,
    dangling: TableRef[Node, float] = nil,
): Table[Node, float] =
    if dg.len() == 0:
        return initTable[Node, float]()

    let N = dg.numberOfNodes()

    var x: Table[Node, float] = initTable[Node, float]()
    if nstart == nil:
        for node in dg.nodes():
            x[node] = 1.0 / float(N)
    else:
        var s: float = 0
        for val in nstart[].values():
            s += val
        for (node, val) in nstart[].pairs():
            x[node] = val / float(s)

    var p: Table[Node, float] = initTable[Node, float]()
    if personalization == nil:
        for node in dg.nodes():
            p[node] = 1.0 / float(N)
    else:
        var s: float = 0
        for val in personalization[].values():
            s += val
        for (node, val) in personalization[].pairs():
            x[node] = val / float(s)

    var danglingWeights: Table[Node, float] = initTable[Node, float]()
    if dangling == nil:
        danglingWeights = p
    else:
        var s: float = 0
        for val in dangling[].values():
            s += float(val)
        for (node, val) in dangling[].pairs():
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

proc pagerank(
    g: Graph,
    alpha: float = 0.85,
    personalization: TableRef[Node, float] = nil,
    maxIter: int = 100,
    tol: float = 1.0e-6,
    nstart: TableRef[Node, float] = nil,
    dangling: TableRef[Node, float] = nil,
): Table[Node, float] =
    return g.toDirected()
            .pagerank(
                alpha=alpha,
                personalization=personalization,
                maxIter=maxIter,
                tol=tol,
                nstart=nstart,
                dangling=dangling
            )

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
    let ret0 = pagerank(G)
    let nxRet0: Table[Node, float]
        = {
            0: 0.09700181758983709,
            1: 0.05287839103742701,
            2: 0.057078423047636745,
            3: 0.03586064322306479,
            4: 0.021979406974834498,
            5: 0.02911334166344221,
            6: 0.029113341663442212,
            7: 0.024490758039509182,
            8: 0.029765339186167035,
            10: 0.0219794069748345,
            11: 0.009564916863537148,
            12: 0.014645186487916191,
            13: 0.029536314977202986,
            17: 0.014558859774243493,
            19: 0.019604416711937297,
            21: 0.014558859774243493,
            31: 0.03715663592267942,
            30: 0.02458933653429248,
            9: 0.014308950284462801,
            27: 0.025638803528350497,
            28: 0.01957296050943854,
            32: 0.07169213006588289,
            16: 0.016785378110253487,
            33: 0.10091791674871213,
            14: 0.014535161524273827,
            15: 0.014535161524273827,
            18: 0.014535161524273827,
            20: 0.014535161524273827,
            22: 0.014535161524273827,
            23: 0.03152091531163228,
            25: 0.021005628174745786,
            29: 0.02628726283711208,
            24: 0.021075455001162945,
            26: 0.015043395360629756
        }.toTable()
    for (node, val) in ret0.pairs():
        if 1e-15 < abs(val - nxRet0[node]):
            echo(fmt"node {node}: got {val}, expected {nxRet0[node]}")
            echo(fmt"diff={val - nxRet0[node]}")

    var DG = newDirectedGraph()
    DG.addEdgesFrom(edges)
    let ret1 = pagerank(DG)
    let nxRet1
        = {
        0: 0.015060398201356056,
        1: 0.015860478291831532,
        2: 0.017545657516999914,
        3: 0.019409903871309166,
        4: 0.015860478291831532,
        5: 0.015860478291831532,
        6: 0.027095006459620766,
        7: 0.024909454583064414,
        8: 0.01772472464614078,
        10: 0.027095006459620766,
        11: 0.015860478291831532,
        12: 0.02136002900358678,
        13: 0.024909454583064414,
        17: 0.017545657516999914,
        19: 0.017545657516999914,
        21: 0.017545657516999914,
        31: 0.04592580168141822,
        30: 0.02176761579390405,
        9: 0.016924644555665305,
        27: 0.023751994661056028,
        28: 0.016924644555665305,
        32: 0.09548948104425682,
        16: 0.04258589015733158,
        33: 0.2590491773753372,
        14: 0.015060398201356056,
        15: 0.015060398201356056,
        18: 0.015060398201356056,
        20: 0.015060398201356056,
        22: 0.015060398201356056,
        23: 0.015060398201356056,
        25: 0.02188774830674678,
        29: 0.02402129521468138,
        24: 0.015060398201356056,
        26: 0.015060398201356056
        }.toTable()
    for (node, val) in ret1.pairs():
        if 1e-15 < abs(val - nxRet1[node]):
            echo(fmt"node {node}: got {val}, expected {nxRet1[node]}")
            echo(fmt"diff={val - nxRet1[node]}")