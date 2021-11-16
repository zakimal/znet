import parsecsv
import strutils

import ./graph

# TODO:
# https://github.com/networkx/networkx/blob/1646a5fe664d902f3d4ed9d282a7868d82e0be6f/networkx/readwrite/edgelist.py#L43
# def generate_edgelist(G, delimiter=" ", data=True)

proc writeEdgelist*(
    dg: ref DirectedGraph,
    path: string,
    separator: char = ' ',
) =
    let fp: File = open(path, FileMode.fmWrite)
    defer:
        fp.close()
    for edge in dg.edges():
        fp.writeLine(edge.fromNode, separator, edge.toNode)

proc readEdgelist*(
    path: string,
    separator: char = ' ',
): ref DirectedGraph =
    let dg = newDirectedGraph()

    var parser = CsvParser()
    parser.open(path, separator=separator)
    defer:
        parser.close()
    parser.readHeaderRow()
    while parser.readRow():
        let
            fromNode = parser.rowEntry("from").parseInt()
            toNode = parser.rowEntry("to").parseInt()
        dg.addEdge(fromNode, toNode)

    return dg

when isMainModule:
    let G = readEdgelist("karate.csv", separator=',')
    echo G.numberOfNodes()
    echo G.numberOfEdges()

    writeEdgelist(G, path="karate2.tsv", separator='\t')