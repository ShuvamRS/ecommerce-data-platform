# Unified Ecommerce Data Platform

This project brings Olist ecommerce and marketing data, Retailrocket product events, and IBGE municipality data into one Azure Databricks lakehouse.

The data moves through Bronze and Silver before dbt builds the Gold dimensions, facts, and marts used for analytics. The repository also includes API ingestion, data quality checks, separate dev/test/prod environments, and GitHub Actions for CI/CD.

## Architecture

```text
                           UNIFIED ECOMMERCE DATA PLATFORM

        Olist Marketing                Olist Ecommerce                 Retailrocket
              CSVs                           CSVs                         Events
                \                              |                            /
                 \                             |                           /
                  +----------------------------+--------------------------+
                                               |
                                               v
                                Unity Catalog Landing Volume
                                               |
                                               v
                                      Databricks Auto Loader
                                               |
                                               v
          IBGE Localidades API ------> Bronze Delta Tables <------ IBGE SIDRA Population API
                                               |
                                               v
                                        Silver Delta Tables
                                               |
                +------------------------------+------------------------------+
                |                                                             |
                |               Item-Product Bridge (Retailrocket / Olist)    |
                |                                                             |
                |                                                             |
                +------------------------------+------------------------------+
                                               |
                                               v
                                            dbt Gold
                                               |
             +---------------------------------+----------------------------------+
             |                                 |                                  |
             v                                 v                                  v
        Dimensions                           Facts                         Business Marts
```

## Data Sources

| Source | Data |
|---|---|
| **Olist Ecommerce** | Customers, geolocation, orders, order items, payments, reviews, products, sellers, and product-category translations |
| **Olist Marketing** | Qualified leads and closed deals |
| **Retailrocket** | Product views, add-to-cart events, and transaction events |
| **IBGE** | Municipality reference data and annual municipality population |

## Bronze

Olist, Olist Marketing, and Retailrocket data are ingested with Databricks Auto Loader.

Bronze keeps the source fields and adds ingestion metadata such as the source path, ingestion timestamp, and run ID. Auto Loader checkpoints and rescued data are also retained for ingestion and schema handling.

IBGE municipality and population responses are stored in Bronze before being cleaned downstream.

## Silver

Silver contains the cleaned and typed datasets used by the rest of the project.

Current Silver processing includes:

- timestamp and data type cleanup
- product-category translation
- customer, seller, and geolocation cleanup
- Retailrocket event preparation
- IBGE municipality cleanup
- IBGE population cleanup
- Retailrocket/Olist item-product mapping

## Gold

Gold is built with dbt.

### Dimensions

- `dim_customer`
- `dim_date`
- `dim_location`
- `dim_municipality`
- `dim_product`
- `dim_seller`

### Facts

- `fact_orders`
- `fact_order_items`
- `fact_payments`
- `fact_reviews`
- `fact_mql`
- `fact_closed_deals`
- `fact_web_events`
- `fact_municipality_population`

### Business Marts

- `mart_order_summary` — order, payment, review, freight, and delivery metrics
- `mart_seller_acquisition` — qualified leads, closed deals, conversion, and time to close
- `mart_product_summary` — Retailrocket product activity and Olist sales for mapped products

### Quality

- `location_standardization_issues`

## IBGE Enrichment

IBGE municipality data is used to add municipality-level context to Olist locations. Population data is available for 2016, 2017, and 2018.

Current Gold results include:

- 5,571 municipalities in `dim_municipality`
- 15,235 rows in `dim_location`
- 16,710 municipality-year rows in `fact_municipality_population`

## Data Quality

dbt tests cover model keys, required fields, relationships, accepted values, selected join checks, and important reconciliations.

Latest full dbt build:

```text
PASS=186  WARN=0  ERROR=0  SKIP=0
```

## Environments and CI/CD

The Databricks project has separate targets for:

- `dev`
- `test`
- `prod`

Databricks Asset Bundles are used for deployment configuration.

GitHub Actions handles pull request validation, development deployment, and test/production promotion. Authentication uses Microsoft Entra ID and OIDC.

## Repository Structure

```text
.
├── .github/workflows/   # CI/CD workflows
├── dbt/                 # Gold models, documentation, and tests
├── notebooks/
│   ├── development/     # Development notebooks
│   └── operational/     # Bronze and Silver notebooks
├── resources/           # Databricks resource definitions
├── scripts/             # Supporting scripts
└── databricks.yml       # Databricks Asset Bundle configuration
```

## Technologies

- Azure Databricks
- PySpark
- SQL
- Delta Lake
- Unity Catalog
- Databricks Auto Loader
- dbt Core / dbt-databricks
- Databricks Asset Bundles
- GitHub Actions
- Microsoft Entra ID / OIDC
- IBGE APIs

## Retailrocket and Olist Product Mapping

Retailrocket and Olist use different product IDs. The Silver layer includes a fixed project-generated mapping so product-level metrics from the two datasets can be compared.
