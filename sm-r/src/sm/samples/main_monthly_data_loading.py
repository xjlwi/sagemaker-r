# -*- coding: utf-8 -*-
"""
Created on Thu Jul  8 16:24:47 2021

@author: leow.weiqin
"""
#set flag for library
#os.environ["ENVIRONMENT_FLAG"] = 'production'

#script for data loading
import os
if os.environ["ENVIRONMENT_FLAG"] == 'development':
    from sql.python.PostgreSQL_ConnectionDev import pgupdateSQLTable_with_checking
elif os.environ["ENVIRONMENT_FLAG"] == 'production':
    from sql.python.PostgreSQL_ConnectionProd import pgupdateSQLTable_with_checking
from feature_engineering.partial_fe.data_prep_functions import *
from feature_engineering.partial_fe import *
from utils.aws_helper_python import upload_file_dev, upload_file_prod
import logging
import datetime
import sys

## logging
#create log folder if it does not exist
log_folder = os.getcwd()+"\logs\monthly_FE"
if not os.path.exists(log_folder):
    os.makedirs(log_folder)
log_filename = os.path.join(log_folder,"log_monthly_FE_{}.log".format(datetime.date.today()))
log_filename_s3 = "log_monthly_FE_{}.log".format(datetime.date.today())
#logging config
logging.basicConfig(level=logging.INFO,\
                    format='%(asctime)s %(levelname)-8s %(message)s',\
                    datefmt='%a, %d %b %Y %H:%M:%S',\
                    filename=log_filename,\
                    filemode='a')
logging.getLogger().addHandler(logging.StreamHandler(sys.stdout))

## saving final dataframe to csv
data_folder = os.getcwd()+"\data"
if not os.path.exists(data_folder):
    os.makedirs(data_folder)
data_filename = os.path.join(data_folder,"monthly_features_phase2.csv")
data_filename_s3 = "monthly_features_phase2.csv"
data_filename_2 = os.path.join(data_folder,"monthly_features_ihs_supply_demand_all_binded_phase2.csv")
data_filename_2_s3 = "monthly_features_ihs_supply_demand_all_binded_phase2.csv"

