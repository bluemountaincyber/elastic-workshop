output "elastic_url" {
  value = "http://${azurerm_public_ip.el_pip.ip_address}:5601"
}

output "victim_url" {
  value = "http://${azurerm_public_ip.victim_pip.ip_address}"
}