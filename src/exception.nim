# Exceptions

import strformat

type
    ZNetException*                       = ref object of Exception
    ZNetError*                           = ref object of ZNetException
    ZNetPointlessConcept*                = ref object of ZNetException
    ZNetAlgorithmError*                  = ref object of ZNetException
    ZNetUnfeasible*                      = ref object of ZNetAlgorithmError
    ZNetNoPath*                          = ref object of ZNetUnfeasible
    ZNetNoCycle*                         = ref object of ZNetUnfeasible
    ZNetHasACycle*                       = ref object of ZNetException
    ZNetUnbounded*                       = ref object of ZNetAlgorithmError
    ZNetNotImplemented*                  = ref object of ZNetException
    ZNetNodeNotFound*                    = ref object of ZNetException
    ZNetAmbiguousSolution*               = ref object of ZNetException
    ZNetExceededMaxIterations*           = ref object of ZNetException
    ZNetPowerIterationFailedConvergence* = ref object of ZNetExceededMaxIterations
        numIterations: int

proc newZNetPowerIterationFailedConvergence*(numIterations: int): ZNetPowerIterationFailedConvergence =
    var e: ZNetPowerIterationFailedConvergence
    new(e)
    e.numIterations = numIterations
    e.msg = fmt"power iteration failed to converge within {numIterations} iterations"
    return e
