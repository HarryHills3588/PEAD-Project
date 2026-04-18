from src.scripts.ingestion.data_loader import DataLoader

ticker_list = [
    
]

data_loader = DataLoader()

for ticker in ticker_list:
    data_loader.ingest_raw_data(ticker)