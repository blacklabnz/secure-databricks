# Databricks notebook source
dbutils.widgets.text("adls_name",  "blkstor", "adls_name")
dbutils.widgets.text("adls_container",  "land", "adls_container")

# COMMAND ----------

adls_name = dbutils.widgets.get("adls_name")
adls_container = dbutils.widgets.get("adls_container")

# COMMAND ----------

spark.conf.set("fs.azure.account.auth.type", "OAuth")
spark.conf.set("fs.azure.account.oauth.provider.type", "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider")
spark.conf.set("fs.azure.account.oauth2.client.id", dbutils.secrets.get(scope="keyvault-managed",key="sp-id"))
spark.conf.set("fs.azure.account.oauth2.client.secret", dbutils.secrets.get(scope="keyvault-managed",key="sp-secret"))
spark.conf.set("fs.azure.account.oauth2.client.endpoint", "https://login.microsoftonline.com/replace-with-your-tenant-id/oauth2/token")

# COMMAND ----------

df = spark.read.json(f"abfss://{adls_container}@{adls_name}.dfs.core.windows.net/pubapis.json")

# COMMAND ----------

df.show()