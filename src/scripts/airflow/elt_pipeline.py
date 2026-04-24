from pathlib import Path
import sys

project_root = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(project_root))

from airflow.sdk import DAG
from airflow.providers.standard.operators.python import PythonOperator
from airflow.providers.standard.operators.bash import BashOperator
from datetime import datetime
from config import ticker_list
import pendulum
from datetime import timedelta

from src.scripts.ingestion.data_loader import DataLoader
from utils.dbconnection import DBConnection

def run_ingestion_task(**context):
    start_date = context['data_interval_start']
    run_date = datetime(start_date.year, start_date.month, start_date.day)
    data_loader = DataLoader()
    for ticker in ticker_list:
        data_loader.ingest_raw_data(ticker, end_date=run_date)
        
def clean_ingestion_schema():
    db_conn = DBConnection()
    db_conn.execute_sql_file('ingestion_cleaning.sql')
    

with DAG(
    dag_id='Data_loading_backfill_DB',
    start_date=datetime(2015,4,20),
    schedule=timedelta(days=548),
    max_active_runs=1,
    catchup=True
    ):
    
    ingestion_task = PythonOperator(
        task_id='test_for_python_context',
        python_callable=run_ingestion_task,
        retries = 0
    )
    
    transformation_task = BashOperator(
        task_id='Transformation',
        bash_command='cd "/Users/harryhillsdownley/Desktop/CWRU/CSDS 397/PEAD Project/src/scripts/transformations" && dbt run --select +path:models/data_warehouse',
    )
    
    cleanup_task = PythonOperator(
        task_id='cleaning_ingestion_area',
        python_callable=clean_ingestion_schema,
    )
    
    compute_analytics = BashOperator(
        task_id='compute_analytics',
        bash_command='cd "/Users/harryhillsdownley/Desktop/CWRU/CSDS 397/PEAD Project/src/scripts/transformations" && dbt run --select path:models/data_warehouse+'
    )
    
    ingestion_task >> transformation_task >> cleanup_task >> compute_analytics