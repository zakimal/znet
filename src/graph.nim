import algorithm
import tables
import sets
import strformat
import sequtils

import ./exception.nim

# Node
type Node* = int
const None* = -1.Node

# Edge
type
    Edge* = tuple[u, v: Node]
    DirectedEdge* = tuple[fromNode, toNode: Node]
    WeightedEdge* = tuple[u, v: Node, weight: float]
    WeightedDirectedEdge* = tuple[fromNode, toNode: Node, weight: float]

# Graph (Undirected Graph)
type Graph* = ref object of RootObj
    isDirected*: bool
    adj*: Table[Node, HashSet[Node]]
    # nodeAttributes*: Table[Node, Table[string, string]]
    # edgeAttributes*: Table[tuple[u, v: Node], Table[string, string]]

proc newGraph*(): Graph =
    new(result)
    result.isDirected = false
    result.adj = initTable[Node, HashSet[Node]]()

proc isDirected*(g: Graph): bool =
    return g.isDirected

# Directed Graph
type DirectedGraph* = ref object of Graph
    pred*: Table[Node, HashSet[Node]]

proc newDirectedGraph*(): DirectedGraph =
    new(result)
    result.isDirected = true
    result.adj = initTable[Node, HashSet[Node]]()
    result.pred = initTable[Node, HashSet[Node]]()

proc addNode*(g: Graph, node: Node) =
    if node notin g.adj:
        if node == None:
            raise newException(ValueError, "None cannot be a node")
        g.adj[node] = initHashSet[Node]()

proc addNodesFrom*(g: Graph, nodes: openArray[Node]) =
    for node in nodes:
        g.addNode(node)

proc addNodesFrom*(g: Graph, nodes: HashSet[Node]) =
    for node in nodes:
        g.addNode(node)

proc removeNode*(g: Graph, node: Node) =
    var nbrs: HashSet[Node]
    try:
        nbrs = g.adj[node]
        g.adj.del(node)
    except KeyError:
        var e = ZNetError()
        e.msg = fmt"The node {node} is not in the graph"
        raise e
    for u in nbrs:
        g.adj[u].excl(node)

proc removeNodesFrom*(g: Graph, nodes: openArray[Node]) =
    for node in nodes:
        g.removeNode(node)

proc removeNodesFrom*(g: Graph, nodes: HashSet[Node]) =
    for node in nodes:
        g.removeNode(node)

proc addEdge*(g: Graph, u, v: Node) =
    if u notin g.adj:
        if u == None:
            raise newException(ValueError, "None cannot be a node")
        g.adj[u] = initHashSet[Node]()
    if v notin g.adj:
        if v == None:
            raise newException(ValueError, "None cannot be a node")
        g.adj[v] = initHashSet[Node]()
    g.adj[u].incl(v)
    g.adj[v].incl(u)

proc addEdge*(g: Graph, edge: Edge) =
    g.addEdge(edge.u, edge.v)

proc addEdgesFrom*(g: Graph, edges: openArray[Edge]) =
    for edge in edges:
        g.addEdge(edge)

proc addEdgesFrom*(g: Graph, edges: HashSet[Edge]) =
    for edge in edges:
        g.addEdge(edge)

proc removeEdge*(g: Graph, u, v: Node) =
    try:
        var isMissing: bool
        isMissing = g.adj[u].missingOrExcl(v)
        if isMissing:
            var e = ZNetError()
            e.msg = fmt"The edge {u}-{v} is not in the graph"
            raise e
        if u != v:
            g.adj[v].excl(u)
    except KeyError:
        var e = ZNetError()
        e.msg = fmt"The edge {u}-{v} is not in the graph"
        raise e

proc removeEdge*(g: Graph, edge: Edge) =
    g.removeEdge(edge.u, edge.v)

proc removeEdgesFrom*(g: Graph, edges: openArray[Edge]) =
    for edge in edges:
        g.removeEdge(edge)

proc removeEdgesFrom*(g: Graph, edges: HashSet[Edge]) =
    for edge in edges:
        g.removeEdge(edge)

# TODO:
# proc update*(g: Graph, nodes)
# proc update*(g: Graph, edges)
# proc update*(g: Graph, edges, nodes)

proc clear*(g: Graph) =
    g.adj.clear()

proc clearEdges*(g: Graph) =
    for node in g.adj.keys():
        g.adj[node].clear()

