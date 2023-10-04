#Standard Values
# ddosrg     = "DDoS-RG"
# ddosname   = "DDoS1"
keyvault   = "Az-Terraform-KeyVault"
keyvaultrg = "Hub01"

#Assign Variables values for ProdVnet creation
#**************************************************************************************************************************************
vnetaddress       = "10.0.61.0/25" 
websubnetaddress = "10.0.61.0/27" 
appsubnetaddress  = "10.0.61.32/27"
dbsubnetaddress   = "10.0.61.64/27"
prodresourcegroup = "tier3-Prod"
clientname        = "tier3"
location = "Central India"

#Assign Variables values for VM creation
#**************************************************************************************************************************************
rg                 = "tier3-Prod"
dbvm = {
  "dbvm1" = {
    name        = "VMINDB01A"
    size        = "Standard_E4ds_v5"
    disk_db     = "256"
    disk_log    = "128"
    disk_backup = "128"
  },
  "dbvm2" ={
    name        = "VMINDB01B"
    size        = "Standard_E4ds_v5"
    disk_db     = "256"
    disk_log    = "128"
    disk_backup = "128"
  }
}
vmnameweb = {
  "vm1" = {
    name  = "INMAZWIWP01A"
    size  = "Standard_D4ds_v5"
    disk = "128"
  },
  "vm2" = {
    name  = "INMAZWIWP01B"
    size  = "Standard_D4ds_v5"
    disk = "128"
  }
}
vmnameapp = {
  "vm1" = {
    name  = "VMINAPP01A"
    size  = "Standard_D4ds_v5"
    disk = "128"
  },
  "vm2" = {
    name  = "INMAZWIAP01B"
    size  = "Standard_D4ds_v5"
    disk = "128"
  }
}
# boot diagnostic settings (Storage account and RG are location specific, see below for values)
bootdiag_SA = "bootdiagin"
bootdiag_RG = "Boot-Diag-In"