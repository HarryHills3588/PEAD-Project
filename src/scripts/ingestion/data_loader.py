import sys, os
sys.path.append(os.path.dirname(os.path.abspath('../')))

import pandas as pd
import numpy as np
from requests import get
import  datetime as dt
from utils.dbconnection import DBConnection
from supabase import Client
from dotenv import load_dotenv
import datetime as dt

class DataLoader():
    def __init__(self) -> None:
        load_dotenv()
        self.db_conn = DBConnection()
        self.apikey = os.getenv('FIN_DS_KEY')
        self.client = self.db_conn.get_sb_client()
        self.fmp_key = os.getenv('FMP_KEY')
        
        self.endpoints = {
            'earnings': "https://api.financialdatasets.ai/earnings",
            'prices': "https://financialmodelingprep.com/stable/historical-price-eod/full?symbol={ticker}&from={from_date}&to={to}&apikey={fmp_key}",
            'facts':  "https://api.financialdatasets.ai/company/facts",
            'fmp_earnings': "https://financialmodelingprep.com/stable/earnings?symbol={ticker}&apikey={fmp_key}"
        }
        

    def get_data(self, endpoint:str, ticker:str, interval:str = 'day', end_date:dt.datetime = dt.datetime.now()):
        start_date:dt.datetime = end_date - dt.timedelta(30)
        
        if endpoint in self.endpoints.keys() and self.apikey:
            request_url = self.endpoints[endpoint] + f'?ticker={ticker}'
            header = {"X-API-KEY": self.apikey}
            
            if endpoint == 'prices':
                start_date_str = start_date.strftime("%Y-%m-%d")
                end_date_str = end_date.strftime("%Y-%m-%d")
                
                request_url = self.endpoints[endpoint].format(
                    ticker = ticker, 
                    from_date = start_date_str,
                    to = end_date_str,
                    fmp_key = self.fmp_key
                )
                
                ### TODO: see if has the same columns if not same format, format through pd.DF and convert back to json
                response = get(request_url)
                
            elif endpoint == 'fmp_earnings':
                request_url = self.endpoints[endpoint].format(ticker=ticker, fmp_key=self.fmp_key)
                response = get(request_url)
                
            else:
                response = get(request_url,headers=header)
            
            return response.json()
        
    def db_insert_df(self, table_name:str, df:pd.DataFrame):
        if isinstance(self.client,Client):
            df = df.replace([np.inf, -np.inf], np.nan)
            df_dict = [
                {k: (None if isinstance(v, float) and np.isnan(v) else v) for k, v in row.items()}
                for row in df.to_dict(orient='records')
            ]
            
            self.client.schema('raw').table(table_name).insert(df_dict).execute() #type:ignore
            
    def process_earnings(self, earnings:dict):
        out_dict = {
            'ticker': earnings['ticker'],
        }
        
        try:
            out_dict['fiscal_period'] = earnings['fiscal_period']
        except KeyError as e:
            print('No fiscal period in main dict')
        
        for key in earnings['quarterly'].keys():
            out_dict[key] = earnings['quarterly'][key]
        
        return out_dict
        
    def process_facts(self, facts:dict):
        out_dict = {
            'ticker': facts['ticker'],
            'name': facts['name'],
            'sector': facts['sector'],
            'industry': facts['industry'],
            'exchange': facts['exchange'],
            'location': facts['location']
        }
        
        return out_dict
        
    def ingest_raw_data(self, ticker:str, end_date:dt.datetime = dt.datetime.now()):
        # Initialize the tables and raw schema if they dont exist
        self.db_conn.execute_sql_file('create_raw_schema.sql')
        self.db_conn.execute_sql_file('create_facts_tbl.sql')
        self.db_conn.execute_sql_file('create_prices_tbl.sql')
        self.db_conn.execute_sql_file('create_fmp_earnings_tbl.sql')
        
        # Populate these tables
        prices = self.get_data('prices',ticker, end_date=end_date)['prices'] #TODO: LOOK AT [PRICES KEY]
        facts = self.get_data('facts', ticker)['company_facts']
        
        fmp_table = self.get_data('fmp_earnings', ticker)
        
        self.db_insert_df('fmp_earnings', pd.DataFrame(fmp_table))
        self.db_insert_df('prices', pd.DataFrame(prices))
        
        if isinstance(self.client, Client):
            facts_dict = self.process_facts(facts)
            
            self.client.schema('raw').table('facts').insert(facts_dict).execute()