proc nodes*(g: Graph): seq[Node] =
    var ret = newSeq[Node]()
    for node in g.adj.keys():
        ret.add(node)
    ret.sort()
    return ret

proc nodeIterator*(g: Graph): iterator: Node =
    return iterator: Node =
        for node in g.nodes():
            yield node

proc nodeSet*(g: Graph): HashSet[Node] =
    var ret = initHashSet[Node]()
    for node in g.adj.keys():
        ret.incl(node)
    return ret

proc nodeSeq*(g: Graph): seq[Node] =
    return g.nodes()

proc hasNode*(g: Graph, node: Node): bool =
    return node in g.adj

proc contains*(g: Graph, node: Node): bool =
    return node in g.adj

proc edges*(g: Graph): seq[Edge] =
    var ret = newSeq[Edge]()
    for (u, vs) in g.adj.pairs():
        for v in vs:
            if u <= v:
                ret.add((u, v))
    ret.sort()
    return ret

proc edgeIterator*(g: Graph): iterator: Edge =
    return iterator: Edge =
        for (u, v) in g.edges():
            yield (u, v)

proc edgeSet*(g: Graph): HashSet[Edge] =
    var ret = initHashSet[Edge]()
    for (u, vs) in g.adj.pairs():
        for v in vs:
            if u <= v:
                ret.incl((u, v))
    return ret

proc edgeSeq*(g: Graph): seq[Edge] =
    return g.edges()

proc hasEdge*(g: Graph, u, v: Node): bool =
    try:
        return v in g.adj[u]
    except KeyError:
        return false

proc hasEdge*(g: Graph, edge: Edge): bool =
    try:
        return edge.v in g.adj[edge.u]
    except KeyError:
        return false

proc contains*(g: Graph, u, v: Node): bool =
    return g.hasEdge(u, v)

proc contains*(g: Graph, edge: Edge): bool =
    return g.hasEdge(edge)

# TODO:
# proc getEdgeData(g: Graph)

proc neighbors*(g: Graph, n: Node): seq[Node] =
    var ret: seq[Node] = newSeq[Node]()
    if n notin g.adj:
        var e = ZNetError()
        e.msg = fmt"The node {n} is not in the graph"
        raise e
    for nbr in g.adj[n]:
        ret.add(nbr)
    ret.sort()
    return ret

proc neighborIterator*(g: Graph, n: Node): iterator: Node =
    return iterator: Node =
        for nbr in g.neighbors(n):
            yield nbr

proc neighborSet*(g: Graph, n: Node): HashSet[Node] =
    var ret = initHashSet[Node]()
    for nbr in g.neighbors(n):
        ret.incl(nbr)
    return ret

proc neighborSeq*(g: Graph, n: Node): seq[Node] =
    return g.neighbors(n)

proc adj*(g: Graph): Table[Node, HashSet[Node]] =
    return g.adj

proc adjacency*(g: Graph): iterator: tuple[node: Node, adjacentNodes: iterator: Node] =
    var ret = newSeq[tuple[node: Node, adjacentNodes: iterator: Node]]()
    for n in g.adj.keys():
        var itr = g.neighborIterator(n)
        ret.add((n, itr))
    return iterator: tuple[node: Node, adjacentNodes: iterator: Node] =
        for ele in ret:
            yield ele

proc nbunchIter*(g: Graph): iterator: Node =
    return g.nodeIterator()

proc nbunchIter*(g: Graph, nbunch: Node): iterator: Node =
    return iterator: Node =
        for node in @[nbunch]:
            yield node

proc nbunchIter*(g: Graph, nbunch: seq[Node]): iterator: Node =
    return iterator: Node =
        for node in nbunch:
            if node in g.nodeSet():
                yield node

proc order*(g: Graph): int =
    return g.adj.len()

proc numberOfNodes*(g: Graph): int =
    return g.adj.len()

proc len*(g: Graph): int =
    return g.adj.len()

proc degree*(g: Graph): Table[Node, int] =
    var ret = initTable[Node, int]()
    for node in g.nodeSeq():
        ret[node] = g.adj[node].len()
    return ret

proc degree*(g: Graph, node: Node): int =
    return g.adj[node].len()

proc degree*(g: Graph, nbunch: seq[Node]): seq[tuple[node: Node, degree: int]] =
    var ret = newSeq[tuple[node: Node, degree: int]]()
    for node in g.nodeSeq():
        ret.add((node, g.adj[node].len()))
    return ret

