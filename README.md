# terraform-gcp-control-plane

Terraform module to deploy a [Gatling Control Plane](https://docs.gatling.io/reference/install/cloud/private-locations/gcp/installation/) on a GCP Compute Engine virtual machine.

## Features

- Deploys a Gatling Control Plane as a GCP Compute Engine VM running Docker on Container-Optimized OS
- Configures [Private Locations](https://docs.gatling.io/reference/install/cloud/private-locations/gcp/configuration/) for load generator provisioning on GCP Compute Engine instances
- Optional [Private Packages](https://docs.gatling.io/reference/install/cloud/private-locations/private-packages/) support via Google Cloud Storage
- Least-privilege IAM custom role and service account created automatically
- Supports shielded and confidential VM configurations

## Prerequisites

- Terraform `>= 1.0`
- Google provider
- An existing GCP project with Compute Engine and Secret Manager APIs enabled
- A Gatling control plane token stored in GCP Secret Manager

> [!IMPORTANT]
> This module does **not** create any networking resources (VPC, subnets, etc.) or the GCP project. These must be provided as inputs.

## Examples

- [Complete example](example/)

## Requirements

| Name                                                                | Version |
|---------------------------------------------------------------------|---------|
| [terraform](https://www.terraform.io/)                              | >= 1.0  |
| [google](https://registry.terraform.io/providers/hashicorp/google/) | >= 4.0  |

## Providers

| Name                                                                |
|---------------------------------------------------------------------|
| [google](https://registry.terraform.io/providers/hashicorp/google/) |

## Resources

| Name                                            | Type        |
|-------------------------------------------------|-------------|
| `google_compute_instance`                       | resource    |
| `google_project_iam_custom_role`                | resource    |
| `google_service_account`                        | resource    |
| `google_project_iam_member`                     | resource    |
| `random_string`                                 | resource    |
| `google_client_config`                          | data source |

## Documentation

- [GCP Private Locations — Installation](https://docs.gatling.io/reference/install/cloud/private-locations/gcp/installation/)
- [GCP Private Locations — Configuration](https://docs.gatling.io/reference/install/cloud/private-locations/gcp/configuration/)
- [Private Packages](https://docs.gatling.io/reference/install/cloud/private-locations/private-packages/)
- [Build from Sources](https://docs.gatling.io/reference/execute/cloud/user/build-from-sources/)

## License

Apache 2.0 — see [LICENSE](LICENSE) for details.
