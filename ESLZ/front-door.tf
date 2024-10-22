variable "front_doors" {
  type = any
  default = {}
  description = "Value for run books. This is a collection of values as defined in runbook.tfvars"
}

module "front_door" {
    for_each = var.front_doors
    source = "github.com/canada-ca-terraform-modules/terraform-azurerm-caf-front-door.git"
    env = var.env
    group = var.group
    project = var.project
    userDefinedString = each.key
    front_door= each.value
    resource_groups = local.resource_groups_all
    zones = local.zones
    origin_host_name             = "example2.example.com"
}