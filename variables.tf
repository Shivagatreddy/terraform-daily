variable "location" {
  default = "East US"
}

variable "resource_group_name" {
  default = "aks-lab-rg"
}

variable "acr_name" {
  default = "aksPythonACR"
}

variable "sql_server_name" {
  default = "akssqlserverdemos"
}

variable "sql_admin_user" {
  default = "sqladminuser"
}

variable "keyvault_name" {
  default = "kvaksdemobharath"
}

variable "sql_admin_password" {
  description = "Password for SQL admin user"
  sensitive   = true
  default = " "
}