proc size*(g: Graph): int =
    var ret = 0
    for degree in g.degree().values():
        ret += degree
    return ret div 2

# TODO:
# proc size*(g: Graph, weight: string = ""): int =
#     return

proc numberOfEdges*(g: Graph): int =
    return g.size()

proc numberOfEdges*(g: Graph, u, v: Node): int =
    if v in g.neighborSet(u):
        return 1
    return 0

proc copy*(g: Graph): Graph =
    var ret = newGraph()
    ret.addEdgesFrom(g.edges())
    return ret

proc copy*(dg: DirectedGraph): DirectedGraph =
    var ret = newDirectedGraph()
    ret.addEdgesFrom(dg.edges())
    return ret

proc toUndirected*(g: Graph): Graph =
    if g.isDirected:
        var ret = newGraph()
        ret.addEdgesFrom(g.edges())
        return ret
    return g.copy()

proc toDirected*(g: Graph): DirectedGraph =
    if g.isDirected:
        var ret = newDirectedGraph()
        ret.addEdgesFrom(g.edges())
        return ret
    var ret = newDirectedGraph()
    for edge in g.edges():
        ret.addEdge(edge.u, edge.v)
        ret.addEdge(edge.v, edge.u)
    return ret

proc subgraph*(g: Graph, nodes: HashSet[Node]): Graph =
    var ret = newGraph()
    ret.addNodesFrom(nodes)
    for (u, v) in g.edges():
        if u in nodes and v in nodes:
            ret.addEdge((u, v))
    return ret

proc edgeSubgraph*(g: Graph, edges: HashSet[Edge]): Graph =
    var ret = newGraph()
    for edge in edges:
        if g.hasEdge(edge):
            ret.addEdge(edge)
    return ret

proc `[]`*(g: Graph, node: Node): seq[Node] =
    return g.neighborSeq(node)

proc `in`*(g: Graph, node: Node): bool =
    return g.hasNode(node)

proc `+`*(g: Graph, node: Node): Graph =
    g.addNode(node)
    return g

proc `+`*(g: Graph, nodes: HashSet[Node]): Graph =
    g.addNodesFrom(nodes)
    return g

proc `+`*(g: Graph, nodes: openArray[Node]): Graph =
    g.addNodesFrom(nodes)
    return g

proc `-`*(g: Graph, node: Node): Graph =
    g.removeNode(node)
    return g

proc `-`*(g: Graph, nodes: HashSet[Node]): Graph =
    g.removeNodesFrom(nodes)
    return g

proc `-`*(g: Graph, nodes: openArray[Node]): Graph =
    g.removeNodesFrom(nodes)
    return g

proc `+=`*(g: Graph, node: Node) =
    g.addNode(node)

proc `+=`*(g: Graph, nodes: HashSet[Node]) =
    g.addNodesFrom(nodes)

proc `+=`*(g: Graph, nodes: openArray[Node]) =
    g.addNodesFrom(nodes)

proc `-=`*(g: Graph, node: Node) =
    g.removeNode(node)

proc `-=`*(g: Graph, nodes: HashSet[Node]) =
    g.removeNodesFrom(nodes)

proc `-=`*(g: Graph, nodes: openArray[Node]) =
    g.removeNodesFrom(nodes)

proc `in`*(g: Graph, edge: Edge): bool =
    return g.hasEdge(edge)

proc `+`*(g: Graph, edge: Edge): Graph =
    g.addEdge(edge)
    return g

proc `+`*(g: Graph, edges: HashSet[Edge]): Graph =
    g.addEdgesFrom(edges)
    return g

proc `+`*(g: Graph, edges: openArray[Edge]): Graph =
    g.addEdgesFrom(edges)
    return g

proc `-`*(g: Graph, edge: Edge): Graph =
    g.removeEdge(edge)
    return g

proc `-`*(g: Graph, edges: HashSet[Edge]): Graph =
    g.removeEdgesFrom(edges)
    return g

proc `-`*(g: Graph, edges: openArray[Edge]): Graph =
    g.removeEdgesFrom(edges)
    return g

proc `+=`*(g: Graph, edge: Edge) =
    g.addEdge(edge)

proc `+=`*(g: Graph, edges: HashSet[Edge]) =
    g.addEdgesFrom(edges)

proc `+=`*(g: Graph, edges: openArray[Edge]) =
    g.addEdgesFrom(edges)

