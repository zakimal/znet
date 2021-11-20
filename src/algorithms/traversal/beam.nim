import algorithm
import sequtils
import tables

import ../../graph.nim
from ./bfs.nim import genericBfsEdges

iterator bfsBeamEdges*(
    g: Graph,
    source: Node,
    value: proc(node: Node): float,
    width: int = -1
): Edge =
    var widthUsing = width
    if width == -1:
        widthUsing = g.len()
    var successors: ref proc(node: Node): iterator: Node = new proc(node: Node): iterator: Node

    successors[] =
        proc(node: Node): iterator: Node =
            return iterator: Node =
                var nbrsWithValues: seq[tuple[value: float, node: Node]] = newSeq[tuple[value: float, node: Node]]()
                for nbr in g.neighborIterator(node):
                    nbrsWithValues.add((-value(nbr), nbr))
                nbrsWithValues.sort()
                var ret: seq[Node] = @[]
                for i in 0..<min(widthUsing, len(nbrsWithValues)):
                    ret.add(nbrsWithValues[i].node)
                for n in ret:
                    yield n
    for edge in g.genericBfsEdges(source=source, neighbors=successors):
        yield edge

when isMainModule:
    var edges = @[(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6), (0, 7), (0, 8), (0, 10), (0, 11), (0, 12), (0, 13), (0, 17), (0, 19), (0, 21), (0, 31), (1, 2), (1, 3), (1, 7), (1, 13), (1, 17), (1, 19), (1, 21), (1, 30), (2, 3), (2, 7), (2, 8), (2, 9), (2, 13), (2, 27), (2, 28), (2, 32), (3, 7), (3, 12), (3, 13), (4, 6), (4, 10), (5, 6), (5, 10), (5, 16), (6, 16), (8, 30), (8, 32), (8, 33), (9, 33), (13, 33), (14, 32), (14, 33), (15, 32), (15, 33), (18, 32), (18, 33), (19, 33), (20, 32), (20, 33), (22, 32), (22, 33), (23, 25), (23, 27), (23, 29), (23, 32), (23, 33), (24, 25), (24, 27), (24, 31), (25, 31), (26, 29), (26, 33), (27, 33), (28, 31), (28, 33), (29, 32), (29, 33), (30, 32), (30, 33), (31, 32), (31, 33), (32, 33)]
    var G = newGraph()
    G.addEdgesFrom(edges)
    let source = 0
    let width = 5
    let getCentrality: proc(node: Node): float =
        proc(node: Node): float =
            let eigenCent: Table[Node, float] = {0: 0.3554834941851944, 1: 0.26595387045450253, 2: 0.3171893899684448, 3: 0.21117407832057064, 4: 0.07596645881657382, 5: 0.07948057788594248, 6: 0.07948057788594248, 7: 0.17095511498035437, 8: 0.22740509147166055, 10: 0.07596645881657382, 11: 0.05285416945233647, 12: 0.08425192086558088, 13: 0.22646969838808154, 17: 0.09239675666845955, 19: 0.14791134007618673, 21: 0.09239675666845955, 31: 0.19103626979791707, 30: 0.17476027834493094, 9: 0.10267519030637762, 27: 0.13347932684333313, 28: 0.1310792562722122, 32: 0.308651047733696, 16: 0.023634794260596875, 33: 0.37337121301323506, 14: 0.10140627846270836, 15: 0.10140627846270836, 18: 0.10140627846270836, 20: 0.10140627846270836, 22: 0.10140627846270836, 23: 0.1501232869172679, 25: 0.05920820250279011, 29: 0.13496528673866573, 24: 0.05705373563802807, 26: 0.07558192219009328}.toTable()
            return eigenCent[node]
    # for edge in G.bfsBeamEdges(source, getCentrality, width):
    #     echo(edge)
    doAssert G.bfsBeamEdges(source, getCentrality, width).toSeq() == @[(0, 2), (0, 1), (0, 8), (0, 13), (0, 3), (2, 32), (1, 30), (8, 33), (3, 7), (32, 31), (31, 28), (31, 25), (25, 23), (25, 24), (23, 29), (23, 27), (29, 26)]