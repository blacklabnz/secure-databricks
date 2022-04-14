# Secure Databricks clusters

## Databricks clusters can be secured with the following:

1. secured cluster connectivity
2. vNet injection 
   
## Resource access be databricks cluster can also be secured with:
1. access resource with private 
   
## Please refer to the following diagram for the simple architecture:
![architecture](https://github.com/blacklabnz/blacklabnz.github.io/blob/main/static/posts/databricks-secure/dbr-secure.png) 

## In the repo you will find terraform IaC resources require for the following
1. deploy Databricks cluster with secured connectivity with no public ip address and vNet injection which helps to put clusters inside a existing vNet.
2. Accessing resources e.g. Storage account and keyvault with private endpoint and Azure private DNS record.