locals {
  private_location_permissions = [
    "compute.disks.create",
    "compute.instances.create",
    "compute.instances.delete",
    "compute.instances.list",
    "compute.instances.setLabels",
    "compute.instances.setMetadata",
    "compute.subnetworks.use",
    "compute.subnetworks.useExternalIp",
    "secretmanager.versions.access"
  ]

  private_package_permissions = [
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "iam.serviceAccounts.signBlob"
  ]

  custom_image_permissions = [
    "compute.images.useReadOnly"
  ]

  instance_template_permissions = [
    "compute.instanceTemplates.useReadOnly"
  ]

  has_custom_image = anytrue([
    for location in local.locations : location.machine != null ? location.machine.image.type == "custom" : false
  ])

  has_instance_template = anytrue([
    for location in local.locations : lookup(location, "instance-template", null) != null
  ])

  has_private_package = local.private-package != null

  extra_permissions = concat(
    local.has_custom_image ? local.custom_image_permissions : [],
    local.has_instance_template ? local.instance_template_permissions : [],
    local.has_private_package ? local.private_package_permissions : []
  )

  permissions = concat(local.private_location_permissions, local.extra_permissions)
}

data "google_client_config" "current" {}

resource "google_project_iam_custom_role" "custom_role" {
  role_id     = "control_plane_role_${replace(var.name, "-", "_")}"
  title       = "Gatling Control Plane Role"
  description = "A custom role with permissions to spawn and terminate Gatling load injectors and access secret manager versions."
  project     = data.google_client_config.current.project
  permissions = local.permissions
}

resource "google_service_account" "service_account" {
  account_id   = coalesce(var.service-account-name, var.name)
  display_name = "Gatling Control Plane Service Account"
}

resource "google_project_iam_member" "service_account_role_binding" {
  project = data.google_client_config.current.project
  role    = google_project_iam_custom_role.custom_role.name
  member  = "serviceAccount:${google_service_account.service_account.email}"
}
