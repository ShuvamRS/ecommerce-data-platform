# Unified Ecommerce Data Platform

An end-to-end data engineering project built on Azure Databricks using Brazilian ecommerce, marketing, behavioral, and public demographic data.

The project brings together ecommerce, marketing, behavioral, and public demographic data in a lakehouse architecture with separate Bronze, Silver, and Gold layers. It focuses on reliable ingestion, data quality, source integration, geographic enrichment, dimensional modeling, environment separation, and controlled deployment.

## Architecture

```text
Olist Ecommerce files
Olist Marketing files
Retailrocket events file
        |
        v
Landing files
        |
        v
Databricks Bronze
        |
        v
Databricks Silver ----------------------+-----------------------------+
                                        |                             |
                                        +--> item/product bridge -----+
                                                                      |
IBGE municipality APIs --> Databricks Bronze --> Databricks Silver ---+--> dbt Gold
                                                                            |
                                                                            +--> Dimensions
                                                                            +--> Facts
                                                                            +--> Business marts
```

The file-based sources are ingested into Bronze before being cleaned in Silver. IBGE data follows its own API ingestion path through Bronze and Silver. The item/product bridge is built in Silver from the cleaned Retailrocket events and Olist product data. dbt then builds the analytical Gold layer from the required Silver datasets and the bridge.

## Data sources

The platform currently brings together four data domains.

| Source | What it contributes |
|---|---|
| **Olist Ecommerce** | Customers, orders, order items, payments, reviews, products, sellers, geolocation, and product-category translations |
| **Olist Marketing Funnel** | Qualified marketing leads and closed deals used to analyze seller acquisition |
| **Retailrocket Events** | Product-level behavioral events such as views, add-to-cart activity, and transactions |
| **IBGE** | Brazilian municipality reference data and annual population data used to enrich geographic analysis |

Olist, Olist Marketing, and Retailrocket arrive as files. IBGE data is retrieved from public APIs.

## How the platform works

### Bronze

Bronze keeps the source data close to how it arrived while adding the information needed to trace an ingestion back to its origin. File-based datasets are ingested with Auto Loader and retain source-file and ingestion metadata. Checkpoints make the ingestion restartable, and rescued data is preserved instead of silently discarding unexpected fields.

The IBGE API data follows the same general idea: capture the source response first, then clean and model it downstream.

### Silver

Silver turns the raw ingested data into clean, typed datasets that can be reused across the project.

This is where source-specific cleanup happens, including timestamp conversion, normalized identifiers, geographic standardization, and preparation of the Retailrocket event data. IBGE municipalities and population data are also cleaned here before they are used by the analytical models.

Silver also contains the controlled mapping used to connect Retailrocket items with Olist products for product-level comparison.

### Gold

Gold is built with dbt and is organized around business-friendly dimensions, facts, and marts rather than the structure of the original source files.

The model covers the core ecommerce areas I wanted to analyze: orders, products, sellers, payments, reviews, marketing acquisition, product behavior, location, and municipality population.

## Gold models

The current Gold layer includes six dimensions:

- `dim_customer`
- `dim_date`
- `dim_location`
- `dim_municipality`
- `dim_product`
- `dim_seller`

Eight fact tables preserve the main business processes:

- `fact_orders`
- `fact_order_items`
- `fact_payments`
- `fact_reviews`
- `fact_mql`
- `fact_closed_deals`
- `fact_web_events`
- `fact_municipality_population`

Three business marts provide simpler consumption models for common analytical questions:

- **`mart_order_summary`** — one order with item, payment, review, freight, and delivery information brought together without multiplying the order grain.
- **`mart_seller_acquisition`** — marketing leads and their conversion into closed seller deals, including lead source and time to close.
- **`mart_product_summary`** — product-level comparison of mapped Retailrocket behavioral activity with Olist sales activity.

There is also a small quality model, `location_standardization_issues`, that keeps unresolved location-standardization cases visible instead of hiding them inside transformations.

## Geographic enrichment

The Olist datasets contain city, state, and ZIP-related location information, but that alone is limited for broader geographic analysis.

The platform enriches the ecommerce data with IBGE municipality data and annual population figures. Locations are standardized before municipality matching, and the matching uses exact normalized city/state values rather than fuzzy matching that could quietly assign the wrong municipality.

Unmatched locations are allowed to remain unmatched. This makes the limitation visible and avoids manufacturing geographic precision that the source data cannot support.

## Data quality

Testing is focused on contracts that protect the meaning of the data rather than maximizing the number of tests.

Examples include:

- uniqueness at important business grains;
- required keys and fields;
- relationships between facts and dimensions;
- accepted business values where they are useful;
- checks for join fanout where a join could multiply rows;
- targeted reconciliations for important population-preservation rules.

The latest full dbt regression completed with **186 passes, 0 warnings, and 0 errors**.

The location and municipality enrichment is also checked for duplicate mappings and row multiplication, and the Retailrocket-to-Olist item mapping is validated for one-to-one uniqueness.

## Environments and deployment

The project keeps development, test, and production isolated instead of treating a single workspace/schema as every environment.

Databricks Asset Bundles define the deployable resources for:

- `dev`
- `test`
- `prod`

GitHub Actions is used for CI/CD. Pull requests validate the dbt project and Databricks bundle before merge. Changes merged to `main` are deployed to development, while promotion to test or production is deliberate and tied to an approved commit.

Authentication between GitHub and Azure uses workload identity/OIDC rather than storing a long-lived Databricks personal access token in GitHub.

## Repository structure

```text
.
├── .github/workflows/   # CI, development deployment, and release promotion
├── dbt/                 # Gold transformations, documentation, and tests
├── notebooks/
│   ├── development/     # Development versions of Bronze and Silver processing
│   └── operational/     # Lean operational Bronze and Silver notebooks
├── resources/           # Databricks resource definitions
├── scripts/             # Supporting project scripts
└── databricks.yml       # Databricks Asset Bundle configuration
```

I keep development and operational notebooks separate on purpose. Development notebooks are useful while exploring and validating behavior; operational notebooks are kept smaller and focused on repeatable execution.

## Main technologies

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

## A note on the Retailrocket and Olist mapping

Retailrocket and Olist do not share a real product identifier, so their products cannot be naturally joined.

To make product-level comparison possible, the project creates a deterministic one-to-one mapping between the known Retailrocket item set and Olist products. The mapping is generated and validated as part of the project and remains stable once created.

This is intentionally a **project-generated analytical mapping**. It is not identity resolution, and the resulting comparisons should not be interpreted as proof that a Retailrocket event caused an Olist purchase or that the two source systems represent the same users.

Keeping that distinction explicit was important to me because a technically successful join is not the same thing as a defensible business relationship.