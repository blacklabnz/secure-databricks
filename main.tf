locals {
  org           = "blk"
  rg            = "${local.org}-secure-dbr"
  rg_location   = "australiaeast"
  vnet_dbr      = "${local.org}-spoke-dbr"
  vnet_resource = "${local.org}-spoke-resource"

  vnet_dbr_address_space = "10.0.0.0/16"

  vnet_dbr_subnet_prv        = "private"
  vnet_dbr_subnet_prv_prefix = "10.0.1.0/24"

  vnet_dbr_subnet_pub        = "public"
  vnet_dbr_subnet_pub_prefix = "10.0.2.0/24"

  vnet_resource_address_space = "10.1.0.0/16"

  vnet_resource_subnet_stor        = "stor"
  vnet_resource_subnet_stor_prefix = "10.1.1.0/24"

  vnet_resource_subnet_kv        = "keyvault"
  vnet_resource_subnet_kv_prefix = "10.1.2.0/24"

  dbr         = "${local.org}-secure-dbr"
  dbr_sku     = "premium"
  dbr_mgmt_rg = "${local.dbr}-mgmt-rg"
  dbr_nsg     = "${local.org}-nsg"
  dbr_cluster = "${local.org}-cluster"

  stor         = "${local.org}stortvnz"
  stor_pe      = "${local.stor}pe"
  stor_prv_con = "${local.stor}prvcon"

  kv         = "${local.org}-kv-tvnz"
  kv_pe      = "${local.kv}pe"
  kv_prv_con = "${local.kv}prvcon"
}

resource "azurerm_resource_group" "secure_dbr" {
  name     = local.rg
  location = local.rg_location
}

resource "azurerm_virtual_network" "vnet_dbr" {
  name                = local.vnet_dbr
  location            = local.rg_location
  resource_group_name = azurerm_resource_group.secure_dbr.name
  address_space       = [local.vnet_dbr_address_space]

  depends_on = [azurerm_resource_group.secure_dbr]
}

resource "azurerm_subnet" "dbr_prv" {
  name                 = local.vnet_dbr_subnet_prv
  resource_group_name  = local.rg
  virtual_network_name = azurerm_virtual_network.vnet_dbr.name
  address_prefixes     = [local.vnet_dbr_subnet_prv_prefix]

  delegation {
    name = "dbr_prv_dlg"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }
  depends_on = [azurerm_virtual_network.vnet_dbr]
}

resource "azurerm_subnet" "dbr_pub" {
  name                 = local.vnet_dbr_subnet_pub
  resource_group_name  = local.rg
  virtual_network_name = azurerm_virtual_network.vnet_dbr.name
  address_prefixes     = [local.vnet_dbr_subnet_pub_prefix]

  delegation {
    name = "dbr_pub_dlg"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }
  depends_on = [azurerm_virtual_network.vnet_dbr]
}

resource "azurerm_virtual_network" "vnet_resource" {
  name                = local.vnet_resource
  location            = local.rg_location
  resource_group_name = azurerm_resource_group.secure_dbr.name
  address_space       = [local.vnet_resource_address_space]

  depends_on = [azurerm_resource_group.secure_dbr]
}

resource "azurerm_subnet" "resource_stor" {
  name                                           = local.vnet_resource_subnet_stor
  resource_group_name                            = local.rg
  virtual_network_name                           = azurerm_virtual_network.vnet_resource.name
  address_prefixes                               = [local.vnet_resource_subnet_stor_prefix]
  enforce_private_link_endpoint_network_policies = true

  depends_on = [azurerm_virtual_network.vnet_resource]
}

resource "azurerm_subnet" "resource_kv" {
  name                                           = local.vnet_resource_subnet_kv
  resource_group_name                            = local.rg
  virtual_network_name                           = azurerm_virtual_network.vnet_resource.name
  address_prefixes                               = [local.vnet_resource_subnet_kv_prefix]
  enforce_private_link_endpoint_network_policies = true

  depends_on = [azurerm_virtual_network.vnet_resource]
}

resource "azurerm_virtual_network_peering" "dbr_to_resource" {
  name                      = "dbr-vent-to-resource-vnet"
  resource_group_name       = local.rg
  virtual_network_name      = azurerm_virtual_network.vnet_dbr.name
  remote_virtual_network_id = azurerm_virtual_network.vnet_resource.id
}

resource "azurerm_virtual_network_peering" "resource_to_dbr" {
  name                      = "resource-vent-to-dbr-vnet"
  resource_group_name       = local.rg
  virtual_network_name      = azurerm_virtual_network.vnet_resource.name
  remote_virtual_network_id = azurerm_virtual_network.vnet_dbr.id
}

resource "azurerm_network_security_group" "dbr_nsg" {
  name                = local.dbr_nsg
  location            = local.rg_location
  resource_group_name = azurerm_resource_group.secure_dbr.name
}

