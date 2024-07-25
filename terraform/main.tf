locals {
  bucket_name  = "azure-multitenant-ubuntu-2204"
  channel_name = "latest"
  location     = "eastus"
}


data "hcp_packer_artifact" "tenant1-image" {
  bucket_name    = local.bucket_name
  channel_name   = local.channel_name
  region         = local.location
  platform       = "azure"
  component_type = "azure-arm.azure-ubuntu-tenant01"
}

data "hcp_packer_artifact" "tenant2-image" {
  bucket_name    = local.bucket_name
  channel_name   = local.channel_name
  region         = local.location
  platform       = "azure"
  component_type = "azure-arm.azure-ubuntu-tenant02"
}

output "tenant01-image" {
  value = data.hcp_packer_artifact.tenant1-image.external_identifier
}

output "tenant02-image" {
  value = data.hcp_packer_artifact.tenant2-image.external_identifier
}
