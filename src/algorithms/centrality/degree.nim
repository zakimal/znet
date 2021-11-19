import tables
import strformat

import ../../graph.nim
import ../../exception.nim

proc degreeCentrality(g: Graph): Table[Node, float] =
    var ret: Table[Node, float] = initTable[Node, float]()
    if len(g) <= 1:
        for node in g.nodes():
            ret[node] = 1.0
        return ret
    let s = 1.0 / float(len(g) - 1)
    for node in g.nodes():
        ret[node] = float(g.degree(node)) * s
    return ret

proc degreeCentrality(dg: DirectedGraph): Table[Node, float] =
    let g = dg.toUndirected()
    var ret: Table[Node, float] = initTable[Node, float]()
    if len(g) <= 1:
        for node in g.nodes():
            ret[node] = 1.0
        return ret
    let s = 1.0 / float(len(g) - 1)
    for node in g.nodes():
        ret[node] = float(g.degree(node)) * s
    return ret

proc indegreeCentrality(dg: DirectedGraph): Table[Node, float] =
    if not dg.isDirected:
        var e = ZNetError()
        e.msg = fmt"indegreeCentrality is not implemented for undirected graph"
        raise e
    var ret: Table[Node, float] = initTable[Node, float]()
    if len(dg) <= 1:
        for node in dg.nodes():
            ret[node] = 1.0
        return ret
    let s = 1.0 / float(len(dg) - 1)
    for node in dg.nodes():
        ret[node] = float(dg.indegree(node)) * s
    return ret