proc `-=`*(g: Graph, edge: Edge) =
    g.removeEdge(edge)

proc `-=`*(g: Graph, edges: HashSet[Edge]) =
    g.removeEdgesFrom(edges)

proc `-=`*(g: Graph, edges: openArray[Edge]) =
    g.removeEdgesFrom(edges)

# TODO:
# proc `+`(g0: Graph, g1: Graph): Graph
# proc `-`(g0: Graph, g1: Graph): Graph
# proc `*`(g0: Graph, g1: Graph): Graph

proc addNode*(dg: DirectedGraph, node: Node) =
    if node notin dg.adj:
        if node == None:
            raise newException(ValueError, "None cannot be a node")
        dg.adj[node] = initHashSet[Node]()
        dg.pred[node] = initHashSet[Node]()

proc addNodesFrom*(dg: DirectedGraph, nodes: openArray[Node]) =
    for node in nodes:
        dg.addNode(node)

proc addNodesFrom*(dg: DirectedGraph, nodes: HashSet[Node]) =
    for node in nodes:
        dg.addNode(node)

proc removeNode*(dg: DirectedGraph, node: Node) =
    var nbrs: HashSet[Node]
    try:
        nbrs = dg.adj[node]
    except KeyError:
        var e = ZNetError()
        e.msg = fmt"The node {node} is not in the digraph"
        raise e
    for nbr in nbrs:
        dg.pred[nbr].excl(node) # remove all edges node->nbr
    dg.adj.del(node) # remove node from adj (= succ)
    for pred in dg.pred[node]:
        dg.adj[pred].excl(node) # remove all edge node->nbr
    dg.pred.del(node) # remove node from pred

proc removeNodesFrom*(dg: DirectedGraph, nodes: openArray[Node]) =
    for node in nodes:
        dg.removeNode(node)

proc removeNodesFrom*(dg: DirectedGraph, nodes: HashSet[Node]) =
    for node in nodes:
        dg.removeNode(node)

proc addEdge*(dg: DirectedGraph, fromNode, toNode: Node) =
    if fromNode notin dg.adj:
        if fromNode == None:
            raise newException(ValueError, "None cannot be a node")
        dg.adj[fromNode] = initHashSet[Node]()
        dg.pred[fromNode] = initHashSet[Node]()
    if toNode notin dg.adj:
        if toNode == None:
            raise newException(ValueError, "None cannot be a node")
        dg.adj[toNode] = initHashSet[Node]()
        dg.pred[toNode] = initHashSet[Node]()
    dg.adj[fromNode].incl(toNode)
    dg.pred[toNode].incl(fromNode)

proc addEdge*(dg: DirectedGraph, edge: Edge) =
    let fromNode = edge.u
    let toNode = edge.v
    if fromNode notin dg.adj:
        if fromNode == None:
            raise newException(ValueError, "None cannot be a node")
        dg.adj[fromNode] = initHashSet[Node]()
        dg.pred[fromNode] = initHashSet[Node]()
    if toNode notin dg.adj:
        if toNode == None:
            raise newException(ValueError, "None cannot be a node")
        dg.adj[toNode] = initHashSet[Node]()
        dg.pred[toNode] = initHashSet[Node]()
    dg.adj[fromNode].incl(toNode)
    dg.pred[toNode].incl(fromNode)

proc addEdgesFrom*(dg: DirectedGraph, edges: openArray[Edge]) =
    for edge in edges:
        dg.addEdge(edge)

proc addEdgesFrom*(dg: DirectedGraph, edges: HashSet[Edge]) =
    for edge in edges:
        dg.addEdge(edge)

proc removeEdge*(dg: DirectedGraph, fromNode, toNode: Node) =
    try:
        var isMissing: bool
        isMissing = dg.adj[fromNode].missingOrExcl(toNode)
        dg.pred[toNode].excl(fromNode)
        if isMissing:
            var e = ZNetError()
            e.msg = fmt"The edge {fromNode}-{toNode} is not in the graph"
            raise e
    except KeyError:
        var e = ZNetError()
        e.msg = fmt"The edge {fromNode}-{toNode} is not in the graph"
        raise e

proc removeEdge*(dg: DirectedGraph, edge: Edge) =
    dg.removeEdge(edge.u, edge.v)

proc removeEdgesFrom*(dg: DirectedGraph, edges: openArray[Edge]) =
    for edge in edges:
        dg.removeEdge(edge)

