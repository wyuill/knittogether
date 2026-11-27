local({
  # Ensure VS Code session watcher is attached in this workspace.
  if (!interactive() || Sys.getenv("TERM_PROGRAM") != "vscode") {
    return(invisible())
  }

  if ("tools:vscode" %in% search()) {
    return(invisible())
  }

  init_file <- path.expand("~/.vscode-R/init.R")
  if (!file.exists(init_file)) {
    return(invisible())
  }

  try(source(init_file, chdir = TRUE, local = TRUE), silent = TRUE)

  if (!("tools:vscode" %in% search()) && exists(".First.sys", envir = .GlobalEnv, inherits = FALSE)) {
    try(get(".First.sys", envir = .GlobalEnv)(), silent = TRUE)
  }

  invisible()
})
