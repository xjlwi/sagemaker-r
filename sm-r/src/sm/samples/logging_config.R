

## Logging folder path
log_path <- paste0(here::here(), "/raphael/data/logs/")
if (!dir.exists(log_path)){
  dir.create(log_path, recursive = T)
} else {
  print("Logging folder already exists!")
}
current_date  <- gsub(":|-| ", "", Sys.Date())
# Log only errors (not warnings or info messages)
set.logging.functions(info.log.func = function(msg) invisible())
flog.threshold(INFO)   # TRACE, DEBUG, INFO, WARN, ERROR, FATAL
log_file <- paste0(here::here(), "/raphael/data/logs/", 
                   log_file_name, "_", current_date, ".log")
flog.appender(appender.file(log_file))
options(keep.source = TRUE) # Track source code references of scripts 
options(verbose = FALSE)