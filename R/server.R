##' Default middleware.
##'
##' All default middlewares are stored within \code{middlewares} environment
##' inside this package. Users and add-on packages can append custom middleware
##' to this environment. See help page of \code{\link{middleware}} for more
##' details.
##'
##' Default middlewares are:
##' \itemize{
##'
##'   \item{mw_session}{Return a handler for interactive evaluation. Provides
##' "eval" operation.}
##'      
##'   \item{mw_describe}{Return a handler for session management. Supported ops
##' are "clone", "close" and "ls-sessions".}
##'
##'   \item{mw_eval}{Return a handler for interactive evaluation. Provides
##' "eval" operation.}
##' 
##' }
##' @name middlewares
NULL

##' @export
middlewares <-
    list2env(list(session = mw_session, 
                  describe = mw_describe,
                  eval = mw_eval))

##' nREPL Server.
##'
##' nREPL server is a blocking connection that waits for requests from the nREPL
##' client and sends the responses back.
##'
##' \code{default_handler} returns a handler which is a stack of handlers
##' produced by default middlewares.
##'
##' @name server
##' @param port Port number on which to start an nREPL server.
##' @param handler Function of variable arity to process incoming requests.
##' @param transport_fn Constructor that returns a transport connection
##' object. See \code{\link{transport}}.
##' @seealso \link{middlewares}
##' @export
start_server <- function(port = 4005,
                         handler = default_handler(),
                         transport_fn = transport_bencode){
    cat("Started server on port =", port, "\nWaiting for conection ... ")
    ss <- socketConnection(port = port, server = TRUE, open = "r+b")
    transport <- transport_fn(ss)
    cat("connection established.\n")
    on.exit(transport$close())
    handle_messages(transport, handler)
}

##' @rdname server
##' @param additional_middlewares A list of middleware functions to merge into
##' the list of default \code{\link{middlewares}}
##' @export
default_handler <- function(additional_middlewares = list()){
    add_session_maybe(mw_session(mw_eval(mw_describe(unknown_op))))
}

## default_handler <- function(additional_middlewares = list()){
##     mws <- c(as.list(middlewares),
##              additional_middlewares)
##     mws <- linearize_mws(mws)
##     add_session_maybe(Reduce(function(f, h) f(h), mws, init = unknown_op, right = T))
## }

handle_messages <- function(transport, handler){
    while(TRUE){
        msg <- transport$read(10)
        if(!is.null(msg)){
            do.call(handler, assoc(msg, transport = transport))
            ## tryCatch(do.call(handler, assoc(msg, transport = transport)),
            ##          error = function(e){
            ##              cat("Unhandled exception on message\n")
            ##              print(msg)
            ##              cat(as.character(e))
            ##          })
        }
    }
}