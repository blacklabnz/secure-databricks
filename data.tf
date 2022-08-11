data "azurerm_databricks_workspace" "dbr" {
  name                = azurerm_databricks_workspace.dbr.name
  resource_group_name = local.rg
}

data "databricks_spark_version" "latest" {
  depends_on = [azurerm_databricks_workspace.dbr]
}

data "databricks_node_type" "smallest" {
  local_disk = true
  min_cores  = 4
  category   = "Compute optimized"
}

data "azurerm_client_config" "current" {}

data "external" "my_ip" {
  program = ["curl", "https://api.ipify.org?format=json"]
}
