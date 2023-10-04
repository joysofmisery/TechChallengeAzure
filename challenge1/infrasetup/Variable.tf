variable "rg" {
  type    = string
  default = ""
}

variable "prodresourcegroup" {
  type    = string
  default = ""
}
variable "bootdiag_SA" {
  type    = string
  default = ""
}

variable "bootdiag_RG" {
  type    = string
  default = ""
}

variable "keyvault" {
  type    = string
  default = ""
}

variable "keyvaultrg" {
  type    = string
  default = ""
}

variable "tags" {
  type = map(any)
  default = {
    "Created By" = "amit.singh"
    ENV          = "Prod"
    Client       = "XYZ"
    "Created On" = "3 Oct 2023"
  }
}

variable "vnetaddress" {
  type    = string
  default = ""
}

variable "prodsubnetaddress" {
  type    = string
  default = ""
}

variable "devsubnetaddress" {
  type    = string
  default = ""
}

variable "uatsubnetaddress" {
  type    = string
  default = ""
}

variable "dbsubnetaddress" {
  type    = string
  default = ""
}

variable "ddosrg" {
  type    = string
  default = ""
}

variable "ddosname" {
  type    = string
  default = ""
}

variable "vmnameweb" {
  type = map(object({
    name = string
    size = string
    disk = string
    nic  = number
  }))
}

variable "vmnameapp" {
  type = map(object({
    name = string
    size = string
    disk = string
    nic  = number
  }))
}

variable "dbvm" {
  type = map(object({
    name        = string
    size        = string
    disk_db     = string
    disk_log    = string
    disk_backup = string
  }))
}

variable "clientname" {
  type    = string
  default = ""
}

variable "location" {
  type    = string
  default = ""
}
