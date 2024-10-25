front_doors ={
    website =  {
    # Resource Group and Location
        resource_group = "Project"
        location            = "global"  # Front Door location should be set to "global"

        # Front Door Profile Configuration
        profile_name = "example-frontdoor-profile"
        profile_sku  = "Premium_AzureFrontDoor"  # Options: Standard_AzureFrontDoor, Premium_AzureFrontDoor

        dns={
                internal_dns_zone_name ="zone1"
                internal_dns_record_name = "www"
                ttl=3600
        }
        # Front Door Origin Groups
        origin_group = {
           
            session_affinity_enabled = true
            restore_traffic_time_to_healed_or_new_endpoint_in_minutes = 10
            health_probe_interval_in_seconds = 240
            health_probe_path                = "/healthProbe"
            health_probe_protocol            = "Https"
            health_probe_request_type        = "HEAD"
            load_balancing_additional_latency_in_milliseconds = 0
            load_balancing_sample_size                        = 16
            load_balancing_successful_samples_required        = 3
            backends                        = ["origin1", "origin2"]  # Reference to origin names defined in the `origins` map
            
        }

        # Front Door Origins
        
        origin = {
            http_port             = 80
            https_port            = 443
            certificate_name_check_enabled = false
            enabled               = true
            priority              = 2
            weight                = 50
            use_private_link     = {
                enable =   false
                request_message        = "Request access for Private Link Origin CDN Frontdoor"
                target_type            = "blob"
                location               = "canadacentral"  # location of storage account
                private_link_target_id = "" #id of storage acccount /subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/example-rg/providers/Microsoft.Storage/storageAccounts/example-storage-account
            }
            use_private_link_service     = {
                enable =   false
                request_message        = "Request access for Private Link Origin CDN Frontdoor"
                location               = "canadacentral" # location of resource group
                private_link_target_id = "" #id of private link service
            }
        }
        



        # Front Door Custom Domains
        custom_domains = {
            custom-domain1 = {
                host_name  = "custom.example.com"
                certificate_type    = "ManagedCertificate"
                minimum_tls_version = "TLS12"
                ttl =3600
            }
            custom-domain2 = {
                host_name  = "www.custom.example.com"
                certificate_type    = "ManagedCertificate"
                minimum_tls_version = "TLS12"
                ttl=3600
            }
        }

        # Front Door Routes
        
        route = {
            supported_protocols      = ["Https", "Http"]
            patterns_to_match       = ["/*"]
            forwarding_protocol     = "MatchRequest"
            enabled                 = true
            link_to_default_domain  = true
            https_redirect_enabled = true
            cache ={
                enabled = false
                query_string_caching_behavior = "IgnoreQueryString"
                query_strings=[]
                compression_enabled = false
                content_types_to_compress = ["text/html"]
            }
        }
        

        # Front Door Rule Sets
        rules = {

                rule1=    {
                        order = 1
                        conditions = [
                        {
                            type         = "request_uri_condition"
                            operator     = "Equal"
                            negate       = false
                            match_values = ["/example-path"]
                            selector     = ""
                            transforms   = ["Lowercase"]
                        }
                        ]
                        actions = [
                        {
                            action_type  = "route_configuration_override_action"
                            forwarding_protocol = "HttpsOnly"
                            #cache_duration = "364.23:59:59" #cache_duration' field must not be set if the 'cache_behavior' is 'HonorOrigin'
                            cache_behavior = "HonorOrigin" #cache_behavior to be one of ["HonorOrigin" "OverrideAlways" "OverrideIfOriginMissing" "Disabled"]
                            query_string_caching_behavior = "IgnoreQueryString" # be one of ["IgnoreQueryString" "UseQueryString" "IgnoreSpecifiedQueryStrings" "IncludeSpecifiedQueryStrings"]
                        }
                        ]
                    }

                rule2=    {

                        order = 2
                        conditions = [
                        {
                            type         = "request_header_condition"
                            header_name      = "User-Agent"
                            operator         = "Equal"
                            negate_condition = false
                            match_values     = ["Chrome"]
                            transforms       = []
                        }
                        ]
                        actions = [
                        {
                            action_type  = "request_header_action"
                            header_action = "Overwrite"
                            header_name   = "X-Custom-Header"
                            header_value  = "CustomValue"
                            cache_behavior = ""
                            cache_duration = ""
                            redirect_type = ""
                            destination_protocol = ""
                            destination_host = ""
                            destination_path = ""
                            destination_query_string = ""
                            preserve_unmatched_path = false
                        }
                        ]
                    }

                rule3=    {
                        order = 3
                        conditions = [
                        {
                            type         = "remote_address_condition"
                            operator     = "IPMatch"
                            negate       = false
                            match_values = ["192.168.0.0/24"]
                            selector     = ""
                            transforms   = []
                        }
                        ]
                        actions = [
                        {
                            action_type  = "response_header_action"
                            header_action = "Overwrite"
                            header_name   = "X-Powered-By"
                            header_value  = "Terraform"
                            cache_behavior = ""
                            cache_duration = ""
                            redirect_type = ""
                            destination_protocol = ""
                            destination_host = ""
                            destination_path = ""
                            destination_query_string = ""
                            preserve_unmatched_path = false
                        }
                        ]
                    }

                rule4=    {
                        order = 4
                        conditions = [
                        {
                            type         = "query_string_condition"
                            operator     = "Equal"
                            negate       = false
                            match_values = ["id=123"]
                            selector     = "id"
                            transforms   = []
                        }
                        ]
                        actions = [
                        {
                            action_type  = "url_redirect_action"
                            redirect_type            = "Found"
                            redirect_protocol     = "Https"
                            destination_hostname         = "www.example.com"
                            destination_path         = "/new-path"
                            query_string = "id=123"
                            destination_fragment  =    "   "
                        }
                        ]
                    }

                rule5=    {
                        order = 5
                        conditions = [
                        {
                            type         = "request_method_condition"
                            operator     = "Equal"
                            negate       = false
                            match_values = ["GET"]
                            selector     = ""
                            transforms   = []
                        }
                        ]
                        actions = [
                        {
                            action_type  = "url_rewrite_action"
                            source_pattern = "/old-path/*"
                            destination    = "/new-path/"
                            preserve_unmatched_path = false
                            header_name  = ""
                            header_value = ""
                            cache_behavior = ""
                            cache_duration = ""
                            redirect_type = ""
                            destination_protocol = ""
                            destination_host = ""
                            destination_query_string = ""
                        }
                        ]
                    }
                
            
        }

        firewall_policy ={
            enabled                           = true
            mode                              =  "Prevention"
            redirect_url                      =  "https://www.microsoft.com"
            custom_block_response_status_code = 403
            custom_block_response_body        = "PGh0bWw+CjxoZWFkZXI+PHRpdGxlPkhlbGxvPC90aXRsZT48L2hlYWRlcj4KPGJvZHk+CkhlbGxvIHdvcmxkCjwvYm9keT4KPC9odG1sPg=="
            custom_rules ={
                rule1 ={
                    enabled                        = true
                    priority                       = 1
                    rate_limit_duration_in_minutes = 1
                    rate_limit_threshold           = 10
                    type                           = "MatchRule"
                    action                         = "Block"
                    match_variable     = "RemoteAddr"
                    operator           = "IPMatch"
                    negation_condition = false
                    match_values       = ["10.0.1.0/24", "10.0.0.0/24"]
                }
                
                rule2={
                    enabled                        = true
                    priority                       = 2
                    rate_limit_duration_in_minutes = 1
                    rate_limit_threshold           = 10
                    type                           = "MatchRule"
                    action                         = "Block"
                    match_variable     = "RemoteAddr"
                    operator           = "IPMatch"
                    negation_condition = false
                    match_values       = ["192.168.1.0/24"]
                }
            }
            managed_rules ={
                rule1 = {
                    type    = "Microsoft_BotManagerRuleSet"
                    version = "1.0"
                    action  = "Log"
                }
                rule2  = {
                    type    = "DefaultRuleSet"
                    version = "1.0"
                    action = "Allow"
                    exclusions = {
                        exclusion1 = {
                            match_variable = "QueryStringArgNames"
                            operator       = "Equals"
                            selector       = "not_suspicious"
                        }
                    }
                    overrides = {
                        override1 = {
                            rule_group_name = "PHP"
                            rules = {
                                rule_1 = {
                                    rule_id = "933100"
                                    enabled = false
                                    action  = "Block"
                                }
                            }

                        }
                        override2 = {
                            rule_group_name = "SQLI"
                            exclusions = {
                                exclusion ={
                                    match_variable = "QueryStringArgNames"
                                    operator       = "Equals"
                                    selector       = "really_not_suspicious"
                                }
                            }

                            rules = {
                                rule_2 ={
                                    rule_id = "942200"
                                    action  = "Block"

                                    exclusion ={
                                    match_variable = "QueryStringArgNames"
                                    operator       = "Equals"
                                    selector       = "innocent"
                                    }
                                }
                            }

                        }
                    }
                }
            }

        }
                # Front Door Security Policies
        security_policy = {
            patterns_to_match = ["/*"]
        }

        # Front Door Secret
        # secret = {
        #     key_vault_certificate_id = "" # required. kevault certificate id
        # }

        # Tags for All Resources
        tags = {
            environment = "dev"
            project     = "example-project"
            owner       = "team-azure"
        }
    }


}
