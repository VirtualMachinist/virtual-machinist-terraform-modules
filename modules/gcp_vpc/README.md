# GCP VPC Module

Creates a secure GCP VPC with public/private subnets and IAP firewall rules.

## Usage
```hcl
module "foundry_network" {
  source = "github.com/VirtualMachinist/virtual-machinist-terraform-modules//modules/gcp_vpc?ref=v1.0.0"

  project_id   = "vm-foundry-dev"
  vpc_name     = "foundry-vpc"
  region       = "us-central1"
  public_cidr  = "10.0.1.0/24"
  private_cidr = "10.0.2.0/24"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project_id | GCP project ID | string | n/a | yes |
| vpc_name | Name of the VPC | string | n/a | yes |
| region | GCP region | string | n/a | yes |
| public_cidr | Public subnet CIDR | string | "10.0.1.0/24" | no |
| private_cidr | Private subnet CIDR | string | "10.0.2.0/24" | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | VPC ID |
| vpc_self_link | VPC self-link |
| public_subnet_id | Public subnet ID |
| private_subnet_id | Private subnet ID |

## Cert Ties
- **Terraform Associate**: Module composition, variables/outputs
- **GCP Cloud Architect**: VPC design, private subnets, IAP access