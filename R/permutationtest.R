#' Integrated Welch-t Squared Permutation Test for Two Samples of x-y-Data
#' 
#' Perform a permutation test of equal distribution (mean) for two  samples of 
#' functional or multivariate data.
#' @param sample1,sample2 lists of function values, object of type \code{\link{fdsample}}, 
#'   need to have identical x-values. 
#' @param use.tbar logical, defaults to \code{FALSE}. If \code{TRUE}, integrated squared
#'  mean differences are divided by integrated variance, see `Details'.
#' @param nperm \code{NULL} or an integer giving the number of random 
#'   permutations. If \code{NULL}, all permutations are used. Only feasible if 
#'   group sizes \eqn{m_1}, \eqn{m_2} do not exceed 10. Default value is 25000,
#'   thus all permutations will be used on groups with \code{m_1 = m_2 =9}.
#' @details Test statistics are integral means of studentized square distances 
#'   between the group means. The test statistics are closely related, but not 
#'   equal to Hotelling's two-sample T-squared statistic. It is assumed that 
#'   the functions all have the same, equidistant arguments. Depending on the 
#'   value of \code{use.tbar}, the test statistic is either
#'   \itemize{
#'   \item \eqn{T = mean [ (mu_1(x)-mu_2(x))^2 / (s_1^2(x)/m_1 + s_2^2(x)/m_2) ]}    or
#'   \item \eqn{Tbar = mean [ (mu_1(x)-mu_2(x))^2 ] / mean[ s_1^2(x)/m_1 + s_2^2(x)/m_2 ]}
#'   }
#'   where \eqn{m_1} \eqn{m_2} denote the group sizes
#'   for  \code{sample1} and \code{sample2}, and \eqn{mu_1(x), mu_2(x)} 
#'   and \eqn{s_1^2(x), s_2^2(x)} are within group 
#'   means and variances at a fixed argument \eqn{x}. 
#'   To calculate T, the mean is taken over all \eqn{n} arguments \eqn{x}.
#'   

#'   If \code{nperm} is given as an integer, the permutations are sampled randomly, 
#'   unless \code{nperm} is larger than the number of disjoint combinations. In that
#'   case, and also if \code{nperm == NULL}, the exact test with all permutations is used
#'   (combinations, for symmetry reasons). If this causes memory or computing 
#'   time issues, set \code{nperm} to a fixed value. 
#' @return 
#' A list with class \code{"htest"} containing the following components:
#' \item{statistic}{the value of the test statistic,}
#' \item{p.value}{the p-value of the test,}
#' \item{alternative}{a character string describing the alternative hypothesis,}
#' \item{method}{a character string indicating what type of test was performed,}
#' \item{data.name}{a character string giving the name(s) of the data.}
#'    
#' @examples
#' # test the difference of atlantic and continental Canadian temperature curves
#' tL2.permtest(TempAtla, TempCont, nperm = 999)
#'    
#' @author Ute Hahn,  \email{ute@@imf.au.dk}
#' @export
#' @source Hahn(2012), with slight modification (using the mean instead of the 
#'    integral, in order to avoid having to pass the arguments of the functions)
#' @references Hahn, U. (2012) A Studentized Permutation Test for the Comparison 
#' of Spatial Point Patterns. \emph{Journal of the American Statistical 
#' Association},  \bold{107} (498), 754--764.
#' @keywords htest
#' @keywords robust
#' @keywords nonparametric
#' @keywords ts    

tL2.permtest <- function (sample1, sample2, nperm = 25000, use.tbar=FALSE)
{
  ##### preparations ----------------
  if(sample1$dimarg != sample2$dimarg) stop("not the same length of x vector")
  if(mean( abs(sample1$args - sample2$args))/mean(abs(sample1$args)) > 0.05)  
    stop("not even approximately the same x-values")
  m1 <- sample1$groupsize
  m2 <- sample2$groupsize
  if (m1 <2 | m2 < 2) stop("need at least two y-vectors per group")
  m <- m1+m2
  foos <- cbind(sample1$fvals, sample2$fvals)
  # get the permutations. 
  # If m1 == m2, break the symmetry and save half time and memory!
  
  allcomb <- is.null(nperm)
  ncomb <- if (m1 == m2) choose(m-1, m1-1) else choose(m, m1)
  # if nperm is larger than the actual number of combinations, also use all of them
  if (!allcomb)
  {
    # ncomb <- if (m1 == m2) choose(m-1, m1-1) else choose(m, m1)
    if (ncomb < (nperm + 1)) allcomb <- TRUE
  }
  if (allcomb) 
    {
      if (m1 == m2) index1 <- rbind(1, combn(m - 1, m1 - 1) + 1)
      else index1 <- combn(m, m1)
    } else {
      if (m1 == m2) index1 <- rbind(1, replicate(nperm, sample(m - 1, m1 - 1) + 1)) 
      else index1 <- replicate(nperm, sample(m, m1)) 
      index1 <- cbind((1 : m1), index1) # the first is the original
    }
   
  # do the calculations the good old fashioned way with sums and sqs, to save time
  
  SX. <- apply (foos, 1, sum)
  SXX. <- apply (foos^2, 1, sum)
  
  Tstatistic <- function (ind) # could be further optimized in symmetric case 
  {
    SX1 <- apply(foos[, ind], 1, sum)
    SXX1 <- apply(foos[, ind]^2, 1, sum)
    SX2 <- SX. - SX1
    SXX2 <- SXX. - SXX1
    mu1 <- SX1 / m1 
    mu2 <- SX2 / m2
    ss1 <- (SXX1 - (SX1^2 / m1)) / ((m1-1) / m1)
    ss2 <- (SXX2 - (SX2^2 / m2)) / ((m2-1) / m2)
    
    if (use.tbar) return (sum((mu1 -mu2)^2) / sum((ss1 + ss2))) else 
                  return (mean((mu1 -mu2)^2 / (ss1 + ss2), na.rm=T))
  }
  
  Tvals <- apply(index1, 2, Tstatistic)
  
  pval <- mean(Tvals >= Tvals[1])           
  stat <- Tvals[1]
  names(stat) <- if(use.tbar) "Tbar" else "T"
  datname <- paste( deparse(substitute(sample1)),"and", deparse(substitute(sample2)))
  method <- c(paste("Studentized two sample permutation test for fda, using T",
                  ifelse(use.tbar, "bar", ""), sep=""),
              ifelse(allcomb, paste("exact test, using all",ncomb,"permutations (combinations)"), 
                        paste("using",nperm,"randomly selected permuations")))
  alternative <- "samples not exchangeable"
  ptt <- list(statistic = stat, 
              p.value = pval, 
              alternative = alternative, 
              method = method, 
              data.name = datname)
  class(ptt) <- "htest"
  return(ptt)
}
  