proc removeEdgesFrom*(dg: DirectedGraph, edges: HashSet[Edge]) =
    for edge in edges:
        dg.removeEdge(edge)

proc clear*(dg: DirectedGraph) =
    dg.adj.clear()
    dg.pred.clear()

proc clearEdges*(dg: DirectedGraph) =
    for node in dg.nodes():
        dg.adj[node].clear()
        dg.pred[node].clear()

# TODO:
# proc update*(dg: DirectedGraph, nodes)
# proc update*(dg: DirectedGraph, edges)
# proc update*(dg: DirectedGraph, edges, nodes)

proc edges*(dg: DirectedGraph): seq[Edge] =
    var ret = newSeq[Edge]()
    for (u, vs) in dg.adj.pairs():
        for v in vs:
            ret.add((u, v))
    ret.sort()
    return ret

proc outEdges*(dg: DirectedGraph): seq[Edge] =
    return dg.edges()

proc inEdges*(dg: DirectedGraph): seq[Edge] =
    return dg.edges()

proc edgeSet*(dg: DirectedGraph): HashSet[Edge] =
    var ret = initHashSet[Edge]()
    for (u, vs) in dg.adj.pairs():
        for v in vs:
            ret.incl((u, v))
    return ret

proc successors*(dg: DirectedGraph, node: Node): seq[Node] =
    try:
        var ret = dg.adj[node].toSeq()
        ret.sort()
        return ret
    except KeyError:
        var e = ZNetError()
        e.msg = fmt"The node {node} is not in the digraph"
        raise e

proc successorIterator*(dg: DirectedGraph, node: Node): iterator: Node =
    return iterator: Node =
        for successorNode in dg.successors(node):
            yield successorNode

proc successorSet*(dg: DirectedGraph, node: Node): HashSet[Node] =
    var ret = initHashSet[Node]()
    for successorNode in dg.successors(node):
        ret.incl(successorNode)
    return ret

proc successorSeq*(dg: DirectedGraph, node: Node): seq[Node] =
    return dg.successors(node)

proc succ*(dg: DirectedGraph): Table[Node, HashSet[Node]] =
    return dg.adj

proc predecessors*(dg: DirectedGraph, node: Node): seq[Node] =
    try:
        var ret = dg.pred[node].toSeq()
        ret.sort()
        return ret
    except KeyError:
        var e = ZNetError()
        e.msg = fmt"The node {node} is not in the digraph"
        raise e

proc predecessorIterator*(dg: DirectedGraph, node: Node): iterator: Node =
     return iterator: Node =
        for predecessorNode in dg.predecessors(node):
            yield predecessorNode

proc predecessorSet*(dg: DirectedGraph, node: Node): HashSet[Node] =
    var ret = initHashSet[Node]()
    for predecessorNode in dg.predecessors(node):
        ret.incl(predecessorNode)
    return ret

proc predecessorSeq*(dg: DirectedGraph, node: Node): seq[Node] =
    return dg.predecessors(node)

proc pred*(dg: DirectedGraph): Table[Node, HashSet[Node]] =
    return dg.pred

proc indegree*(dg: DirectedGraph): Table[Node, int] =
    var ret = initTable[Node, int]()
    for node in dg.nodeSeq():
        ret[node] = dg.pred[node].len()
    return ret

proc indegree*(dg: DirectedGraph, node: Node): int =
    return dg.pred[node].len()

proc indegree*(dg: DirectedGraph, nbunch: seq[Node]): seq[tuple[node: Node, degree: int]] =
    var ret = newSeq[tuple[node: Node, degree: int]]()
    for node in dg.nodeSeq():
        ret.add((node, dg.pred[node].len()))
    return ret

proc outdegree*(dg: DirectedGraph): Table[Node, int] =
    return dg.degree()

proc outdegree*(dg: DirectedGraph, node: Node): int =
    return dg.degree(node)

proc outdegree*(dg: DirectedGraph, nbunch: seq[Node]): seq[tuple[node: Node, degree: int]] =
    return dg.degree(nbunch)

proc size*(dg: DirectedGraph): int =
    var ret = 0
    for degree in dg.outdegree().values():
        ret += degree
    return ret

# TODO:
# proc size*(dg: DirectedGraph, weight: string = ""): int =
#     return

proc toUndirected*(dg: DirectedGraph): Graph =
    var ret = newGraph()
    for edge in dg.edges():
        if edge.u <= edge.v:
            ret.addEdge(edge)
    return ret

