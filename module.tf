
locals {
  custom_domain_ids = values(azurerm_cdn_frontdoor_custom_domain.custom_domain)[*].id
}


# Azure Front Door Profile
resource "azurerm_cdn_frontdoor_profile" "frontdoor_profile" {
  name                = local.front-door-name
  resource_group_name = local.resource_group_name
  sku_name            = try(var.front_door.profile_sku, "Standard_AzureFrontDoor")
  tags                = var.tags
}

# Azure Front Door Endpoint
resource "azurerm_cdn_frontdoor_endpoint" "endpoint" {
  name                = "${local.front-door-name}-endpoint"
  cdn_frontdoor_profile_id        = azurerm_cdn_frontdoor_profile.frontdoor_profile.id
  tags                = var.tags
}

# Azure Front Door Origin Groups
resource "azurerm_cdn_frontdoor_origin_group" "origin_group" {
  session_affinity_enabled = var.front_door.origin_group.session_affinity_enabled
  name                              = "${local.front-door-name}-og"
  cdn_frontdoor_profile_id                      = azurerm_cdn_frontdoor_profile.frontdoor_profile.id
  restore_traffic_time_to_healed_or_new_endpoint_in_minutes = var.front_door.origin_group.restore_traffic_time_to_healed_or_new_endpoint_in_minutes

  health_probe {
    interval_in_seconds = try(var.front_door.origin_group.health_probe_interval_in_seconds, 240)
    path                = try(var.front_door.origin_group.health_probe_path, "/healthProbe")
    protocol            = try(var.front_door.origin_group.health_probe_protocol, "Https")
    request_type        = try(var.front_door.origin_group.health_probe_request_type,"HEAD")
  }

  load_balancing {
    additional_latency_in_milliseconds = try(var.front_door.origin_group.load_balancing_additional_latency_in_milliseconds, 0)
    sample_size                        = try(var.front_door.origin_group.load_balancing_sample_size, 16)
    successful_samples_required        = try(var.front_door.origin_group.load_balancing_successful_samples_required,3)
  }
}

# Azure Front Door Origins
resource "azurerm_cdn_frontdoor_origin" "frontdoor_origin" {
  name                = "${local.front-door-name}-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin_group.id
  certificate_name_check_enabled = var.front_door.origin.certificate_name_check_enabled
  host_name           = var.origin_host_name
  http_port           = try(var.front_door.origin.http_port,80)
  https_port          = try(var.front_door.origin.https_port, 443)
  origin_host_header = var.origin_host_name
  enabled             = try(var.front_door.origin.enabled, true)
  priority            = try(var.front_door.origin.priority, 2)
  weight              = try(var.front_door.origin.weight, 50)
  dynamic "private_link" {
    for_each = try(var.front_door.origin.use_private_link.enable, false) != false ? [1] : []
    content {
                request_message        = var.front_door.origin.use_private_link.request_message
                target_type            = var.front_door.origin.use_private_link.target_type
                location               = var.front_door.origin.use_private_link.location
                private_link_target_id = var.front_door.origin.use_private_link.private_link_target_id
    }
  }
  dynamic "private_link" {
    for_each = try(var.front_door.origin.use_private_link_service.enable, false) != false ? [1] : []
    content {
                request_message        = var.front_door.origin.use_private_link.request_message
                location               = var.front_door.origin.use_private_link.location
                private_link_target_id = var.front_door.origin.use_private_link.private_link_target_id
    }
  }
}

# Azure Front Door Routes
resource "azurerm_cdn_frontdoor_route" "route" {
  name                          = "${local.front-door-name}-route"
  cdn_frontdoor_origin_group_id             =  azurerm_cdn_frontdoor_origin_group.origin_group.id
  cdn_frontdoor_endpoint_id        = azurerm_cdn_frontdoor_endpoint.endpoint.id
  cdn_frontdoor_origin_ids  = [azurerm_cdn_frontdoor_origin.frontdoor_origin.id]
  cdn_frontdoor_custom_domain_ids = local.custom_domain_ids
  cdn_frontdoor_rule_set_ids    = [azurerm_cdn_frontdoor_rule_set.rule_set.id]
  link_to_default_domain          = false
  https_redirect_enabled = true
  supported_protocols            = try(var.front_door.route.supported_protocols, ["Https", "Http"])
  patterns_to_match             = try(var.front_door.route.patterns_to_match, ["/*"])
  forwarding_protocol           = try(var.front_door.route.forwarding_protocol, "MatchRequest")
  enabled                       = try(var.front_door.route.enabled,false)
  dynamic "cache" {
    for_each = try(var.front_door.route.cache.enable, false) != false ? [1] : []
    content {
              query_string_caching_behavior = try(var.front_door.route.cache.query_string_caching_behavior, "IgnoreQueryString")
              query_strings=try(var.front_door.route.cache.query_strings, [])
              compression_enabled = try(var.front_door.route.cache.compression_enabled, false)
              content_types_to_compress = try(var.front_door.route.cache.content_types_to_compress, ["text/html"])
    }
  }

}

