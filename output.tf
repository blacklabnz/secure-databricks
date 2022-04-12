output "id" {
  value       = azurerm_resource_group.secure_dbr.id
}

output "dbr" {
  value = azurerm_databricks_workspace.dbr
}

output "ip" {
  value = data.external.my_ip.result.ip
}
