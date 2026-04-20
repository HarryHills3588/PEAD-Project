from airflow.sdk import DAG
from airflow.providers.standard.operators.python import PythonOperator
from airflow.providers.standard.operators.bash import BashOperator
from datetime import datetime
from src.scripts.ingestion.data_loader import DataLoader
import pendulum

ticker_list = [
    'NVDA'
]

data_loader = DataLoader()

for ticker in ticker_list:
    data_loader.ingest_raw_data(ticker, )

def run_ingestion_task(**context):
    start_date = context['data_interval_start']
    run_date = datetime(start_date.year, start_date.month, start_date.year)
    
    for ticker in ticker_list:
        data_loader.ingest_raw_data(ticker, end_date=run_date)

with DAG(
    dag_id='Testing_context_date_applications',
    start_date=datetime(2025,1,1),
    schedule='@daily',
    catchup=True
    
):
    ingestion_task = PythonOperator(
        task_id='test_for_python_context',
        python_callable=run_ingestion_task
    )