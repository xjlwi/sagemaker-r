## libraries ####
pacman::p_load(dplyr, glue, futile.logger, tryCatchLog, here)

universal_start_time <- Sys.time()
log_file_name <- "log_main_monthly_model"

## FUNCTIONS ####
Sys.setenv("ENVIRONMENT_FLAG" = 'production')
source(paste0(here::here(), "/src/sm/samples/SetupSysEnv.R"))
source(paste0(here::here(), "/src/sm/samples/logging_config.R"))

#Check for monthly_features
flog.info(glue::glue("Running Model Training Monthly."))
  
## DECLARE MODEL DIR 
model_dir <- paste0(here::here(), "/opt/ml/model/")
if (!dir.exists(model_dir)){
  dir.create(model_dir, recursive=T)
  print ("Created model directory.")
}else{
  print ("Model directory exists!")
}
write.csv(data.frame(), paste0(model_dir, "dummy.csv"))

## Pickup log file, upload to S3 ----
log_file_name <- "log_model_trigger_monthly_crude_jetkero_gasoline95_SM"
source(paste0(here::here(), "/raphael/utils/logging_config.R"))
bucket_name_raphael_dev <- config$AWS_RAPHAEL_BUCKET_NAME
uploadObjS3 (obj = log_file, s3folder_path = "log_files", 
             s3file_name = paste0(log_file_name, "_", current_date, ".log"))