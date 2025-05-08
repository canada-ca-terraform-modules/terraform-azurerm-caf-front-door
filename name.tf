locals {
  name_regex = "/[//\"'\\[\\]:|<>+=;,?*@&]/" # Can't include those characters  name: \/"'[]:|<>+=;,?*@&
  env_4                         = substr(var.env, 0, 4)
  userDefinedString_7           = substr(var.userDefinedString, 0, 64 - (7 + length(var.project)))
  front-door-name                = replace("${local.env_4}-${var.project}-${local.userDefinedString_7}", local.name_regex, "")
  rule_set-name =               replace("${local.front-door-name}", "-", "")

}