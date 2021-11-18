template toFirstClassIter*(xs): untyped =
    iterator iter(): auto {.closure.} =
        for x in xs:
            yield x
    return iter()