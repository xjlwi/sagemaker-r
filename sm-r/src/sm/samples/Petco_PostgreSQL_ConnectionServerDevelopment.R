pacman::p_load(data.table, dplyr, RPostgreSQL, config)


pgupdateSQLTable <- function(table_name, data_df, database_datatypes, db_type = "PostgreSQL", 
                             append = TRUE, overwrite = FALSE){
    #'@param table_name : Table which the data will be written to. If there is a schema, please include in the table_name.
    #'@param data_df : Dataframe to be written to the database table.
    #'@param database_datatypes : Database metadata which contains the datatypes for each table.
    #'@param db_type : Type of database, used for referencing from database_datatypes.
    #'@param append : YES to append to the table.
    #'@param overwrite: YES to rewrite table entirely.
    #'@return No specific object to return.
    # Connection to database
    driver <- dbDriver("PostgreSQL")
    
    db_con <- dbConnect(driver, dbname = config$DB_NAME, 
                        host = config$DB_HOST,
                        port = config$DB_PORT, user = config$DB_USER, 
                        password = DB_PASSWORD,
                        options="-c search_path=schema1")
    
    # Getting the list of datatypes for writing to database
    varTypeDf <- database_datatypes %>% filter(table_name == table_name, data_type == db_type)
    # If there are different number of columns as compared to database_datatypes or mismatch in names, give warning.
    if (sum(!varTypeDf$Variable %in% colnames(data_df))){
        warning("The column names in data_df do not match that of in database_datatypes. Those which are not found will be excluded.")
    }
    # varTypeList <- varTypeDf$Datatype[which(varTypeDf$Variable %in% colnames(data_df))]
    # names(varTypeList) <- varTypeDf$Variable[which(varTypeDf$Variable %in% colnames(data_df))]
    # # Converting Boolean (TRUE/FALSE) columns to BIT datatype
    # boolean_colnames <- names(varTypeList)[which(varTypeList == 'BIT')]
    # data_df[boolean_colnames] <- sapply(data_df[boolean_colnames], function(x) as.integer(x))
    
    #sqlSave(db_con, data_df, table_name, append = append, rownames = FALSE, colnames = FALSE, verbose = verbose, safer = safer, varTypes = varTypeList)
    dbWriteTable(db_con, c("public", paste(table_name)), value = data_df, row.names = FALSE, append = append, overwrite = overwrite)
    
    on.exit(dbDisconnect(db_con))
}

pgsmartAppendSQL <- function(table_name, data_df, database_datatypes, datetime_colname = "DateTime", data_replace_days = 100){
    #'@param table_name : Table which the data will be written to. If there is a schema, please include in the table_name.
    #'@param data_df : Dataframe to be written to the database table.
    #'@param database_datatypes : Database metadata which contains the datatypes for each table.
    #'@param datetime_colname : The column name of datetime
    #'@param data_replace_days: How many rows of data in existing table to be replaced
    #'@return No specific object to return.
    # Connection to database
    driver <- dbDriver("PostgreSQL")
    
    db_con <- dbConnect(driver, dbname = config$DB_NAME, 
                        host = config$DB_HOST,
                        port = config$DB_PORT, user = config$DB_USER, password =DB_PASSWORD,
                        options="-c search_path=schema1")
    
    if (data_replace_days <= 0){
        stop("data_replace_days should be greater than 0.")
    }
    
    data_df <- data_df %>% arrange(!!as.symbol(datetime_colname))
    latest_datetime <- last(data_df[[datetime_colname]])
    
    # Finding out which DateTime to begin replacement
    delete_start_date <- latest_datetime - lubridate::days(data_replace_days)
    data_df_filtered <- data_df %>% filter(!!as.symbol(datetime_colname) >= delete_start_date)
    
    # Deleting previous data in SQL based on data_replace_days 
    sql_query_statement <- paste0('DELETE FROM public."', table_name, '" WHERE "', paste0(datetime_colname), '" >= ', paste0("'", as.character(delete_start_date)), "'")
    dbSendQuery(db_con, statement = sql_query_statement)
    dbDisconnect(db_con)
    
    # Appending new data into SQL table
    pgupdateSQLTable(table_name, data_df_filtered, database_datatypes, append = TRUE)
    
    on.exit(dbDisconnect(db_con))
}

