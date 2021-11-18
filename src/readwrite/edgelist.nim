import parsecsv
import strformat
import strutils

import ../graph.nim

proc readEdgelist*(path: string, delimiter: char = ' '): Graph =
    if path == "":
        raise newException(Exception, fmt"file not found at path='{path}'")
    var parser: CsvParser
    parser.open(path, separator=delimiter)
    defer: parser.close()
    var G = newGraph()
    var edges: seq[Edge] = @[]
    while parser.readRow():
        var edgeStr: seq[string] = parser.row
        var edge: tuple[u, v: int]
        edge.u = parseInt(edgeStr[0])
        edge.v = parseInt(edgeStr[1])
        edges.add(edge)
    G.addEdgesFrom(edges)
    return G

proc readDirectedEdgelist*(path: string, delimiter: char = ' '): DirectedGraph =
    if path == "":
        raise newException(Exception, fmt"file not found at path='{path}'")
    var parser: CsvParser
    parser.open(path, separator=delimiter)
    defer: parser.close()
    var G = newDirectedGraph()
    var edges: seq[Edge] = @[]
    while parser.readRow():
        var edgeStr: seq[string] = parser.row
        var edge: tuple[u, v: int]
        edge.u = parseInt(edgeStr[0])
        edge.v = parseInt(edgeStr[1])
        edges.add(edge)
    G.addEdgesFrom(edges)
    return G

proc writeEdgelist*(path: string, g: Graph, delimiter: char = ' ') =
    if path == "":
        raise newException(Exception, fmt"file not found at path='{path}'")
    let fp = open(path, fmWrite)
    defer: fp.close()
    for edge in g.edges():
        fp.writeLine(fmt"{edge.u}{delimiter}{edge.v}")

when isMainModule:
    var G = readEdgelist("./testdata/test.edgelist", delimiter=' ')
    for edge in G.edges():
        echo(edge)
    echo(G.numberOfEdges())
    echo("---")
    var DG = readDirectedEdgelist("./testdata/test.edgelist", delimiter=' ')
    for edge in DG.edges():
        echo(edge)
    echo(DG.numberOfEdges())

    writeEdgelist("./testdata/test.edgelist.csv", DG, delimiter=',')