# Azure Front Door Custom Domains
resource "azurerm_cdn_frontdoor_custom_domain" "custom_domain" {
  for_each            = var.front_door.custom_domains
  name                = "${local.front-door-name}-${each.key}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoor_profile.id 
  host_name           = each.value.host_name
  tls {
      certificate_type    = try(each.value.certificate_type, "ManagedCertificate")
      minimum_tls_version = try(each.value.minimum_tls_version, "TLS12")
    }
}

# Azure Front Door Custom Domain Association
resource "azurerm_cdn_frontdoor_custom_domain_association" "domain_association" {
  for_each            = var.front_door.custom_domains
  cdn_frontdoor_custom_domain_id        = azurerm_cdn_frontdoor_custom_domain.custom_domain[each.key].id
  cdn_frontdoor_route_ids       = [azurerm_cdn_frontdoor_route.route.id]
}

resource "azurerm_dns_cname_record" "cname_record" {
  for_each = {
      for key, value in var.front_door.custom_domains : key => value
      if value.internal_dns_record == true
  }
  depends_on = [azurerm_cdn_frontdoor_route.route, azurerm_cdn_frontdoor_security_policy.fd_security_policy]

  name                = each.value.host_name
  zone_name           = var.zones[each.value.internal_dsn_zone_name].name
  resource_group_name = var.resource_groups["DNS"].name
  ttl                 = try(each.value.ttl,3600)
  record              = azurerm_cdn_frontdoor_endpoint.endpoint.host_name
}

resource "azurerm_dns_txt_record" "txt_record" {
  for_each = {
      for key, value in var.front_door.custom_domains : key => value
      if value.internal_dns_record == true
  }
  name                = join(".", ["_dnsauth", "${each.value.host_name}"])
  zone_name           = var.zones[each.value.internal_dsn_zone_name].name
  resource_group_name = var.resource_groups["DNS"].name
  ttl                 = try(each.value.ttl,3600)

  record {
    value = azurerm_cdn_frontdoor_custom_domain.custom_domain[each.key].validation_token
  }
}


# Azure Front Door Rule Sets
resource "azurerm_cdn_frontdoor_rule_set" "rule_set" {
  name                = "${local.rule_set-name}"
  cdn_frontdoor_profile_id        = azurerm_cdn_frontdoor_profile.frontdoor_profile.id
}


# # Azure Front Door Rules
resource "azurerm_cdn_frontdoor_rule" "rules" {
  depends_on = [azurerm_cdn_frontdoor_origin_group.origin_group, azurerm_cdn_frontdoor_origin.frontdoor_origin]
  for_each = try(var.front_door.rules, {})

  name                    = each.key
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.rule_set.id
  order                   = each.value.order

  # Conditions
  dynamic "conditions" {
    for_each = each.value.conditions

    content {
      # Request URI Condition
      dynamic "request_uri_condition" {
        for_each = [for cond in each.value.conditions : cond if lookup(cond, "type", null) == "request_uri_condition"]

        content {
          operator         = request_uri_condition.value.operator
          negate_condition = request_uri_condition.value.negate
          match_values     = request_uri_condition.value.match_values
          transforms       = request_uri_condition.value.transforms
        }
      }

      # Request Header Condition
      dynamic "request_header_condition" {
        for_each = [for cond in each.value.conditions : cond if lookup(cond, "type", null) == "request_header_condition"]

        content {
          header_name      = request_header_condition.value.header_name
          operator         = request_header_condition.value.operator
          negate_condition = request_header_condition.value.negate_condition
          match_values     = request_header_condition.value.match_values
          transforms       = request_header_condition.value.transforms
        }
      }

      # Remote Address Condition
      dynamic "remote_address_condition" {
        for_each = [for cond in each.value.conditions : cond if lookup(cond, "type", null) == "remote_address_condition"]

        content {
          operator         = remote_address_condition.value.operator
          negate_condition = remote_address_condition.value.negate
          match_values     = remote_address_condition.value.match_values
        }
      }

      # Query String Condition
      dynamic "query_string_condition" {
        for_each = [for cond in each.value.conditions : cond if lookup(cond, "type", null) == "query_string_condition"]

        content {
          operator         = query_string_condition.value.operator
          negate_condition = query_string_condition.value.negate
          match_values     = query_string_condition.value.match_values
          transforms       = query_string_condition.value.transforms
        }
      }

      # Request Method Condition
      dynamic "request_method_condition" {
        for_each = [for cond in each.value.conditions : cond if lookup(cond, "type", null) == "request_method_condition"]

        content {
          match_values = request_method_condition.value.match_values
        }
      }
    }
  }

  # Actions
  dynamic "actions" {
    for_each = each.value.actions

    content {
      # Cache Expiration Action
      dynamic "route_configuration_override_action" {
        for_each = [for act in each.value.actions : act if lookup(act, "action_type", null) == "route_configuration_override_action"]

        content {
          forwarding_protocol = route_configuration_override_action.value.forwarding_protocol
          cache_duration = try(route_configuration_override_action.value.cache_duration, null)
          cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.origin_group.id
          cache_behavior = route_configuration_override_action.value.cache_behavior
          query_string_caching_behavior = route_configuration_override_action.value.query_string_caching_behavior
        }
      }

      # Request Header Action
      dynamic "request_header_action" {
        for_each = [for act in each.value.actions : act if lookup(act, "action_type", null) == "request_header_action"]

        content {
          header_action = request_header_action.value.header_action
          header_name   = request_header_action.value.header_name
          value  = request_header_action.value.header_value
        }
      }

      # Response Header Action
      dynamic "response_header_action" {
        for_each = [for act in each.value.actions : act if lookup(act, "action_type", null) == "response_header_action"]

        content {
          header_action = response_header_action.value.header_action
          header_name   = response_header_action.value.header_name
          value  = response_header_action.value.header_value
        }
      }

      # URL Redirect Action
      dynamic "url_redirect_action" {
        for_each = [for act in each.value.actions : act if lookup(act, "action_type", null)  == "url_redirect_action"]

        content {
          redirect_type            = url_redirect_action.value.redirect_type
          redirect_protocol     = url_redirect_action.value.redirect_protocol
          destination_hostname         = url_redirect_action.value.destination_hostname
          destination_path         = url_redirect_action.value.destination_path
          query_string = url_redirect_action.value.query_string
          destination_fragment  = url_redirect_action.value.destination_fragment
        }
      }

      # URL Rewrite Action
      dynamic "url_rewrite_action" {
        for_each = [for act in each.value.actions : act if lookup(act, "action_type", null) == "url_rewrite_action"]

        content {
          source_pattern         = url_rewrite_action.value.source_pattern
          destination            = url_rewrite_action.value.destination
          preserve_unmatched_path = url_rewrite_action.value.preserve_unmatched_path
        }
      }
    }
  }
}