proc toDirected*(dg: DirectedGraph): DirectedGraph =
    return dg.copy()

proc reverse*(dg: DirectedGraph, copy: bool): DirectedGraph =
    if copy:
        var ret = newDirectedGraph()
        for edge in dg.edges():
            ret.addEdge(edge.v, edge.u)
        return ret
    let edges = dg.edges()
    dg.clear()
    for edge in edges:
        dg.addEdge(edge.v, edge.u)
    return dg

proc `+`*(dg: DirectedGraph, node: Node): DirectedGraph =
    dg.addNode(node)
    return dg

proc `+`*(dg: DirectedGraph, nodes: HashSet[Node]): DirectedGraph =
    dg.addNodesFrom(nodes)
    return dg

proc `+`*(dg: DirectedGraph, nodes: openArray[Node]): DirectedGraph =
    dg.addNodesFrom(nodes)
    return dg

proc `-`*(dg: DirectedGraph, node: Node): DirectedGraph =
    dg.removeNode(node)
    return dg

proc `-`*(dg: DirectedGraph, nodes: HashSet[Node]): DirectedGraph =
    dg.removeNodesFrom(nodes)
    return dg

proc `-`*(dg: DirectedGraph, nodes: openArray[Node]): DirectedGraph =
    dg.removeNodesFrom(nodes)
    return dg

proc `+=`*(dg: DirectedGraph, node: Node) =
    dg.addNode(node)

proc `+=`*(dg: DirectedGraph, nodes: HashSet[Node]) =
    dg.addNodesFrom(nodes)

proc `+=`*(dg: DirectedGraph, nodes: openArray[Node]) =
    dg.addNodesFrom(nodes)

proc `-=`*(dg: DirectedGraph, node: Node) =
    dg.removeNode(node)

proc `-=`*(dg: DirectedGraph, nodes: HashSet[Node]) =
    dg.removeNodesFrom(nodes)

proc `-=`*(dg: DirectedGraph, nodes: openArray[Node]) =
    dg.removeNodesFrom(nodes)

proc `in`*(dg: DirectedGraph, edge: Edge): bool =
    return dg.hasEdge(edge)

proc `+`*(dg: DirectedGraph, edge: Edge): DirectedGraph =
    dg.addEdge(edge)
    return dg

proc `+`*(dg: DirectedGraph, edges: HashSet[Edge]): DirectedGraph =
    dg.addEdgesFrom(edges)
    return dg

proc `+`*(dg: DirectedGraph, edges: openArray[Edge]): DirectedGraph =
    dg.addEdgesFrom(edges)
    return dg

proc `-`*(dg: DirectedGraph, edge: Edge): DirectedGraph =
    dg.removeEdge(edge)
    return dg

proc `-`*(dg: DirectedGraph, edges: HashSet[Edge]): DirectedGraph =
    dg.removeEdgesFrom(edges)
    return dg

proc `-`*(dg: DirectedGraph, edges: openArray[Edge]): DirectedGraph =
    dg.removeEdgesFrom(edges)
    return dg

proc `+=`*(dg: DirectedGraph, edge: Edge) =
    dg.addEdge(edge)

proc `+=`*(dg: DirectedGraph, edges: HashSet[Edge]) =
    dg.addEdgesFrom(edges)

proc `+=`*(dg: DirectedGraph, edges: openArray[Edge]) =
    dg.addEdgesFrom(edges)

proc `-=`*(dg: DirectedGraph, edge: Edge) =
    dg.removeEdge(edge)

proc `-=`*(dg: DirectedGraph, edges: HashSet[Edge]) =
    dg.removeEdgesFrom(edges)

proc `-=`*(dg: DirectedGraph, edges: openArray[Edge]) =
    dg.removeEdgesFrom(edges)


