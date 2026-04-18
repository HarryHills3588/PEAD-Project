from supabase import create_client, Client
from dotenv import load_dotenv
import os 

load_dotenv()

class DBConnection():
    def __init__(self) -> None :
        supabase_url = os.getenv('SUPABASE_URL')
        supabase_pass = os.getenv('SUPABASE_KEY')
        
        if supabase_url and supabase_pass:
            self.client: Client = create_client(supabase_url=supabase_url, supabase_key=supabase_pass)
        
    def get_client(self):
        if self.client:
            return self.client
        else:
            return ValueError('No client available')