#'@details  Run Config first. Then run aws_helper.
#'@downstream Petco_PostgresConnection
#'@return   DB Password, AWS S3 Environment Access Key, Secret Access Key.

get_aws_secret <- function (secret_key, SecretID){
  #'@param  secret_key [str] secret key required to be returned.
  #'@param  SecretID [str] AWS_ARN_SECRETS string. 
  
  svc <- paws::secretsmanager(
    config = list(
      credentials = list(
        creds = list(
          access_key_id = Sys.getenv("AWS_ACCESS_KEY_ID"),
          secret_access_key = Sys.getenv("AWS_SECRET_ACCESS_KEY")
        ),
        profile = "default"
      ),
      region = config$AWS_DEFAULT_REGION
    )
  )
  
  secret_value <- svc$get_secret_value(SecretId = SecretID)
  
  # Parse into dataframe
  secret_strings <- as.data.frame(jsonlite::parse_json(secret_value$SecretString))
  
  # Filter for secret key
  access_key <- secret_strings %>% dplyr::select(one_of(secret_key)) %>% 
    unlist(., use.names = F)
  return(access_key)
}

## Execution to get DB PASSWORD.
set_config <- function(){
  Sys.setenv("AWS_ACCESS_KEY_ID" = config$AWS_ACCESS_KEY_ID,
             "AWS_SECRET_ACCESS_KEY" = config$AWS_SECRET_ACCESS_KEY,
             "AWS_DEFAULT_REGION" = config$AWS_DEFAULT_REGION, 
             "AWS_S3_ENDPOINT" = config$AWS_S3_ENDPOINT)
  bucket_name_raphael_dev <<- config$AWS_RAPHAEL_BUCKET_NAME
}
unload_config <- function(){
  Sys.unsetenv("AWS_ACCESS_KEY_ID")
  Sys.unsetenv("AWS_SECRET_ACCESS_KEY")
  Sys.unsetenv("AWS_DEFAULT_REGION")
  Sys.unsetenv("AWS_S3_ENDPOINT")
  print ("Successfully unset Environmrnt keys...")
}
set_config()

uploadObjS3 <- function (obj, s3folder_path, s3file_name){
  #'@description  Uploads object from local to s3 bucket production
  #'@param  obj   Object path from local.
  #'@param  s3folder_path Location/folder in s3.
  #'@param  s3file_name Name of file to be saved as in s3 folder. Must include extensions of file
  #'e.g. .csv, .RDS, .log
  
  current_date <- gsub("-|:| ", "", Sys.Date())
  
  object_name <- paste0(s3folder_path, "/",
                        s3file_name)
  
  put_object(file = obj,
             object = object_name,
             bucket = bucket_name_raphael_dev)
  
  cat (glue::glue("Uploaded {object_name} into {s3folder_path}"))
}
# Returns PostgresDB Password.
DB_PASSWORD = get_aws_secret(secret_key = "DB_PASSWORD", SecretID = config$AWS_SECRETS_ARN) %>% 
  as.character()
Sys.setenv("DB_PASSWORD" = DB_PASSWORD)
set_config()