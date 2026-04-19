import sys, os
sys.path.append(os.path.dirname(os.path.abspath('../')))

import pandas as pd
import numpy as np
from requests import get
import  datetime as dt
from utils.dbconnection import DBConnection
from supabase import Client

class DataLoader():
    def __init__(self) -> None:
        self.db_conn = DBConnection()
        self.apikey = os.getenv('FIN_DS_KEY')
        self.client = self.db_conn.get_sb_client()
        self.fmp_key = os.getenv('FMP_KEY')
        
        self.endpoints = {
            'earnings': "https://api.financialdatasets.ai/earnings",
            'prices': "https://api.financialdatasets.ai/prices",
            'facts':  "https://api.financialdatasets.ai/company/facts",
            'fmp_earnings': "https://financialmodelingprep.com/stable/earnings?symbol=AAPL&apikey={self.fmp_key}"
        }
        

    def get_data(self, endpoint:str, ticker:str, interval:str = 'day'):
        if endpoint in self.endpoints.keys() and self.apikey:
            request_url = self.endpoints[endpoint] + f'?ticker={ticker}'
            header = {"X-API-KEY": self.apikey}
            
            if endpoint == 'prices':
                end_date = dt.datetime.now()
                start_date = end_date - dt.timedelta(days=30)
                
                start_date_str = start_date.strftime("%Y-%m-%d")
                end_date_str = end_date.strftime("%Y-%m-%d")
                
                
                request_url += f'&interval={interval}' + f'&start_date={start_date_str}' + f'&end_date={end_date_str}'
                response = get(request_url,headers=header)
                
            elif endpoint == 'fmp_earnings':
                request_url = self.endpoints[endpoint]
                response = get(request_url)
                
            else:
                response = get(request_url,headers=header)
            
            return response.json()
        
    def db_insert_df(self, table_name:str, df:pd.DataFrame):
        if isinstance(self.client,Client):
            df_dict = df.to_dict(orient='records')
            
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
        
    def ingest_raw_data(self, ticker:str):
        # Initialize the tables and raw schema if they dont exist
        self.db_conn.execute_sql_file('create_raw_schema.sql')
        self.db_conn.execute_sql_file('create_earnings_tbl.sql')
        self.db_conn.execute_sql_file('create_facts_tbl.sql')
        self.db_conn.execute_sql_file('create_prices_tbl.sql')
        self.db_conn.execute_sql_file('create_fmp_earnings_tbl.sql')
        
        # Populate these tables
        earnings = self.get_data('earnings',ticker)['earnings']
        prices = self.get_data('prices',ticker)['prices']
        facts = self.get_data('facts', ticker)['company_facts']
        
        fmp_table = self.get_data('fmp_earnings', ticker)
        
        self.db_insert_df('fmp_earnings', pd.DataFrame(fmp_table))
        self.db_insert_df('prices', pd.DataFrame(prices))
        
        if isinstance(self.client, Client):
            earnings_dict = self.process_earnings(earnings)
            facts_dict = self.process_facts(facts)
            
            self.client.schema('raw').table('earnings').insert(earnings_dict).execute()
            self.client.schema('raw').table('facts').insert(facts_dict).execute()