proc outdegreeCentrality(dg: DirectedGraph): Table[Node, float] =
    if not dg.isDirected:
        var e = ZNetError()
        e.msg = fmt"indegreeCentrality is not implemented for undirected graph"
        raise e
    var ret: Table[Node, float] = initTable[Node, float]()
    if len(dg) <= 1:
        for node in dg.nodes():
            ret[node] = 1.0
        return ret
    let s = 1.0 / float(len(dg) - 1)
    for node in dg.nodes():
        ret[node] = float(dg.outdegree(node)) * s
    return ret

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
    let ret0 = degreeCentrality(G)
    let nxRet0: Table[Node, float]
        = {
            0: 0.48484848484848486,
            1: 0.2727272727272727,
            2: 0.30303030303030304,
            3: 0.18181818181818182,
            4: 0.09090909090909091,
            5: 0.12121212121212122,
            6: 0.12121212121212122,
            7: 0.12121212121212122,
            8: 0.15151515151515152,
            9: 0.06060606060606061,
            10: 0.09090909090909091,
            11: 0.030303030303030304,
            12: 0.06060606060606061,
            13: 0.15151515151515152,
            14: 0.06060606060606061,
            15: 0.06060606060606061,
            16: 0.06060606060606061,
            17: 0.06060606060606061,
            18: 0.06060606060606061,
            19: 0.09090909090909091,
            20: 0.06060606060606061,
            21: 0.06060606060606061,
            22: 0.06060606060606061,
            23: 0.15151515151515152,
            24: 0.09090909090909091,
            25: 0.09090909090909091,
            26: 0.06060606060606061,
            27: 0.12121212121212122,
            28: 0.09090909090909091,
            29: 0.12121212121212122,
            30: 0.12121212121212122,
            31: 0.18181818181818182,
            32: 0.36363636363636365,
            33: 0.5151515151515151
        }.toTable()
    for (node, val) in ret0.pairs():
        if val != nxRet0[node]:
            echo(fmt"node {node}: got {val}, expected {nxRet0[node]}")
            echo(fmt"diff={val - nxRet0[node]}")

    var DG = newDirectedGraph()
    DG.addEdgesFrom(edges)
    let ret1 = degreeCentrality(DG)
    let nxRet1
        = {
            0: 0.48484848484848486,
            1: 0.2727272727272727,
            2: 0.30303030303030304,
            3: 0.18181818181818182,
            4: 0.09090909090909091,
            5: 0.12121212121212122,
            6: 0.12121212121212122,
            7: 0.12121212121212122,
            8: 0.15151515151515152,
            10: 0.09090909090909091,
            11: 0.030303030303030304,
            12: 0.06060606060606061,
            13: 0.15151515151515152,
            17: 0.06060606060606061,
            19: 0.09090909090909091,
            21: 0.06060606060606061,
            31: 0.18181818181818182,
            30: 0.12121212121212122,
            9: 0.06060606060606061,
            27: 0.12121212121212122,
            28: 0.09090909090909091,
            32: 0.36363636363636365,
            16: 0.06060606060606061,
            33: 0.5151515151515151,
            14: 0.06060606060606061,
            15: 0.06060606060606061,
            18: 0.06060606060606061,
            20: 0.06060606060606061,
            22: 0.06060606060606061,
            23: 0.15151515151515152,
            25: 0.09090909090909091,
            29: 0.12121212121212122,
            24: 0.09090909090909091,
            26: 0.06060606060606061
        }.toTable()
    for (node, val) in ret1.pairs():
        if val != nxRet1[node]:
            echo(fmt"node {node}: got {val}, expected {nxRet1[node]}")
            echo(fmt"diff={val - nxRet1[node]}")

    let ret2 = indegreeCentrality(DG)
    let nxRet2
        = {
            0: 0.0,
            1: 0.030303030303030304,
            2: 0.06060606060606061,
            3: 0.09090909090909091,
            4: 0.030303030303030304,
            5: 0.030303030303030304,
            6: 0.09090909090909091,
            7: 0.12121212121212122,
            8: 0.06060606060606061,
            10: 0.09090909090909091,
            11: 0.030303030303030304,
            12: 0.06060606060606061,
            13: 0.12121212121212122,
            17: 0.06060606060606061,
            19: 0.06060606060606061,
            21: 0.06060606060606061,
            31: 0.12121212121212122,
            30: 0.06060606060606061,
            9: 0.030303030303030304,
            27: 0.09090909090909091,
            28: 0.030303030303030304,
            32: 0.33333333333333337,
            16: 0.06060606060606061,
            33: 0.5151515151515151,
            14: 0.0,
            15: 0.0,
            18: 0.0,
            20: 0.0,
            22: 0.0,
            23: 0.0,
            25: 0.06060606060606061,
            29: 0.06060606060606061,
            24: 0.0,
            26: 0.0
        }.toTable()
    for (node, val) in ret2.pairs():
        if val != nxRet2[node]:
            echo(fmt"node {node}: got {val}, expected {nxRet2[node]}")
            echo(fmt"diff={val - nxRet2[node]}")

    let ret3 = outdegreeCentrality(DG)
    let nxRet3
        = {
            0: 0.48484848484848486,
            1: 0.24242424242424243,
            2: 0.24242424242424243,
            3: 0.09090909090909091,
            4: 0.06060606060606061,
            5: 0.09090909090909091,
            6: 0.030303030303030304,
            7: 0.0,
            8: 0.09090909090909091,
            10: 0.0,
            11: 0.0,
            12: 0.0,
            13: 0.030303030303030304,
            17: 0.0,
            19: 0.030303030303030304,
            21: 0.0,
            31: 0.06060606060606061,
            30: 0.06060606060606061,
            9: 0.030303030303030304,
            27: 0.030303030303030304,
            28: 0.06060606060606061,
            32: 0.030303030303030304,
            16: 0.0,
            33: 0.0,
            14: 0.06060606060606061,
            15: 0.06060606060606061,
            18: 0.06060606060606061,
            20: 0.06060606060606061,
            22: 0.06060606060606061,
            23: 0.15151515151515152,
            25: 0.030303030303030304,
            29: 0.06060606060606061,
            24: 0.09090909090909091,
            26: 0.06060606060606061
        }.toTable()
    for (node, val) in ret3.pairs():
        if val != nxRet3[node]:
            echo(fmt"node {node}: got {val}, expected {nxRet3[node]}")
            echo(fmt"diff={val - nxRet3[node]}")