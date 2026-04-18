import sys, os
sys.path.append(os.path.dirname(os.path.abspath('../')))

import pandas as pd
import numpy as np
from requests import get
import  datetime as dt
from utils.dbconnection import DBConnection

class DataLoader():
    def __init__(self) -> None:
        self.endpoints = {
            'earnings': "https://api.financialdatasets.ai/earnings",
            'prices': "https://api.financialdatasets.ai/prices",
            'facts':  "https://api.financialdatasets.ai/company/facts"
        }
        
        self.apikey = os.getenv('FIN_DS_KEY')
        self.client = DBConnection().get_sb_client()

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
            
            return response.json()
        
    def ingest_raw_data(self):
        
        
        
    def db_insert_df(self):
        