
resource "azurerm_subnet" "subnet" {
  for_each = var.subnets

  address_prefixes                              = each.value.address_prefixes
  name                                          = each.key
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = azurerm_virtual_network.vnet.name
  private_endpoint_network_policies_enabled     = each.value.private_endpoint_network_policies_enabled
  private_link_service_network_policies_enabled = each.value.private_link_service_network_policies_enabled
  service_endpoint_policy_ids                   = each.value.service_endpoint_policy_ids
  service_endpoints                             = each.value.service_endpoints

  dynamic "delegation" {
    for_each = each.value.delegations == null ? [] : each.value.delegations

    content {
      name = delegation.value.name

      service_delegation {
        name    = delegation.value.service_delegation.name
        actions = delegation.value.service_delegation.actions
      }
    }
  }

  # Do not remove this `depends_on` or we'll met a parallel related issue that failed the creation of `azurerm_subnet_route_table_association` and `azurerm_subnet_network_security_group_association`
  depends_on = [azurerm_virtual_network_dns_servers.vnet_dns]
}

locals {
  azurerm_subnet_name2id = {
    for index, subnet in azurerm_subnet.subnet :
    subnet.name => subnet.id
  }
}

resource "azurerm_subnet_network_security_group_association" "vnet" {
  for_each = local.subnet_with_network_security_group

  network_security_group_id = each.value
  subnet_id                 = local.azurerm_subnet_name2id[each.key]
}

resource "azurerm_subnet_route_table_association" "vnet" {
  for_each = local.subnets_with_route_table

  route_table_id = each.value
  subnet_id      = local.azurerm_subnet_name2id[each.key]
}

resource "azurerm_subnet_nat_gateway_association" "nat_gw" {
  for_each = local.subnet_with_nat_gateway

  nat_gateway_id = each.value
  subnet_id      = local.azurerm_subnet_name2id[each.key]
}