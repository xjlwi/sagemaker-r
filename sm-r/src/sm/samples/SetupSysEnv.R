#'@author Crystal Lwi
#'@version  1.0 26 Aug 2021
#'@details  This script will do 3 things: 
#   1) get ENVIRONMENT_FLAG, 
#   2) Sets-up DB, AWS S3 Endpoint Configurations
#   3) Connects to respective Production/Development Endpoints for RDS and S3 services.

# Set Environment for Production or Dev
pacman::p_load(paws, config, aws.s3, here)

# This is passed from Dockerfile. or if local, source manually.
ENV_FLAG <- Sys.getenv("ENVIRONMENT_FLAG")

# Set Sys.env first.
if (ENV_FLAG == "production"){
  print ("Setting System Environment to : Production")
  Sys.setenv("R_CONFIG_ACTIVE" = "production") # set to production for config.yml
}else if (ENV_FLAG == "development"){
  print ("Setting System Environment to : Development")
  Sys.setenv("R_CONFIG_ACTIVE" = "default") # default is Development.
}
# Get Config based on Environment
print(here::here())
print (list.files(here::here(), recursive=TRUE))
config <<- config::get(file = paste0(here::here(), "/config.yml"), use_parent = FALSE)
# Set DB Password, AWS S3 Enviroment
source(paste0(here::here(), "/src/sm/samples/aws_helper.R")) # Returns DB Password, AWS S3 bucket env

# Run Postgres DB Functions 
if (ENV_FLAG == "production"){
  source(paste0(here::here(), "/src/sm/samples/Petco_PostgreSQL_ConnectionServer.R"))
  print ("Connected to Production RDS.")
}else if (ENV_FLAG == "development"){
  source(paste0(here::here(), "/src/sm/samples/Petco_PostgreSQL_ConnectionServerDevelopment.R"))
  print ("Connected to Development RDS.")
}
