from supabase import create_client, Client
from dotenv import load_dotenv
import os 
from sqlalchemy import create_engine, text

load_dotenv()

class DBConnection():
    def __init__(self) -> None :
        supabase_url = os.getenv('SUPABASE_URL')
        supabase_pass = os.getenv('SUPABASE_KEY')
        conn_str = os.getenv('DB_CONN_STR')
        
        if supabase_url and supabase_pass:
            self.client: Client = create_client(supabase_url=supabase_url, supabase_key=supabase_pass)
            
        ## Engine creation
        if conn_str:
            self.engine = create_engine(conn_str)
        
    def get_sb_client(self):
        if self.client:
            return self.client
        else:
            return ValueError('No client available')
        
    def get_script_client(self):
        if self.engine:
            return self.engine
        else:
            return None
        
    def execute_sql_file(self, filename:str):
        client = self.get_script_client()
        
        with open(filename, 'r') as file:
            query = file.read()
        
        if client:
            with client.connect() as conn:
                result = conn.execute(text(query))

                if result.returns_rows:
                    return result.all()
                
                conn.commit()