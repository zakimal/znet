import tables
import algorithm
import sequtils
import sets
import heapqueue

import ../../graph.nim
import ../../exception.nim

proc basicGraphicalTests(sequence: seq[int]): tuple[dmax: int, dmin: int, dsum: int, n: int, numDegs: seq[int]] =
    var degSequence = sequence
    var p = len(degSequence)
    var numDegs: seq[int] = newSeq[int]()
    for i in 0..<p:
        numDegs[i] = 0
    var dmax = 0
    var dmin = p
    var dsum = 0
    var n = 0
    for d in degSequence:
        if d < 0 or d >= p:
            var e = ZNetUnfeasible()
            raise e
        elif d > 0:
            dmax = max(dmax, d)
            dmin = min(dmin, d)
            dsum += d
            n += 1
            numDegs[d] += 1
    if dsum mod 2 == 1 or dsum > n * (n - 1):
        var e = ZNetUnfeasible()
        raise e
    return (dmax, dmin, dsum, n, numDegs)

proc isValidDegreeSequenceErodsGallai*(sequence: seq[int]): bool =
    var dmax: int
    var dmin: int
    var dsum: int
    var n: int
    var numDegs: seq[int]
    try:
        (dmax, dmin, dsum, n, numDegs) = basicGraphicalTests(sequence)
    except ZNetUnfeasible:
        return false

    if n == 0 or dmin * n >= (dmax + dmin + 1) * (dmax + dmin + 1):
        return true

    var modstubs: seq[int] = @[]
    for i in 0..<(dmax + 1):
        modstubs.add(0)

    while 0 < n:
        while numDegs[dmax] == 0:
            dmax -= 1
        if n - 1 < dmax:
            return false
        numDegs[dmax] = numDegs[dmax] - 1
        n -= 1
        var mslen = 0
        var k = dmax
        for i in 0..<dmax:
            while numDegs[k] == 0:
                k -= 1
            numDegs[k] -= 1
            n -= 1
            if 1 < k:
                modstubs[mslen] = k - 1
                mslen += 1
        for i in 0..<mslen:
            var stub = modstubs[i]
            numDegs[stub] += 1
            n += 1
    return true

proc isValidDegreeSequenceHavelHakimi*(sequence: seq[int]): bool =
    var dmax: int
    var dmin: int
    var dsum: int
    var n: int
    var numDegs: seq[int]
    try:
        (dmax, dmin, dsum, n, numDegs) = basicGraphicalTests(sequence)
    except ZNetUnfeasible:
        return false

    if n == 0 or 4 * dmin * n >= (dmax + dmin + 1) * (dmax + dmin + 1):
        return true

    var k: int = 0
    var sumDeg: int = 0
    var sumNj: int = 0
    var sumJnj: int = 0

    for dk in countdown(dmax, dmin):
        if dk < k + 1:
            return true
        if 0 < numDegs[dk]:
            var runSize = numDegs[dk]
            if dk < k + runSize:
                runSize = dk - k
            sumDeg += runSize * dk
            for v in 0..<runSize:
                sumNj += numDegs[k + v]
                sumJnj += (k + v) * numDegs[k + v]
            k += runSize
            if sumDeg > k * (n - 1) - k * sumNj + sumJnj:
                return false
    return true

proc isMultiGraphical*(sequence: seq[int]): bool =
    var degSequence: seq[int] = sequence
    var dsum = 0
    var dmax = 0
    for d in degSequence:
        if d < 0:
            return false
        dsum += d
        dmax = max(dmax, d)
    if dsum mod 2 == 1 or dsum < 2 * dmax:
        return false
    return true

proc isPseudoGraphical*(sequence: seq[int]): bool =
    var s = 0
    for d in sequence:
        s += d
    return s mod 2 == 0 and min(sequence) >= 0

proc isDiGraphical*(inSequence: seq[int], outSequence: seq[int]): bool =
    var sumin = 0
    var sumout = 0
    var nin = len(inSequence)
    var nout = len(outSequence)
    var maxn = max(nin, nout)
    var maxin = 0
    if maxn == 0:
        return true
    var stubheap: HeapQueue[tuple[outDeg: int, inDeg: int]] = initHeapQueue[tuple[outDeg: int, inDeg: int]]()
    var zeroheap: HeapQueue[int] = initHeapQueue[int]()
    for n in 0..<maxn:
        var inDeg = 0
        var outDeg = 0
        if n < nout:
            outDeg = outSequence[n]
        if n < nin:
            inDeg = inSequence[n]
        if inDeg < 0 or outDeg < 0:
            return false
        sumin += inDeg
        sumout += outDeg
        maxin = max(maxin, inDeg)
        if inDeg > 0:
            stubheap.push((-1 * outDeg, -1 * inDeg))
        elif outDeg > 0:
            zeroheap.push(-1 * outDeg)
    if sumin != sumout:
        return false

    var modstubs: seq[tuple[outDeg: int, inDeg: int]] = @[]
    for i in 0..maxin:
        modstubs.add((0, 0))
    while len(modstubs) != 0:
        var (freeout, freein) = stubheap.pop()
        freein *= -1
        if freein > len(stubheap) + len(zeroheap):
            return false
        var mslen = 0
        for i in 0..<freein:
            var stubout: int
            var stubin: int
            if len(zeroheap) != 0 and (len(stubheap) == 0 or stubheap[0][0] > zeroheap[0]):
                stubout = zeroheap.pop()
                stubin = 0
            else:
                (stubout, stubin) = stubheap.pop()
            if stubout == 0:
                return false
            if stubout + 1 < 0 or stubin < 0:
                modstubs[mslen] = (stubout + 1, stubin)
                mslen += 1
        for i in 0..<mslen:
            var stub: tuple[outDeg: int, inDeg: int] = modstubs[i]
            if stub[1] < 0:
                stubheap.push(stub)
            else:
                zeroheap.push(stub[0])
        if freeout < 0:
            zeroheap.push(freeout)
    return true

proc isGraphical*(sequence: seq[int], methodName: string = "eg"): bool =
    if methodName == "eg":
        return isValidDegreeSequenceErodsGallai(sequence)
    elif methodName == "hh":
        return isValidDegreeSequenceHavelHakimi(sequence)
    var e = ZNetException()
    e.msg = "method must be 'eg' or 'hh'"
    raise e