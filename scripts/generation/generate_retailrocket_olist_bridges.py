from pyspark.sql.functions import col, concat, count, countDistinct, lit, row_number, sha2
from pyspark.sql.window import Window


# Setup
environment = "dev"
catalog = f"ecommerce_{environment}"

events_table = f"{catalog}.silver.retailrocket_events"
products_table = f"{catalog}.silver.olist_products"
customers_table = f"{catalog}.silver.olist_customers"

item_target_table = f"{catalog}.silver.retailrocket_olist_item_bridge"
visitor_target_table = f"{catalog}.silver.retailrocket_olist_visitor_bridge"

seed = "20260805"


# Read distinct non-null identifiers
events_df = spark.table(events_table)

items_df = (
    events_df
    .select(col("item_id").alias("retailrocket_item_id"))
    .where(col("retailrocket_item_id").isNotNull())
    .distinct()
)

products_df = (
    spark.table(products_table)
    .select(col("product_id").alias("olist_product_id"))
    .where(col("olist_product_id").isNotNull())
    .distinct()
)

visitors_df = (
    events_df
    .select(col("visitor_id").alias("retailrocket_visitor_id"))
    .where(col("retailrocket_visitor_id").isNotNull())
    .distinct()
)

customers_df = (
    spark.table(customers_table)
    .select(col("customer_unique_id").alias("olist_customer_unique_id"))
    .where(col("olist_customer_unique_id").isNotNull())
    .distinct()
)

item_count = items_df.count()
product_count = products_df.count()
visitor_count = visitors_df.count()
customer_count = customers_df.count()

item_mapping_count = min(item_count, product_count)
visitor_mapping_count = min(visitor_count, customer_count)


# Generate item-to-product mapping
item_window = Window.orderBy(
    sha2(concat(lit(seed), col("retailrocket_item_id")), 256),
    col("retailrocket_item_id"),
)

product_window = Window.orderBy(
    sha2(concat(lit(seed), col("olist_product_id")), 256),
    col("olist_product_id"),
)

ranked_items_df = (
    items_df
    .withColumn("mapping_position", row_number().over(item_window))
    .where(col("mapping_position") <= item_mapping_count)
)

ranked_products_df = (
    products_df
    .withColumn("mapping_position", row_number().over(product_window))
    .where(col("mapping_position") <= item_mapping_count)
)

item_bridge_df = (
    ranked_items_df
    .join(ranked_products_df, "mapping_position")
    .select("retailrocket_item_id", "olist_product_id")
)


# Generate visitor-to-customer mapping
visitor_window = Window.orderBy(
    sha2(concat(lit(seed), col("retailrocket_visitor_id")), 256),
    col("retailrocket_visitor_id"),
)

customer_window = Window.orderBy(
    sha2(concat(lit(seed), col("olist_customer_unique_id")), 256),
    col("olist_customer_unique_id"),
)

ranked_visitors_df = (
    visitors_df
    .withColumn("mapping_position", row_number().over(visitor_window))
    .where(col("mapping_position") <= visitor_mapping_count)
)

ranked_customers_df = (
    customers_df
    .withColumn("mapping_position", row_number().over(customer_window))
    .where(col("mapping_position") <= visitor_mapping_count)
)

visitor_bridge_df = (
    ranked_visitors_df
    .join(ranked_customers_df, "mapping_position")
    .select("retailrocket_visitor_id", "olist_customer_unique_id")
)


# Validate row counts and uniqueness
item_result = item_bridge_df.agg(
    count("*").alias("row_count"),
    countDistinct("retailrocket_item_id").alias("distinct_item_count"),
    countDistinct("olist_product_id").alias("distinct_product_count")
).first()

visitor_result = visitor_bridge_df.agg(
    count("*").alias("row_count"),
    countDistinct("retailrocket_visitor_id").alias("distinct_visitor_count"),
    countDistinct("olist_customer_unique_id").alias("distinct_customer_count")
).first()

assert item_result["row_count"] == item_mapping_count
assert item_result["distinct_item_count"] == item_mapping_count
assert item_result["distinct_product_count"] == item_mapping_count

assert visitor_result["row_count"] == visitor_mapping_count
assert visitor_result["distinct_visitor_count"] == visitor_mapping_count
assert visitor_result["distinct_customer_count"] == visitor_mapping_count


# Write bridge tables
(
    item_bridge_df.write
    .format("delta")
    .mode("overwrite")
    .option("overwriteSchema", "true")
    .saveAsTable(item_target_table)
)

(
    visitor_bridge_df.write
    .format("delta")
    .mode("overwrite")
    .option("overwriteSchema", "true")
    .saveAsTable(visitor_target_table)
)


# Show results
print("Item-product bridge")
print("Eligible Retailrocket items:", item_count)
print("Eligible Olist products:", product_count)
print("Mapped rows:", item_mapping_count)
print("Unmatched Retailrocket items:", item_count - item_mapping_count)
print("Unmatched Olist products:", product_count - item_mapping_count)
print("Target table:", item_target_table)
print()
print("Visitor-customer bridge")
print("Eligible Retailrocket visitors:", visitor_count)
print("Eligible Olist customers:", customer_count)
print("Mapped rows:", visitor_mapping_count)
print("Unmatched Retailrocket visitors:", visitor_count - visitor_mapping_count)
print("Unmatched Olist customers:", customer_count - visitor_mapping_count)
print("Target table:", visitor_target_table)