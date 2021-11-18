import parsecsv
import strformat
import strutils

import ../graph.nim

proc readAdjlist*(path: string, delimiter: char = ' '): Graph =
    if path == "":
        raise newException(Exception, fmt"file not found at path='{path}'")
    var parser: CsvParser
    parser.open(path, separator=delimiter)
    defer: parser.close()
    var G = newGraph()
    var edges: seq[Edge] = @[]
    while parser.readRow():
        var adjlistStr: seq[string] = parser.row
        let adjlistLen = len(adjlistStr)
        let node = parseInt(adjlistStr[0])
        for i in 1..<adjlistLen:
            let adj = parseInt(adjlistStr[i])
            edges.add((node, adj))
    G.addEdgesFrom(edges)
    return G

proc readDirectedAdjlist*(path: string, delimiter: char = ' '): DirectedGraph =
    if path == "":
        raise newException(Exception, fmt"file not found at path='{path}'")
    var parser: CsvParser
    parser.open(path, separator=delimiter)
    defer: parser.close()
    var G = newDirectedGraph()
    var edges: seq[Edge] = @[]
    while parser.readRow():
        var adjlistStr: seq[string] = parser.row
        let adjlistLen = len(adjlistStr)
        let node = parseInt(adjlistStr[0])
        for i in 1..<adjlistLen:
            let adj = parseInt(adjlistStr[i])
            edges.add((node, adj))
    G.addEdgesFrom(edges)
    return G

proc writeAdjlist*(path: string, g: Graph, delimiter: char = ' ') =
    if path == "":
        raise newException(Exception, fmt"file not found at path='{path}'")
    let fp = open(path, fmWrite)
    defer: fp.close()
    for node in g.nodes():
        var line: string = $node
        for adj in g.neighbors(node):
            line = line & delimiter & $adj
        fp.writeLine(line)

when isMainModule:
    var G = readAdjlist("./testdata/test.adjlist", delimiter=' ')
    for edge in G.edges():
        echo(edge)
    echo(G.numberOfEdges())
    echo("---")
    var DG = readDirectedAdjlist("./testdata/test.adjlist", delimiter=' ')
    for edge in DG.edges():
        echo(edge)
    echo(DG.numberOfEdges())

    writeAdjlist("./testdata/test.adjlist.csv", DG, delimiter=',')