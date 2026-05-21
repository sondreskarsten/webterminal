skip_if_no_ttyd <- function() {
  skip_if(Sys.which("ttyd") == "", "ttyd not installed")
}

skip_if_no_shellinaboxd <- function() {
  skip_if(Sys.which("shellinaboxd") == "", "shellinaboxd not installed")
}

skip_if_no_tmux <- function() {
  skip_if(Sys.which("tmux") == "", "tmux not installed")
}

skip_if_not_rstudio <- function() {
  skip_if(!rstudioapi::isAvailable(), "Not running inside RStudio")
}
