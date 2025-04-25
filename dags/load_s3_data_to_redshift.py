from datetime import datetime, timedelta
from airflow import DAG
import os
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.operators.bash import BashOperator
from airflow.utils.task_group import TaskGroup
from airflow.models.baseoperator import chain

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2025, 1, 1),
    'email_on_failure': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=2),  
}

with DAG(
    dag_id="load_s3_to_redshift",
    schedule_interval="@once",
    default_args=default_args,
    max_active_runs=1,
    template_searchpath=['/usr/local/airflow/include/scripts/ddl_bronze'],
    catchup=False,
    tags=['redshift', 'bronze', 'dbt'],
) as dag:

    with TaskGroup("bronze_ddl") as bronze_ddl_group:
        bronze_ddl_sql_files = [
            'create_schema.sql',
            'grant_usage_public.sql',
            'grant_all_awsuser.sql',
            'create_crm_cust_info.sql',
            'create_crm_prd_info.sql',
            'create_crm_sales_details.sql',
            'create_erp_loc_a101.sql',
            'create_erp_cust_az12.sql',
            'create_erp_px_cat_g1v2.sql',
        ]

        bronze_ddl_tasks = [
            PostgresOperator(
                task_id=f"execute_{sql_file.replace('.sql', '')}",
                postgres_conn_id='redshift_default',
                sql=sql_file,
                retries=2,
                retry_delay=timedelta(minutes=1),
                execution_timeout=timedelta(minutes=3),  
            )
            for sql_file in bronze_ddl_sql_files
        ]

        chain(*bronze_ddl_tasks)

    with TaskGroup("truncate_bronze") as truncate_bronze_group:
        truncate_tables = [
            'bronze.crm_cust_info',
            'bronze.crm_prd_info',
            'bronze.crm_sales_details',
            'bronze.erp_loc_a101',
            'bronze.erp_cust_az12',
            'bronze.erp_px_cat_g1v2',
        ]

        truncate_tasks = [
            PostgresOperator(
                task_id=f"truncate_{table.split('.')[-1]}",
                postgres_conn_id='redshift_default',
                sql=f"TRUNCATE TABLE {table};",
                execution_timeout=timedelta(minutes=1),  
            )
            for table in truncate_tables
        ]

        chain(*truncate_tasks)

    with TaskGroup("copy_data") as copy_group:
        s3_base_path = os.environ.get('S3_BASE_PATH')
        iam_role = os.environ.get('REDSHIFT_IAM_ROLE')
        region = os.environ.get('AWS_REGION')

        copy_tasks = {
            'crm_cust_info': 'bronze.crm_cust_info',
            'crm_prd_info': 'bronze.crm_prd_info',
            'crm_sales_details': 'bronze.crm_sales_details',
            'erp_loc_a101': 'bronze.erp_loc_a101',
            'erp_cust_az12': 'bronze.erp_cust_az12',
            'erp_px_cat_g1v2': 'bronze.erp_px_cat_g1v2',
        }

        copy_operators = [
            PostgresOperator(
                task_id=f"copy_{source}",
                postgres_conn_id='redshift_default',
                sql=f"""
                    COPY {table}
                    FROM '{s3_base_path}{source}.csv'
                    IAM_ROLE '{iam_role}'
                    REGION '{region}'
                    FORMAT AS CSV
                    DELIMITER ','
                    IGNOREHEADER 1
                    ACCEPTINVCHARS
                    COMPUPDATE OFF
                    STATUPDATE OFF;
                """,  
                execution_timeout=timedelta(minutes=6),  
            )
            for source, table in copy_tasks.items()
        ]

        chain(*copy_operators)

    dbt_silver = BashOperator(
        task_id='dbt_run_silver',
        bash_command="""
        cd /usr/local/airflow/include/dbt && \
        dbt deps && \
        dbt run --select silver \
                --profiles-dir . \
                --target dev_silver \
                --fail-fast \
                --threads 8  
        """,
        execution_timeout=timedelta(minutes=10),
    )
    
    # Test models in silver
    dbt_test_silver = BashOperator(
        task_id='dbt_test_silver',
        bash_command="""
        cd /usr/local/airflow/include/dbt && \
        dbt test --select silver \
                --profiles-dir . \
                --target dev_silver \
                --fail-fast \
                --threads 8
        """,
        execution_timeout=timedelta(minutes=10),
    )

    dbt_gold = BashOperator(
        task_id='dbt_run_gold',
        bash_command="""
        cd /usr/local/airflow/include/dbt && \
        dbt deps && \
        dbt run --select gold \
                --profiles-dir . \
                --target dev_gold \
                --fail-fast \
                --threads 8  
        """,
        execution_timeout=timedelta(minutes=10),
    )
    
    # Test models in gold
    dbt_test_gold = BashOperator(
        task_id='dbt_test_gold',
        bash_command="""
        cd /usr/local/airflow/include/dbt && \
        dbt test --select gold \
                --profiles-dir . \
                --target dev_gold \
                --fail-fast \
                --threads 8
        """,
        execution_timeout=timedelta(minutes=10),
    )

    bronze_ddl_group >> truncate_bronze_group >> copy_group >> dbt_silver >> dbt_test_silver >> dbt_gold >> dbt_test_gold
