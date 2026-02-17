variable "name" {
  description = "Name of the control plane"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9\\-]{5,29}$", var.name))
    error_message = "The name must be 6-30 characters, start with a lowercase letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "service-account-name" {
  description = "Name of the service account to create. Defaults to var.name."
  type        = string
  default     = null
}

variable "description" {
  description = "Description of the control plane."
  type        = string
  default     = "My GCP control plane description"
}

variable "token-secret-name" {
  description = "Control plane secret token stored in GCP Secret Manager."
  type        = string

  validation {
    condition     = length(var.token-secret-name) > 0
    error_message = "The token secret name must not be empty."
  }
}

variable "network" {
  description = "Network configuration for the VM"
  type = object({
    zone               = string
    network            = optional(string)
    subnetwork         = optional(string)
    enable-external-ip = optional(bool, true)
  })

  validation {
    condition     = var.network.zone != null
    error_message = "Zone must be provided."
  }
  validation {
    condition = (
      (var.network.network != null ? length(var.network.network) : 0) > 0 ||
      (var.network.subnetwork != null ? length(var.network.subnetwork) : 0) > 0
    )
    error_message = "Either network or subnetwork must be specified in the network configuration."
  }
}

variable "compute" {
  description = "Compute configuration for the VM"
  type = object({
    boot-disk-image            = optional(string, "projects/cos-cloud/global/images/cos-stable-113-18244-85-49")
    machine-type               = optional(string, "e2-standard-2")
    min-cpu-platform           = optional(string)
    confidential-instance-type = optional(string)
    shielded = optional(object({
      enable-secure-boot          = optional(bool, true)
      enable-vtpm                 = optional(bool, true)
      enable-integrity-monitoring = optional(bool, true)
    }), {})
    confidential = optional(object({
      enable        = optional(bool, false)
      instance-type = optional(string, "e2-standard-2")
    }), {})
  })
  default = {}
}

variable "container" {
  description = "Container configuration for the control plane"
  type = object({
    image       = optional(string, "gatlingcorp/control-plane:latest")
    command     = optional(list(string), [])
    environment = optional(list(string), [])
  })
  default = {}
}

variable "git" {
  description = "Control plane git configuration."
  type = object({
    credentials = optional(object({
      username          = optional(string, "")
      token-secret-name = optional(string, "")
    }), {})
    ssh = optional(object({
      secret-name = optional(string, "")
      file-name   = optional(string, "id_rsa")
    }), {})
    cache = optional(object({
      paths = optional(list(string), [])
    }), {})
  })
  default = {}

  validation {
    condition = (
      length(var.git.credentials.username) == 0 ||
      length(var.git.credentials.token-secret-name) > 0
    )
    error_message = "When credentials.username is set, credentials.token-secret-name must also be provided."
  }
}

variable "locations" {
  description = "Configuration for the private locations."
  type = list(object({
    id                = string
    description       = optional(string, "Private Location on GCP")
    project           = string
    zone              = string
    instance-template = optional(string, null)
    machine = optional(object({
      type        = optional(string, "c3-highcpu-4")
      preemptible = optional(bool, false)
      engine      = optional(string, "classic")
      image = optional(object({
        type    = optional(string, "certified")
        java    = optional(string, "latest")
        project = optional(string)
        family  = optional(string)
        id      = optional(string)
      }), {})
      disk = optional(object({ sizeGb = number }), { sizeGb = 20 })
      network-interface = optional(object({
        project          = optional(string)
        network          = optional(string)
        subnetwork       = optional(string)
        with-external-ip = optional(bool, true)
      }), {})
    }), null)
    system-properties = optional(map(string), {})
    java-home         = optional(string, null)
    jvm-options       = optional(list(string), [])
    enterprise-cloud  = optional(map(any), {})
  }))

  validation {
    condition     = length(var.locations) > 0
    error_message = "At least one private location must be specified."
  }

  validation {
    condition     = alltrue([for loc in var.locations : can(regex("^prl_[0-9a-z_]{1,26}$", loc.id))])
    error_message = "Private location ID must be prefixed by 'prl_', contain only numbers, lowercase letters, and underscores, and be at most 30 characters long."
  }

  validation {
    condition     = alltrue([for loc in var.locations : length(loc.project) > 0])
    error_message = "Project must not be empty."
  }

  validation {
    condition     = alltrue([for loc in var.locations : length(loc.zone) > 0])
    error_message = "Zone must not be empty."
  }

  validation {
    condition     = alltrue([for loc in var.locations : loc.machine == null ? true : contains(["classic", "javascript"], loc.machine.engine)])
    error_message = "The engine must be either 'classic' or 'javascript'."
  }

  validation {
    condition     = alltrue([for loc in var.locations : loc.machine == null ? true : contains(["certified", "custom"], loc.machine.image.type)])
    error_message = "The image type must be either 'certified' or 'custom'."
  }

  validation {
    condition = alltrue([for loc in var.locations : loc.machine == null ? true : (loc.machine.image.type != "custom" || (
      loc.machine.image.project != null &&
      (loc.machine.image.id != null || loc.machine.image.family != null)
    ))])
    error_message = "If image.type is 'custom', then project must be defined and either id or family must be specified."
  }

  validation {
    condition     = alltrue([for loc in var.locations : loc.machine == null ? true : loc.machine.disk.sizeGb >= 20])
    error_message = "Disk sizeGb must be greater than or equal to 20."
  }
}

variable "private-package" {
  description = "Configuration for the private package (GCS-based)."
  type = object({
    project = string
    bucket  = string
    path    = optional(string, "")
    upload = optional(object({
      directory = string
    }), { directory = "/tmp" })
  })
  default = null

  validation {
    condition     = var.private-package == null || length(var.private-package.bucket) > 0
    error_message = "Bucket must not be empty."
  }

  validation {
    condition     = var.private-package == null || length(var.private-package.project) > 0
    error_message = "Project must not be empty."
  }
}

variable "enterprise-cloud" {
  type    = map(any)
  default = {}
}

variable "extra-content" {
  type    = map(any)
  default = {}
}

variable "server" {
  description = "Control Plane Repository Server configuration."
  type = object({
    port        = optional(number, 8080)
    bindAddress = optional(string, "0.0.0.0")
    certificate = optional(object({
      path     = optional(string)
      password = optional(string, null)
    }), null)
  })
  default = {}

  validation {
    condition     = var.server.port > 0 && var.server.port <= 65535
    error_message = "Server port must be between 1 and 65535."
  }
  validation {
    condition     = length(var.server.bindAddress) > 0
    error_message = "Server bindAddress must not be empty."
  }
}
