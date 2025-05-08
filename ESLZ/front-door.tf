variable "front_doors" {
  type = any
  default = {}
  description = "Front Doors to deploy"
}

module "front_door" {
    source = "github.com/canada-ca-terraform-modules/terraform-azurerm-caf-front-door.git?ref=v1.0.4"

    for_each = var.front_doors
    env = var.env
    group = var.group
    project = var.project
    userDefinedString = each.key
    front_door= each.value
    resource_groups = local.resource_groups_all
    zones = local.zones
    origin_host_name             = "example2.example.com"
    tags = var.tags
}