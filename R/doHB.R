doHB <- function(likelihood_user, choicedata, control = HBControl())
{
     
     # turns the user specified likelihood function into something RSGHB can use
     likelihood <- function(fc, b, env)
     {
          if (env$gNIV > 0)
          {
               gIDS <- env$gIDS 
               C    <- trans(b, env)
               
               if (env$gNIV > 1) C <- C[gIDS, ]
               
               if (env$gNIV == 1) C <- matrix(C[gIDS], ncol = env$gNIV)
          }

          p <- likelihood_user(fc = fc, b = C)
          
          p <- replace(p, is.na(p), 1e-323)
          
          p0 <- rep(1,env$gNP)

          p0 <- .C("aggregation", 
             as.double(env$gIDS), 
             as.double(env$gNOBS),
             as.double(env$gNP),
             as.double(p),
             as.double(1:env$gNP),
             as.double(p0)
          )[[6]]
          
          p0 <- replace(p0, p0 < 1e-323, 1e-323)
               
          return(p0)
     }
     
     # Assign user controls
     # TODO: handle this differently once hb() no longer operates on an environment of inputs
     for (input in names(control)) assign(input, value = control[[input]])
     useCustomPVMatrix <- if (is.null(pvMatrix)) {FALSE} else {TRUE}
     
     # ------------------
     # FIXED GLOBAL VARIABLES
     # These should not be over-written by the analyst
     
     # variable initialization
     gNP           <- 0         # number of individuals used in the model estimation
     gNOBS         <- 0         # number of observations
     TIMES         <- 0         # Number of observations for each person
     gIDS          <- 0         # index map for individual to observation
     respIDs       <- 0         # vector of unique identifiers
     A             <- 0         # vector of means for the underlying normal distribution for the random coefficients
     B             <- 0         # matrix of respondent specific coefficients
     Dmat          <- 0         # var-covar for the set of preferences
     
     Choice        <- 0         # vector of choices
     
     gNIV          <- length(gVarNamesNormal)         # Number of random normal coefficients
     gFIV          <- length(gVarNamesFixed)         # Number of fixed (non-random) coefficients

     if (is.null(pvMatrix) & gNIV > 0) pvMatrix <- priorVariance * diag(gNIV)

     # need to make sure the pvMatrix is a matrix
     if (!is.matrix(pvMatrix) & gNIV > 0) stop("\npvMatrix is not a matrix. Make sure that your prior covariance matrix is ",gNIV," by ",gNIV,".")
     
     # need to fail if pvMatrix is of the wrong size
     if (!is.null(pvMatrix) & gNIV > 0) {
          if (nrow(pvMatrix) != gNIV | ncol(pvMatrix) != gNIV) stop("\nThe prior covariance matrix is of the wrong size. Make sure that your prior covariance matrix is ",gNIV," by ",gNIV,".")
     }
     
     # prior covariance matrix labels
     rownames(pvMatrix) <- colnames(pvMatrix) <- gVarNamesNormal
     
     begintime     <- Sys.time()    # used to calculate overall estimation time
     starttime     <- Sys.time()    # used to calculate seconds per iteration
     
     distNames     <- c("N", "LN+", "LN-", "CN+", "CN-", "JSB")  # short names for the distributions
                      # Normal, Postive Log-Normal, Negative Log-Normal, Positive Censored Normal, Negative Censored Normal, Johnson SB
     constraintLabels <- c("<", ">")     
     
     # acceptance rate calculations
     acceptanceRatePerc  <- 0
     acceptanceRateF     <- 0    # this is the count over the last 100 iterations.
     acceptanceRateFPerc <- 0
     
     rhoFadj         <- 1e-5
     
     if (checkModel(nodiagnostics = nodiagnostics, verbose = verbose))
     {     
          r <- 1
          # Post Burn-in iterations          
          ma <- matrix(0, nrow = gNIV, ncol = gNEREP)
          md <- array(0, dim = c(gNIV, gNIV, gNEREP), dimnames = list(NULL, NULL, 1:gNEREP))
          mb <- matrix(0, nrow = gNP, ncol = gNIV)
          mb.squared <- matrix(0, nrow = gNP, ncol = gNIV)
          mp <- matrix(0, nrow = gNP, ncol = gNEREP)
          mf <- matrix(0, nrow = gFIV, ncol = gNEREP)
          mc <- matrix(0, nrow = gNP, ncol = gNIV)
          mc.squared <- matrix(0, nrow = gNP, ncol = gNIV)      # variance calculation     
          storedDraws <- list()
          
          # object to store the model results and settings
          results <- list(modelname = modelname,
                          params.fixed = gVarNamesFixed,
                          params.vary = gVarNamesNormal,
                          distributions = distNames[gDIST],
                          pv = pvMatrix,
                          df = degreesOfFreedom,
                          gNP = gNP,
                          gNOBS = gNOBS,
                          gNCREP = gNCREP,
                          gNEREP = gNEREP,
                          constraints = constraintsNorm,
                          iter.detail = data.frame(Iteration = NA,
                                                   `Log-Likelihood` = NA,
                                                   RLH = NA,
                                                   `Parameter RMS` = NA,
                                                   `Avg. Variance` = NA,
                                                   `Acceptance Rate (Fixed)` = NA,
                                                   `Acceptance Rate (Normal)` = NA,
                                                   check.names = FALSE)
          )
          
          # object to hold the sample-level log-likelihoods
          sLikelihood <- NULL
          
          hb(A, B, Dmat, FC)
          
          if(gNIV > 0)
          {
               ma   <- cbind(iteration = (gNCREP + 1):(gNCREP + gNEREP), t(ma))
               
               mcsd <- cbind(id = respIDs, sqrt((mc.squared - mc^2/gNEREP)/gNEREP))
               mc   <- cbind(id = respIDs, RLH = rowMeans(mp), mc/gNEREP)
               
               mbsd <- cbind(id = respIDs, sqrt((mb.squared - mb^2/gNEREP)/gNEREP))
               mb   <- cbind(id = respIDs, mb/gNEREP)
               colnames(mc) <- c("Respondent", "RLH", gVarNamesNormal)
               colnames(ma) <- c("iteration", gVarNamesNormal)
               
               colnames(mcsd) <- c("id", gVarNamesNormal)
               colnames(mb)   <- c("id", gVarNamesNormal)
               colnames(mbsd) <- c("id", gVarNamesNormal)
               
               results$A   <- ma
               results$B   <- mb
               results$Bsd <- mbsd
               results$C   <- mc
               results$Csd <- mcsd
               results$D   <- md
          }
          
          if (gFIV > 0)
          {   
               mf  <- cbind(iteration = (gNCREP + 1):(gNCREP + gNEREP), t(mf))
               colnames(mf) <- c("iteration", gVarNamesFixed)
               results$F <- mf
          }          
          
          if (gStoreDraws)
          {
               results$Draws <- storedDraws
               names(results$Draws) <- respIDs
               
          }
          
          # store choice data, final probabilities, and other information
          results$choices <- Choice
          results$p <- likelihood_user(fc = if (is.null(results[["F"]])) {NULL} else {colMeans(as.matrix(results[["F"]][, -1]))},
                                       b = if (is.null(results[["C"]])) {NULL} else {as.matrix(results[["C"]][gIDS, -c(1:2)])})
          results$ll0 <- sum(log(likelihood_user(fc = FC, b = matrix(svN, ncol = length(svN), nrow = length(gIDS), byrow = TRUE))))
          results$llf <- sum(log(results[["p"]]))
          results[["iter.detail"]] <- results[["iter.detail"]][-1, ]
          
          results$sLikelihood <- sLikelihood
          
          if (verbose) cat("Estimation complete.\n")
          
          class(results) <- "RSGHB"
          
     } else {
       results <- NULL
     }

     return(results)
}