resource "azurerm_cdn_frontdoor_firewall_policy" "fd_firewall_policy" {
    name                = "${local.rule_set-name}firewall"
    resource_group_name = local.resource_group_name
    sku_name                          = azurerm_cdn_frontdoor_profile.frontdoor_profile.sku_name
    dynamic "custom_rule" {
      for_each = try(var.front_door.firewall_policy.custom_rules, {})

      content {
        name                          = custom_rule.key
        type                          =  custom_rule.value.type
        priority                      = custom_rule.value.priority
        enabled                       = custom_rule.value.enabled
        rate_limit_duration_in_minutes = custom_rule.value.rate_limit_duration_in_minutes
        rate_limit_threshold           = custom_rule.value.rate_limit_threshold
        action                        = custom_rule.value.action
        match_condition {
          match_variable     = custom_rule.value.match_variable
          operator           = custom_rule.value.operator
          negation_condition = custom_rule.value.negation_condition
          match_values       = custom_rule.value.match_values
        }
      }
    }

    dynamic "managed_rule" {

      for_each =try(var.front_door.firewall_policy.managed_rules,  {}) 
      content {
        type = managed_rule.value.type
        version = managed_rule.value.version
        action  = try(managed_rule.value.action,null)

        dynamic "exclusion" {
          for_each = try(managed_rule.value.exclusions, {}) 
          content {
            match_variable = exclusion.value.match_variable
            operator       = exclusion.value.operator
            selector       = exclusion.value.selector
          }
        }

        dynamic "override" {

          for_each = try(managed_rule.value.overrides, {})
          content {
            rule_group_name = override.value.rule_group_name

            dynamic "rule" {
              for_each = try(override.value.rule,null) != null ? override.value.rule : {}

              content {
                rule_id = rule.value.rule_id
                enabled = rule.value.enabled
                action  = rule.value.action

                dynamic "exclusion" {
                  for_each = try(rule.value.exclusion,{})

                  content {
                    match_variable = exclusion.value.match_variable
                    operator       = exclusion.value.operator
                    selector       = exclusion.value.selector
                  }
                }
              }
            }
          }
        }
      }
    }

    enabled = var.front_door.firewall_policy.enabled
    mode    = var.front_door.firewall_policy.mode
    redirect_url                      = var.front_door.firewall_policy.redirect_url
    custom_block_response_status_code = var.front_door.firewall_policy.custom_block_response_status_code
    custom_block_response_body        = var.front_door.firewall_policy.custom_block_response_body
}



resource "azurerm_cdn_frontdoor_security_policy" "fd_security_policy" {
  name                     = "${local.rule_set-name}securitypolicy"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoor_profile.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.fd_firewall_policy.id

      association {
        dynamic "domain" {
            for_each = var.front_door.custom_domains 
            content {
              cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_custom_domain.custom_domain[domain.key].id
            }
        }
        patterns_to_match = var.front_door.security_policy.patterns_to_match
      }
    }
  }
}

resource "azurerm_cdn_frontdoor_secret" "fd_secret" {
  count = try(var.front_door.secret,null) == null ? 0 : 1
  name                     = "${local.front-door-name}-fd-secret"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoor_profile.id

  secret {
    customer_certificate {
      key_vault_certificate_id = var.front_door.secret.key_vault_certificate_id
    }
  }
}


