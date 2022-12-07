# Databricks notebook source
display(dbutils.fs.ls('/databricks-datasets/nyctaxi/tripdata/green'))

# COMMAND ----------

spark.conf.set("fs.azure.account.auth.type", "OAuth")
spark.conf.set("fs.azure.account.oauth.provider.type", "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider")
spark.conf.set("fs.azure.account.oauth2.client.id", "")
spark.conf.set("fs.azure.account.oauth2.client.secret", "")
spark.conf.set("fs.azure.account.oauth2.client.endpoint", "https://login.microsoftonline.com/{}/oauth2/token")


# COMMAND ----------

dbutils.fs.cp(
    "/databricks-datasets/nyctaxi/tripdata/green/green_tripdata_2019-12.csv.gz", 
    "abfss://land@blkdatalake.dfs.core.windows.net/trip_data/green_tripdata_2019-12.csv.gz")

dbutils.fs.cp(
    "/databricks-datasets/nyctaxi/taxizone/taxi_zone_lookup.csv", 
    "abfss://land@blkdatalake.dfs.core.windows.net/zone_lookup/taxi_zone_lookup.csv")

# COMMAND ----------

df_trip = (spark.read
    .options(header="True")
    .csv("abfss://land@blkdatalake.dfs.core.windows.net/trip_data/green_tripdata_2019-12.csv.gz"))

# COMMAND ----------

# # save data to stoage location as delta table
# df_trip.write.mode("overwrite").format("delta").save("abfss://dbr@blkdatalake.dfs.core.windows.net/ingested/trip_data")
# save data as delta hive table
df_trip.write.mode("overwrite").format("delta").saveAsTable("catalog1.schema1.nyctaxi_trip")

# COMMAND ----------

df_zone = (spark.read
    .options(header="True")
    .csv("abfss://land@blkdatalake.dfs.core.windows.net/zone_lookup/taxi_zone_lookup.csv"))

# COMMAND ----------

# # save data to stoage location as delta table
# df_zone.write.mode("overwrite").format("delta").save("abfss://dbr@blkdatalake.dfs.core.windows.net/ingested/zone_data")

# save data to delta hive table
df_zone.write.mode("overwrite").format("delta").saveAsTable("catalog1.schema1.nyctaxi_zone")

# COMMAND ----------

# MAGIC %sql
# MAGIC -- CREATE TABLE IF NOT EXISTS nyctaxi_trip USING delta LOCATION 'abfss://dbr@blkdatalake.dfs.core.windows.net/ingested/trip_data';
# MAGIC -- CREATE TABLE IF NOT EXISTS nyctaxi_zone USING delta LOCATION 'abfss://dbr@blkdatalake.dfs.core.windows.net/ingested/zone_data';

# COMMAND ----------

# MAGIC %sql
# MAGIC select * from nyctaxi_trip

# COMMAND ----------

# MAGIC %sql
# MAGIC select * from nyctaxi_zone

# COMMAND ----------

# MAGIC %sql
# MAGIC -- -- create delta table using a storage file location
# MAGIC -- create or replace table nyctaxi_curated_tbl using delta LOCATION 'abfss://dbr@blkdatalake.dfs.core.windows.net/curated/trip_data'
# MAGIC create or replace table catalog1.schema1.nyctaxi_curated_tbl using delta
# MAGIC as(
# MAGIC   with a as (
# MAGIC     select 
# MAGIC       lpep_pickup_datetime as pickup_time, 
# MAGIC       lpep_dropoff_datetime as dropoff_time,
# MAGIC       PULocationID, 
# MAGIC       DOLocationID, 
# MAGIC       z.Zone as pickup_zone, 
# MAGIC       z.LocationID as pickup_zone_id,
# MAGIC       x.Zone as dropoff_zone,
# MAGIC       x.LocationID as dropoff_zone_id
# MAGIC     from catalog1.schema1.nyctaxi_trip t left join catalog1.schema1.nyctaxi_zone z on t.PULocationID = z.LocationID left join catalog1.schema1.nyctaxi_zone x on t.DOLocationID = x.LocationID
# MAGIC   )
# MAGIC select pickup_time, dropoff_time, pickup_zone, dropoff_zone from a);

# COMMAND ----------

# MAGIC %sql
# MAGIC select count(*) from test_unity.nyctaxi_curated_tbl
# MAGIC -- describe table extended nyctaxi_curated_tbl
# MAGIC -- drop table nyctaxi_curated_tbl

# COMMAND ----------

# MAGIC %sql
# MAGIC describe table extended riki.nyctaxi_curated_tbl
# MAGIC -- show tables
# MAGIC -- show views
# MAGIC -- select * from default.nyctaxi_table
# MAGIC -- drop view default.nyctaxi_curated
# MAGIC -- drop table default.nyctaxi_zone1
# MAGIC -- select count(*) from default.nyctaxi_zone;
# MAGIC -- select count(*) from default.nyctaxi_2;

# COMMAND ----------

# MAGIC %sql
# MAGIC -- delete from nyctaxi_1 where Payment_Type = 'CASH'
# MAGIC -- describe history nyctaxi_1 
# MAGIC -- RESTORE TABLE nyctaxi_1 TO VERSION AS OF 7
