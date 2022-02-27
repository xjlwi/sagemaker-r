## libraries ####
pacman::p_load(dplyr, glue, futile.logger, tryCatchLog, here, caret) # we are using R futile.logger for logging.


universal_start_time <- Sys.time()
log_file_name <- "log_main_monthly_model"

## FUNCTIONS ####
# `here::here()` refers to root directory.
Sys.setenv("ENVIRONMENT_FLAG" = 'development') # determine the production or development. 
source(paste0(here::here(), "/src/sm/samples/SetupSysEnv.R")) # Sys Env is to connect to the AWS Environment, whether Production or development
source(paste0(here::here(), "/src/sm/samples/logging_config.R")) 
source(paste0(here::here(), "/src/sm/samples/model_settings.R")) # Load model constants and sample dataset.

#Check for monthly_features
flog.info(glue::glue("Creating model directory. Successfully loaded model_settings.R"))
  
## DECLARE MODEL DIR =============== 
#   This is unique for Sagemaker Processing and Model Training functions.
## =================================
model_dir <- paste0(here::here(), "/opt/ml/model/")
if (!dir.exists(model_dir)){
  dir.create(model_dir, recursive=T)
  print ("Created model directory.")
}else{
  print ("Model directory exists!")
}

## Create an empty dummy csv ##
write.csv(data.frame("This is a sample file."), paste0(model_dir, "dummy.csv"))
cat(glue::glue(" ------------------
    Empty Dummy data frame created from main_monthly_model_sagemaker demo.R 
   ------------------"))
flog.info(glue::glue("Created empty dummy dataset."))

## Create a Classification Model using Iris dataset ##
flog.info(glue::glue("Running Model Training for Iris Monthly."))

set.seed(7)
fit.cart <- train(Species ~., data=dataset, method= "rpart", metric=metric, trControl= control)
cat(glue::glue(" -----------------
    Created a Training model for classification of iris dataset.
    -----------------"))
uploadModelSM(model= fit.cart,
              model_dir,
              model_version = "cart")


## Pickup log file, upload to S3 ##
log_file_name <- "log_main_monthly_model"
source(paste0(here::here(), "/src/sm/samples/logging_config.R"))
bucket_name_raphael_dev <- config$AWS_RAPHAEL_BUCKET_NAME
uploadObjS3 (obj = log_file, s3folder_path = "log_files/SagemakerDemo", 
             s3file_name = paste0(log_file_name, "_", current_date, ".log"))
