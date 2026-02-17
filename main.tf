locals {
  locations       = [for loc in var.locations : merge(loc, { type = "gcp" })]
  private-package = var.private-package != null ? merge(var.private-package, { type = "gcp" }) : null
}
