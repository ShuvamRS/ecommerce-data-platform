# Ecommerce Data Platform

This project integrates Olist ecommerce and marketing data with IBGE municipality and population data in an Azure Databricks lakehouse.

Batch files land in Azure Data Lake Storage Gen2 and are ingested incrementally with Databricks Auto Loader. PySpark handles Bronze and Silver processing, dbt builds the analytical Gold layer, Databricks Jobs orchestrate the platform, and Databricks Asset Bundles deploy the same workloads across dev, test, and prod. Power BI consumes selected Gold models through the Databricks SQL Warehouse.

**Built with:** Azure Databricks, Azure Data Lake Storage Gen2, PySpark, Spark SQL, Delta Lake, Unity Catalog, Databricks Auto Loader, dbt Core, Databricks Jobs, Databricks Asset Bundles, GitHub Actions, Power BI

## Architecture

```mermaid
flowchart TB
    subgraph SRC["Data Sources"]
        direction LR
        OE["Olist Ecommerce"]
        OM["Olist Marketing"]
        IL["IBGE Localidades API"]
        IP["IBGE Population API"]
    end

    ADLS["Azure Data Lake Storage Gen2<br/>Landing & Raw Responses"]

    subgraph ING["Databricks Ingestion"]
        direction LR
        AL["Auto Loader<br/>Olist batch files"]
        API["API ingestion<br/>IBGE responses"]
    end

    subgraph MED["Azure Databricks · Unity Catalog"]
        direction TB
        B["Bronze<br/>Source-aligned Delta"]
        S["Silver<br/>Cleaned & typed"]
        G["Gold<br/>dbt dimensions · facts · marts"]
        B --> S --> G
    end

    SQL["Databricks SQL Warehouse"]
    BI["Power BI"]

    OE --> ADLS
    OM --> ADLS
    IL --> ADLS
    IP --> ADLS

    ADLS --> AL
    ADLS --> API
    AL --> B
    API --> B

    G --> SQL --> BI

    classDef source fill:#EAF2FB,stroke:#2F6FA7,color:#17324D,stroke-width:1.5px
    classDef api fill:#E7F5F2,stroke:#2A7C6F,color:#17483D,stroke-width:1.5px
    classDef storage fill:#DCEBFA,stroke:#2F6FA7,color:#17324D,stroke-width:1.8px
    classDef ingest fill:#E5F3F7,stroke:#2B7A8B,color:#174650,stroke-width:1.5px
    classDef bronze fill:#E8B074,stroke:#9A5D1E,color:#3F250C,stroke-width:1.8px
    classDef silver fill:#D9DEE3,stroke:#6B7785,color:#202A35,stroke-width:1.8px
    classDef gold fill:#F4D35E,stroke:#A57A00,color:#3F3100,stroke-width:1.8px
    classDef serving fill:#DCE8F6,stroke:#315F8C,color:#17324D,stroke-width:1.8px

    class OE,OM source
    class IL,IP api
    class ADLS storage
    class AL,API ingest
    class B bronze
    class S silver
    class G gold
    class SQL,BI serving

    style SRC fill:#F8FAFC,stroke:#B9C6D3,stroke-width:1px,color:#1F2937
    style ING fill:#F8FBFC,stroke:#B7CDD3,stroke-width:1px,color:#1F2937
    style MED fill:#FAFAFA,stroke:#B7C0CA,stroke-width:1px,color:#1F2937

    linkStyle default stroke:#64748B,stroke-width:1.5px
```

The Databricks data pipeline and the Power BI Import refresh run separately.

## Data Sources