### Function to Read Tables 
pgreadSQLTable <- function(table_name = NULL, sql_query_statement = NULL, database_datatypes = Database_Datatypes, db_type = "PostgreSQL"){
    #'@param table_name : Table which the data will be read from. If there is a schema, please include in the table_name.
    #'@param sql_query_statement : Can be provided in place of table_name to perform unique query on SQL table instead of reading entire table.
    
    # Connection to database
    driver <- dbDriver("PostgreSQL")
    
    db_con <- dbConnect(driver, dbname = config$DB_NAME, 
                        host = config$DB_HOST,
                        port = config$DB_PORT, user = config$DB_USER, 
                        password = DB_PASSWORD,
                        options="-c search_path=schema1")
    
    # Reading Table from SQL
    if (!is.null(table_name)){
        sql_query_statement <- paste0('SELECT * from public."', table_name, '"')
        sql_df <- dbGetQuery(db_con, sql_query_statement)
        
        # varTypeDf <- database_datatypes %>% filter(Table == table_name, DB_Type == db_type)
        # varTypeList <- varTypeDf$Datatype[which(varTypeDf$Variable %in% colnames(sql_df))]
        # names(varTypeList) <- varTypeDf$Variable[which(varTypeDf$Variable %in% colnames(sql_df))]
        # 
        # boolean_colnames <- names(varTypeList[which(varTypeList == 'BIT')])
        # if (length(boolean_colnames) > 0){
        #   sql_df[[boolean_colnames]] <- sapply(sql_df[[boolean_colnames]], function(x) as.logical(x))
        # }
        
        dbDisconnect(db_con)
        return (sql_df)
    } else if (!is.null(sql_query_statement)){
        # Checking if statement is SELECT (return dataframe), otherwise return NULL
        if (grepl("SELECT", sql_query_statement)){
            sql_df <- dbGetQuery(db_con, sql_query_statement, stringsAsFactors = FALSE)
            dbDisconnect(db_con)
            return (sql_df)
        } else {
            dbGetQuery(db_con, sql_query_statement)
            dbDisconnect(db_con)
            return (NULL)
        }
    } else {
        stop("Either table_name or sql_query_statement should be provided.")
    }
    on.exit(dbDisconnect(db_con))
}

## Check if Crude Forecast already exists in SQL Table, if not append to SQL Table.
pgupdateSQLTable_MonthlyForecast <- function (latest_forecast_df){
    
    existing_forecast <- pgreadSQLTable("monthly_forecast_phase2") %>% 
        as.data.frame() %>% 
        dplyr::mutate(keys = paste(date_time,model,crack_col,sep = "_"))
    
    existing_keys <- existing_forecast['keys'] %>% 
        as.vector()
    
    latest_forecast_df <- latest_forecast_df %>% 
        dplyr::mutate(keys = paste(date_time,model,crack_col,sep = "_")) %>% 
        dplyr::filter(!keys %in% existing_keys) %>% 
        dplyr::select(-keys)
    
    forecast_date <- latest_forecast_df['date_time'][1]
    
    ## Update to SQL if 
    if (nrow(latest_forecast_df)<1){
        print ("Forecast already exists in SQL Table!")
    }else{
        print (glue::glue("Updating monthly forecast to 'monthly_forecast_phase2' for {forecast_date}."))
        pgupdateSQLTable("monthly_forecast_phase2", latest_forecast_df, Database_Datatypes, append = T, overwrite = F)
    }
}

## Check if Crude Forecast already exists in SQL Table, if not append to SQL Table.
pgupdateSQLTable_DailyForecast <- function (latest_forecast_df){
    
    existing_forecast <- pgreadSQLTable("daily_forecast_phase2") %>% ##TODO add query by product
        as.data.frame() %>% 
        dplyr::mutate(keys = paste(date_time,model,crack_col,sep = "_"))
    
    existing_keys <- existing_forecast['keys'] %>% 
        as.vector()
    
    latest_forecast_df_filtered <- latest_forecast_df %>% 
        dplyr::mutate(keys = paste(date_time,model,crack_col,sep = "_")) %>% 
        dplyr::filter(!keys %in% existing_keys) %>% 
        dplyr::select(-keys)
    
    forecast_date <- latest_forecast_df_filtered['date_time'][1]
    
    ## Update to SQL if 
    if (nrow(latest_forecast_df_filtered)<1){
        print ("Forecast already exists in SQL Table!")
    }else{
        print (glue::glue("Updating daily forecast to 'daily_forecast_phase2' for {forecast_date}."))
        pgupdateSQLTable("daily_forecast_phase2", latest_forecast_df_filtered, Database_Datatypes, append = T, overwrite = F)
    }
}

