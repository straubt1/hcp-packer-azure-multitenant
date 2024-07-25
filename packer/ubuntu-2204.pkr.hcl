packer {
  required_plugins {
    azure = {
      version = ">= 2.0.2"
      source  = "github.com/hashicorp/azure"
    }
  }
}

# variable "tenant01" {
#   description = "Credentials for Azure Tenant 1"
#   type = object(
#     {
#       name            = string
#       tenant_id       = string
#       subscription_id = string
#       client_id       = string
#       client_secret   = string
#     }
#   )
#   default = {
#     name            = env("t01_ARM_TENANT_NAME")
#     tenant_id       = env("t01_ARM_TENANT_ID")
#     subscription_id = env("t01_ARM_SUBSCRIPTION_ID")
#     client_id       = env("t01_ARM_CLIENT_ID")
#     client_secret   = env("t01_ARM_CLIENT_SECRET")
#   }
# }

# variable "tenant02" {
#   description = "Credentials for Azure Tenant 1"
#   type = object(
#     {
#       name            = string
#       tenant_id       = string
#       subscription_id = string
#       client_id       = string
#       client_secret   = string
#     }
#   )
#   default = {
#     name            = env("t02_ARM_TENANT_NAME")
#     tenant_id       = env("t02_ARM_TENANT_ID")
#     subscription_id = env("t02_ARM_SUBSCRIPTION_ID")
#     client_id       = env("t02_ARM_CLIENT_ID")
#     client_secret   = env("t02_ARM_CLIENT_SECRET")
#   }
# }

variable "tenant_configuration" {
  type = list(object({
    location                          = string # Location to build the image in
    image_resource_group_name         = string # RG to store the image in
    tenant_id                         = string
    subscription_id                   = string
    client_id                         = string
    client_secret                     = string
    image_gallery_resource_group_name = string
    image_gallery_name                = string       # SIG name
    image_regions                     = list(string) # List of regions to replicate the image in with the SIG
  }))

  validation {
    condition     = length(var.tenant_configuration) == 2
    error_message = "There must be exactly 2 tenants configurations passed into this template."
  }
}

# variable "azure_configuration" {
#   description = ""
#   type = object(
#     {
#       location                  = string
#       image_resource_group_name = string
#       # image_gallery_name          = string
#       # image_regions               = list(string)
#       # build_resource_group_name   = string
#       # virtual_network_name        = string
#       # virtual_network_subnet_name = string
#     }
#   )
#   default = {
#     location                  = env("ARM_LOCATION")
#     image_resource_group_name = env("ARM_IMAGE_RESOURCE_GROUP_NAME")
#     # image_gallery_name          = env("ARM_IMAGE_GALLERY_NAME")
#     # image_regions               = [""] #env("ARM_IMAGE_GALLERY_REGIONS")
#     # build_resource_group_name   = env("ARM_VNET_RESOURCE_GROUP_NAME")
#     # virtual_network_name        = env("ARM_VNET_NAME")
#     # virtual_network_subnet_name = env("ARM_SUBNET_NAME")
#   }
# }


locals {
  os_name     = "ubuntu-2204"
  bucket_name = "azure-multitenant-${local.os_name}"
  date        = formatdate("HHmm", timestamp())

  os_type         = "Linux"
  image_offer     = "0001-com-ubuntu-server-jammy"
  image_publisher = "Canonical"
  image_sku       = "22_04-lts-gen2" #"22_04-lts"

  # 
  azure_image_name = local.bucket_name # join("_", [local.bucket_name, local.os_name])
  image_version    = "0.0.5"           # must increment for each build

  common_tags = {
    os         = "ubuntu"
    os-version = "2204"
    owner      = "azure-team"
    built-by   = "packer"
    build-date = local.date
  }
  build_tags = {
    build-time   = timestamp()
    build-source = basename(path.cwd)
  }
}


source "azure-arm" "ubuntu-t01" {
  tenant_id       = var.tenant_configuration[0].tenant_id
  subscription_id = var.tenant_configuration[0].subscription_id
  client_id       = var.tenant_configuration[0].client_id
  client_secret   = var.tenant_configuration[0].client_secret

  os_type         = local.os_type
  image_offer     = local.image_offer
  image_publisher = local.image_publisher
  image_sku       = local.image_sku

  vm_size                           = "Standard_B2als_v2"
  managed_image_resource_group_name = var.tenant_configuration[0].image_resource_group_name
  location                          = var.tenant_configuration[0].location
  ssh_username                      = "azureuser" # Set this here since it is different in AWS and Azure
  ssh_agent_auth                    = false

  azure_tags = local.common_tags

  shared_image_gallery_destination {
    subscription        = var.tenant_configuration[0].subscription_id
    resource_group      = var.tenant_configuration[0].image_gallery_resource_group_name
    gallery_name        = var.tenant_configuration[0].image_gallery_name
    replication_regions = var.tenant_configuration[0].image_regions
    image_name          = local.azure_image_name
    image_version       = local.image_version
  }
}

source "azure-arm" "ubuntu-t02" {
  tenant_id       = var.tenant_configuration[1].tenant_id
  subscription_id = var.tenant_configuration[1].subscription_id
  client_id       = var.tenant_configuration[1].client_id
  client_secret   = var.tenant_configuration[1].client_secret

  os_type         = local.os_type
  image_offer     = local.image_offer
  image_publisher = local.image_publisher
  image_sku       = local.image_sku

  vm_size                           = "Standard_B2als_v2"
  managed_image_resource_group_name = var.tenant_configuration[1].image_resource_group_name
  location                          = var.tenant_configuration[1].location
  ssh_username                      = "azureuser" # Set this here since it is different in AWS and Azure
  ssh_agent_auth                    = false

  azure_tags = local.common_tags

  shared_image_gallery_destination {
    subscription        = var.tenant_configuration[1].subscription_id
    resource_group      = var.tenant_configuration[1].image_gallery_resource_group_name
    gallery_name        = var.tenant_configuration[1].image_gallery_name
    replication_regions = var.tenant_configuration[1].image_regions
    image_name          = local.azure_image_name
    image_version       = local.image_version
  }
}

build {
  name = "azure"

  hcp_packer_registry {
    bucket_name   = local.bucket_name
    description   = "Multi Azure Tenant Image Deployment to HCP Packer Registry."
    bucket_labels = local.common_tags
    build_labels  = local.build_tags
  }

  # This source will create the image in Tenant 1
  # with the component_type "azure-arm.azure-ubuntu-tenant01"
  source "source.azure-arm.ubuntu-t01" {
    name = "azure-ubuntu-tenant01" # must be string literal
    # managed_image_name = join("_", [local.bucket_name, "azure", local.os_name, "tenant01"])
  }

  # This source will create the image in Tenant 2
  # with the component_type "azure-arm.azure-ubuntu-tenant02"
  source "source.azure-arm.ubuntu-t02" {
    name = "azure-ubuntu-tenant02" # must be string literal
    # managed_image_name = join("_", [local.bucket_name, "azure", local.os_name, "tenant02"])
  }
}