resource "azurerm_subnet_network_security_group_association" "dbr_prv" {
  subnet_id                 = azurerm_subnet.dbr_prv.id
  network_security_group_id = azurerm_network_security_group.dbr_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "dbr_pub" {
  subnet_id                 = azurerm_subnet.dbr_pub.id
  network_security_group_id = azurerm_network_security_group.dbr_nsg.id
}

resource "azurerm_databricks_workspace" "dbr" {
  name                = local.dbr
  resource_group_name = local.rg
  location            = local.rg_location
  sku                 = local.dbr_sku

  managed_resource_group_name = local.dbr_mgmt_rg

  custom_parameters {
    no_public_ip        = true
    virtual_network_id  = azurerm_virtual_network.vnet_dbr.id
    public_subnet_name  = azurerm_subnet.dbr_pub.name
    private_subnet_name = azurerm_subnet.dbr_prv.name

    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.dbr_pub.id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.dbr_prv.id
  }
}

resource "databricks_cluster" "cluster" {
  cluster_name            = local.dbr_cluster
  spark_version           = data.databricks_spark_version.latest.id
  node_type_id            = data.databricks_node_type.smallest.id
  autotermination_minutes = 20
  spark_conf = {
    "spark.databricks.cluster.profile" : "singleNode"
    "spark.master" : "local[*]"
  }

  custom_tags = {
    "ResourceClass" = "SingleNode"
  }
}

resource "azurerm_storage_account" "stor" {
  name                = local.stor
  resource_group_name = local.rg

  location                 = local.rg_location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  is_hns_enabled = true

  network_rules {
    default_action = "Deny"
    ip_rules       = [data.external.my_ip.result.ip]
  }
}

resource "azurerm_storage_container" "container" {
  name                  = "land"
  storage_account_name  = azurerm_storage_account.stor.name
  container_access_type = "private"
}

resource "azurerm_private_endpoint" "stor_pe" {
  name                = local.stor_pe
  location            = local.rg_location
  resource_group_name = local.rg
  subnet_id           = azurerm_subnet.resource_stor.id

  private_service_connection {
    name                           = local.stor_prv_con
    private_connection_resource_id = azurerm_storage_account.stor.id
    is_manual_connection           = false
    subresource_names              = ["dfs"]
  }
}

resource "azurerm_private_dns_zone" "stor_dfs" {
  name                = "privatelink.dfs.core.windows.net"
  resource_group_name = local.rg
}

resource "azurerm_private_dns_zone_virtual_network_link" "dbr_vnet_link_stor" {
  name                  = "dbr_vnet_link"
  resource_group_name   = local.rg
  private_dns_zone_name = azurerm_private_dns_zone.stor_dfs.name
  virtual_network_id    = azurerm_virtual_network.vnet_dbr.id
}

resource "azurerm_private_dns_a_record" "storpe_dns" {
  name                = local.stor
  zone_name           = azurerm_private_dns_zone.stor_dfs.name
  resource_group_name = local.rg
  ttl                 = 300
  records             = [azurerm_private_endpoint.stor_pe.private_service_connection.0.private_ip_address]
}

resource "azurerm_key_vault" "kv" {
  name                        = local.kv
  location                    = local.rg_location
  resource_group_name         = local.rg
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  network_acls {
    default_action = "Deny"
    bypass = "AzureServices"
    ip_rules = [data.external.my_ip.result.ip]
  }
}

resource "azurerm_private_endpoint" "kv_pe" {
  name                = local.kv_pe
  location            = local.rg_location
  resource_group_name = local.rg
  subnet_id           = azurerm_subnet.resource_kv.id

  private_service_connection {
    name                           = local.kv_prv_con
    private_connection_resource_id = azurerm_key_vault.kv.id
    is_manual_connection           = false
    subresource_names              = ["Vault"]
  }
}

resource "azurerm_private_dns_zone" "kv" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = local.rg
}

resource "azurerm_private_dns_zone_virtual_network_link" "dbr_vnet_link_kv" {
  name                  = "dbr_vnet_link_kv"
  resource_group_name   = local.rg
  private_dns_zone_name = azurerm_private_dns_zone.kv.name
  virtual_network_id    = azurerm_virtual_network.vnet_dbr.id
}

resource "azurerm_private_dns_a_record" "kvpe_dns" {
  name                = local.kv
  zone_name           = azurerm_private_dns_zone.kv.name
  resource_group_name = local.rg
  ttl                 = 300
  records             = [azurerm_private_endpoint.kv_pe.private_service_connection.0.private_ip_address]
}

# resource "databricks_secret_scope" "kv" {
#   name = "keyvault-managed"

#   keyvault_metadata {
#     resource_id = azurerm_key_vault.kv.id
#     dns_name    = azurerm_key_vault.kv.vault_uri
#   }
# }

resource "databricks_notebook" "py_notebooks" {
  for_each = fileset("${path.module}/notebooks", "*.py")
  source = "${path.module}/notebooks/${each.key}"
  path   = "/run/${element(split(".", each.key), 0)}"
  language = "PYTHON"
}

resource "databricks_notebook" "sql_notbooks" {
  for_each = fileset("${path.module}/notebooks", "*.sql")
  source = "${path.module}/notebooks/${each.key}"
  path   = "/run/${element(split(".", each.key), 0)}"
  language = "SQL"
}