when isMainModule:
    var G = newGraph()
    doAssert G.isDirected == false
    doAssert isDirected(G) == false
    doAssert G.adj.len() == 0

    var DiG = newDirectedGraph()
    doAssert DiG.isDirected == true
    doAssert isDirected(DiG) == true
    doAssert DiG.adj.len() == 0

    G.addNode(0)
    G.addNode(1)
    for (node, neighbors) in G.adj.pairs():
        echo(fmt"{node}: {neighbors}")

    echo("---")
    G.addNodesFrom(@[2, 3, 4])
    for (node, neighbors) in G.adj.pairs():
        echo(fmt"{node}: {neighbors}")

    echo("---")
    var nodesForAdding = initHashSet[Node]()
    nodesForAdding.incl(5)
    nodesForAdding.incl(6)
    G.addNodesFrom(nodesForAdding)
    for (node, neighbors) in G.adj.pairs():
        echo(fmt"{node}: {neighbors}")

    echo("---")
    G.removeNodesFrom(@[2, 3, 4])
    for (node, neighbors) in G.adj.pairs():
        echo(fmt"{node}: {neighbors}")

    echo("---")
    nodesForAdding = initHashSet[Node]()
    nodesForAdding.incl(5)
    nodesForAdding.incl(6)
    G.removeNodesFrom(nodesForAdding)
    for (node, neighbors) in G.adj.pairs():
        echo(fmt"{node}: {neighbors}")

    echo("---")
    try:
        G.removeNode(5)
    except ZNetError as e:
        echo(e.msg)

    echo("---")
    G.addEdge(2, 3)
    for (node, neighbors) in G.adj.pairs():
        echo(fmt"{node}: {neighbors}")

    echo("---")
    try:
        G.addEdge(None, 1)
    except ValueError as e:
        echo(e.msg)

    echo("---")
    try:
        G.addEdge(0, None)
    except ValueError as e:
        echo(e.msg)

    echo("---")
    G.addEdge((5, 6))
    for (node, neighbors) in G.adj.pairs():
        echo(fmt"{node}: {neighbors}")

    echo("---")
    G.addEdgesFrom(@[(2, 3), (4, 5)])
    for (node, neighbors) in G.adj.pairs():
        echo(fmt"{node}: {neighbors}")

    echo("---")
    var edgesForAdding = initHashSet[Edge]()
    edgesForAdding.incl((0, 1))
    G.addEdgesFrom(edgesForAdding)
    for (node, neighbors) in G.adj.pairs():
        echo(fmt"{node}: {neighbors}")

    echo("---")
    G.removeEdge(0, 1)
    for (node, neighbors) in G.adj.pairs():
        echo(fmt"{node}: {neighbors}")

    echo("---")
    G.removeEdge((4, 5))
    for (node, neighbors) in G.adj.pairs():
        echo(fmt"{node}: {neighbors}")

    echo("---")
    try:
        G.removeEdge(0, 1)
    except ZNetError as e:
        echo(e.msg)

    echo("---")
    try:
        G.removeEdge(7, 8)
    except ZNetError as e:
        echo(e.msg)

    echo("---")
    G.removeEdgesFrom(@[(2, 3)])
    for (node, neighbors) in G.adj.pairs():
        echo(fmt"{node}: {neighbors}")

    echo("---")
    edgesForAdding = initHashSet[Edge]()
    edgesForAdding.incl((6, 5))
    G.removeEdgesFrom(edgesForAdding)
    for (node, neighbors) in G.adj.pairs():
        echo(fmt"{node}: {neighbors}")

    echo("---")
    G.addEdgesFrom(@[(0, 1), (2, 4), (5, 9)])
    for (node, neighbors) in G.adj.pairs():
        echo(fmt"{node}: {neighbors}")

    echo("---")
    G.clear()
    for (node, neighbors) in G.adj.pairs():
        echo(fmt"{node}: {neighbors}")

    echo("---")
    G.addEdgesFrom(@[(0, 1), (2, 4), (5, 9)])
    for (node, neighbors) in G.adj.pairs():
        echo(fmt"{node}: {neighbors}")

    echo("---")
    G.clearEdges()
    for (node, neighbors) in G.adj.pairs():
        echo(fmt"{node}: {neighbors}")

    echo("---")
    echo(G.nodes())

    echo("---")
    echo(G.edges())

    echo("---")
    G.addEdgesFrom(@[(0, 1), (2, 4), (9, 5)])
    for (node, neighbors) in G.adj.pairs():
        echo(fmt"{node}: {neighbors}")

    doAssert G.hasNode(4) == true
    doAssert G.hasNode(3) == false
    doAssert G.contains(4) == true
    doAssert G.contains(3) == false
    doAssert 4 in G == true
    doAssert 3 in G == false

    echo("---")
    echo(G.edges())

    doAssert G.hasEdge(0, 1) == true
    doAssert G.hasEdge((0, 1)) == true
    doAssert G.hasEdge(2, 3) == false
    doAssert G.hasEdge((2, 3)) == false

    doAssert G.contains(0, 1) == true
    doAssert G.contains((0, 1)) == true
    doAssert G.contains(2, 3) == false
    doAssert G.contains((2, 3)) == false

    echo("---")
    edgesForAdding = initHashSet[Edge]()
    for i in 0..10:
        edgesForAdding.incl((i, i + 2))
    G.addEdgesFrom(edgesForAdding)
    for (node, neighbors) in G.adj.pairs():
        echo(fmt"{node}: {neighbors}")

    echo("---")
    for neighbor in G.neighbors(9):
        echo(neighbor)

    echo("---")
    var adjList = G.adjacency()
    for (n, neighbors) in adjList:
        var nbr = neighbors.toSeq()
        echo(fmt"node: {n:4} | {nbr}")

    echo("---")
    echo(G[0])

    echo("---")
    echo(G.order())

    echo("---")
    for (n, degree) in G.degree().pairs():
        echo(fmt"node: {n:4} | degree: {degree}")

    echo("---")
    echo(G.size())

    echo("---")
    var H = G.copy()
    G.removeNode(12)
    doAssert G.contains(12) == false
    echo(H.neighbors(12))

    echo("---")
    G = newGraph()
    G.addEdgesFrom(@[(0, 1), (1, 2), (2, 3)])
    echo(G.edges())
    var subgraphNodes = initHashSet[Node]()
    subgraphNodes.incl(0)
    subgraphNodes.incl(1)
    subgraphNodes.incl(2)
    var subG = G.subgraph(subgraphNodes)
    echo(subG.edges())

    echo("---")
    G = newGraph()
    G.addEdgesFrom(@[(0, 1), (1, 2), (2, 3), (3, 4), (4, 5)])
    echo(G.edges())
    var subgraphEdges = initHashSet[Edge]()
    subgraphEdges.incl((0, 1))
    subgraphEdges.incl((3, 4))
    subG = G.edgeSubgraph(subgraphEdges)
    echo(subG.edges())

    echo("---")
    G = newGraph()
    G = G + 0
    G += 1
    G = G + 2 + 3 + 4
    G += (0, 1)
    G = G + (1, 2) + (3, 4)
    G += @[(5, 6), (6, 7)]
    echo(G.nodes())
    for (node, neighbors) in G.adj.pairs():
        echo(fmt"{node}: {neighbors}")

    echo("---")
    var DG = newDirectedGraph()
    DG.addEdge(0, 1)
    echo(DG.adj)
    echo(DG.pred)
    DG.addEdge((1, 2))
    echo(DG.adj)
    echo(DG.pred)

    echo("---")
    DG.removeEdge(0, 1)
    echo(DG.adj)
    echo(DG.pred)
    try:
        DG.removeEdge(3, 4)
    except ZNetError as e:
        echo(e.msg)
    echo(DG.adj)
    echo(DG.pred)

    echo("---")
    DG = newDirectedGraph()
    # DG += 1
    # DG.addNode(1)
    # DG += (0, 1)
    for i in 0..4:
        # DG.addEdge(i, i + 1)
        DG += (i, i + 1)
    echo(DG.adj)
    echo(DG.pred)
    DG.removeNode(2)
    echo(DG.adj)
    echo(DG.pred)
    DG.removeEdge(3, 4)
    echo(DG.adj)
    echo(DG.pred)
    DG.clearEdges()
    echo(DG.adj)
    echo(DG.pred)
    DG.clear()
    echo(DG.adj)
    echo(DG.pred)

    echo("---")
    G = newGraph()
    for i in 0..4:
        G += (i, i + 1)
        G += (i + 1, i)
    for edge in G.edges():
        echo(edge)
    echo(G.numberOfEdges())

    echo("---")
    DG = newDirectedGraph()
    for i in 0..4:
        DG += (i, i + 1)
        DG += (i + 1, i)
    for edge in DG.edges():
        echo(edge)

    # echo("---")
    # H = G.toUndirected()
    # echo(fmt"#nodes={G.numberOfNodes()}, #edge={G.numberOfEdges()}")
    # echo(fmt"#nodes={H.numberOfNodes()}, #edge={H.numberOfEdges()}")

    # var I = G.toDirected()
    # echo(fmt"#nodes={I.numberOfNodes()}, #edge={I.numberOfEdges()}")