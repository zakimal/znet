import tables

import ../../graph
import ../../readwrite

proc indegreeCentrality*(
    dg: ref DirectedGraph
): Table[Node, float] =
    var centrality = initTable[Node, float](dg.len())
    if dg.len() <= 1:
        for node in dg.nodes:
            centrality[node] = 1.0
        return centrality
    var s = 1.0 / (float(dg.len()) - 1.0)
    for node in dg.nodes:
        let indegree = dg.indegree(node)
        centrality[node] = float(indegree) * s
    return centrality

proc outdegreeCentrality*(
    dg: ref DirectedGraph
): Table[Node, float] =
    var centrality = initTable[Node, float](dg.len())
    if dg.len() <= 1:
        for node in dg.nodes:
            centrality[node] = 1.0
        return centrality
    var s = 1.0 / (float(dg.len()) - 1.0)
    for node in dg.nodes:
        let outdegree = dg.outdegree(node)
        centrality[node] = float(outdegree) * s
    return centrality

when isMainModule:
    var G = readEdgelist("../../karate.csv", separator=',')
    var centrality = indegreeCentrality(G)
    echo centrality

    centrality = outdegreeCentrality(G)
    echo centrality