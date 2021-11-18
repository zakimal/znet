import tables

import ./graph.nim

proc relabelNodes*(g: Graph, mapping: Table[int, int]): Graph =
    var relabeledGraph = newGraph()
    for edge in g.edges():
        let oldu = edge.u
        let oldv = edge.v
        relabeledGraph.addEdge(
            mapping.getOrDefault(oldu, oldu), mapping.getOrDefault(oldv, oldv)
        )
    return relabeledGraph

when isMainModule:
    var G = newGraph()
    for i in 0..3:
        G += (i, i + 1)
    for edge in G.edges():
        echo(edge)
    echo()
    var mapping = {1: 99, 2: 100}.toTable()
    var H = G.relabelNodes(mapping)
    for edge in H.edges():
        echo(edge)