## Check if a table already exists in SQL Table and append to SQL Table if exist.
## if the table does not exist, it will create a new table.
pgupdateSQLTable_with_checking <- function (latest_df, table_name, keys){
    
    #'@param latest_df: The dataframe to be pushed
    #'@param table_name: The name of the table in RDS DB
    #'@param keys: columns to be used a unique key identifier (to check if there is any duplicates)
    #check existing table in RDS DB
    existing_table <- pgGetTableNames()
    
    if(table_name %in% existing_table$table_name){
        
        #read existing table
        existing_forecast <- pgreadSQLTable(table_name) %>% 
            as.data.frame()
        
        #concatenate key columns   
        existing_forecast <- existing_forecast %>% 
            tidyr::unite("keys",all_of(keys),remove = FALSE)
        
        #convert keys column into vector
        existing_keys <- existing_forecast %>% 
            dplyr::pull(keys)
        
        latest_df <- latest_df %>% 
            tidyr::unite("keys",all_of(keys),remove = FALSE) %>% 
            dplyr::filter(!keys %in% existing_keys) %>% 
            dplyr::select(-keys)
        
        forecast_date <- latest_df$date_time[1]
        
        ## Update to SQL if 
        if (nrow(latest_df)<1){
            print ("Forecast already exists in SQL Table!")
            flog.info("Forecast already exists in SQL Table!")
        }else{
            flog.info (paste("\t Updating data to ", table_name,  "for days from ", forecast_date))
            pgupdateSQLTable(table_name, latest_df, Database_Datatypes, append = T, overwrite = F)
        }
    } else{
        pgupdateSQLTable(table_name, latest_df, Database_Datatypes, append = F, overwrite = T)
        flog.info("The table does not exist in RDS DB, pushing entire dataframe.")
    }   
    
    
}
pgGetSchema <- function(database_datatypes, db_type = "PostgreSQL"){
    #'@param database_datatypes : Database metadata which contains the datatypes for each table.
    #'@param db_type : Type of database, used for referencing from database_datatypes.
    #'@return A dataframe that contains all the table names in the RDS DB
    # Connection to database
    driver <- dbDriver("PostgreSQL")
    
    db_con <- dbConnect(driver, dbname = config$DB_NAME, 
                        host = config$DB_HOST,
                        port = 5432, user = config$DB_USER, password = DB_PASSWORD,
                        options="-c search_path=schema1")
    
    existing_table <- dbGetQuery(db_con,"SELECT table_name, column_name, data_type FROM information_schema.columns WHERE table_schema  = 'public'")
    on.exit(dbDisconnect(db_con))
    
    return(existing_table)
}
## Get existing table in RDS DB
pgGetTableNames <- function(database_datatypes, db_type = "PostgreSQL"){
    #'@param database_datatypes : Database metadata which contains the datatypes for each table.
    #'@param db_type : Type of database, used for referencing from database_datatypes.
    #'@return A dataframe that contains all the table names in the RDS DB
    # Connection to database
    driver <- dbDriver("PostgreSQL")
    
    db_con <- dbConnect(driver, dbname = config$DB_NAME, 
                        host = config$DB_HOST,
                        port = 5432, user = config$DB_USER, password = DB_PASSWORD,
                        options="-c search_path=schema1")
    
    existing_table <- dbGetQuery(db_con,"SELECT table_name FROM information_schema.tables")
    on.exit(dbDisconnect(db_con))
    
    return(existing_table)
}

### SQL Query Statements for daily forecast by crack_col
generateDailyQueryProduct <- function (crackCol, table_name){
    #'@details  Returns sql_query_statement for `table_name`.
    #'@param    crackCol [str] Unique crackCol string. Can contain one/more crackCols. 
    #'@param    table_name [str] Database Table name to query from.
    
    if (length(crackCol) == 1){
        sql1 <- paste0('SELECT * FROM public.', table_name, " WHERE crack_col ")
        sql2 <- paste0("LIKE ('", crackCol, "')")  
        sql_final <- paste0 (sql1, sql2)
    }else if (length(crackCol) > 1){
        crackCol <- paste(crackCol, collapse = "','")
        
        sql1 <- paste0("SELECT * FROM public.", table_name, " WHERE crack_col ")
        sql2 <- paste0("IN ('", crackCol, "')")  
        sql_final <- paste0(sql1, sql2)
    }
    return (sql_final)
}

generateSQLQueryDate <- function(table_name, min_date, max_date, datetime_colname){
    sql1 <- paste0('SELECT * FROM public.', deparse(table_name), "WHERE ", deparse(datetime_colname))
    sql2 <- paste0(" >= timestamp '", min_date, "' AND ", deparse(datetime_colname))
    sql3 <- paste0(" <= timestamp '", max_date, "' ORDER BY ", deparse(datetime_colname))
    
    sql_final <- paste0(sql1, sql2, sql3)
    return (sql_final)
}


## SQL Query for max date
generateSQLQuery <- function (db_table, dateColumn){
    #'@return : Max date in dataframe from db_table
    query1 <- paste0('SELECT MAX(',db_table, '."')
    query2 <- paste0(dateColumn, '")')
    query3 <- paste0('FROM public.', deparse(db_table))
    return (paste0(query1, query2, query3))
}

## SQL Query for Max date in table name
generateSQLQueryMaxDateProduct <- function(table_name, dateColumn, crack_col) {
    #'@description : Query for Max date in table name based on specific crack col. Returns df.
    #'@param table_name Database table name
    #'@param dateColumn [str] String indicating the specific date column
    #'@param crack_col [str] Specific crack names/crude names.
    #'@return : Max date in dataframe from db_table
    
    query1 <- paste0("SELECT DISTINCT ", dateColumn, " FROM public.")
    query2 <- paste0(deparse(table_name), " WHERE")
    query3 <- paste0("crack_col LIKE ('", crack_col, "') ORDER BY")
    query4 <- paste0(deparse(dateColumn), " DESC LIMIT 1")
    return (paste(query1, query2, query3, query4))
}

## SQL Query for distinct crack col
generateSQLQueryDistinctCrackCol <- function (table_name){
    query1 <- paste0("SELECT DISTINCT crack_col FROM public.", deparse(table_name))
    return (query1)
}
### Database Metadata ----
Database_Datatypes <- pgGetSchema()
