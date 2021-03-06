HBControl <- function(modelname = "HBModel",
                      gVarNamesNormal = NULL,
                      gVarNamesFixed = NULL,
                      gDIST = rep(1, length(gVarNamesNormal)),
                      FC = rep(0, length(gVarNamesFixed)),
                      svN = rep(0, length(gVarNamesNormal)),
                      gNCREP = 100000, gNEREP = 100000,
                      gNSKIP = 1, gINFOSKIP = 250,
                      priorVariance = 2,
                      degreesOfFreedom = 5,
                      constraintsNorm = NULL,
                      fixedA = NULL, fixedD = NULL,
                      rho = 0.1, rhoF = 0.0001,
                      targetAcceptanceNormal = 0.3,
                      targetAcceptanceFixed = 0.3,
                      gFULLCV = TRUE, gStoreDraws = FALSE,
                      gMINCOEF = 0, gMAXCOEF = 0,
                      verbose = TRUE, nodiagnostics = FALSE,
                      ...) {
     
     deprecated.args <- names(list(...))
     
     if ("gSIGDIG" %in% deprecated.args) warning("'gSIGDIG' is deprecated and will be ignored. Use options(\"digits\"= ...) instead.", call. = FALSE)
     if ("writeModel" %in% deprecated.args) warning("'writeModel' is deprecated and will be ignored. Use writeModel() directly.", call. = FALSE)
     if ("gSeed" %in% deprecated.args) warning("'gSeed' is deprecated and will be ignored. Use set.seed() directly.", call. = FALSE)
     
     return(list(modelname = modelname,
                 gVarNamesNormal = gVarNamesNormal,
                 gVarNamesFixed = gVarNamesFixed,
                 gDIST = gDIST,
                 FC = FC,
                 svN = svN,
                 gNCREP = gNCREP,
                 gNEREP = gNEREP,
                 gNSKIP = gNSKIP,
                 gINFOSKIP = gINFOSKIP,
                 priorVariance = priorVariance,
                 pvMatrix = NULL,
                 degreesOfFreedom = degreesOfFreedom,
                 constraintsNorm = constraintsNorm,
                 fixedA = fixedA,
                 fixedD = fixedD,
                 rho = rho,
                 rhoF = rhoF,
                 targetAcceptanceNormal = targetAcceptanceNormal,
                 targetAcceptanceFixed = targetAcceptanceFixed,
                 gFULLCV = gFULLCV,
                 gStoreDraws = gStoreDraws,
                 gMINCOEF = gMINCOEF,
                 gMAXCOEF = gMAXCOEF,
                 verbose = verbose,
                 nodiagnostics = nodiagnostics))
     
}
