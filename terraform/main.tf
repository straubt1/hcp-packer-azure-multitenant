locals {
  bucket_name  = "azure-multitenant-ubuntu-2204"
  channel_name = "latest"
}

data "hcp_packer_artifact" "tenant1-eastus" {
  bucket_name    = local.bucket_name
  channel_name   = local.channel_name
  platform       = "azure"
  component_type = "azure-arm.azure-ubuntu-tenant01"
  region         = "eastus"
}

data "hcp_packer_artifact" "tenant1-westus" {
  bucket_name    = local.bucket_name
  channel_name   = local.channel_name
  platform       = "azure"
  component_type = "azure-arm.azure-ubuntu-tenant01"
  region         = "eastus" # must specify the region the SIG is deployed to

  lifecycle {
    postcondition {
      condition     = contains(split(", ", self.labels["sig_replicated_regions"]), "westus")
      error_message = "Bucket Version does not contain a SIG replication in 'westus'"
    }
  }
}


data "hcp_packer_artifact" "tenant2-eastus" {
  bucket_name    = local.bucket_name
  channel_name   = local.channel_name
  platform       = "azure"
  component_type = "azure-arm.azure-ubuntu-tenant02"
  region         = "eastus"
}

data "hcp_packer_artifact" "tenant2-westus" {
  bucket_name    = local.bucket_name
  channel_name   = local.channel_name
  platform       = "azure"
  component_type = "azure-arm.azure-ubuntu-tenant02"
  region         = "eastus" # must specify the region the SIG is deployed to

  lifecycle {
    postcondition {
      condition     = contains(split(", ", self.labels["sig_replicated_regions"]), "westus")
      error_message = "Bucket Version does not contain a SIG replication in 'westus'"
    }
  }
}

output "images" {
  value = {
    tenant01-eastus = data.hcp_packer_artifact.tenant1-eastus.external_identifier
    tenant01-westus = data.hcp_packer_artifact.tenant1-westus.external_identifier
    tenant02-eastus = data.hcp_packer_artifact.tenant2-eastus.external_identifier
    tenant02-westus = data.hcp_packer_artifact.tenant2-westus.external_identifier
  }
}

