variable "location" {
  description = "Azure location for the VM"
  type = string
  default = "canadacentral"
}

variable "tags" {
  description = "Tags that will be applied to every associated VM resource"
  type = map(string)
  default = {}
}

variable "env" {
  description = "(Required) 4 character string defining the environment name prefix for the VM"
  type = string
}

variable "group" {
  description = "(Required) Character string defining the group for the target subscription"
  type = string
}

variable "project" {
  description = "(Required) Character string defining the project for the target subscription"
  type = string
}

variable "userDefinedString" {
  description = "(Required) User defined portion value for the name of the VM."
  type = string
}

variable "front_door" {
  description = "(Required) front door configuration."
  type        = any
  default     = null
}

variable "resource_groups" {
  description = "(Required) Resource group object for the front door"
  type = any
  default = {}
}

variable "zones" {
  description = "(Required) Resource DNS zone object for the front door"
  type = any
  default = {}
}

variable "origin_host_name" {
  description = "(Required) Host name of origin for the front door"
  type = string
}




