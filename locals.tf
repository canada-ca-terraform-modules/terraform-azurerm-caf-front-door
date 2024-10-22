locals {
  resource_group_name = strcontains(var.front_door.resource_group, "/resourceGroups/") ? regex("[^\\/]+$", var.front_door.resource_group) :  var.resource_groups[var.front_door.resource_group].name
}