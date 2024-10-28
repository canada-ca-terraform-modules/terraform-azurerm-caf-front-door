output "front-door-object" {
  description = "Outputs the entire front door object"
  value = azurerm_cdn_frontdoor_profile.frontdoor_profile
}

output "front-door-id" {
  description = "Outputs the front door profile ID"
  value = azurerm_cdn_frontdoor_profile.frontdoor_profile.id
}

output "front-door-name" {
  description = "Outputs the front door profile name"
  value = azurerm_cdn_frontdoor_profile.frontdoor_profile
}




