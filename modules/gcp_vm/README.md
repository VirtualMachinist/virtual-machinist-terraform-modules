# GCP VM Module

Creates a Google Compute Engine VM instance with configurable networking, boot disk, and security settings.

## Usage
```hcl
module "foundry_vm" {
  source = "github.com/VirtualMachinist/virtual-machinist-terraform-modules//modules/gcp_vm?ref=v1.0.0"

  project_id = "virtual-machinist"
  vm_name    = "foundry-workstation"
  zone       = "us-central1-a"

  machine_type = "e2-medium"
  image        = "rocky-linux-cloud/rocky-linux-9"
  disk_size_gb = 50

  network    = module.foundry_network.vpc_self_link
  subnetwork = module.foundry_network.private_subnet_id

  tags             = ["allow-iap-ssh"]
  enable_public_ip = false

  startup_script = file("${path.module}/scripts/bootstrap.sh")

  labels = {
    environment = "dev"
    purpose     = "foundry-workstation"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_id | GCP project ID | string | n/a | yes |
| vm_name | Name of the VM instance | string | n/a | yes |
| zone | GCP zone for the VM | string | n/a | yes |
| machine_type | Machine type | string | "e2-medium" | no |
| image | Boot disk image | string | "rocky-linux-cloud/rocky-linux-9" | no |
| disk_size_gb | Boot disk size in GB | number | 20 | no |
| network | VPC network | string | n/a | yes |
| subnetwork | Subnetwork | string | n/a | yes |
| tags | Network tags | list(string) | ["allow-iap-ssh"] | no |
| enable_public_ip | Assign external IP | bool | false | no |
| service_account_email | Service account email | string | null | no |
| service_account_scopes | OAuth scopes | list(string) | ["cloud-platform"] | no |
| metadata | Metadata key-value pairs | map(string) | {} | no |
| startup_script | Startup script | string | null | no |
| labels | Labels for the VM | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| vm_name | Name of the VM |
| vm_id | Instance ID |
| vm_self_link | Self-link of the VM |
| internal_ip | Internal IP address |
| external_ip | External IP (if assigned) |
| zone | Zone of the VM |

## Features

- **Shielded VM**: Secure Boot, vTPM, and Integrity Monitoring enabled by default
- **IAP-ready**: Default tag `allow-iap-ssh` works with the `gcp_vpc` module's firewall rules
- **No public IP by default**: Follows security best practices for private subnet workloads
- **Flexible startup script**: Pass bootstrap commands or reference external scripts

## Cert Ties

- **Terraform Associate**: Module composition, variables/outputs, dynamic blocks
- **GCP Cloud Architect**: Compute Engine, networking, security best practices
- **GCP DevOps**: Infrastructure automation, VM lifecycle management