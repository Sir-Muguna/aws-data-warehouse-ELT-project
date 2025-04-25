Here's your markdown, **reformatted for GitHub** with proper spacing, syntax highlighting where appropriate, and preserved structure:

```markdown
# 🚀 AWS Data Warehouse ELT Project

Welcome to the **AWS Data Warehouse ELT Project** — a robust, scalable, and cloud-native data engineering pipeline that automates the extraction, transformation, and loading (ELT) of raw business data into an Amazon Redshift-powered warehouse. This project showcases real-world data warehousing concepts using **Apache Airflow**, **AWS S3**, **Amazon Redshift**, and modern orchestration best practices.

![MetaData](./include/docs/architecture.png)

---

## 🧠 Key Features

- ⚙️ **Airflow Orchestration**: Task scheduling, logging, and monitoring via DAGs.  
- 🪣 **Data Lake on S3**: Stores raw and intermediate files (Bronze & Silver layers).  
- 🧽 **ELT Design**: Transformation logic is handled in Redshift using dbt.  
- 🛢 **Data Warehouse**: Redshift holds the final star-schema (Gold layer) optimized for analytics.  
- 📈 **Modular and Scalable**: Built for extensibility and cloud-scale workloads.

---

## 🗂️ Project Architecture

This project follows the **Medallion Architecture** pattern using AWS-native services and transformation layers powered by **dbt**.

### 🧱 Medallion Architecture Layers

1. **Bronze (DDL Definitions)**: Create base staging tables in Redshift.  
2. **Silver (Cleaned Data)**: Load and clean raw data using SQL models in dbt.  
3. **Gold (Data Mart)**: Star schema (facts and dimensions) ready for analytics.

---

## 🔁 DAG Workflow

The main DAG `load_s3_data_to_redshift.py` orchestrates the entire ELT flow:

1. **Stage to Redshift**: Copies raw CSV files from S3 to Redshift.  
2. **DDL Creation (Bronze)**: Executes Redshift SQL scripts to create schema and base tables.  
3. **Run dbt Models**:  
   - Silver layer: cleans and prepares the data.  
   - Gold layer: builds dimension and fact tables.  
4. **Data Quality Checks** *(optional)*: Ensure integrity before marking pipeline as successful.

---

## 📁 Repository Structure

```
aws-data-warehouse-ELT-project/
│
├── dags/
│   └── load_s3_data_to_redshift.py       # Airflow DAG file
│
├── include/
│   └── datasets/                         # Optional: raw datasets (local testing)
│
├── dbt/
│   ├── dbt_packages/
│   ├── logs/
│   ├── macros/
│   ├── models/
│   │   ├── gold/                         # Final dimensional models
│   │   │   ├── dim_customers.sql
│   │   │   ├── dim_products.sql
│   │   │   ├── fact_sales.sql
│   │   │   └── schema.yml
│   │   └── silver/                       # Cleaned data layer
│   │       ├── crm_cust_info.sql
│   │       ├── crm_prd_info.sql
│   │       ├── crm_sales_details.sql
│   │       ├── erp_cust_atz12.sql
│   │       ├── erp_loc_a101.sql
│   │       ├── erp_px_cat_g1v2.sql
│   │       └── sources.yml
│   ├── target/                           # dbt compiled and run outputs
│   ├── dbt_project.yml
│   ├── profiles.yml
│   ├── packages.yml
│   └── package-lock.yml
│
├── logs/                                 # Airflow log directory
│
├── scripts/
│   └── ddl_bronze/                       # Table creation SQL scripts
│       ├── create_crm_cust_info.sql
│       ├── create_crm_prd_info.sql
│       ├── create_crm_sales_details.sql
│       ├── create_erp_cust_atz12.sql
│       ├── create_erp_loc_a101.sql
│       ├── create_erp_px_cat_g1v2.sql
│       ├── create_schema.sql
│       ├── grant_allusersql.sql
│       └── grant_usage_public.sql
```

---

## 🧪 Data Sources

Data used in this project simulates common CRM and ERP datasets:

- Customer information  
- Product catalogs  
- Sales transactions  
- Geographic and time-related attributes

---

## 🧠 Warehouse Design (Star Schema)

The **Gold Layer** in Redshift contains the following tables:

- `dim_customers`  
- `dim_products`  
- `fact_sales`
```

Let me know if you'd like to add badges, setup instructions, or contribute sections!