try:
    #check pmi data availability
    logging.info('Checking for PMI and IHS Supply Demand data availability.')
    monthlyFE_flag = check_pmi_sd_availability()
    
    #check if monthly features already existing
    logging.info('Checking for PMI and IHS Supply Demand data availability.')
    monthlyFeatures_flag = check_for_monthly_features()
    
    if monthlyFE_flag == True and monthlyFeatures_flag == False:
        logging.info("PMI and IHS Supply Demand data is available and monthly features for the latest month is not produced yet, Thus performing FE.")
         #### data prep for monthly features
        logging.info("Running data prep for monthly features.")
        ##define start date (different for datasets) and end date (same accross dataset)
        #dates that can be updated monthly
        monthly_crack_start_date = datetime.date(year = 2004, month = 1, day = 1) ##TODO to detect max date from existing feature table
        fc_start_date = datetime.date(year = 2010, month = 1, day = 1)
        tradeflow_naphtha_start_date = datetime.date(year = 2011, month = 1, day = 1)
        fundamental_data_start_date = datetime.date(year = 2013, month = 3, day = 1)
        end_date = datetime.date.today().replace(day=1)
        trmi_end_date = end_date - datetime.timedelta(days=1) #required to be in date format instead of string
    
        #those that involve TA FE have to remain the same start date (cannot just pull recent months as it will affect the value)
        jetkero_stock_start_date = datetime.date(year = 2010, month = 1, day = 1)
        pmi_features_start_date = datetime.date(year = 2009, month = 12, day = 1)
        pmi_naphtha_features_start_date = datetime.date(year = 1992, month = 1, day = 1)
        pmi_expanding_features_start_date = datetime.date(year = 2002, month = 9, day = 1)
        pmi_transportation_features_start_date = datetime.date(year = 2009, month = 10, day = 1)
        trmi_start_date = datetime.date(year = 2010, month = 1, day = 1)
        trmi_start_date_2 = datetime.date(year = 1998, month = 1, day = 1)
        petchem_margin_start_date = datetime.date(year = 2014, month = 1, day = 1)
       
    
        ### crack price
        df_monthlyCrackPrice = MonthlyCrackPrice_data_prep(start_date = monthly_crack_start_date,
                                                           end_date = end_date)
        
        
        ### forward curve
        df_fc_final = FC_data_prep(df_monthlyCrackPrice= df_monthlyCrackPrice,
                                   start_date = fc_start_date,
                                   end_date = end_date)
        
        
        ### jet kero stock
        df_jetkero_stocks_final = jetkero_stocks_data_prep(start_date = jetkero_stock_start_date,
                                                           end_date = end_date)
        
        
        ### pmi
        df_pmi_final = pmi_data_prep(start_date = pmi_features_start_date,
                                     start_date_2 = pmi_naphtha_features_start_date,
                                     start_date_3 = pmi_expanding_features_start_date,
                                     start_date_4 = pmi_transportation_features_start_date,
                                     end_date = end_date)
          
        ### TRMI
        df_TRMI_final = TRMI_data_prep(start_date = trmi_start_date,
                                       start_date_2 = trmi_start_date_2,
                                       end_date = trmi_end_date)
        
        
        ### Tradeflow gasoil (require all data for seaonal feature, thus no start_date/end_date param
        df_tradeflow_gasoil = tradeflow_gasoil_data_prep()
        
        
        ### Tradeflow naphtha (used by gasoline95 model)
        df_tradeflow_naphtha =tradeflow_naphtha_data_prep(start_date = tradeflow_naphtha_start_date,
                                                          end_date = end_date)
        
        
        ### R2 features ((require all data for seaonal feature, thus no start_date/end_date param)
        df_fundamental_data_FE = fundamental_data_loading(end_date = end_date)
        
        ##push table to RDS DB, the updated table will be used by fundamental_data_prep
        logging.info("Pushing df_fundamental_data_FE to RDS DB.")
        
        ##TODO to change to prod db when productionalize
        pgupdateSQLTable_with_checking(latest_df = df_fundamental_data_FE,
                                           table_name = "monthly_data_merged_phase2",
                                           date_column = 'Date',
                                           keys = ['Date'])
        
        df_fundamental_data_final = fundamental_data_prep(start_date = fundamental_data_start_date,
                                                          end_date = end_date)
        
        
        ##petchem margin features
        df_petchem_margin_final = petchem_margin_data_prep(df_monthlyCrackPrice = df_monthlyCrackPrice,
                                                           start_date= petchem_margin_start_date,
                                                           end_date = end_date)
        
        
        ### IHS Supply Demand features (start and end date not applicable due to the all binded format)
        df_IHS_Supply_Demand_all_binded_final, df_IHS_Supply_Demand_appended_final = ihs_supply_demand_data_prep()
        
        
        ## merge all tables (monthly features)
        logging.info("Merging tables from relevant datasets.")
        df_merged = df_monthlyCrackPrice.merge(df_fc_final, how='outer', on='date_time')\
        .merge(df_jetkero_stocks_final, how='outer', on='date_time')\
        .merge(df_pmi_final, how='outer', on='date_time')\
        .merge(df_TRMI_final, how='outer', on='date_time')\
        .merge(df_tradeflow_gasoil, how='outer', on='date_time')\
        .merge(df_tradeflow_naphtha, how='outer', on='date_time')\
        .merge(df_fundamental_data_final, how='outer', on='date_time')\
        .merge(df_petchem_margin_final, how='outer', on='date_time')\
        .merge(df_IHS_Supply_Demand_appended_final, how='outer', on='date_time')
        logging.info("Monthly features (df_merged) data prep completed.")
        
        df_merged.sort_values(by="date_time",inplace = True)
        df_merged.reset_index(drop = True, inplace = True)
    
       
        
        ##push table to RDS DB
        logging.info("Pushing df_merged to RDS DB.")
        ##TODO to change to prod db when productionalize 
        pgupdateSQLTable_with_checking(latest_df = df_merged,
                                           table_name = "monthly_features_phase2",
                                           keys = ['date_time'],
                                           date_column = "date_time")
        
        logging.info("Pushing df_IHS_Supply_Demand_all_binded_final to RDS DB.")
        ##TODO to change to prod db when productionalize
        pgupdateSQLTable_with_checking(latest_df = df_IHS_Supply_Demand_all_binded_final,
                                           table_name = "monthly_features_ihs_supply_demand_all_binded_phase2",
                                           keys = ['date_time','tag'],
                                           date_column = "date_time")
        
    #    logging.info("Saving final dataframe to csv.")
    #    df_merged.to_csv(data_filename)
    #    df_IHS_Supply_Demand_all_binded_final.to_csv(data_filename_2)
        
        #logging.info("Pushing final dataframe csv to S3.")
        #upload_file_dev(file_name = data_filename, object_name = 'monthly_features_phase2/{}'.format(data_filename_s3))
        #upload_file_dev(file_name = data_filename_2, object_name = 'monthly_features_phase2/{}'.format(data_filename_2_s3))
    
        logging.info("main_monthly_data_loading completed.")  
        
    elif monthlyFE_flag == False or monthlyFeatures_flag == True:
        if monthlyFE_flag == False:
            logging.info("Latest PMI and IHS Supply Demand data is not available, hence not performing monthly FE.")
        elif monthlyFeatures_flag == True:
            logging.info("Monthly features already available hence not performing monthly FE.")

    
except: # catch *all* exceptions
    e = sys.exc_info()
    logging.error(e) # (Exception Type, Exception Value, TraceBack)

logging.info("Pushing log file to S3.")
if os.environ["ENVIRONMENT_FLAG"] == 'development':
    upload_file_dev(file_name = log_filename, object_name = 'log_files/{}'.format(log_filename_s3))
elif os.environ["ENVIRONMENT_FLAG"] == 'production':
    upload_file_prod(file_name = log_filename, object_name = 'log_files/{}'.format(log_filename_s3))

logging.shutdown()
os._exit(00)
