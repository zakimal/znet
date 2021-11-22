import algorithm
import sequtils
import tables
import strformat
import sets

import ../../graph.nim
import ../../exception.nim

iterator buildPathsFromPredecessors(
    sources: HashSet[Node],
    target: Node,
    pred: Table[Node, seq[Node]]
): seq[Node] =
    if target notin pred:
        var e = ZNetNoPath()
        e.msg = fmt"the target node {target} cannot be reached from given sources {sources}"
        raise e
    var seen: HashSet[Node] = initHashSet[Node]()
    var stack: seq[tuple[node: Node, i: int]] = newSeq[tuple[node: Node, i: int]]()
    stack.add((target, 0))
    var top = 0
    while 0 <= top:
        var (node, i) = stack[top]
        if node in sources:
            var ret: seq[Node] = newSeq[Node]()
            for idx in countdown(top, 0):
                ret.add(stack[idx].node)
            yield ret
        if i < len(pred[node]):
            stack[top].i = i + 1
            var next = pred[node][i]
            if next in seen:
                continue
            else:
                seen.incl(next)
            top += 1
            if top == len(stack):
                stack.add((next, 0))
            else:
                stack[top] = (next, 0)
        else:
            seen.excl(node)
            top -= 1


when isMainModule:
    discard