## libraries ####
pacman::p_load(dplyr, glue, futile.logger, tryCatchLog, here)

universal_start_time <- Sys.time()
log_file_name <- "log_model_trigger_monthly_crude_jetkero_gasoline95_SM"

## FUNCTIONS ####
Sys.setenv("ENVIRONMENT_FLAG" = 'production')
source(paste0(here::here(), "/raphael/utils/SetupSysEnv.R"))
source(paste0(here::here(), "/raphael/modelling/helper/trigger_checking_functions.R"))
source(paste0(here::here(), "/raphael/utils/logging_config.R"))


#Check for monthly_features
MONTHLYFEATURESFLAG <- check_monthly_features()
MONTHLYFORECASTFLAG <- check_monthly_forecasts()

if (MONTHLYFEATURESFLAG == TRUE & MONTHLYFORECASTFLAG == FALSE){
  flog.info(glue::glue("Running Model Training Monthly for crude, jetkero and gasoline95..."))
  
  source(paste0(here::here(),"/raphael/modelling/crude/monthly/main_modelling_monthly_crude.R"))
  source(paste0(here::here(),"/raphael/modelling/crude/monthly/main_modelling_monthly_crude_forecast.R"))
  
  source(paste0(here::here(),"/raphael/modelling/jetkero/monthly_train/main_modelling_monthly_jetkero.R"))
  source(paste0(here::here(),"/raphael/modelling/jetkero/monthly_train/main_modelling_monthly_forecast_jetkero.R"))
  
  source(paste0(here::here(), "/raphael/modelling/Gasoline95/Monthly Model/gasoline95_brent_dubai_model_save.R"))
  source(paste0(here::here(),"/raphael/modelling/Gasoline95/Monthly/gasoline95_brent_dubai_monthly_forecast.R"))
}else if(MONTHLYFEATURESFLAG == FALSE | MONTHLYFORECASTFLAG == TRUE){ 
  #if monthly features is not available or monthly forecast is already available then skip execution
  if(MONTHLYFEATURESFLAG == FALSE){
    flog.info(glue::glue("\t Monthly features not available. Skipped monthly model {Sys.Date()}. 
                       Proceeding with daily adjustment using M-1 forecasts"))
    print(glue::glue("\t Monthly features not available. Skipped monthly model {Sys.Date()}. 
                       Proceeding with daily adjustment using M-1 forecasts"))
  } else if(MONTHLYFORECASTFLAG == TRUE){
    flog.info(glue::glue("\t Monthly forecast already available. Skipped monthly model {Sys.Date()}."))
    print(glue::glue("\t Monthly forecast already available. Skipped monthly model {Sys.Date()}."))
  }
  ## DECLARE MODEL DIR 
  model_dir <- paste0(here::here(), "/opt/ml/model/")
  if (!dir.exists(model_dir)){
    dir.create(model_dir, recursive=T)
    print ("Created model directory.")
  }else{
    print ("Model directory exists!")
  }
  write.csv(data.frame(), paste0(model_dir, "dummy.csv"))
}

## Pickup log file, upload to S3 ----
log_file_name <- "log_model_trigger_monthly_crude_jetkero_gasoline95_SM"
source(paste0(here::here(), "/raphael/utils/logging_config.R"))
bucket_name_raphael_dev <- config$AWS_RAPHAEL_BUCKET_NAME
uploadObjS3 (obj = log_file, s3folder_path = "log_files", 
             s3file_name = paste0(log_file_name, "_", current_date, ".log"))