| Source | Data |
|---|---|
| [Olist Brazilian E-Commerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) | Customers, geolocation, orders, order items, payments, reviews, products, sellers, and product-category translations |
| [Olist Marketing Funnel](https://www.kaggle.com/datasets/olistbr/marketing-funnel-olist) | Marketing-qualified leads and closed deals |
| [IBGE Localidades API](https://servicodados.ibge.gov.br/api/docs/localidades) | Official municipality reference data |
| [IBGE SIDRA](https://servicodados.ibge.gov.br/api/docs/agregados?versao=3) | Municipality population estimates |

## Ingestion and Transformation

### Bronze and Silver

Olist ecommerce and marketing sources use dataset-specific Auto Loader notebooks. Bronze retains source and ingestion metadata, `_rescued_data`, schema-tracking state, and checkpoint state for repeatable incremental ingestion.

Silver notebooks apply data types, standardization, deduplication where needed, and dataset-specific cleaning before the data is used by dbt.

IBGE Localidades and SIDRA responses are preserved in the ADLS Gen2 landing area before Bronze processing. Municipality population ingestion derives the required years from Silver orders and requests only years that have not already been loaded.

The repository keeps development notebooks separate from the parameterized operational notebooks used by Databricks Jobs.

### Gold with dbt

dbt builds normalization and intermediate models before the final dimensions, facts, marts, and quality model. Location models standardize Olist city/state values and map them to official IBGE municipalities.

| Layer | Models |
|---|---|
| Dimensions | `dim_customer`, `dim_date`, `dim_location`, `dim_municipality`, `dim_product`, `dim_seller` |
| Facts | `fact_orders`, `fact_order_items`, `fact_payments`, `fact_reviews`, `fact_mql`, `fact_closed_deals`, `fact_municipality_population` |
| Business marts | `mart_order_summary`, `mart_seller_acquisition` |
| Quality | `location_standardization_issues` |

### dbt Lineage

![dbt Gold lineage](screenshots/dbt_dag.png)

## Pipeline Orchestration

`ecommerce_platform` is the master Databricks Job. It runs `bronze_static`, `silver_static`, `ibge_enrichment`, and `gold` in sequence, while each child job remains independently runnable.

### Master Pipeline

<p align="center">
  <img src="screenshots/ecommerce_platform_run.png" alt="Databricks ecommerce platform run" width="50%">
</p>

### Bronze

<p align="center">
  <img src="screenshots/bronze_run.png" alt="Databricks Bronze run" width="50%">
</p>

### Silver

<p align="center">
  <img src="screenshots/silver_run.png" alt="Databricks Silver run" width="50%">
</p>

### IBGE Enrichment

<p align="center">
  <img src="screenshots/ibge_enrichment_run.png" alt="Databricks IBGE enrichment run" width="50%">
</p>

### Gold

<p align="center">
  <img src="screenshots/gold_run.png" alt="Databricks Gold dbt run" width="50%">
</p>

## Environments and CI/CD

The Databricks Asset Bundle defines the same Job resources across separate `dev`, `test`, and `prod` targets. Operational notebooks receive the environment through the bundle target so catalogs, landing paths, and Auto Loader state remain isolated.

```mermaid
flowchart TB
    subgraph CODE["Source Control & CI"]
        direction LR
        FB["Feature Branch"]
        PR["Pull Request"]
        CI["CI<br/>dbt parse<br/>Bundle validate"]
        MAIN["main"]

        FB --> PR --> CI --> MAIN
    end

    subgraph DEVFLOW["Automatic DEV Delivery"]
        direction TB
        CD["CD<br/>Bundle validate -t dev<br/>Bundle deploy -t dev"]
        DEV["DEV<br/>ecommerce_dev"]

        CD --> DEV
    end

    subgraph PROMOTION["Controlled Promotion"]
        direction TB
        SHA["Approved Commit SHA"]
        TEST["TEST<br/>Bundle validate -t test<br/>Bundle deploy -t test<br/>Run ecommerce_platform"]
        PROD["PROD<br/>Bundle validate -t prod<br/>Bundle deploy -t prod<br/>No automatic run"]

        SHA --> TEST --> PROD
    end

    MAIN --> CD
    MAIN --> SHA

    classDef code fill:#F1F4F7,stroke:#64748B,color:#1F2937,stroke-width:1.5px
    classDef ci fill:#DDF1FA,stroke:#2B7A9B,color:#17465B,stroke-width:1.6px
    classDef deploy fill:#DCE8F6,stroke:#315F8C,color:#17324D,stroke-width:1.6px
    classDef dev fill:#D9EAFB,stroke:#2F6FA7,color:#17324D,stroke-width:1.7px
    classDef sha fill:#EEF2F6,stroke:#64748B,color:#1F2937,stroke-width:1.5px
    classDef test fill:#FCE7B2,stroke:#B7791F,color:#5A3A08,stroke-width:1.7px
    classDef prod fill:#DDF2E3,stroke:#3F8A5A,color:#1E5130,stroke-width:1.7px

    class FB,PR,MAIN code
    class CI ci
    class CD deploy
    class DEV dev
    class SHA sha
    class TEST test
    class PROD prod

    style CODE fill:#FAFBFC,stroke:#B8C2CC,stroke-width:1px,color:#1F2937
    style DEVFLOW fill:#F7FAFD,stroke:#AEBECB,stroke-width:1px,color:#1F2937
    style PROMOTION fill:#FCFCFA,stroke:#B8C2CC,stroke-width:1px,color:#1F2937

    linkStyle default stroke:#64748B,stroke-width:1.5px
```

| Target | Catalog | Deployment |
|---|---|---|
| DEV | `ecommerce_dev` | Pushes to `main` validate and deploy automatically |
| TEST | `ecommerce_test` | Manual promotion of an approved commit SHA; validates, deploys, and runs `ecommerce_platform` |
| PROD | `ecommerce_prod` | Manual promotion of an approved commit SHA; validates and deploys without automatically running the production pipeline |

The current platform release completed full runs in DEV and TEST, and the approved release was deployed to PROD.

## Data Quality

dbt tests cover uniqueness, required fields, relationships, accepted values, fact grain, join fanout, and selected business reconciliations. Location enrichment checks municipality mapping and protects against row multiplication.

The latest full dbt build passed in both DEV and TEST:

```text
PASS=168  WARN=0  ERROR=0  SKIP=0  NO-OP=0  TOTAL=168
```

## Power BI Report

Power BI imports selected Gold models through the Databricks SQL Warehouse.

### Executive Overview

![Power BI Executive Overview](screenshots/dashboard_page_1.png)

### Orders & Delivery

![Power BI Orders and Delivery](screenshots/dashboard_page_2.png)

### Product Performance

![Power BI Product Performance](screenshots/dashboard_page_3.png)

### Seller Acquisition

![Power BI Seller Acquisition](screenshots/dashboard_page_4.png)

### Geography & Market Context

![Power BI Geography and Market Context](screenshots/dashboard_page_5.png)

## Repository Structure

```text
.
├── .github/
│   └── workflows/
│       ├── ci.yml
│       ├── cd.yml
│       └── promote.yml
├── dbt/
│   ├── macros/
│   ├── models/
│   │   ├── sources/
│   │   ├── normalization/
│   │   ├── intermediate/
│   │   ├── marts/
│   │   │   ├── dimensions/
│   │   │   ├── facts/
│   │   │   └── business/
│   │   └── quality/
│   ├── tests/
│   └── dbt_project.yml
├── notebooks/
│   ├── development/
│   │   ├── bronze/
│   │   └── silver/
│   └── operational/
│       ├── bronze/
│       └── silver/
├── resources/
│   ├── bronze_static.job.yml
│   ├── silver_static.job.yml
│   ├── ibge_enrichment.job.yml
│   ├── gold.job.yml
│   └── ecommerce_platform.job.yml
├── screenshots/
├── databricks.yml
└── README.md
```

## Dataset

- [Olist Brazilian E-Commerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
- [Olist Marketing Funnel](https://www.kaggle.com/datasets/olistbr/marketing-funnel-olist)
- [IBGE Localidades API](https://servicodados.ibge.gov.br/api/docs/localidades)
- [IBGE SIDRA Population](https://servicodados.ibge.gov.br/api/docs/agregados?versao=3)
