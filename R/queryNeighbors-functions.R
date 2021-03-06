#' Query neighbors in range
#' 
#' Find all neighboring data points within a certain distance of a query point.
#' 
#' @inheritParams findNeighbors-functions
#' @param query A numeric matrix of query points, containing different data points in the rows but the same number and ordering of dimensions in the columns.
#' @param threshold A positive numeric scalar specifying the maximum distance at which a point is considered a neighbor.
#' Alternatively, a vector containing a different distance threshold for each query point.
#' @param transposed A logical scalar indicating whether the \code{query} is transposed, 
#' in which case \code{query} is assumed to contain dimensions in the rows and data points in the columns.
#' @param subset A vector indicating the rows of \code{query} (or columns, if \code{transposed=TRUE}) for which the neighbors should be identified.
#' 
#' @details
#' This function identifies points in \code{X} that are neighbors (i.e., within a distance \code{threshold}) of each point in \code{query}.
#' The exact implementation can either use the KMKNNN approach or a VP tree.
#' This requires both \code{X} and \code{query} to have the same number of variables.
#' 
#' By default, neighbors are identified for all data points within \code{query}.
#' If \code{subset} is specified, neighbors are only detected for the query points in the subset.
#' This yields the same result as (but is more efficient than) subsetting the output matrices after running \code{queryNeighbors} on the full \code{query}.
#' 
#' If \code{threshold} is a vector, each entry is assumed to specify a (possibly different) threshold for each point in \code{query}.
#' If \code{subset} is also specified, each entry is assumed to specify a threshold for each point in \code{subset}.
#' An error will be raised if \code{threshold} is a vector of incorrect length.
#' 
#' Turning off \code{get.index} or \code{get.distance} will provide a slight speed boost and reduce memory usage when those returned values are not of interest.
#' If both \code{get.index=FALSE} and \code{get.distance=FALSE}, an integer vector containing the number of neighbors to each point is returned instead, 
#' which is more memory efficient when the identities of/distances to the neighbors are not required.
#' 
#' If \code{transposed=TRUE}, this function assumes that \code{query} is already transposed, which saves a bit of time by avoiding an unnecessary transposition.
#' Using \code{BPPARAM} will also split the search by query points across multiple processes.
#' 
#' If multiple queries are to be performed to the same \code{X}, it may be beneficial to build the index from \code{X} (e.g., with \code{\link{buildKmknn}}).
#' The resulting BiocNeighborIndex object can be supplied as \code{precomputed} to multiple function calls, avoiding the need to repeat index construction in each call.
#' Note that when \code{precomputed} is supplied, the value of \code{X} is ignored.
#' 
#' @return
#' A list is returned containing:
#' \itemize{
#'     \item \code{index}, if \code{get.index=TRUE}.
#'         This is a list of integer vectors where each entry corresponds to a point (denoted here as \eqn{i}) in \code{query}.
#'         The vector for \eqn{i} contains the set of row indices of all points in \code{X} that lie within \code{threshold} of point \eqn{i}.
#'         Points in each vector are not ordered, and \eqn{i} will always be included in its own set.
#'     \item \code{distance}, if \code{get.distance=TRUE}.
#'         This is a list of numeric vectors where each entry corresponds to a point (as above) and contains the distances of the neighbors from \eqn{i}.
#'         Elements of each vector in \code{distance} match to elements of the corresponding vector in \code{index}.
#' }
#' If \code{get.index=FALSE} and \code{get.distance=FALSE}, an integer vector is returned instead containing the number of neighbors to \eqn{i}.
#' 
#' If \code{subset} is not \code{NULL}, each entry of the above lists refers to a point in the subset, in the same order as supplied in \code{subset}.
#' 
#' See \code{?"\link{BiocNeighbors-raw-index}"} for an explanation of the output when \code{raw.index=TRUE}.
#' 
#' @author
#' Aaron Lun
#' 
#' @seealso
#' \code{\link{buildKmknn}} or \code{\link{buildVptree}} to build an index ahead of time.
#' 
#' See \code{?"\link{BiocNeighbors-algorithms}"} for an overview of the available algorithms.
#' 
#' @examples
#' Y <- matrix(rnorm(100000), ncol=20)
#' Z <- matrix(rnorm(20000), ncol=20)
#' 
#' out <- rangeQueryKmknn(Y, query=Z, threshold=1)
#' head(out$index)
#' head(out$distance)
#' 
#' out2 <- rangeQueryVptree(Y, query=Z, threshold=1)
#' head(out2$index)
#' head(out2$distance)
#' 
#' out3 <- rangeQueryExhaustive(Y, query=Z, threshold=1)
#' head(out3$index)
#' head(out3$distance)
#' 
#' @name queryNeighbors-functions
NULL

#' @export
#' @rdname queryNeighbors-functions
#' @importFrom BiocParallel SerialParam 
rangeQueryExhaustive <- function(X, query, threshold, get.index=TRUE, get.distance=TRUE, BPPARAM=SerialParam(), precomputed=NULL, transposed=FALSE, subset=NULL, raw.index=FALSE, ...)
{
    .template_range_query_exact(X, query, threshold, get.index=get.index, get.distance=get.distance, BPPARAM=BPPARAM, precomputed=precomputed, 
        transposed=transposed, subset=subset, raw.index=raw.index, 
        buildFUN=buildExhaustive, searchFUN=range_query_exhaustive, searchArgsFUN=.find_exhaustive_args, ...) 
}

#' @export
#' @rdname queryNeighbors-functions
#' @importFrom BiocParallel SerialParam 
rangeQueryKmknn <- function(X, query, threshold, get.index=TRUE, get.distance=TRUE, BPPARAM=SerialParam(), precomputed=NULL, transposed=FALSE, subset=NULL, raw.index=FALSE, ...)
{
    .template_range_query_exact(X, query, threshold, get.index=get.index, get.distance=get.distance, BPPARAM=BPPARAM, precomputed=precomputed, 
        transposed=transposed, subset=subset, raw.index=raw.index, 
        buildFUN=buildKmknn, searchFUN=range_query_kmknn, searchArgsFUN=.find_kmknn_args, ...) 
}

#' @export
#' @rdname queryNeighbors-functions
#' @importFrom BiocParallel SerialParam 
rangeQueryVptree <- function(X, query, threshold, get.index=TRUE, get.distance=TRUE, BPPARAM=SerialParam(), precomputed=NULL, transposed=FALSE, subset=NULL, raw.index=FALSE, ...)
{
    .template_range_query_exact(X, query, threshold, get.index=get.index, get.distance=get.distance, BPPARAM=BPPARAM, precomputed=precomputed, 
        transposed=transposed, subset=subset, raw.index=raw.index, 
        buildFUN=buildVptree, searchFUN=range_query_vptree, searchArgsFUN=.find_vptree_args, ...)
}
